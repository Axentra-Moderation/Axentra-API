import { Interface } from "node:readline";

interface Guild {
  id: string;
  settings: JSON;
  createdAt: Date;
  updatedAt: Date;

  members?: GuildMember[];
  permissions?: GuildPermission[];
  warnings?: Warning[];
  bans?: Ban[];
  mutes?: Mute[];
  kicks?: Kick[];
  purges?: Purge[];
  pardons?: Pardon[];
  modLogs?: ModLog[];
}

interface User {
  id: string;
  username: string;
  globalName: string;
  avatar: string;
  discordAccessToken: string;
  discordRefreshToken: string;
  discordTokenExpiry: Date;
  createdAt: Date;
  updatedAt: Date;
}

interface Ban {
  id: string;
  guildId: string;
  guild: Guild;
  userId: string;
  memberId: string;
  member: GuildMember;
  moderatorId: string;
  reason: string;
  active: boolean;
  duration: Int32Array;
  expiresAt: Date;
  createdAt: Date;
}

interface Mute {
  id: string;
  guildId: string;
  guild: Guild;
  userId: string;
  memberId: string;
  member: GuildMember;
  moderatorId: string;
  reason: string;
  active: boolean;
  duration: Int32Array;
  expiresAt: Date;
  createdAt: Date;
}

interface Kick {
  id: string;
  guildId: string;
  guild: Guild;
  userId: string;
  memberId: string;
  member: GuildMember;
  moderatorId: string;
  reason: string;
  createdAt: Date;
}

interface Purge {
  id: string;
  guildId: string;
  guild: Guild;
  moderatorId: string;
  targetId: string;
  amount: Int32Array;
  reason: string;
  createdAt: Date;
}

interface Pardon {
  id: string;
  guildId: string;
  guild: Guild;
  targetId: string;
  memberId: string;
  member: GuildMember;
  moderatorId: string;
  type: PardonType;
  reason: string;
  createdAt: Date;
}

interface ModLog {
  id: string;
  guildId: string;
  guild: Guild;
  targetId: string;
  memberId: string;
  member: GuildMember;
  moderatorId: string;
  action: ModerationAction;
  reason: string;
  duration: Int32Array;
  expiresAt: Date;
  createdAt: Date;
}

interface Warning {
  id: string;
  guildId: string;
  guild: Guild;
  userId: string;
  memberId: string;
  member: GuildMember;
  moderatorId: string;
  reason: string;
  active: boolean;
  expiresAt: Date;
  createdAt: Date;
}

interface GuildMember {
  id: string;
  guildId: string;
  guild: Guild;
  userId: string;
  joinedAt: Date;
  nickname: string;
  roleIds: string[];
  isBot: boolean;
  createdAt: Date;
  UpdatedAt: Date;

  warnings: [];
  bans: [];
  mutes: [];
  kicks: [];
  pardons: [];
  modLogs: [];
}

interface GuildPermission {
  id: string;
  guildId: string;
  guild: Guild;
  roleId: string;
  level: PermissionLevel;
}

type ModerationAction =
  | "WARN"
  | "BAN"
  | "UNBAN"
  | "KICK"
  | "MUTE"
  | "UNMUTE"
  | "PURGE"
  | "PARDON";

type PermissionLevel = "NONE" | "MOD" | "ADMIN";

type PardonType = "UNBAN" | "UNMUTE";
