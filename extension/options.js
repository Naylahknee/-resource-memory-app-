const DEFAULT_EXCLUSIONS = ['mail.google.com','outlook.live.com','outlook.office.com','icloud.com','chase.com','bankofamerica.com','wellsfargo.com','capitalone.com','mychart.com','mychart.org','1password.com','lastpass.com','bitwarden.com'];

async function load() {
  const saved = await chrome.storage.local.get(['apiBase','email','token','excludedDomains']);
  document.getElementById('apiBase').value = saved.apiBase || '';
  document.getElementById('email').value = saved.email || '';
  document.getElementById('excluded').value = (saved.excludedDomains || DEFAULT_EXCLUSIONS).join('\n');
  document.getElementById('authStatus').textContent = saved.token ? 'This browser is connected.' : '';
}

document.getElementById('login').addEventListener('click', async () => {
  const apiBase = document.getElementById('apiBase').value.trim().replace(/\/$/, '');
  const email = document.getElementById('email').value.trim();
  const password = document.getElementById('password').value;
  const status = document.getElementById('authStatus');
  status.textContent = 'Signing in…';
  try {
    const response = await fetch(`${apiBase}/auth/login`, { method:'POST', headers:{'content-type':'application/json'}, body:JSON.stringify({email,password}) });
    const payload = await response.json();
    if (!response.ok || !payload.token) throw new Error(payload.error || 'Sign in failed.');
    await chrome.storage.local.set({ apiBase, email, token: payload.token });
    document.getElementById('password').value = '';
    status.textContent = 'Connected.';
  } catch (error) { status.textContent = error.message; }
});

document.getElementById('save').addEventListener('click', async () => {
  const excludedDomains = document.getElementById('excluded').value.split(/\r?\n|,/).map(v => v.trim().toLowerCase()).filter(Boolean);
  await chrome.storage.local.set({ excludedDomains });
  document.getElementById('saveStatus').textContent = 'Saved.';
});

load();
