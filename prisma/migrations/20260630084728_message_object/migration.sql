-- CreateEnum
CREATE TYPE "MessageType" AS ENUM ('DEFAULT', 'RECIPIENT_ADD', 'RECIPIENT_REMOVE', 'CALL', 'CHANNEL_NAME_CHANGE', 'CHANNEL_ICON_CHANGE', 'CHANNEL_PINNED_MESSAGE', 'USER_JOIN', 'GUILD_BOOST', 'GUILD_BOOST_TIER_1', 'GUILD_BOOST_TIER_2', 'GUILD_BOOST_TIER_3', 'CHANNEL_FOLLOW_ADD', 'GUILD_DISCOVERY_DISQUALIFIED', 'GUILD_DISCOVERY_REQUALIFIED', 'GUILD_DISCOVERY_GRACE_PERIOD_INITIAL_WARNING', 'GUILD_DISCOVERY_GRACE_PERIOD_FINAL_WARNING', 'THREAD_CREATED', 'REPLY', 'CHAT_INPUT_COMMAND', 'THREAD_STARTER_MESSAGE', 'GUILD_INVITE_REMINDER', 'CONTEXT_MENU_COMMAND', 'AUTO_MODERATION_ACTION', 'ROLE_SUBSCRIPTION_PURCHASE', 'INTERACTION_PREMIUM_UPSELL', 'STAGE_START', 'STAGE_END', 'STAGE_SPEAKER', 'STAGE_TOPIC', 'GUILD_APPLICATION_PREMIUM_SUBSCRIPTION', 'GUILD_INCIDENT_ALERT_MODE_ENABLED', 'GUILD_INCIDENT_ALERT_MODE_DISABLED', 'GUILD_INCIDENT_REPORT_RAID', 'GUILD_INCIDENT_REPORT_FALSE_ALARM', 'PURCHASE_NOTIFICATION', 'POLL_RESULT');

-- CreateTable
CREATE TABLE "messages" (
    "id" TEXT NOT NULL,
    "channel_id" TEXT NOT NULL,
    "author_id" TEXT,
    "guild_id" TEXT,
    "content" TEXT,
    "timestamp" TIMESTAMP(3) NOT NULL,
    "edited_timestamp" TIMESTAMP(3),
    "tts" BOOLEAN NOT NULL DEFAULT false,
    "mention_everyone" BOOLEAN NOT NULL DEFAULT false,
    "mention_role_ids" TEXT[],
    "nonce" TEXT,
    "pinned" BOOLEAN NOT NULL DEFAULT false,
    "webhook_id" TEXT,
    "type" "MessageType" NOT NULL,
    "flags" INTEGER,
    "application_id" TEXT,
    "message_snapshots" JSONB,
    "interaction_metadata" JSONB,
    "role_subscription_data" JSONB,
    "shared_client_theme" JSONB,
    "call" JSONB,
    "resolved" JSONB,
    "position" INTEGER,
    "created_at" TIMESTAMP(3) NOT NULL DEFAULT CURRENT_TIMESTAMP,
    "updated_at" TIMESTAMP(3) NOT NULL,

    CONSTRAINT "messages_pkey" PRIMARY KEY ("id")
);

-- CreateTable
CREATE TABLE "message_mentions" (
    "id" TEXT NOT NULL,
    "message_id" TEXT NOT NULL,
    "user_id" TEXT NOT NULL,

    CONSTRAINT "message_mentions_pkey" PRIMARY KEY ("id")
);

-- CreateTable
CREATE TABLE "message_attachments" (
    "id" TEXT NOT NULL,
    "message_id" TEXT NOT NULL,
    "filename" TEXT NOT NULL,
    "title" TEXT,
    "description" TEXT,
    "content_type" TEXT,
    "size" INTEGER NOT NULL,
    "url" TEXT NOT NULL,
    "proxy_url" TEXT NOT NULL,
    "height" INTEGER,
    "width" INTEGER,
    "ephemeral" BOOLEAN DEFAULT false,
    "duration_secs" DOUBLE PRECISION,
    "waveform" TEXT,
    "flags" INTEGER,

    CONSTRAINT "message_attachments_pkey" PRIMARY KEY ("id")
);

-- CreateTable
CREATE TABLE "message_embeds" (
    "id" TEXT NOT NULL,
    "message_id" TEXT NOT NULL,
    "title" TEXT,
    "type" TEXT,
    "description" TEXT,
    "url" TEXT,
    "timestamp" TIMESTAMP(3),
    "color" INTEGER,
    "flags" INTEGER,

    CONSTRAINT "message_embeds_pkey" PRIMARY KEY ("id")
);

-- CreateTable
CREATE TABLE "message_embed_footers" (
    "id" TEXT NOT NULL,
    "text" TEXT NOT NULL,
    "icon_url" TEXT,
    "proxy_icon_url" TEXT,
    "embed_id" TEXT NOT NULL,

    CONSTRAINT "message_embed_footers_pkey" PRIMARY KEY ("id")
);

-- CreateTable
CREATE TABLE "message_embed_media" (
    "id" TEXT NOT NULL,
    "url" TEXT,
    "proxy_url" TEXT,
    "height" INTEGER,
    "width" INTEGER,
    "content_type" TEXT,
    "placeholder" TEXT,
    "placeholder_version" INTEGER,
    "description" TEXT,
    "flags" INTEGER,
    "embed_as_image_id" TEXT,
    "embed_as_thumbnail_id" TEXT,
    "embed_as_video_id" TEXT,

    CONSTRAINT "message_embed_media_pkey" PRIMARY KEY ("id")
);

-- CreateTable
CREATE TABLE "message_embed_providers" (
    "id" TEXT NOT NULL,
    "name" TEXT,
    "url" TEXT,
    "embed_id" TEXT NOT NULL,

    CONSTRAINT "message_embed_providers_pkey" PRIMARY KEY ("id")
);

-- CreateTable
CREATE TABLE "message_embed_authors" (
    "id" TEXT NOT NULL,
    "name" TEXT NOT NULL,
    "url" TEXT,
    "icon_url" TEXT,
    "proxy_icon_url" TEXT,
    "embed_id" TEXT NOT NULL,

    CONSTRAINT "message_embed_authors_pkey" PRIMARY KEY ("id")
);

-- CreateTable
CREATE TABLE "message_embed_fields" (
    "id" TEXT NOT NULL,
    "name" TEXT NOT NULL,
    "value" TEXT NOT NULL,
    "inline" BOOLEAN DEFAULT false,
    "embed_id" TEXT NOT NULL,

    CONSTRAINT "message_embed_fields_pkey" PRIMARY KEY ("id")
);

-- CreateTable
CREATE TABLE "message_reactions" (
    "id" TEXT NOT NULL,
    "message_id" TEXT NOT NULL,
    "count" INTEGER NOT NULL,
    "count_burst" INTEGER NOT NULL DEFAULT 0,
    "count_normal" INTEGER NOT NULL DEFAULT 0,
    "me" BOOLEAN NOT NULL DEFAULT false,
    "me_burst" BOOLEAN NOT NULL DEFAULT false,
    "emoji_id" TEXT,
    "emoji_name" TEXT,
    "burst_colors" TEXT[],

    CONSTRAINT "message_reactions_pkey" PRIMARY KEY ("id")
);

-- CreateTable
CREATE TABLE "message_references" (
    "id" TEXT NOT NULL,
    "message_id" TEXT NOT NULL,
    "type" INTEGER NOT NULL DEFAULT 0,
    "referenced_message_id" TEXT,
    "channel_id" TEXT,
    "guild_id" TEXT,
    "fail_if_not_exists" BOOLEAN DEFAULT true,

    CONSTRAINT "message_references_pkey" PRIMARY KEY ("id")
);

-- CreateIndex
CREATE INDEX "messages_guild_id_idx" ON "messages"("guild_id");

-- CreateIndex
CREATE INDEX "messages_channel_id_idx" ON "messages"("channel_id");

-- CreateIndex
CREATE INDEX "messages_author_id_idx" ON "messages"("author_id");

-- CreateIndex
CREATE INDEX "message_mentions_message_id_idx" ON "message_mentions"("message_id");

-- CreateIndex
CREATE UNIQUE INDEX "message_mentions_message_id_user_id_key" ON "message_mentions"("message_id", "user_id");

-- CreateIndex
CREATE INDEX "message_attachments_message_id_idx" ON "message_attachments"("message_id");

-- CreateIndex
CREATE INDEX "message_embeds_message_id_idx" ON "message_embeds"("message_id");

-- CreateIndex
CREATE UNIQUE INDEX "message_embed_footers_embed_id_key" ON "message_embed_footers"("embed_id");

-- CreateIndex
CREATE UNIQUE INDEX "message_embed_media_embed_as_image_id_key" ON "message_embed_media"("embed_as_image_id");

-- CreateIndex
CREATE UNIQUE INDEX "message_embed_media_embed_as_thumbnail_id_key" ON "message_embed_media"("embed_as_thumbnail_id");

-- CreateIndex
CREATE UNIQUE INDEX "message_embed_media_embed_as_video_id_key" ON "message_embed_media"("embed_as_video_id");

-- CreateIndex
CREATE UNIQUE INDEX "message_embed_providers_embed_id_key" ON "message_embed_providers"("embed_id");

-- CreateIndex
CREATE UNIQUE INDEX "message_embed_authors_embed_id_key" ON "message_embed_authors"("embed_id");

-- CreateIndex
CREATE INDEX "message_embed_fields_embed_id_idx" ON "message_embed_fields"("embed_id");

-- CreateIndex
CREATE INDEX "message_reactions_message_id_idx" ON "message_reactions"("message_id");

-- CreateIndex
CREATE UNIQUE INDEX "message_reactions_message_id_emoji_id_emoji_name_key" ON "message_reactions"("message_id", "emoji_id", "emoji_name");

-- CreateIndex
CREATE UNIQUE INDEX "message_references_message_id_key" ON "message_references"("message_id");

-- AddForeignKey
ALTER TABLE "messages" ADD CONSTRAINT "messages_author_id_fkey" FOREIGN KEY ("author_id") REFERENCES "users"("id") ON DELETE SET NULL ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "messages" ADD CONSTRAINT "messages_guild_id_fkey" FOREIGN KEY ("guild_id") REFERENCES "guilds"("id") ON DELETE SET NULL ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "message_mentions" ADD CONSTRAINT "message_mentions_message_id_fkey" FOREIGN KEY ("message_id") REFERENCES "messages"("id") ON DELETE CASCADE ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "message_mentions" ADD CONSTRAINT "message_mentions_user_id_fkey" FOREIGN KEY ("user_id") REFERENCES "users"("id") ON DELETE RESTRICT ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "message_attachments" ADD CONSTRAINT "message_attachments_message_id_fkey" FOREIGN KEY ("message_id") REFERENCES "messages"("id") ON DELETE CASCADE ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "message_embeds" ADD CONSTRAINT "message_embeds_message_id_fkey" FOREIGN KEY ("message_id") REFERENCES "messages"("id") ON DELETE CASCADE ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "message_embed_footers" ADD CONSTRAINT "message_embed_footers_embed_id_fkey" FOREIGN KEY ("embed_id") REFERENCES "message_embeds"("id") ON DELETE CASCADE ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "message_embed_media" ADD CONSTRAINT "message_embed_media_embed_as_image_id_fkey" FOREIGN KEY ("embed_as_image_id") REFERENCES "message_embeds"("id") ON DELETE CASCADE ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "message_embed_media" ADD CONSTRAINT "message_embed_media_embed_as_thumbnail_id_fkey" FOREIGN KEY ("embed_as_thumbnail_id") REFERENCES "message_embeds"("id") ON DELETE CASCADE ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "message_embed_media" ADD CONSTRAINT "message_embed_media_embed_as_video_id_fkey" FOREIGN KEY ("embed_as_video_id") REFERENCES "message_embeds"("id") ON DELETE CASCADE ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "message_embed_providers" ADD CONSTRAINT "message_embed_providers_embed_id_fkey" FOREIGN KEY ("embed_id") REFERENCES "message_embeds"("id") ON DELETE CASCADE ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "message_embed_authors" ADD CONSTRAINT "message_embed_authors_embed_id_fkey" FOREIGN KEY ("embed_id") REFERENCES "message_embeds"("id") ON DELETE CASCADE ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "message_embed_fields" ADD CONSTRAINT "message_embed_fields_embed_id_fkey" FOREIGN KEY ("embed_id") REFERENCES "message_embeds"("id") ON DELETE CASCADE ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "message_reactions" ADD CONSTRAINT "message_reactions_message_id_fkey" FOREIGN KEY ("message_id") REFERENCES "messages"("id") ON DELETE CASCADE ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "message_references" ADD CONSTRAINT "message_references_message_id_fkey" FOREIGN KEY ("message_id") REFERENCES "messages"("id") ON DELETE CASCADE ON UPDATE CASCADE;
