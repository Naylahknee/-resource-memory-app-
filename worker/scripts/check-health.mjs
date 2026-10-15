// Post-deploy smoke check. /health is intentionally minimal ({"ok":true}) so it
// discloses no configuration; password hashing itself is covered by
// `npm test` (worker/test/password.test.mjs), including a self-test of the
// exact production PBKDF2 path.
const baseUrl = process.argv[2] ?? 'https://resource-memory-api.madincrease.workers.dev';
try {
  const response = await fetch(new URL('/health', baseUrl), { signal: AbortSignal.timeout(15000) });
  const health = await response.json();
  if (!response.ok || health.ok !== true) {
    throw new Error('Worker is unhealthy or still running old code. Deploy the latest worker and retry.');
  }
  console.log('Worker is up and serving the latest build.');
} catch (error) {
  console.error(error.message);
  process.exitCode = 1;
}
