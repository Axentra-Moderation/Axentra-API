# Discord Moderation Bot — Standalone REST API Plan

A standalone TypeScript REST API consumed by both the web dashboard and the Discord bot.
The bot and dashboard are separate clients; this API is the single source of truth for all data and business logic.

---

## Table of Contents

1. [Architecture Overview](#architecture-overview)
2. [Package Dependencies](#package-dependencies)
3. [Project Structure](#project-structure)
4. [API Routes](#api-routes)
5. [Key Design Decisions](#key-design-decisions)
6. [Prisma Database Schema](#prisma-database-schema)
7. [Entry Point](#entry-point)
8. [Environment Variables](#environment-variables)

---

## Architecture Overview

```
┌─────────────────┐        ┌─────────────────┐
│   Discord Bot   │        │  Web Dashboard  │
│  (discord.js)   │        │ (React / Next)  │
└────────┬────────┘        └────────┬────────┘
         │  Bot API Key             │  Discord OAuth2 JWT
         │                          │
         └──────────┬───────────────┘
                    │ HTTPS
          ┌─────────▼─────────┐
          │   REST API        │
          │   (Express)       │
          ├───────────────────┤
          │   Services        │
          │   Repositories    │
          ├───────────────────┤
          │   PostgreSQL      │
          │   (via Prisma)    │
          └───────────────────┘
```

The bot authenticates with a **static API key** (server-to-server). The dashboard authenticates via **Discord OAuth2 → JWT**. Both hit the same endpoints; middleware determines what each caller is allowed to do.

---

## Package Dependencies

### Core

| Package      | Purpose                        |
| ------------ | ------------------------------ |
| `express`    | HTTP framework                 |
| `typescript` | Language                       |
| `tsx`        | TypeScript runner / hot reload |
| `dotenv`     | Environment variables          |

### Database & ORM

| Package          | Purpose                |
| ---------------- | ---------------------- |
| `prisma`         | Schema, migrations     |
| `@prisma/client` | Generated query client |
| `pg`             | PostgreSQL driver      |

### Auth & Security

| Package                                | Purpose                                 |
| -------------------------------------- | --------------------------------------- |
| `jsonwebtoken` + `@types/jsonwebtoken` | JWT signing and verification            |
| `passport` + `passport-discord`        | Discord OAuth2 flow for dashboard users |
| `express-rate-limit`                   | Per-route rate limiting                 |
| `helmet`                               | Secure HTTP headers                     |
| `cors`                                 | Cross-origin support for the dashboard  |

### Validation & Utilities

| Package    | Purpose                                |
| ---------- | -------------------------------------- |
| `zod`      | Request body / param validation        |
| `uuid`     | ID generation                          |
| `date-fns` | Expiry calculation for temp bans/mutes |

### Logging

| Package                     | Purpose                        |
| --------------------------- | ------------------------------ |
| `winston`                   | Structured application logging |
| `winston-daily-rotate-file` | Rotating log files by date     |

### Dev Tools

| Package                               | Purpose          |
| ------------------------------------- | ---------------- |
| `eslint` + `prettier`                 | Code quality     |
| `@types/express`, `@types/node`, etc. | Type definitions |

---

## Project Structure

```
mod-api/
├── src/
│   ├── index.ts                    # Entry point
│   │
│   ├── app.ts                      # Express app setup (middleware, routes)
│   │
│   ├── middleware/
│   │   ├── auth.ts                 # Resolves caller identity (bot key or JWT)
│   │   ├── permissions.ts          # Guild-level permission checks
│   │   ├── rateLimiter.ts          # Route-specific rate limiters
│   │   ├── validate.ts             # Zod request validation wrapper
│   │   └── errorHandler.ts         # Global error handler
│   │
│   ├── routes/
│   │   ├── auth.ts                 # POST /auth/discord, GET /auth/callback, POST /auth/refresh
│   │   ├── guilds.ts               # GET/PATCH /guilds/:guildId (settings)
│   │   ├── moderation.ts           # POST /guilds/:guildId/moderation/:action
│   │   ├── logs.ts                 # GET /guilds/:guildId/logs
│   │   ├── warnings.ts             # GET/POST/DELETE /guilds/:guildId/warnings
│   │   └── permissions.ts          # GET/PUT /guilds/:guildId/permissions
│   │
│   ├── services/
│   │   ├── moderation.service.ts   # Ban, kick, mute, warn logic
│   │   ├── logging.service.ts      # Write to Winston + DB audit log
│   │   ├── permissions.service.ts  # Resolve what a caller can do in a guild
│   │   ├── guild.service.ts        # Guild config read/write
│   │   └── automod.service.ts      # Automod rule evaluation
│   │
│   ├── repositories/               # All DB access — services never call Prisma directly
│   │   ├── guild.repo.ts
│   │   ├── modlog.repo.ts
│   │   ├── warning.repo.ts
│   │   └── user.repo.ts
│   │
│   ├── types/
│   │   ├── caller.ts               # CallerType: BOT | DASHBOARD_USER
│   │   ├── moderation.ts           # Action enums, payloads
│   │   ├── permissions.ts          # Permission levels and flags
│   │   └── api.ts                  # Shared request/response shapes
│   │
│   └── utils/
│       ├── logger.ts               # Winston instance
│       ├── validators.ts           # Zod schemas for each route
│       └── constants.ts
│
├── prisma/
│   └── schema.prisma
├── .env
├── .env.example
├── tsconfig.json
├── package.json
└── README.md
```

---

## API Routes

### Auth — `/auth`

| Method | Path             | Caller    | Description                  |
| ------ | ---------------- | --------- | ---------------------------- |
| `GET`  | `/auth/discord`  | Dashboard | Redirect to Discord OAuth2   |
| `GET`  | `/auth/callback` | Dashboard | OAuth2 callback, returns JWT |
| `POST` | `/auth/refresh`  | Dashboard | Refresh an expired JWT       |

### Guilds — `/guilds/:guildId`

| Method  | Path               | Caller    | Description           |
| ------- | ------------------ | --------- | --------------------- |
| `GET`   | `/guilds/:guildId` | Both      | Get guild settings    |
| `PATCH` | `/guilds/:guildId` | Dashboard | Update guild settings |

### Moderation — `/guilds/:guildId/moderation`

| Method   | Path                                         | Caller | Description                          |
| -------- | -------------------------------------------- | ------ | ------------------------------------ |
| `POST`   | `/guilds/:guildId/moderation/ban/:userId`    | Both   | Ban a user                           |
| `DELETE` | `/guilds/:guildId/moderation/ban/:userId`    | Both   | Unban a user                         |
| `POST`   | `/guilds/:guildId/moderation/kick/:userId`   | Both   | Kick/Soft Ban a user                 |
| `POST`   | `/guilds/:guildId/moderation/mute/:userId`   | Both   | Mute a user (with optional duration) |
| `DELETE` | `/guilds/:guildId/moderation/unmute/:userId` | Both   | Remove mute                          |
| `POST`   | `/guilds/:guildId/moderation/warn/:userId`   | Both   | Issue a warning                      |
| `DELETE` | `/guilds/:guildId/moderation/purge/:userId`  | Both   | Bulk delete messages                 |

### Warnings — `/guilds/:guildId/warnings`

| Method   | Path                                   | Caller | Description                        |
| -------- | -------------------------------------- | ------ | ---------------------------------- |
| `GET`    | `/guilds/:guildId/warnings`            | Both   | List warnings (filterable by user) |
| `POST`   | `/guilds/:guildId/warnings`            | Both   | Create a warning                   |
| `DELETE` | `/guilds/:guildId/warnings/:warningId` | Both   | Remove/pardon a warning            |

### Logs — `/guilds/:guildId/logs`

| Method | Path                           | Caller | Description                           |
| ------ | ------------------------------ | ------ | ------------------------------------- |
| `GET`  | `/guilds/:guildId/logs`        | Both   | Get audit log (paginated, filterable) |
| `GET`  | `/guilds/:guildId/logs/:logId` | Both   | Get a single log entry                |

### Permissions — `/guilds/:guildId/permissions`

| Method | Path                           | Caller    | Description                              |
| ------ | ------------------------------ | --------- | ---------------------------------------- |
| `GET`  | `/guilds/:guildId/permissions` | Both      | Get permission config for this guild     |
| `PUT`  | `/guilds/:guildId/permissions` | Dashboard | Update which roles can use which actions |

---

## Key Design Decisions

### 1. Two Authentication Methods, One Middleware

`src/middleware/auth.ts` handles both callers transparently:

- **Bot:** Sends `Authorization: Bearer <BOT_API_KEY>` (a static secret from `.env`). Middleware sets `req.caller = { type: 'BOT' }`.
- **Dashboard user:** Sends `Authorization: Bearer <JWT>`. Middleware verifies, decodes, and sets `req.caller = { type: 'DASHBOARD_USER', userId, guildPermissions }`.

Downstream middleware and services can then branch on `req.caller.type` where behaviour differs.

### 2. Permission Middleware

`src/middleware/permissions.ts` runs after `auth.ts` on any route under `/guilds/:guildId`. It calls `permissions.service.ts` to verify:

- The caller has access to this guild (is a member, is the bot, etc.)
- The caller has sufficient permission for the action being performed (e.g. only admins can update guild settings)

This keeps permission logic out of route handlers entirely.

> All moderation actions are guild-scoped. A ban, mute, warning, or permission change applies only to the specified `guildId`, not globally across all guilds.

### 3. Repository Pattern

Services never import `@prisma/client` directly. All queries live in `src/repositories/`. This:

- Makes services easy to unit test by mocking the repo
- Centralises query logic (pagination, filters) in one place
- Makes a future DB swap straightforward

### 4. Zod Validation Middleware

`src/middleware/validate.ts` is a small wrapper that accepts a Zod schema and returns an Express middleware. Route handlers only run if the request body/params are valid — no manual validation inside handlers.

```typescript
// Example usage in a route file
router.post(
  "/ban",
  validate(banSchema), // rejects invalid bodies before handler runs
  moderationController.ban,
);
```

### 5. Unified Audit Logging

Every moderation action goes through `logging.service.ts`, which:

1. Writes a structured entry to Winston (file + console)
2. Inserts a row into the `ModLog` table

This means the dashboard log view always has a complete, queryable history regardless of whether the action came from the bot or the dashboard.

---

## Prisma Database Schema

This schema is intentionally guild-oriented: every moderation event, warning, and permission record is scoped to a specific `guildId`. There is no global ban state tracked here — a user banned in one guild is not banned in another unless a separate guild-level action is taken.

```prisma

generator client {
  provider = "prisma-client-js"
  output   = "../generated/prisma"
}

datasource db {
  provider = "postgresql"
}

enum PermissionLevel {
  NONE
  MOD
  ADMIN
}

enum ModerationAction {
  WARN
  BAN
  UNBAN
  KICK
  MUTE
  UNMUTE
  PURGE
  PARDON
}

enum PardonType {
  UNBAN
  UNMUTE
}

model Guild {
  id           String            @id           // Discord guild snowflake ID
  logChannelId String?
  settings     Json              @default("{}")
  createdAt    DateTime          @default(now())
  updatedAt    DateTime          @updatedAt

  members      GuildMember[]
  permissions  GuildPermission[]
  warnings     Warning[]
  bans         Ban[]
  mutes        Mute[]
  kicks        Kick[]
  purges       Purge[]
  pardons      Pardon[]
  modLogs      ModLog[]
}

model GuildMember {
  id          String   @id @default(uuid())
  guildId     String
  guild       Guild    @relation(fields: [guildId], references: [id])
  userId      String   // Discord user snowflake ID
  joinedAt    DateTime?
  nickname    String?
  roleIds     String[] @default([])
  isBot       Boolean  @default(false)
  createdAt   DateTime @default(now())
  updatedAt   DateTime @updatedAt

  warnings    Warning[]
  bans        Ban[]
  mutes       Mute[]
  kicks       Kick[]
  pardons     Pardon[]
  modLogs     ModLog[]

  @@unique([guildId, userId])
  @@index([guildId])
}

model GuildPermission {
  id       String          @id @default(uuid())
  guildId  String
  guild    Guild           @relation(fields: [guildId], references: [id])
  roleId   String          // Discord role snowflake ID
  level    PermissionLevel

  @@unique([guildId, roleId])
  @@index([guildId])
}

model ModLog {
  id          String           @id @default(uuid())
  guildId     String
  guild       Guild            @relation(fields: [guildId], references: [id])
  targetId    String?          // Discord user ID or null for guild-wide actions
  memberId    String?
  member      GuildMember?     @relation(fields: [memberId], references: [id])
  moderatorId String           // Discord user ID or "BOT"
  action      ModerationAction
  reason      String?
  duration    Int?             // seconds — for temp bans/mutes; null = permanent
  expiresAt   DateTime?
  createdAt   DateTime         @default(now())

  @@index([guildId])
  @@index([targetId])
  @@index([guildId, memberId])
}

model Warning {
  id          String        @id @default(uuid())
  guildId     String
  guild       Guild         @relation(fields: [guildId], references: [id])
  userId      String
  memberId    String?
  member      GuildMember?  @relation(fields: [memberId], references: [id])
  moderatorId String
  reason      String
  active      Boolean       @default(true)
  expiresAt   DateTime?
  createdAt   DateTime      @default(now())

  @@index([guildId, userId])
  @@index([guildId, memberId])
}

model Ban {
  id          String        @id @default(uuid())
  guildId     String
  guild       Guild         @relation(fields: [guildId], references: [id])
  userId      String
  memberId    String?
  member      GuildMember?  @relation(fields: [memberId], references: [id])
  moderatorId String
  reason      String?
  active      Boolean       @default(true)
  duration    Int?          // seconds — for temp bans; null = permanent
  expiresAt   DateTime?
  createdAt   DateTime      @default(now())

  @@index([guildId, userId])
  @@index([guildId, memberId])
}

model Mute {
  id          String        @id @default(uuid())
  guildId     String
  guild       Guild         @relation(fields: [guildId], references: [id])
  userId      String
  memberId    String?
  member      GuildMember?  @relation(fields: [memberId], references: [id])
  moderatorId String
  reason      String?
  active      Boolean       @default(true)
  duration    Int?          // seconds — for temp mutes; null = permanent
  expiresAt   DateTime?
  createdAt   DateTime      @default(now())

  @@index([guildId, userId])
  @@index([guildId, memberId])
}

model Kick {
  id          String        @id @default(uuid())
  guildId     String
  guild       Guild         @relation(fields: [guildId], references: [id])
  userId      String
  memberId    String?
  member      GuildMember?  @relation(fields: [memberId], references: [id])
  moderatorId String
  reason      String?
  createdAt   DateTime      @default(now())

  @@index([guildId, userId])
  @@index([guildId, memberId])
}

model Purge {
  id          String   @id @default(uuid())
  guildId     String
  guild       Guild    @relation(fields: [guildId], references: [id])
  moderatorId String
  targetId    String?
  amount      Int
  reason      String?
  createdAt   DateTime @default(now())

  @@index([guildId])
}

model Pardon {
  id          String        @id @default(uuid())
  guildId     String
  guild       Guild         @relation(fields: [guildId], references: [id])
  targetId    String         // Discord user ID being unbanned or unmuted
  memberId    String?
  member      GuildMember?   @relation(fields: [memberId], references: [id])
  moderatorId String
  type        PardonType
  reason      String?
  createdAt   DateTime       @default(now())

  @@index([guildId, targetId])
  @@index([guildId, memberId])
}

```

---

## Entry Point

```typescript
// src/index.ts
import "dotenv/config";
import { createApp } from "./app";
import { logger } from "./utils/logger";

const PORT = process.env.PORT ?? 3000;

createApp().listen(PORT, () => {
  logger.info(`API listening on port ${PORT}`);
});
```

```typescript
// src/app.ts
import express from "express";
import helmet from "helmet";
import cors from "cors";
import { authRouter } from "./routes/auth";
import { guildsRouter } from "./routes/guilds";
import { moderationRouter } from "./routes/moderation";
import { logsRouter } from "./routes/logs";
import { warningsRouter } from "./routes/warnings";
import { permissionsRouter } from "./routes/permissions";
import { auth } from "./middleware/auth";
import { errorHandler } from "./middleware/errorHandler";

export function createApp() {
  const app = express();

  // Global middleware
  app.use(helmet());
  app.use(cors({ origin: process.env.DASHBOARD_URL }));
  app.use(express.json());

  // Public routes (no auth required)
  app.use("/auth", authRouter);

  // Protected routes
  app.use(auth); // Resolve caller identity
  app.use("/guilds", guildsRouter);
  app.use("/guilds", moderationRouter);
  app.use("/guilds", logsRouter);
  app.use("/guilds", warningsRouter);
  app.use("/guilds", permissionsRouter);

  app.use(errorHandler);

  return app;
}
```

---

## Environment Variables

```env
# Server
PORT=3000

# Database
DATABASE_URL=postgresql://user:password@localhost:5432/modbot

# Auth — Dashboard (Discord OAuth2)
DISCORD_CLIENT_ID=your_client_id
DISCORD_CLIENT_SECRET=your_client_secret
DISCORD_REDIRECT_URI=http://localhost:3000/auth/callback
JWT_SECRET=a_long_random_secret
JWT_EXPIRES_IN=7d

# Auth — Bot (static API key)
BOT_API_KEY=a_different_long_random_secret

# CORS
DASHBOARD_URL=http://localhost:5173
```

---

_Generated with Claude — claude.ai_
