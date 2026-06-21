// src/repositories/apiKey.repo.ts
import { getPrisma } from "../utils/prisma";

const prisma = getPrisma();

export const apiKeyRepo = {
  create(data: {
    prefix: string;
    keyHash: string;
    label?: string;
    expiresAt?: Date;
  }) {
    return prisma.apiKey.create({ data });
  },

  async findByHash(hash: string) {
    return prisma.apiKey.findUnique({ where: { keyHash: hash } });
  },

  touch(id: string) {
    return prisma.apiKey.update({
      where: { id },
      data: { lastUsedAt: new Date() },
    });
  },

  revoke(id: string) {
    return prisma.apiKey.update({
      where: { id },
      data: { revokedAt: new Date() },
    });
  },

  list() {
    return prisma.apiKey.findMany({
      where: { revokedAt: null },
      select: {
        id: true,
        prefix: true,
        label: true,
        createdAt: true,
        lastUsedAt: true,
        expiresAt: true,
      },
      // keyHash is intentionally excluded
    });
  },
};
