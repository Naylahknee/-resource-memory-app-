import { pbkdf2Sync, randomBytes, timingSafeEqual } from 'node:crypto';
import { Buffer } from 'node:buffer';

// The deployed Cloudflare Workers runtime rejects PBKDF2 above 100,000
// iterations (local `wrangler dev` and plain Node do not enforce the cap, so
// this only fails in production -- verified live 2026-10-15 via the
// /health self-test). New hashes therefore use 100,000 iterations.
const ITERATIONS = 100000;
// Hashes created before the cap was respected used 120,000 iterations and are
// stored as bare hex. The runtime cannot verify those, so their owners get a
// clean "needs a password reset" instead of a 500, and can reset with
// worker/scripts/reset-password-sql.mjs (documented in docs/CLOUD_SYNC_SETUP.md).
const PREFIX = 'pbkdf2-sha256';
const SALT_HEX = /^[0-9a-f]{32}$/i;
const HASH_HEX = /^[0-9a-f]{64}$/i;
const MODULAR = /^pbkdf2-sha256\$([1-9][0-9]{0,6})\$([0-9a-f]{64})$/i;

function derive(password: string, saltHex: string, iterations: number): string {
  return pbkdf2Sync(password, Buffer.from(saltHex, 'hex'), iterations, 32, 'sha256').toString('hex');
}

export async function hashPassword(password: string, saltHex?: string): Promise<{ salt: string; hash: string }> {
  const salt = saltHex ?? randomBytes(16).toString('hex');
  if (!SALT_HEX.test(salt)) throw new Error('Invalid password salt.');
  return { salt, hash: `${PREFIX}$${ITERATIONS}$${derive(password, salt, ITERATIONS)}` };
}

export async function verifyPassword(
  password: string,
  saltHex: string,
  storedHash: string,
): Promise<{ ok: boolean; needsReset: boolean; needsRehash: boolean }> {
  const invalid = { ok: false, needsReset: true, needsRehash: false };
  try {
    if (typeof saltHex !== 'string' || !SALT_HEX.test(saltHex) || typeof storedHash !== 'string') return invalid;

    const modular = MODULAR.exec(storedHash);
    if (modular) {
      const iterations = Number(modular[1]);
      // Bound the work before calling crypto, including malformed database rows.
      // Iteration counts the runtime refuses are treated as needing a reset.
      if (iterations > ITERATIONS) return invalid;
      const actual = derive(password, saltHex, iterations);
      const ok = timingSafeEqual(Buffer.from(actual, 'hex'), Buffer.from(modular[2], 'hex'));
      return { ok, needsReset: false, needsRehash: ok && iterations !== ITERATIONS };
    }

    // Legacy bare-hex hashes were made at 120k iterations, which the deployed
    // runtime refuses. Never throw here; the owner resets via the SQL script.
    if (HASH_HEX.test(storedHash)) return invalid;

    return invalid;
  } catch {
    return invalid;
  }
}

export async function passwordCryptoSelfTest(): Promise<boolean> {
  // Test the exact production register/login path (100k via node:crypto)
  // against a known PBKDF2-SHA256 vector, rather than a cheap probe that can
  // pass while real password hashing fails.
  try {
    const record = await hashPassword('health-probe', '00000000000000000000000000000000');
    if (
      record.hash !==
      `${PREFIX}$${ITERATIONS}$90e786dba84989da26ccde1b3d0daec0da06571663045e8210820b06554e0ee8`
    ) {
      return false;
    }
    const check = await verifyPassword('health-probe', record.salt, record.hash);
    return check.ok && !check.needsReset && !check.needsRehash;
  } catch {
    return false;
  }
}
