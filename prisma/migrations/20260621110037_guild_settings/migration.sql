/*
  Warnings:

  - Added the required column `settings` to the `guilds` table without a default value. This is not possible if the table is not empty.

*/
-- AlterTable
ALTER TABLE "guilds" ADD COLUMN     "settings" JSONB NOT NULL;
