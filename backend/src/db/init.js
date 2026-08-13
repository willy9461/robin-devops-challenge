const pool = require('./pool');

// Crea la tabla si no existe. Se llama al arrancar el server.
// Para este alcance (challenge de 48hs) no usamos un sistema de migraciones
// aparte; un CREATE TABLE IF NOT EXISTS es suficiente y documentado como tal.
async function ensureSchema() {
  await pool.query(`
    CREATE TABLE IF NOT EXISTS projects (
      id SERIAL PRIMARY KEY,
      name TEXT NOT NULL,
      client TEXT NOT NULL,
      status TEXT NOT NULL DEFAULT 'active',
      created_at TIMESTAMPTZ NOT NULL DEFAULT now()
    );
  `);
}

module.exports = { ensureSchema };
