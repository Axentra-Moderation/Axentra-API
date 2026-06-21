# API Reference (as implemented)

Base behavior: all routes except `/auth/*` require
`Authorization: Bearer <token>` (see `AUTH.md`). All bodies are JSON.

---

## Auth

### `GET /auth/discord`

Redirects the browser to Discord's OAuth2 authorize page. No auth required.

### `GET /auth/callback`

Discord OAuth2 redirect target. No auth required.

Query params: `code` (provided by Discord).

Response `200`:

```json
{
  "token": "<jwt>",
  "user": {
    "id": "...",
    "username": "...",
    "avatar": "...",
    "globalName": "..."
  }
}
```

Response `401`: `{ "error": "<discord error>" }`

### `POST /auth/refresh`

No auth required (the expired/expiring JWT is the input).

Body:

```json
{ "token": "<jwt>" }
```

Response `200`: `{ "token": "<new jwt>" }`
Response `401`: `{ "error": "Invalid or expired token" }`

---

## Guilds

### `GET /guilds/:guildId`

Returns the stored `Guild` row, including its `settings` JSON blob.

Response `200`: the `Guild` record.
Response `404`: `{ "error": "Guild not found" }`

### `POST /guilds/:guildId`

Upserts the guild's `settings`. Request body is stored as-is in `Guild.settings`.

Body: arbitrary JSON (becomes `settings`).

Response `201`:

```json
{
  "guildId": "...",
  "updates": {
    /* the body you sent */
  }
}
```

Response `400`: `{ "guildId": "...", "error": "<error>" }` (only if the upsert throws)

---

## Moderation

### `PUT /guilds/:guildId/moderation/ban/:userId`

Bans a user: calls Discord's ban API, then records a `Ban` row.

Body:

```json
{ "moderatorId": "...", "reason": "..." }
```

Response `200`: `{ "log": <Ban record> }`
Response `409`: `{ "error": "This user is already banned from that guild.", "log": [<existing Ban rows>] }`
Response `<discord status>`: `{ "error": "Failed to ban user on Discord" }` if Discord rejects the ban.
Response `500`: `{ "error": "Internal Server Error" }`

### `DELETE /guilds/:guildId/moderation/ban/:userId`

Unbans a user: calls Discord's unban API, deletes the `Ban` row, writes a `Log` row.

Body:

```json
{ "moderatorId": "...", "reason": "..." }
```

Response `200`: `{ "log": <Log record> }`
Response `404`: `{ "error": "User not banned." }`
Response `<discord status>`: `{ "error": "Failed to un-ban user on Discord" }` if Discord rejects the unban.
Response `500`: `{ "error": "<raw error object>" }`

> Note: the success response key is `log` in both ban and unban, but they
> represent different record types (`Ban` vs `Log`). Worth keeping in mind
> on the client side — don't assume the shape is the same just because the
> key name matches.

---

## Not yet implemented (see `TODO.md`)

- `kick`, `mute`, `unmute`, `warn`, `purge` — routes from the original plan
  that don't exist yet.
- `GET /guilds/:guildId/logs`, `GET /guilds/:guildId/logs/:logId` — no read
  access to the `Log` table yet, even though writes exist.
- `GET/PUT /guilds/:guildId/permissions` — no permission-config endpoints.
