const { Pool } = require('pg');

// Todas las credenciales vienen por variables de entorno.
// En Cloud Run: DB_HOST será la IP privada de Cloud SQL (misma VPC, Direct
// VPC Egress) y DB_PASSWORD se inyecta desde Secret Manager (secret_env_vars).
// En local: apuntan al Postgres de docker-compose.
const pool = new Pool({
  host: process.env.DB_HOST || 'localhost',
  port: Number(process.env.DB_PORT) || 5432,
  database: process.env.DB_NAME || 'app_db',
  user: process.env.DB_USER || 'app_user',
  password: process.env.DB_PASSWORD,
  max: 5,
  idleTimeoutMillis: 30000,
});

pool.on('error', (err) => {
  console.error('Unexpected error on idle Postgres client', err);
});

module.exports = pool;
