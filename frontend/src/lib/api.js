// URL del backend, configurable por env var. En dev local apunta al backend
// de docker-compose (localhost:8080). En producción, Vite la inyecta en
// build-time desde VITE_API_URL (variable de CI/CD, no hardcodeada).
const API_URL = import.meta.env.VITE_API_URL || 'http://localhost:8080';

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
