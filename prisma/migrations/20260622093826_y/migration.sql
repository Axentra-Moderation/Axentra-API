/*
  Warnings:

  - The values [SOFTBAN] on the enum `LogAction` will be removed. If these variants are still used in the database, this will fail.

*/
-- AlterEnum
BEGIN;
CREATE TYPE "LogAction_new" AS ENUM ('BAN', 'UNBAN', 'KICK', 'MUTE', 'UNMUTE', 'WARN', 'PARDON', 'PURGE');
ALTER TABLE "logs" ALTER COLUMN "action" TYPE "LogAction_new" USING ("action"::text::"LogAction_new");
ALTER TYPE "LogAction" RENAME TO "LogAction_old";
ALTER TYPE "LogAction_new" RENAME TO "LogAction";
DROP TYPE "public"."LogAction_old";
COMMIT;
