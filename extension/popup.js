let capturedTabIds = [];
const status = document.getElementById('status');
const closeBox = document.getElementById('closeBox');
const savedCount = document.getElementById('savedCount');

async function remember(windowOnly) {
  closeBox.hidden = true;
  status.textContent = 'Remembering…';
  document.querySelectorAll('button').forEach(button => button.disabled = true);
  const result = await chrome.runtime.sendMessage({ type: 'capture-session', windowOnly });
  document.querySelectorAll('button').forEach(button => button.disabled = false);
  if (!result?.ok) {
    status.textContent = result?.error || 'Could not save this session.';
    return;
  }
  capturedTabIds = result.tabIds || [];
  const count = result.resource?.session?.tabCount || capturedTabIds.length;
  status.textContent = '';
  savedCount.textContent = `Saved ${count} tab${count === 1 ? '' : 's'}.`;
  closeBox.hidden = false;
}

document.getElementById('all').addEventListener('click', () => remember(false));
document.getElementById('window').addEventListener('click', () => remember(true));
document.getElementById('settings').addEventListener('click', () => chrome.runtime.openOptionsPage());
document.getElementById('keepTabs').addEventListener('click', () => window.close());
document.getElementById('closeTabs').addEventListener('click', async () => {
  await chrome.runtime.sendMessage({ type: 'close-captured-tabs', tabIds: capturedTabIds });
  window.close();
});
