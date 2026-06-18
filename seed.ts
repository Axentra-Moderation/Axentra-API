// seed.ts
import "dotenv/config";
import { getPrisma } from "./src/utils/prisma.js";

const prisma = getPrisma();

async function main() {
  const guild = await prisma.guild.create({
    data: {
      id: "123456789",
      logChannelId: null,
      settings: {},
    },
  });

  console.log("Created guild:", guild);
}

main()
  .catch(console.error)
  .finally(() => prisma.$disconnect());
