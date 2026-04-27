// ============================================================
// Doable AI — Auth helpers
// ============================================================

// Controleer sessie — redirect als niet ingelogd
async function requireAuth(expectedRole = null) {
  const { data: { user }, error } = await supabase.auth.getUser();
  if (error || !user) {
    window.location.href = '/portal/login.html';
    return null;
  }
  const role = user.user_metadata?.role ?? 'client';
  if (expectedRole && role !== expectedRole) {
    // Verkeerde rol → stuur naar juist portaal
    window.location.href = role === 'admin'
      ? '/portal/admin/index.html'
      : '/portal/client/index.html';
    return null;
  }
  return { user, role };
}

// Uitloggen
async function logout() {
  await supabase.auth.signOut();
  window.location.href = '/portal/login.html';
}

// Huidige user ophalen (zonder redirect)
async function getUser() {
  const { data: { user } } = await supabase.auth.getUser();
  return user;
}

// Rol ophalen
async function getRole() {
  const user = await getUser();
  return user?.user_metadata?.role ?? 'client';
}

// Client-record van ingelogde user ophalen
async function getMyClient() {
  const user = await getUser();
  if (!user) return null;
  const { data } = await supabase
    .from('clients')
    .select('*')
    .eq('user_id', user.id)
    .single();
  return data;
}

// Ongelezen berichten tellen
async function getUnreadCount(clientId = null) {
  let query = supabase
    .from('messages')
    .select('id', { count: 'exact', head: true })
    .is('read_at', null);

  const role = await getRole();
  if (role === 'admin') {
    query = query.eq('sender_role', 'client');
  } else {
    query = query.eq('sender_role', 'admin').eq('client_id', clientId);
  }
  const { count } = await query;
  return count ?? 0;
}

// Datum formatteren (NL)
function formatDate(dateStr) {
  if (!dateStr) return '—';
  return new Date(dateStr).toLocaleDateString('nl-NL', {
    day: 'numeric', month: 'long', year: 'numeric'
  });
}

// Bedrag formatteren (EUR)
function formatEur(amount) {
  if (amount == null) return '—';
  return new Intl.NumberFormat('nl-NL', {
    style: 'currency', currency: 'EUR'
  }).format(amount);
}

// Status badge HTML
function statusBadge(status) {
  const map = {
    prospect:  ['badge-muted',  'Prospect'],
    active:    ['badge-green',  'Actief'],
    past:      ['badge-muted',  'Afgerond'],
    intake:    ['badge-blue',   'Intake'],
    building:  ['badge-amber',  'In bouw'],
    delivered: ['badge-green',  'Opgeleverd'],
    support:   ['badge-blue',   'Support'],
    closed:    ['badge-muted',  'Gesloten'],
    draft:     ['badge-muted',  'Concept'],
    sent:      ['badge-blue',   'Verstuurd'],
    paid:      ['badge-green',  'Betaald'],
    overdue:   ['badge-red',    'Verlopen'],
    cancelled: ['badge-muted',  'Geannuleerd'],
    accepted:  ['badge-green',  'Geaccepteerd'],
    rejected:  ['badge-red',    'Afgewezen'],
    expired:   ['badge-muted',  'Verlopen'],
  };
  const [cls, label] = map[status] ?? ['badge-muted', status];
  return `<span class="badge ${cls}">${label}</span>`;
}

// Toast notificatie
function toast(msg, type = 'info') {
  const t = document.createElement('div');
  t.className = `toast toast-${type}`;
  t.textContent = msg;
  document.body.appendChild(t);
  setTimeout(() => t.classList.add('show'), 10);
  setTimeout(() => { t.classList.remove('show'); setTimeout(() => t.remove(), 300); }, 3000);
}

// Error afhandelen
function handleError(err, context = '') {
  console.error(context, err);
  toast(err?.message ?? 'Er is iets misgegaan.', 'error');
}
