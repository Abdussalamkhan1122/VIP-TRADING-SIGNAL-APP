const state = {
  backendUrl: localStorage.getItem('backendUrl') || 'http://localhost:10000',
  adminKey: localStorage.getItem('adminKey') || ''
};

document.querySelectorAll('[data-view]').forEach((button) => {
  button.addEventListener('click', () => showView(button.dataset.view));
});

document.querySelector('#backendUrl').value = state.backendUrl;
document.querySelector('#adminKey').value = state.adminKey;
document.querySelector('#refreshSignals').addEventListener('click', loadSignals);
document.querySelector('#refreshVip').addEventListener('click', loadVipRequests);
document.querySelector('#settingsForm').addEventListener('submit', saveSettings);

loadSignals();
loadSettings();

function showView(id) {
  document.querySelectorAll('.view').forEach((view) => view.classList.remove('active'));
  document.querySelector(`#${id}`).classList.add('active');
  if (id === 'signals') loadSignals();
  if (id === 'vip') loadVipRequests();
}

async function loadSignals() {
  const target = document.querySelector('#signalsList');
  target.innerHTML = '<p>Loading...</p>';
  const data = await get('/api/signals?audience=all');
  target.innerHTML = data.signals.map((signal) => `
    <article class="card">
      <span class="badge">${signal.audience.toUpperCase()}</span>
      <h3>${signal.symbol} ${signal.direction}</h3>
      <p>Entry: ${signal.entry || '-'}</p>
      <p>SL: ${signal.stopLoss || '-'}</p>
      <p>${signal.takeProfits.map((tp) => `${tp.label}: ${tp.value} ${tp.unit}`).join('<br>')}</p>
    </article>
  `).join('') || '<p>No signals yet.</p>';
}

async function loadVipRequests() {
  const target = document.querySelector('#vipList');
  target.innerHTML = '<p>Loading...</p>';
  const data = await get('/api/admin/vip-requests', true);
  target.innerHTML = data.requests.map((request) => `
    <article class="card">
      <span class="badge">${request.status.toUpperCase()}</span>
      <h3>${request.email}</h3>
      <p>${request.displayName || 'No name'}</p>
      <button onclick="updateVip('${request.id}', 'approved')">Approve</button>
      <button onclick="updateVip('${request.id}', 'rejected')">Reject</button>
    </article>
  `).join('') || '<p>No VIP requests yet.</p>';
}

async function updateVip(id, status) {
  await patch(`/api/admin/vip-requests/${id}`, { status }, true);
  loadVipRequests();
}

async function saveSettings(event) {
  event.preventDefault();
  state.backendUrl = document.querySelector('#backendUrl').value.replace(/\/$/, '');
  state.adminKey = document.querySelector('#adminKey').value;
  localStorage.setItem('backendUrl', state.backendUrl);
  localStorage.setItem('adminKey', state.adminKey);
  await patch('/api/admin/settings', {
    freeSignalLimit: document.querySelector('#freeSignalLimit').value,
    resetPeriod: document.querySelector('#resetPeriod').value,
    exnessPartnerLink: document.querySelector('#exnessPartnerLink').value
  }, true);
  alert('Settings saved');
}

async function loadSettings() {
  const data = await get('/api/settings');
  document.querySelector('#freeSignalLimit').value = data.freeSignalLimit;
  document.querySelector('#resetPeriod').value = data.resetPeriod;
  document.querySelector('#exnessPartnerLink').value = data.exnessPartnerLink;
}

async function get(path, admin = false) {
  const response = await fetch(`${state.backendUrl}${path}`, { headers: headers(admin) });
  return response.json();
}

async function patch(path, body, admin = false) {
  const response = await fetch(`${state.backendUrl}${path}`, {
    method: 'PATCH',
    headers: { ...headers(admin), 'content-type': 'application/json' },
    body: JSON.stringify(body)
  });
  return response.json();
}

function headers(admin) {
  return admin ? { authorization: `Bearer ${state.adminKey}` } : {};
}

window.updateVip = updateVip;
