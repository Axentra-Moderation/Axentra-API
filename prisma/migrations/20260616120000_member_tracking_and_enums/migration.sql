-- CreateEnum
CREATE TYPE "PermissionLevel" AS ENUM ('NONE', 'MOD', 'ADMIN');

-- CreateEnum
CREATE TYPE "ModerationAction" AS ENUM ('WARN', 'BAN', 'UNBAN', 'KICK', 'MUTE', 'UNMUTE', 'PURGE', 'PARDON');

-- CreateEnum
CREATE TYPE "PardonType" AS ENUM ('UNBAN', 'UNMUTE');

-- AlterTable
ALTER TABLE "Ban" ADD COLUMN     "memberId" TEXT;

-- AlterTable: convert integer level (0=NONE, 1=MOD, 2=ADMIN) into the PermissionLevel enum
ALTER TABLE "GuildPermission"
ALTER COLUMN "level" DROP DEFAULT,
ALTER COLUMN "level" TYPE "PermissionLevel" USING (
    CASE "level"
        WHEN 0 THEN 'NONE'
        WHEN 1 THEN 'MOD'
        WHEN 2 THEN 'ADMIN'
        ELSE 'NONE'
    END
)::"PermissionLevel";

-- AlterTable
ALTER TABLE "Kick" ADD COLUMN     "memberId" TEXT;

-- AlterTable: existing action text values already match the enum labels, so cast directly
ALTER TABLE "ModLog" ADD COLUMN     "memberId" TEXT,
ALTER COLUMN "targetId" DROP NOT NULL,
ALTER COLUMN "action" TYPE "ModerationAction" USING "action"::"ModerationAction";

-- AlterTable
ALTER TABLE "Mute" ADD COLUMN     "memberId" TEXT;

-- AlterTable: existing type text values already match the enum labels, so cast directly
ALTER TABLE "Pardon" ADD COLUMN     "memberId" TEXT,
ALTER COLUMN "type" TYPE "PardonType" USING "type"::"PardonType";

-- AlterTable
ALTER TABLE "Warning" ADD COLUMN     "expiresAt" TIMESTAMP(3),
ADD COLUMN     "memberId" TEXT;

-- CreateTable
CREATE TABLE "GuildMember" (
    "id" TEXT NOT NULL,
    "guildId" TEXT NOT NULL,
    "userId" TEXT NOT NULL,
    "joinedAt" TIMESTAMP(3),
    "nickname" TEXT,
    "roleIds" TEXT[] DEFAULT ARRAY[]::TEXT[],
    "isBot" BOOLEAN NOT NULL DEFAULT false,
    "createdAt" TIMESTAMP(3) NOT NULL DEFAULT CURRENT_TIMESTAMP,
    "updatedAt" TIMESTAMP(3) NOT NULL,

    CONSTRAINT "GuildMember_pkey" PRIMARY KEY ("id")
);

-- CreateIndex
CREATE INDEX "GuildMember_guildId_idx" ON "GuildMember"("guildId");

-- CreateIndex
CREATE UNIQUE INDEX "GuildMember_guildId_userId_key" ON "GuildMember"("guildId", "userId");

-- CreateIndex
CREATE INDEX "Ban_guildId_memberId_idx" ON "Ban"("guildId", "memberId");

-- CreateIndex
CREATE INDEX "GuildPermission_guildId_idx" ON "GuildPermission"("guildId");

-- CreateIndex
CREATE UNIQUE INDEX "GuildPermission_guildId_roleId_key" ON "GuildPermission"("guildId", "roleId");

-- CreateIndex
CREATE INDEX "Kick_guildId_memberId_idx" ON "Kick"("guildId", "memberId");

-- CreateIndex
CREATE INDEX "ModLog_guildId_memberId_idx" ON "ModLog"("guildId", "memberId");

-- CreateIndex
CREATE INDEX "Mute_guildId_memberId_idx" ON "Mute"("guildId", "memberId");

-- CreateIndex
CREATE INDEX "Pardon_guildId_memberId_idx" ON "Pardon"("guildId", "memberId");

-- CreateIndex
CREATE INDEX "Warning_guildId_memberId_idx" ON "Warning"("guildId", "memberId");

-- AddForeignKey
ALTER TABLE "GuildMember" ADD CONSTRAINT "GuildMember_guildId_fkey" FOREIGN KEY ("guildId") REFERENCES "Guild"("id") ON DELETE RESTRICT ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "ModLog" ADD CONSTRAINT "ModLog_memberId_fkey" FOREIGN KEY ("memberId") REFERENCES "GuildMember"("id") ON DELETE SET NULL ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "Warning" ADD CONSTRAINT "Warning_memberId_fkey" FOREIGN KEY ("memberId") REFERENCES "GuildMember"("id") ON DELETE SET NULL ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "Ban" ADD CONSTRAINT "Ban_memberId_fkey" FOREIGN KEY ("memberId") REFERENCES "GuildMember"("id") ON DELETE SET NULL ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "Mute" ADD CONSTRAINT "Mute_memberId_fkey" FOREIGN KEY ("memberId") REFERENCES "GuildMember"("id") ON DELETE SET NULL ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "Kick" ADD CONSTRAINT "Kick_memberId_fkey" FOREIGN KEY ("memberId") REFERENCES "GuildMember"("id") ON DELETE SET NULL ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "Pardon" ADD CONSTRAINT "Pardon_memberId_fkey" FOREIGN KEY ("memberId") REFERENCES "GuildMember"("id") ON DELETE SET NULL ON UPDATE CASCADE;
