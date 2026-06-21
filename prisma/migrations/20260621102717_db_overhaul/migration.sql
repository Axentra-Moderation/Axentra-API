/*
  Warnings:

  - You are about to drop the `Ban` table. If the table is not empty, all the data it contains will be lost.
  - You are about to drop the `Guild` table. If the table is not empty, all the data it contains will be lost.
  - You are about to drop the `GuildMember` table. If the table is not empty, all the data it contains will be lost.
  - You are about to drop the `GuildPermission` table. If the table is not empty, all the data it contains will be lost.
  - You are about to drop the `Kick` table. If the table is not empty, all the data it contains will be lost.
  - You are about to drop the `ModLog` table. If the table is not empty, all the data it contains will be lost.
  - You are about to drop the `Mute` table. If the table is not empty, all the data it contains will be lost.
  - You are about to drop the `Pardon` table. If the table is not empty, all the data it contains will be lost.
  - You are about to drop the `Purge` table. If the table is not empty, all the data it contains will be lost.
  - You are about to drop the `User` table. If the table is not empty, all the data it contains will be lost.
  - You are about to drop the `Warning` table. If the table is not empty, all the data it contains will be lost.

*/
-- CreateEnum
CREATE TYPE "StickerType" AS ENUM ('STANDARD', 'GUILD');

-- CreateEnum
CREATE TYPE "StickerFormatType" AS ENUM ('PNG', 'APNG', 'LOTTIE', 'GIF');

-- CreateEnum
CREATE TYPE "LogAction" AS ENUM ('BAN', 'UNBAN', 'KICK', 'MUTE', 'UNMUTE', 'WARN', 'PARDON', 'PURGE');

-- DropForeignKey
ALTER TABLE "Ban" DROP CONSTRAINT "Ban_guildId_fkey";

-- DropForeignKey
ALTER TABLE "Ban" DROP CONSTRAINT "Ban_memberId_fkey";

-- DropForeignKey
ALTER TABLE "GuildMember" DROP CONSTRAINT "GuildMember_guildId_fkey";

-- DropForeignKey
ALTER TABLE "GuildPermission" DROP CONSTRAINT "GuildPermission_guildId_fkey";

-- DropForeignKey
ALTER TABLE "Kick" DROP CONSTRAINT "Kick_guildId_fkey";

-- DropForeignKey
ALTER TABLE "Kick" DROP CONSTRAINT "Kick_memberId_fkey";

-- DropForeignKey
ALTER TABLE "ModLog" DROP CONSTRAINT "ModLog_guildId_fkey";

-- DropForeignKey
ALTER TABLE "ModLog" DROP CONSTRAINT "ModLog_memberId_fkey";

-- DropForeignKey
ALTER TABLE "Mute" DROP CONSTRAINT "Mute_guildId_fkey";

-- DropForeignKey
ALTER TABLE "Mute" DROP CONSTRAINT "Mute_memberId_fkey";

-- DropForeignKey
ALTER TABLE "Pardon" DROP CONSTRAINT "Pardon_guildId_fkey";

-- DropForeignKey
ALTER TABLE "Pardon" DROP CONSTRAINT "Pardon_memberId_fkey";

-- DropForeignKey
ALTER TABLE "Purge" DROP CONSTRAINT "Purge_guildId_fkey";

-- DropForeignKey
ALTER TABLE "Warning" DROP CONSTRAINT "Warning_guildId_fkey";

-- DropForeignKey
ALTER TABLE "Warning" DROP CONSTRAINT "Warning_memberId_fkey";

-- AlterTable
ALTER TABLE "ApiKey" ADD COLUMN     "userId" TEXT;

-- DropTable
DROP TABLE "Ban";

-- DropTable
DROP TABLE "Guild";

-- DropTable
DROP TABLE "GuildMember";

-- DropTable
DROP TABLE "GuildPermission";

-- DropTable
DROP TABLE "Kick";

-- DropTable
DROP TABLE "ModLog";

-- DropTable
DROP TABLE "Mute";

-- DropTable
DROP TABLE "Pardon";

-- DropTable
DROP TABLE "Purge";

-- DropTable
DROP TABLE "User";

-- DropTable
DROP TABLE "Warning";

-- DropEnum
DROP TYPE "ModerationAction";

-- DropEnum
DROP TYPE "PardonType";

-- DropEnum
DROP TYPE "PermissionLevel";

-- CreateTable
CREATE TABLE "users" (
    "id" TEXT NOT NULL,
    "username" TEXT NOT NULL,
    "discriminator" TEXT NOT NULL,
    "global_name" TEXT,
    "avatar" TEXT,
    "bot" BOOLEAN DEFAULT false,
    "system" BOOLEAN DEFAULT false,
    "mfa_enabled" BOOLEAN,
    "banner" TEXT,
    "accent_color" INTEGER,
    "locale" TEXT,
    "verified" BOOLEAN,
    "email" TEXT,
    "flags" INTEGER,
    "premium_type" INTEGER,
    "public_flags" INTEGER,
    "created_at" TIMESTAMP(3) NOT NULL DEFAULT CURRENT_TIMESTAMP,
    "updated_at" TIMESTAMP(3) NOT NULL,

    CONSTRAINT "users_pkey" PRIMARY KEY ("id")
);

-- CreateTable
CREATE TABLE "avatar_decoration_data" (
    "id" TEXT NOT NULL,
    "asset" TEXT NOT NULL,
    "sku_id" TEXT NOT NULL,
    "user_id" TEXT NOT NULL,

    CONSTRAINT "avatar_decoration_data_pkey" PRIMARY KEY ("id")
);

-- CreateTable
CREATE TABLE "collectibles" (
    "id" TEXT NOT NULL,
    "user_id" TEXT NOT NULL,

    CONSTRAINT "collectibles_pkey" PRIMARY KEY ("id")
);

-- CreateTable
CREATE TABLE "nameplates" (
    "id" TEXT NOT NULL,
    "sku_id" TEXT NOT NULL,
    "asset" TEXT NOT NULL,
    "label" TEXT NOT NULL,
    "palette" TEXT NOT NULL,
    "collectibles_id" TEXT NOT NULL,

    CONSTRAINT "nameplates_pkey" PRIMARY KEY ("id")
);

-- CreateTable
CREATE TABLE "user_primary_guilds" (
    "id" TEXT NOT NULL,
    "identity_guild_id" TEXT,
    "identity_enabled" BOOLEAN,
    "tag" TEXT,
    "badge" TEXT,
    "user_id" TEXT NOT NULL,

    CONSTRAINT "user_primary_guilds_pkey" PRIMARY KEY ("id")
);

-- CreateTable
CREATE TABLE "guilds" (
    "id" TEXT NOT NULL,
    "name" TEXT NOT NULL,
    "icon" TEXT,
    "icon_hash" TEXT,
    "splash" TEXT,
    "discovery_splash" TEXT,
    "owner_id" TEXT NOT NULL,
    "region" TEXT,
    "afk_channel_id" TEXT,
    "afk_timeout" INTEGER NOT NULL,
    "widget_enabled" BOOLEAN,
    "widget_channel_id" TEXT,
    "verification_level" INTEGER NOT NULL,
    "default_message_notifications" INTEGER NOT NULL,
    "explicit_content_filter" INTEGER NOT NULL,
    "mfa_level" INTEGER NOT NULL,
    "application_id" TEXT,
    "system_channel_id" TEXT,
    "system_channel_flags" INTEGER NOT NULL,
    "rules_channel_id" TEXT,
    "max_presences" INTEGER,
    "max_members" INTEGER,
    "vanity_url_code" TEXT,
    "description" TEXT,
    "banner" TEXT,
    "premium_tier" INTEGER NOT NULL,
    "premium_subscription_count" INTEGER,
    "preferred_locale" TEXT NOT NULL DEFAULT 'en-US',
    "public_updates_channel_id" TEXT,
    "max_video_channel_users" INTEGER,
    "max_stage_video_channel_users" INTEGER,
    "approximate_member_count" INTEGER,
    "approximate_presence_count" INTEGER,
    "nsfw_level" INTEGER NOT NULL,
    "premium_progress_bar_enabled" BOOLEAN NOT NULL,
    "safety_alerts_channel_id" TEXT,
    "features" TEXT[],
    "created_at" TIMESTAMP(3) NOT NULL DEFAULT CURRENT_TIMESTAMP,
    "updated_at" TIMESTAMP(3) NOT NULL,

    CONSTRAINT "guilds_pkey" PRIMARY KEY ("id")
);

-- CreateTable
CREATE TABLE "welcome_screens" (
    "id" TEXT NOT NULL,
    "description" TEXT,
    "guild_id" TEXT NOT NULL,

    CONSTRAINT "welcome_screens_pkey" PRIMARY KEY ("id")
);

-- CreateTable
CREATE TABLE "welcome_screen_channels" (
    "id" TEXT NOT NULL,
    "channel_id" TEXT NOT NULL,
    "description" TEXT NOT NULL,
    "emoji_id" TEXT,
    "emoji_name" TEXT,
    "welcome_screen_id" TEXT NOT NULL,

    CONSTRAINT "welcome_screen_channels_pkey" PRIMARY KEY ("id")
);

-- CreateTable
CREATE TABLE "incidents_data" (
    "id" TEXT NOT NULL,
    "invites_disabled_until" TIMESTAMP(3),
    "dms_disabled_until" TIMESTAMP(3),
    "dm_spam_detected_at" TIMESTAMP(3),
    "raid_detected_at" TIMESTAMP(3),
    "guild_id" TEXT NOT NULL,

    CONSTRAINT "incidents_data_pkey" PRIMARY KEY ("id")
);

-- CreateTable
CREATE TABLE "roles" (
    "id" TEXT NOT NULL,
    "name" TEXT NOT NULL,
    "color" INTEGER,
    "primary_color" INTEGER NOT NULL,
    "secondary_color" INTEGER,
    "tertiary_color" INTEGER,
    "hoist" BOOLEAN NOT NULL,
    "icon" TEXT,
    "unicode_emoji" TEXT,
    "position" INTEGER NOT NULL,
    "permissions" TEXT NOT NULL,
    "managed" BOOLEAN NOT NULL,
    "mentionable" BOOLEAN NOT NULL,
    "flags" INTEGER NOT NULL,
    "tag_bot_id" TEXT,
    "tag_integration_id" TEXT,
    "tag_premium_subscriber" BOOLEAN,
    "tag_subscription_listing_id" TEXT,
    "tag_available_for_purchase" BOOLEAN,
    "tag_guild_connections" BOOLEAN,
    "guild_id" TEXT NOT NULL,
    "created_at" TIMESTAMP(3) NOT NULL DEFAULT CURRENT_TIMESTAMP,
    "updated_at" TIMESTAMP(3) NOT NULL,

    CONSTRAINT "roles_pkey" PRIMARY KEY ("id")
);

-- CreateTable
CREATE TABLE "emojis" (
    "id" TEXT NOT NULL,
    "discord_id" TEXT,
    "name" TEXT,
    "require_colons" BOOLEAN,
    "managed" BOOLEAN,
    "animated" BOOLEAN,
    "available" BOOLEAN,
    "guild_id" TEXT NOT NULL,
    "creator_id" TEXT,
    "created_at" TIMESTAMP(3) NOT NULL DEFAULT CURRENT_TIMESTAMP,
    "updated_at" TIMESTAMP(3) NOT NULL,

    CONSTRAINT "emojis_pkey" PRIMARY KEY ("id")
);

-- CreateTable
CREATE TABLE "stickers" (
    "id" TEXT NOT NULL,
    "discord_id" TEXT,
    "pack_id" TEXT,
    "name" TEXT NOT NULL,
    "description" TEXT,
    "tags" TEXT NOT NULL,
    "type" "StickerType" NOT NULL,
    "format_type" "StickerFormatType" NOT NULL,
    "available" BOOLEAN,
    "sort_value" INTEGER,
    "guild_id" TEXT,
    "creator_id" TEXT,
    "created_at" TIMESTAMP(3) NOT NULL DEFAULT CURRENT_TIMESTAMP,
    "updated_at" TIMESTAMP(3) NOT NULL,

    CONSTRAINT "stickers_pkey" PRIMARY KEY ("id")
);

-- CreateTable
CREATE TABLE "guild_members" (
    "id" TEXT NOT NULL,
    "user_id" TEXT NOT NULL,
    "guild_id" TEXT NOT NULL,
    "nick" TEXT,
    "avatar" TEXT,
    "banner" TEXT,
    "roles" TEXT[],
    "joined_at" TIMESTAMP(3),
    "premium_since" TIMESTAMP(3),
    "deaf" BOOLEAN NOT NULL DEFAULT false,
    "mute" BOOLEAN NOT NULL DEFAULT false,
    "flags" INTEGER NOT NULL DEFAULT 0,
    "pending" BOOLEAN DEFAULT false,
    "permissions" TEXT,
    "communication_disabled_until" TIMESTAMP(3),
    "avatar_decoration_data" JSONB,
    "collectibles" JSONB,
    "created_at" TIMESTAMP(3) NOT NULL DEFAULT CURRENT_TIMESTAMP,
    "updated_at" TIMESTAMP(3) NOT NULL,

    CONSTRAINT "guild_members_pkey" PRIMARY KEY ("id")
);

-- CreateTable
CREATE TABLE "bans" (
    "id" TEXT NOT NULL,
    "reason" TEXT,
    "guild_id" TEXT NOT NULL,
    "user_id" TEXT NOT NULL,
    "moderator_id" TEXT NOT NULL,
    "member_id" TEXT,
    "active" BOOLEAN NOT NULL DEFAULT true,
    "duration" INTEGER,
    "expires_at" TIMESTAMP(3),
    "created_at" TIMESTAMP(3) NOT NULL DEFAULT CURRENT_TIMESTAMP,

    CONSTRAINT "bans_pkey" PRIMARY KEY ("id")
);

-- CreateTable
CREATE TABLE "logs" (
    "id" TEXT NOT NULL,
    "action" "LogAction" NOT NULL,
    "reason" TEXT,
    "duration" INTEGER,
    "expires_at" TIMESTAMP(3),
    "amount" INTEGER,
    "active" BOOLEAN NOT NULL DEFAULT true,
    "created_at" TIMESTAMP(3) NOT NULL DEFAULT CURRENT_TIMESTAMP,
    "guild_id" TEXT NOT NULL,
    "target_id" TEXT,
    "moderator_id" TEXT NOT NULL,
    "member_id" TEXT,

    CONSTRAINT "logs_pkey" PRIMARY KEY ("id")
);

-- CreateTable
CREATE TABLE "_EmojiRoles" (
    "A" TEXT NOT NULL,
    "B" TEXT NOT NULL,

    CONSTRAINT "_EmojiRoles_AB_pkey" PRIMARY KEY ("A","B")
);

-- CreateIndex
CREATE UNIQUE INDEX "avatar_decoration_data_user_id_key" ON "avatar_decoration_data"("user_id");

-- CreateIndex
CREATE UNIQUE INDEX "collectibles_user_id_key" ON "collectibles"("user_id");

-- CreateIndex
CREATE UNIQUE INDEX "nameplates_collectibles_id_key" ON "nameplates"("collectibles_id");

-- CreateIndex
CREATE UNIQUE INDEX "user_primary_guilds_user_id_key" ON "user_primary_guilds"("user_id");

-- CreateIndex
CREATE UNIQUE INDEX "welcome_screens_guild_id_key" ON "welcome_screens"("guild_id");

-- CreateIndex
CREATE UNIQUE INDEX "incidents_data_guild_id_key" ON "incidents_data"("guild_id");

-- CreateIndex
CREATE INDEX "roles_guild_id_idx" ON "roles"("guild_id");

-- CreateIndex
CREATE INDEX "emojis_guild_id_idx" ON "emojis"("guild_id");

-- CreateIndex
CREATE INDEX "stickers_guild_id_idx" ON "stickers"("guild_id");

-- CreateIndex
CREATE UNIQUE INDEX "guild_members_user_id_guild_id_key" ON "guild_members"("user_id", "guild_id");

-- CreateIndex
CREATE INDEX "bans_guild_id_user_id_idx" ON "bans"("guild_id", "user_id");

-- CreateIndex
CREATE INDEX "bans_guild_id_member_id_idx" ON "bans"("guild_id", "member_id");

-- CreateIndex
CREATE INDEX "logs_guild_id_idx" ON "logs"("guild_id");

-- CreateIndex
CREATE INDEX "logs_guild_id_target_id_idx" ON "logs"("guild_id", "target_id");

-- CreateIndex
CREATE INDEX "logs_guild_id_member_id_idx" ON "logs"("guild_id", "member_id");

-- CreateIndex
CREATE INDEX "_EmojiRoles_B_index" ON "_EmojiRoles"("B");

-- AddForeignKey
ALTER TABLE "ApiKey" ADD CONSTRAINT "ApiKey_userId_fkey" FOREIGN KEY ("userId") REFERENCES "users"("id") ON DELETE SET NULL ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "avatar_decoration_data" ADD CONSTRAINT "avatar_decoration_data_user_id_fkey" FOREIGN KEY ("user_id") REFERENCES "users"("id") ON DELETE RESTRICT ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "collectibles" ADD CONSTRAINT "collectibles_user_id_fkey" FOREIGN KEY ("user_id") REFERENCES "users"("id") ON DELETE RESTRICT ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "nameplates" ADD CONSTRAINT "nameplates_collectibles_id_fkey" FOREIGN KEY ("collectibles_id") REFERENCES "collectibles"("id") ON DELETE RESTRICT ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "user_primary_guilds" ADD CONSTRAINT "user_primary_guilds_user_id_fkey" FOREIGN KEY ("user_id") REFERENCES "users"("id") ON DELETE RESTRICT ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "guilds" ADD CONSTRAINT "guilds_owner_id_fkey" FOREIGN KEY ("owner_id") REFERENCES "users"("id") ON DELETE RESTRICT ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "welcome_screens" ADD CONSTRAINT "welcome_screens_guild_id_fkey" FOREIGN KEY ("guild_id") REFERENCES "guilds"("id") ON DELETE RESTRICT ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "welcome_screen_channels" ADD CONSTRAINT "welcome_screen_channels_welcome_screen_id_fkey" FOREIGN KEY ("welcome_screen_id") REFERENCES "welcome_screens"("id") ON DELETE RESTRICT ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "incidents_data" ADD CONSTRAINT "incidents_data_guild_id_fkey" FOREIGN KEY ("guild_id") REFERENCES "guilds"("id") ON DELETE RESTRICT ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "roles" ADD CONSTRAINT "roles_tag_bot_id_fkey" FOREIGN KEY ("tag_bot_id") REFERENCES "users"("id") ON DELETE SET NULL ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "roles" ADD CONSTRAINT "roles_guild_id_fkey" FOREIGN KEY ("guild_id") REFERENCES "guilds"("id") ON DELETE RESTRICT ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "emojis" ADD CONSTRAINT "emojis_guild_id_fkey" FOREIGN KEY ("guild_id") REFERENCES "guilds"("id") ON DELETE RESTRICT ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "emojis" ADD CONSTRAINT "emojis_creator_id_fkey" FOREIGN KEY ("creator_id") REFERENCES "users"("id") ON DELETE SET NULL ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "stickers" ADD CONSTRAINT "stickers_guild_id_fkey" FOREIGN KEY ("guild_id") REFERENCES "guilds"("id") ON DELETE SET NULL ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "stickers" ADD CONSTRAINT "stickers_creator_id_fkey" FOREIGN KEY ("creator_id") REFERENCES "users"("id") ON DELETE SET NULL ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "guild_members" ADD CONSTRAINT "guild_members_user_id_fkey" FOREIGN KEY ("user_id") REFERENCES "users"("id") ON DELETE RESTRICT ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "guild_members" ADD CONSTRAINT "guild_members_guild_id_fkey" FOREIGN KEY ("guild_id") REFERENCES "guilds"("id") ON DELETE RESTRICT ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "bans" ADD CONSTRAINT "bans_guild_id_fkey" FOREIGN KEY ("guild_id") REFERENCES "guilds"("id") ON DELETE RESTRICT ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "bans" ADD CONSTRAINT "bans_user_id_fkey" FOREIGN KEY ("user_id") REFERENCES "users"("id") ON DELETE RESTRICT ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "bans" ADD CONSTRAINT "bans_moderator_id_fkey" FOREIGN KEY ("moderator_id") REFERENCES "users"("id") ON DELETE RESTRICT ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "bans" ADD CONSTRAINT "bans_member_id_fkey" FOREIGN KEY ("member_id") REFERENCES "guild_members"("id") ON DELETE SET NULL ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "logs" ADD CONSTRAINT "logs_guild_id_fkey" FOREIGN KEY ("guild_id") REFERENCES "guilds"("id") ON DELETE RESTRICT ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "logs" ADD CONSTRAINT "logs_target_id_fkey" FOREIGN KEY ("target_id") REFERENCES "users"("id") ON DELETE SET NULL ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "logs" ADD CONSTRAINT "logs_moderator_id_fkey" FOREIGN KEY ("moderator_id") REFERENCES "users"("id") ON DELETE RESTRICT ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "logs" ADD CONSTRAINT "logs_member_id_fkey" FOREIGN KEY ("member_id") REFERENCES "guild_members"("id") ON DELETE SET NULL ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "_EmojiRoles" ADD CONSTRAINT "_EmojiRoles_A_fkey" FOREIGN KEY ("A") REFERENCES "emojis"("id") ON DELETE CASCADE ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "_EmojiRoles" ADD CONSTRAINT "_EmojiRoles_B_fkey" FOREIGN KEY ("B") REFERENCES "roles"("id") ON DELETE CASCADE ON UPDATE CASCADE;
