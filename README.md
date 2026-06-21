# Axentra API

A standalone REST API that serves as the single source of truth for
moderation data and logic, consumed by two separate clients: a Discord
moderation bot and a web dashboard. Built with Express 5, Prisma 7, and
PostgreSQL.

> For implementation status and known issues in detail, see
> [`TODO.md`](./TODO.md). For auth conventions, see [`AUTH.md`](./AUTH.md).
> For the as-built endpoint reference, see [`API.md`](./API.md). For the
> original design document, see [`plan.md`](./plan.md).

---

## What this is

```
┌─────────────────┐        ┌─────────────────┐
│   Discord Bot    │        │  Web Dashboard   │
└────────┬─────────┘        └────────┬─────────┘
         │  Bot API key              │  Discord OAuth2 → JWT
         └──────────┬─────────────────┘
                    │ HTTPS
          ┌─────────▼─────────┐
          │   Axentra API      │
          │   (Express)        │
          ├────────────────────┤
          │   PostgreSQL        │
          │   (via Prisma)      │
          └────────────────────┘
```

The bot authenticates with a static, hashed API key (server-to-server). The
dashboard authenticates via Discord OAuth2, exchanged for a JWT. Both hit
the same endpoints — a single `auth` middleware resolves caller identity
regardless of which one is calling.

The database schema mirrors Discord's actual API objects (`User`, `Guild`,
`Role`, `Emoji`, `Sticker`, `GuildMember`, etc.) rather than keeping only a
minimal moderation-specific schema, so the local DB can act as a real cache
of guild state, not just a moderation log.

---

## What's been built

- ✅ **Auth middleware** resolving two caller types from a single
  `Authorization: Bearer` header — bot API key (`mod_pk_...` prefix, SHA-256
  hashed, checked against the DB) or dashboard JWT.
- ✅ **Discord OAuth2 login flow** — `/auth/discord` → `/auth/callback`
  (exchanges code, upserts the user, issues a JWT) → `/auth/refresh`.
- ✅ **API key management via CLI** (`npm run key:generate`) rather than an
  HTTP endpoint — key creation is an operator action, not exposed over the
  API.
- ✅ **Guild settings read/write** — `GET`/`POST /guilds/:guildId`, backed by
  a freeform JSON `settings` column.
- ✅ **Ban / unban**, modeled after Discord's own REST shape:
  - `PUT /guilds/:guildId/moderation/ban/:userId` — bans on Discord, then
    records a `Ban` row.
  - `DELETE /guilds/:guildId/moderation/ban/:userId` — unbans on Discord,
    deletes the `Ban` row, writes a `Log` row for the audit trail.
- ✅ **Discord-object-shaped Prisma schema** covering `User`, `Guild`,
  `Role`, `Emoji`, `Sticker`, `GuildMember`, plus moderation-specific `Ban`
  and `Log` models layered on top via relations.
- ✅ **Structured logging** via Winston with daily-rotating file transports
  (combined + error-only streams) and console output in development.
- ✅ Local test seeding (`prisma/seed-mock-guild.ts`) for exercising
  ban/unban without a live Discord gateway connection.

## What's planned but not built yet

- ⬜ **Discord gateway / event sync** — nothing currently populates `User`,
  `Guild`, `GuildMember`, `Role`, etc. from live Discord events. All writes
  today are request-driven (ban/unban, OAuth callback). Until this exists,
  moderation actions against a brand-new guild/user will fail on the
  foreign-key constraint, since the related rows don't exist yet.
- ⬜ **Kick, mute/unmute, warn, purge** — only ban/unban are implemented.
  The `LogAction` enum already has entries for all of these
  (`KICK`, `MUTE`, `UNMUTE`, `WARN`, `PARDON`, `PURGE`); routes and
  controllers still need writing.
- ⬜ **Permission middleware** — `auth.ts` currently only resolves _who_ is
  calling, not _what_ they're allowed to do in a given guild. No route
  currently checks the JWT's `guildPermissions` before acting.
- ⬜ **Zod request validation** — request bodies/params are currently read
  with raw casts and no runtime schema validation.
- ⬜ **Global error handler** — each controller currently does its own
  ad-hoc try/catch → status mapping; a shared `errorHandler` middleware is
  planned but not wired in.
- ⬜ **CORS** — needed before the dashboard (a separate browser origin) can
  call this API directly; currently commented out in `app.ts`.
- ⬜ **Read access to the audit log** — `GET /guilds/:guildId/logs` and
  `GET /guilds/:guildId/logs/:logId` don't exist yet, even though `Log` rows
  are already being written by the unban flow.
- ⬜ **Guild permission config endpoints** —
  `GET`/`PUT /guilds/:guildId/permissions` for managing which Discord roles
  map to which permission levels.
- ⬜ **Rate limiting** — `express-rate-limit` is installed but not yet
  applied to any route.
- ⬜ **Tests** — no test suite exists yet.

There's also one known, currently-broken piece worth flagging here directly:
the JWT issued by the OAuth login flow (`{ id, username }`) doesn't yet
match the shape the auth middleware expects (`sub` + `guildPermissions`),
so dashboard login can't fully authenticate against protected routes yet.
See [`AUTH.md`](./AUTH.md) for the full breakdown and possible fixes.

---

## Stack

- **Runtime:** Node.js, TypeScript, `tsx`
- **Framework:** Express 5
- **Database:** PostgreSQL via Prisma 7 (`prisma-client` generator,
  `@prisma/adapter-pg`)
- **Auth:** `jsonwebtoken` (dashboard), SHA-256 hashed static keys (bot),
  Discord OAuth2
- **Logging:** Winston + `winston-daily-rotate-file`
- **Validation (planned):** Zod

## Getting started

```bash
npm install
npx prisma generate
npx prisma migrate dev
npm run dev
```

Required environment variables are listed in `.env.example`. See
[`plan.md`](./plan.md) for the original variable list (some have since
diverged — check `src/index.ts`'s startup `required` check and individual
controllers for the authoritative current list).

To seed a mock guild/user/moderator for local testing without a live bot
connection:

```bash
npx tsx prisma/seed-mock-guild.ts
```

To generate a bot API key:

```bash
npm run key:generate -- "my-label"
```
