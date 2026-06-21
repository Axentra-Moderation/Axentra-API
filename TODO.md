# Axentra API — TODO & Status

This tracks what's actually been built vs. the original plan (`plan.md`), notable
deviations made along the way, known bugs, and what's left.

Last reviewed against commit `7afe2eb`.

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

- [ ] **`lib/prisma.ts` still exists as a second, separate `PrismaClient`
      instance**, used only by `src/repositories/apiKey.repo.ts`. Every other
      controller uses the singleton from `src/utils/prisma.ts` via `getPrisma()`.
      This means there are two separate connection pools / client instances
      doing the same job. Migrate `apiKey.repo.ts` to use `getPrisma()` and
      delete `lib/prisma.ts` entirely.
- [ ] **`discordCallback` (auth callback controller) writes to fields that
      don't exist on the `User` model**: `discordAccessToken`,
      `discordRefreshToken`, `discordTokenExpiry`. The schema has no such
      columns — this will throw at runtime the first time OAuth2 callback is
      actually hit. Either add these fields to `User` in `schema.prisma` (and
      migrate), or stop trying to persist Discord OAuth tokens if they're not
      meant to be stored long-term.
- [ ] **`unbanUser` doesn't write a `Log` row at all.** The ban path creates
      a `Ban` row but the unban path only deletes the `Ban` row — there's no
      audit trail for unbans currently. (A `Log.create({ action: "UNBAN", ... })`
      call needs to be added and properly `await`-ed before the response is sent.)
- [ ] **`banUser`'s duplicate-ban check uses `findMany` + `.length >= 1` and
      returns `302`.** A `302 Found` is a redirect status code and is the wrong
      semantic here — this should likely be `409 Conflict` (resource already
      exists in that state). Also worth considering a unique constraint at the
      DB level (`@@unique([guildId, userId])` scoped to active bans) so this
      can't race under concurrent requests.
- [ ] **`updateGuildSettings` doesn't await `guild.upsert(...)`.** The
      Prisma call's promise is never awaited, so the handler can respond
      `201` before the write has actually completed (or even before it's
      guaranteed to run if the process exits/moves on). Also `logger` is
      imported but the route never logs an error if `try` fails meaningfully
      — the `catch` exists but the original problem (unawaited call) means
      it likely never triggers from real DB errors.
- [ ] **No FK pre-checks before writing `Ban`/`Log` rows.** `Ban.guildId`,
      `Ban.userId`, `Ban.moderatorId` (and the equivalent `Log` fields) are all
      FK-constrained to `Guild`/`User`. If a guild or user hasn't been synced
      into the local DB yet (no gateway listener exists yet — see below), the
      very first moderation action against a new guild/user will fail with a
      `P2003` foreign key violation. Needs either an upsert-on-write strategy
      in the controllers, or a sync job that keeps `Guild`/`User`/`GuildMember`
      populated from Discord events as they happen.
- [ ] **Unused imports**: `logger` is imported but unused in
      `getGuildSettings.controller.ts`; `crypto` is imported but unused in
      `apiKey.repo.ts` (hashing happens in `auth.ts` and `apiKey.ts` instead).

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

- `prisma/seed-mock-guild.ts` exists for local testing — seeds a fixed
  mock `Guild` + owner/target/moderator `User` rows so ban/unban can be
  tested without a live gateway sync. Safe to re-run (uses `upsert`).
- `clearDB.ts` exists at the repo root for wiping local dev data — confirm
  this is dev-only and never wired into any production script.
