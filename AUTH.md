# Auth — Reference

How callers authenticate against Axentra-API, as actually implemented in
`src/middleware/auth.ts`.

## Two caller types, one header

Every protected route reads a single `Authorization: Bearer <token>` header.
`auth.ts` inspects the token itself to decide which caller type it is — there
is no separate header or scheme per caller.

```
Authorization: Bearer mod_pk_xxxxxxxx.<64-char-hex-secret>   → bot (API key)
Authorization: Bearer eyJhbGciOi...                          → dashboard (JWT)
```

Detection rule: if the token starts with `mod_pk_`, it's treated as a bot API
key. Otherwise it's assumed to be a JWT and passed to `jwt.verify`.

## Bot caller (API key)

- Format: `mod_pk_<8-char-hex-prefix>.<64-char-hex-secret>`
- Generated once via CLI: `npm run key:generate -- <label>`
  (`src/utils/generate-key.ts`) — there is **no HTTP endpoint** to mint keys.
  This is intentional; key creation is an operator action, not an API
  capability.
- Verified by SHA-256 hashing the raw token and looking up `ApiKey.keyHash`
  (`apiKey.repo.ts` / `apiKeyRepo.findByHash`). The raw key is never stored,
  only its hash.
- Rejected if `revokedAt` is set or `expiresAt` has passed.
- `lastUsedAt` is touched at most once every 5 minutes per key (debounced,
  fire-and-forget — a failed touch write does not fail the request).
- On success, `req.caller = { type: "BOT", keyId: apiKey.id }`.

## Dashboard caller (Discord OAuth2 → JWT)

- Flow: `GET /auth/discord` → redirect to Discord → `GET /auth/callback`
  (exchanges `code` for a Discord access token, fetches the Discord user,
  upserts a local `User` row, signs and returns a JWT) → `POST /auth/refresh`
  to renew before expiry.
- JWT is signed with `JWT_SECRET`, expires in `7d` (`src/utils/jwt.ts`).
- Expected payload shape: `{ sub: string, guildPermissions: Record<string, string> }`
  — `sub` is the Discord user ID, `guildPermissions` maps `guildId` →
  permission level string per guild.
  - **Note:** `signJwt` (called from the callback and refresh controllers)
    currently only signs `{ id, username }` — it does not yet include `sub`
    or `guildPermissions`. `handleJwt` in `auth.ts` will reject any token
    that doesn't carry those two claims with `401 Malformed JWT payload`.
    This means the dashboard login flow does not yet produce a JWT that
    passes the auth middleware's own check — these need to be reconciled
    (either `signJwt` needs to include `sub`/`guildPermissions`, or
    `handleJwt` needs to accept the `{ id, username }` shape and resolve
    permissions separately, e.g. via a DB lookup at request time).
- On success, `req.caller = { type: "DASHBOARD_USER", userId, guildPermissions }`.

## What downstream code can rely on

Any handler past the `auth` middleware can safely read `req.caller.type` to
branch behavior:

```ts
if (req.caller.type === "BOT") {
  // server-to-server, full trust within whatever the key is scoped to
} else {
  // req.caller.userId, req.caller.guildPermissions available
}
```

There is currently **no permission-level enforcement** beyond identity
resolution — `auth.ts` only answers "who is calling," not "what are they
allowed to do in guild X." A `permissions` middleware that checks
`req.caller.guildPermissions[guildId]` against the action being performed
is still planned but not implemented (tracked in `TODO.md`).

## Known gap: user existence vs. moderation FK constraints

The OAuth callback path upserts the calling dashboard user into `User`
automatically. The **bot** path does not — a bot-authenticated request
(e.g. a ban) references `userId`/`moderatorId`/`guildId` that may not yet
exist as rows in `User`/`Guild`, since nothing currently syncs Discord
gateway events into the DB. Until a sync job exists, moderation actions
against not-yet-seen guilds/users will fail with a Prisma `P2003` foreign
key violation. See `TODO.md` → "Not yet started" → Gateway / Discord event
sync.
