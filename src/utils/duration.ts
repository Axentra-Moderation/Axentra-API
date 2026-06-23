/**
 * Parses a human-friendly duration string into a number of seconds.
 *
 * Supported units (case-sensitive):
 *   s  -> seconds
 *   m  -> minutes
 *   h  -> hours
 *   d  -> days
 *   mo  -> months (approximated as 30 days)
 *   y  -> years  (approximated as 365 days)
 *
 * Accepts an optional space between the number and unit: "5m", "5 m" both work.
 *
 * Examples:
 *   parseDuration("5 s") -> 5
 *   parseDuration("5 m") -> 300
 *   parseDuration("5 h") -> 18000
 *   parseDuration("5 d") -> 432000
 *   parseDuration("5 M") -> 12960000
 *   parseDuration("5 y") -> 157680000
 */

const UNIT_TO_SECONDS: Record<string, number> = {
  s: 1,
  m: 60,
  h: 60 * 60,
  d: 60 * 60 * 24,
  mo: 60 * 60 * 24 * 30, // approximate month
  y: 60 * 60 * 24 * 365, // approximate year
};

const DURATION_PATTERN = /^(\d+)\s*([smhdMy])$/;

export class InvalidDurationError extends Error {
  constructor(input: string) {
    super(
      `Invalid duration: "${input}". Expected a number followed by one of s, m, h, d, M, y (e.g. "5 m").`,
    );
    this.name = "InvalidDurationError";
  }
}

export function parseDuration(input: string): number {
  const trimmed = input.trim();
  const match = DURATION_PATTERN.exec(trimmed);

  if (!match) {
    throw new InvalidDurationError(input);
  }

  const amount = match[1];
  const unit = match[2];

  if (!amount || !unit) {
    throw new InvalidDurationError(input);
  }

  const value = Number(amount);
  const multiplier = UNIT_TO_SECONDS[unit];

  if (!multiplier || !Number.isFinite(value) || value <= 0) {
    throw new InvalidDurationError(input);
  }

  return value * multiplier;
}
