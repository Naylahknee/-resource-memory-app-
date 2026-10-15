import assert from 'node:assert/strict';
import { test } from 'node:test';
import { pbkdf2Sync } from 'node:crypto';
import { hashPassword, verifyPassword, passwordCryptoSelfTest } from '../src/password.ts';

const salt = '00112233445566778899aabbccddeeff';
const password = 'My existing password 🔒';
const fixture = (iterations) => pbkdf2Sync(password, Buffer.from(salt, 'hex'), iterations, 32, 'sha256').toString('hex');

test('legacy 120k hashes require a reset instead of throwing in production', async () => {
  // The deployed Workers runtime refuses PBKDF2 above 100k iterations, so a
  // 120k bare-hex hash can never verify there. The owner resets via
  // worker/scripts/reset-password-sql.mjs.
  assert.deepEqual(await verifyPassword(password, salt, fixture(120000)), {
    ok: false, needsReset: true, needsRehash: false,
  });
});

test('wrong legacy passwords also require a reset', async () => {
  assert.deepEqual(await verifyPassword('wrong password', salt, fixture(120000)), {
    ok: false, needsReset: true, needsRehash: false,
  });
});

test('100k hashes from the reset script log in with no upgrade needed', async () => {
  assert.deepEqual(await verifyPassword(password, salt, `pbkdf2-sha256$100000$${fixture(100000)}`), {
    ok: true, needsReset: false, needsRehash: false,
  });
});

test('new hashes record the count and round-trip', async () => {
  const record = await hashPassword(password);
  assert.match(record.salt, /^[0-9a-f]{32}$/);
  assert.match(record.hash, /^pbkdf2-sha256\$100000\$[0-9a-f]{64}$/);
  assert.deepEqual(await verifyPassword(password, record.salt, record.hash), {
    ok: true, needsReset: false, needsRehash: false,
  });
  assert.equal((await verifyPassword('wrong password', record.salt, record.hash)).ok, false);
});

test('hex casing does not change the reset requirement for legacy hashes', async () => {
  assert.equal((await verifyPassword(password, salt.toUpperCase(), fixture(120000).toUpperCase())).needsReset, true);
});

test('malformed salts, hashes, and iteration counts require reset without throwing', async () => {
  const badHashes = [null, '', 'not-hex', 'a'.repeat(63),
    `pbkdf2-sha256$0$${fixture(1000)}`,
    `pbkdf2-sha256$-1$${fixture(1000)}`,
    `pbkdf2-sha256$120000$${fixture(1000)}`,
    `pbkdf2-sha256$100001$${fixture(1000)}`,
    `pbkdf2-sha256$2147483647$${fixture(1000)}`,
    `pbkdf2-sha256$100000$xyz`];
  for (const hash of badHashes) {
    assert.deepEqual(await verifyPassword(password, salt, hash), { ok: false, needsReset: true, needsRehash: false });
  }
  for (const invalidSalt of [null, '', 'zz'.repeat(16), 'a'.repeat(31)]) {
    assert.equal((await verifyPassword(password, invalidSalt, fixture(120000))).needsReset, true);
  }
});

test('the health probe checks the actual 100k hashing path', async () => {
  assert.equal(await passwordCryptoSelfTest(), true);
});
