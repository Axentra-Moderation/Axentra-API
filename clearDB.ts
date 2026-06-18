import "dotenv/config";
import { getPrisma } from "./src/utils/prisma.js";

const prisma = getPrisma();

async function main() {
  console.log("Clearing all database tables...");

  await prisma.guildPermission.deleteMany({});
  await prisma.modLog.deleteMany({});
  await prisma.warning.deleteMany({});
  await prisma.ban.deleteMany({});
  await prisma.mute.deleteMany({});
  await prisma.kick.deleteMany({});
  await prisma.purge.deleteMany({});
  await prisma.pardon.deleteMany({});
  await prisma.guildMember.deleteMany({});
  await prisma.guild.deleteMany({});
  await prisma.user.deleteMany({});

  console.log("Database cleared successfully.");
}

main()
  .catch((error) => {
    console.error("Failed to clear database:", error);
    process.exitCode = 1;
  })
  .finally(async () => {
    await prisma.$disconnect();
  });
