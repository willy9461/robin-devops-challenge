import { useEffect, useState } from 'react';
import { getProjects, createProject } from './lib/api';
import ProjectForm from './components/ProjectForm';
import ProjectTable from './components/ProjectTable';
import './App.css';

export default function App() {
  const [projects, setProjects] = useState([]);
  const [loading, setLoading] = useState(true);
  const [loadError, setLoadError] = useState(null);
  const [submitting, setSubmitting] = useState(false);

  useEffect(() => {
    loadProjects();
  }, []);

  async function loadProjects() {
    setLoading(true);
    setLoadError(null);
    try {
      const data = await getProjects();
      setProjects(data);
    } catch (err) {
      setLoadError(err.message || 'No se pudieron cargar los proyectos.');
    } finally {
      setLoading(false);
    }
  }

  async function handleCreate(project) {
    setSubmitting(true);
    try {
      const created = await createProject(project);
      setProjects((prev) => [created, ...prev]);
    } finally {
      setSubmitting(false);
    }
  }

  return (
    <div className="app">
      <header className="app__header">
        <p className="app__eyebrow">Software Factory — Panel interno</p>
        <h1 className="app__title">Project Tracker</h1>
        <p className="app__subtitle">
          Seguimiento de proyectos activos por cliente.
        </p>
      </header>

      <main className="app__main">
        <section className="app__panel">
          <ProjectForm onSubmit={handleCreate} submitting={submitting} />
        </section>

        <section className="app__panel app__panel--table">
          {loading && <p className="app__status">Cargando proyectos…</p>}

          {!loading && loadError && (
            <div className="app__error">
              <p>No se pudo conectar con el servidor: {loadError}</p>
              <button type="button" onClick={loadProjects}>
                Reintentar
              </button>
            </div>
          )}

          {!loading && !loadError && <ProjectTable projects={projects} />}
        </section>
      </main>
    </div>
  );
}
