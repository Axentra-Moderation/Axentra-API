# Axentra API — TODO & Status

This tracks what's actually been built vs. the original plan (`plan.md`), notable
deviations made along the way, known bugs, and what's left.

Last reviewed against commit `27cae86` + this session's fixes.

---

## Deviations from the original plan

These are intentional changes made during implementation that differ from
`plan.md` — documented here so the plan doc and the real API don't silently
drift apart.

- **Unban is `DELETE /guilds/:guildId/moderation/ban/:userId`, not a separate
  `POST /unban` route.** The plan originally called for a dedicated unban
  endpoint. Instead, ban/unban share one resource path
  (`/moderation/ban/:userId`) and are distinguished by HTTP verb:
  - `PUT /guilds/:guildId/moderation/ban/:userId` → ban
  - `DELETE /guilds/:guildId/moderation/ban/:userId` → unban
    This is more RESTful (ban is a resource you create/destroy) and matches
    Discord's own API shape for bans.
- **Ban creation uses `PUT`, not `POST`**, again to mirror Discord's own
  `PUT /guilds/{guild.id}/bans/{user.id}` semantics and to make the ban
  idempotent-by-intent (creating the same ban twice should converge, not
  pile up duplicate rows — see bug below where this isn't quite true yet).
- **Database schema was completely revamped to mirror Discord's actual API
  objects** (`User`, `Guild`, `Role`, `Emoji`, `Sticker`, `GuildMember`, etc.)
  rather than the original lean, mod-log-focused schema in `plan.md`
  (`Guild` → `GuildMember` → `Warning`/`Ban`/`Mute`/`Kick`/`Purge`/`Pardon`).
  The current schema is much closer to a full local mirror of Discord's
  object model, with moderation-specific models (`Ban`, `Log`) layered on
  top via relations to `User`/`Guild`/`GuildMember`.
  - The original `ModLog` model with a single `ModerationAction` enum
    (`WARN`, `BAN`, `UNBAN`, `KICK`, `MUTE`, `UNMUTE`, `PURGE`, `PARDON`) was
    replaced by a `Log` model with a near-identical `LogAction` enum, but
    `Warning`, `Mute`, `Kick`, `Purge`, and `Pardon` no longer exist as their
    own models — only `Ban` and `Log` exist. Anything beyond ban/unban is
    presumably meant to be represented purely through `Log` rows for now.
- **Prisma generator switched from `prisma-client-js` to `prisma-client`**
  (Prisma 7's new client generator), with a custom output path
  (`src/generated/prisma`) instead of the plan's `../generated/prisma`
  (repo root). Entry point is `generated/prisma/client.js`, not `index.js`.
- **API key auth uses a `mod_pk_` prefix convention** to distinguish bot
  keys from dashboard JWTs inside the same `Authorization: Bearer` header,
  rather than two different headers/schemes. `auth.ts` branches on whether
  the token starts with `mod_pk_`.
- **API keys are managed via a one-time CLI script** (`npm run key:generate`
  → `src/utils/generate-key.ts`), not an admin HTTP endpoint, by design —
  there is currently no plan to expose key creation over the API.
- **CORS and the global error handler are stubbed out / commented out**
  in `app.ts` for now (`helmet` is active, `cors` and `errorHandler` are
  not yet wired in), as is the `logs`/`warnings`/`permissions` route
  group — only `auth`, `guilds`, and `moderation` routers are mounted.

---

## Known bugs / inconsistencies to fix

- [x] `lib/prisma.ts` duplicate client removed — `apiKey.repo.ts` now uses
      the shared `getPrisma()` singleton. `lib/` directory deleted.
- [x] `discordCallback` no longer writes nonexistent `discordAccessToken` /
      `discordRefreshToken` / `discordTokenExpiry` fields, and now correctly
      sets the required `discriminator` field on `create`.
- [x] `unbanUser` now writes a `Log` row (`action: "UNBAN"`).
- [x] `banUser`'s duplicate-ban check now returns `409` instead of `302`.
- [x] `updateGuildSettings`'s `guild.upsert(...)` call is now `await`-ed.
- [x] Unused `logger` import removed from `getGuildSettings.controller.ts`.
- [ ] **JWT shape mismatch — dashboard login currently can't pass auth.**
      `signJwt` (used by the OAuth callback and refresh controllers) only signs
      `{ id, username }`, but `auth.ts`'s `handleJwt` requires `payload.sub` and
      `payload.guildPermissions`, rejecting anything else with
      `401 Malformed JWT payload`. Every dashboard-issued token currently fails
      the auth check it's meant to pass. Needs a decision: sign `sub` +
      `guildPermissions` at issue time (requires resolving guild permissions
      during OAuth callback), or change `handleJwt` to accept `{ id, username }`
      and resolve permissions per-request from the DB. See `AUTH.md`.
- [ ] **No FK pre-checks before writing `Ban`/`Log` rows in moderation
      controllers.** The OAuth callback now upserts the calling dashboard user,
      but ban/unban (typically bot-called) still assume `Guild`/`User` rows
      already exist. First moderation action against a brand-new guild/user
      will still throw `P2003` until a sync job exists (see below) or the
      controllers upsert on write.
- [ ] **Unused import**: `crypto` was imported but unused in `apiKey.repo.ts`
      (hashing happens in `auth.ts` and `apiKey.ts` instead) — removed as part
      of the `lib/prisma.ts` cleanup, flagging here for visibility in case it
      reappears.

---

## Not yet started

- [ ] **Gateway / Discord event sync.** Nothing currently populates `User`,
      `Guild`, `GuildMember`, `Role`, etc. from live Discord events (member
      join, guild update, role changes, etc.). All current writes are
      request-driven (ban/unban, OAuth callback). Needed before moderation
      actions against arbitrary real users/guilds will work without manual
      seeding.
- [ ] **Kick, mute/unmute, warn, purge endpoints.** Only ban/unban exist
      so far. Routes, controllers, and corresponding `Log` actions
      (`KICK`, `MUTE`, `UNMUTE`, `WARN`, `PARDON`, `PURGE` already exist in the
      `LogAction` enum) need implementing.
- [ ] **Permission middleware** (`middleware/permissions.ts` from the
      original plan). Currently `auth.ts` only resolves _who_ the caller is
      (bot vs. dashboard user + JWT payload), not _what_ they're allowed to do
      in a given guild. No route currently checks `guildPermissions` from the
      JWT payload before acting.
- [ ] **Zod request validation** (`middleware/validate.ts` from the plan).
      Not implemented yet — all request bodies/params are read with raw
      `req.body[...]`/`req.params[...]` casts and no runtime shape validation.
- [ ] **Global error handler** (`middleware/errorHandler.ts`). Commented
      out in `app.ts`; each controller currently does its own ad-hoc
      try/catch → status code mapping instead.
- [ ] **CORS.** Commented out in `app.ts`; needed before the dashboard
      (a separate origin) can actually call this API from a browser.
- [ ] **Logs route(s)** (`GET /guilds/:guildId/logs`, `GET /guilds/:guildId/logs/:logId`)
      for the dashboard to read back the `Log` table — no routes exist for
      this yet even though the `Log` model and writes (partially) exist.
- [ ] **Rate limiting** (`express-rate-limit` is a dependency but not
      wired into `app.ts` anywhere yet).
- [ ] **Tests.** No test setup/files exist anywhere in the repo yet.

---

## Notes for next session

- `AUTH.md` and `API.md` were added this session — `AUTH.md` documents the
  caller/header conventions and flags the JWT shape mismatch above;
  `API.md` documents the actually-implemented endpoints as a contract
  reference, separate from `plan.md`'s original design.
- `prisma/seed-mock-guild.ts` exists for local testing — seeds a fixed
  mock `Guild` + owner/target/moderator `User` rows so ban/unban can be
  tested without a live gateway sync. Safe to re-run (uses `upsert`).
- `clearDB.ts` exists at the repo root for wiping local dev data — confirm
  this is dev-only and never wired into any production script.
