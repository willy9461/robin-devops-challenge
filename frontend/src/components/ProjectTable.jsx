import StatusStamp from './StatusStamp';

function formatDate(iso) {
  return new Date(iso).toLocaleDateString('es-AR', {
    day: '2-digit',
    month: '2-digit',
    year: 'numeric',
  });
}

export default function ProjectTable({ projects }) {
  if (projects.length === 0) {
    return (
      <div className="project-table__empty">
        <p>Todavía no hay proyectos cargados.</p>
        <p className="project-table__empty-hint">
          Agregá el primero con el formulario de arriba.
        </p>
      </div>
    );
  }

  return (
    <table className="project-table">
      <thead>
        <tr>
          <th>Proyecto</th>
          <th>Cliente</th>
          <th>Estado</th>
          <th className="project-table__date-col">Creado</th>
        </tr>
      </thead>
      <tbody>
        {projects.map((p) => (
          <tr key={p.id}>
            <td className="project-table__name">{p.name}</td>
            <td>{p.client}</td>
            <td>
              <StatusStamp status={p.status} />
            </td>
            <td className="project-table__date-col project-table__date">
              {formatDate(p.created_at)}
            </td>
          </tr>
        ))}
      </tbody>
    </table>
  );
}
