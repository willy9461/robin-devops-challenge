const express = require('express');
const cors = require('cors');
const { ensureSchema } = require('./db/init');
const projectsRouter = require('./routes/projects');

const app = express();

// Cloud Run inyecta PORT automáticamente; localmente default a 8080.
const PORT = process.env.PORT || 8080;

// CORS: en producción, restringir al dominio real del frontend (LB/nip.io)
// vía FRONTEND_ORIGIN. Si no está seteada, se permite todo (útil para dev local).
const allowedOrigins = process.env.FRONTEND_ORIGIN
  ? process.env.FRONTEND_ORIGIN.split(',').map((o) => o.trim())
  : null;
app.use(cors(allowedOrigins ? { origin: allowedOrigins } : {}));

app.use(express.json());

app.get('/health', (req, res) => {
  res.json({ status: 'ok' });
});

app.use('/projects', projectsRouter);

app.use((req, res) => {
  res.status(404).json({ error: 'Not found' });
});

async function start() {
  try {
    await ensureSchema();
    app.listen(PORT, () => {
      console.log(`Backend listening on port ${PORT}`);
    });
  } catch (err) {
    console.error('Failed to start server', err);
    process.exit(1);
  }
}

start();
