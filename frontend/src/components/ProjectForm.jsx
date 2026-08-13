import { useState } from 'react';

const EMPTY_FORM = { name: '', client: '', status: 'active' };

export default function ProjectForm({ onSubmit, submitting }) {
  const [form, setForm] = useState(EMPTY_FORM);
  const [error, setError] = useState(null);

  function handleChange(field) {
    return (e) => setForm((f) => ({ ...f, [field]: e.target.value }));
  }

  async function handleSubmit(e) {
    e.preventDefault();
    setError(null);

    if (!form.name.trim() || !form.client.trim()) {
      setError('Completá nombre y cliente.');
      return;
    }

    try {
      await onSubmit(form);
      setForm(EMPTY_FORM);
    } catch (err) {
      setError(err.message || 'No se pudo crear el proyecto.');
    }
  }

  return (
    <form className="project-form" onSubmit={handleSubmit}>
      <div className="project-form__row">
        <label className="project-form__field">
          <span>Proyecto</span>
          <input
            type="text"
            placeholder="Ej. Rediseño e-commerce"
            value={form.name}
            onChange={handleChange('name')}
          />
        </label>

        <label className="project-form__field">
          <span>Cliente</span>
          <input
            type="text"
            placeholder="Ej. Acme Corp"
            value={form.client}
            onChange={handleChange('client')}
          />
        </label>

        <label className="project-form__field project-form__field--status">
          <span>Estado</span>
          <select value={form.status} onChange={handleChange('status')}>
            <option value="active">En curso</option>
            <option value="paused">Pausado</option>
            <option value="done">Terminado</option>
          </select>
        </label>

        <button type="submit" className="project-form__submit" disabled={submitting}>
          {submitting ? 'Agregando…' : 'Agregar proyecto'}
        </button>
      </div>

      {error && <p className="project-form__error">{error}</p>}
    </form>
  );
}
