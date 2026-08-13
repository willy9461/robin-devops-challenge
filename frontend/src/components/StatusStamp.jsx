const STATUS_LABELS = {
  active: 'En curso',
  paused: 'Pausado',
  done: 'Terminado',
};

// El "sello" de estado: en vez de un badge redondeado genérico, un
// rectángulo con doble borde tipo timbre de expediente — cada fila de la
// tabla queda "sellada" con su estado, ese es el elemento distintivo del
// diseño (ver token Signature en la guía de diseño).
export default function StatusStamp({ status }) {
  const label = STATUS_LABELS[status] || status;
  return <span className={`status-stamp status-stamp--${status}`}>{label}</span>;
}
