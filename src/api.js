const API_BASE = '/api/v1/contrib/fsrecordmetadata';

async function apiFetch(path, options = {}) {
  const headers = { Accept: 'application/json', ...options.headers };
  if (options.body) headers['Content-Type'] = 'application/json';

  const res = await fetch(`${API_BASE}${path}`, {
    credentials: 'same-origin',
    ...options,
    headers,
  });

  if (!res.ok) {
    const body = await res.json().catch(() => ({}));
    const err = new Error(body.error || `Request failed (${res.status})`);
    err.status = res.status;
    throw err;
  }

  return res;
}

const qs = (params) => {
  const clean = {};
  for (const [k, v] of Object.entries(params || {})) {
    if (v !== null && v !== undefined && v !== '') clean[k] = v;
  }
  return new URLSearchParams(clean).toString();
};

// Entries
export const getEntries = (params) =>
  apiFetch(`/entries?${qs(params)}`).then((r) => r.json());

export const getEntriesPaged = async (params) => {
  const res = await apiFetch(`/entries?${qs(params)}`);
  return {
    rows: await res.json(),
    total: parseInt(res.headers.get('X-Total-Count') || '0', 10),
  };
};

export const createEntry = (body) =>
  apiFetch('/entries', { method: 'POST', body: JSON.stringify(body) }).then((r) => r.json());

export const createEntries = (body) =>
  apiFetch("/entries/bulk", { method: "POST", body: JSON.stringify(body) }).then((r) => r.json());

export const previewEntries = (body) =>
  apiFetch("/entries/preview", { method: "POST", body: JSON.stringify(body) }).then((r) => r.json());

export const updateEntry = (id, body) =>
  apiFetch(`/entries/${id}`, { method: 'PUT', body: JSON.stringify(body) }).then((r) => r.json());

export const checkDtn = (dtn) =>
  apiFetch(`/entries/check-dtn?${qs({ dtn })}`).then((r) => r.json());

// Record lookup
export const lookupRecord = (params) =>
  apiFetch(`/lookup?${qs(params)}`).then((r) => r.json());

// Problems
export const getProblems = (params) =>
  apiFetch(`/problems?${qs(params)}`).then((r) => r.json());

export const getProblemsPaged = async (params) => {
  const res = await apiFetch(`/problems?${qs(params)}`);
  return {
    rows: await res.json(),
    total: parseInt(res.headers.get('X-Total-Count') || '0', 10),
  };
};

export const createProblem = (body) =>
  apiFetch('/problems', { method: 'POST', body: JSON.stringify(body) }).then((r) => r.json());

export const updateProblem = (id, body) =>
  apiFetch(`/problems/${id}`, { method: 'PUT', body: JSON.stringify(body) }).then((r) => r.json());

// Staff
export const searchStaff = (q) =>
  apiFetch(`/staff?${qs({ q })}`).then((r) => r.json());

export const getUsers = () => apiFetch("/users").then((r) => r.json());

export const saveUsers = (body) =>
  apiFetch("/users", { method: "PUT", body: JSON.stringify(body) }).then((r) => r.json());

export { apiFetch, API_BASE };
