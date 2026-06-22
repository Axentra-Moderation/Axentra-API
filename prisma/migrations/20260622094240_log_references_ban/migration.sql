-- AlterTable
ALTER TABLE "logs" ADD COLUMN     "banId" TEXT;

-- AddForeignKey
ALTER TABLE "logs" ADD CONSTRAINT "logs_banId_fkey" FOREIGN KEY ("banId") REFERENCES "bans"("id") ON DELETE SET NULL ON UPDATE CASCADE;
