// URL del backend, configurable por env var. En producción, apunta al
// subdominio del backend detrás del Load Balancer (api.<ip>.nip.io),
// inyectada en build-time por el CI/CD. En desarrollo local (pnpm dev,
// sin Load Balancer), hay que setear VITE_API_URL explícitamente en un
// .env.local (ver .env.example) — sin ninguna de las dos, el default
// vacío hace que el fetch sea relativo al origen actual.
const API_URL = import.meta.env.VITE_API_URL || '';

async function request(path, options = {}) {
  const res = await fetch(`${API_URL}${path}`, {
    headers: { 'Content-Type': 'application/json' },
    ...options,
  });

  if (!res.ok) {
    let message = `Error ${res.status}`;
    try {
      const body = await res.json();
      if (body?.error) message = body.error;
    } catch {
      // respuesta sin JSON, se usa el mensaje default
    }
    throw new Error(message);
  }

  return res.json();
}

export function getProjects() {
  return request('/projects');
}

export function createProject(project) {
  return request('/projects', {
    method: 'POST',
    body: JSON.stringify(project),
  });
}
