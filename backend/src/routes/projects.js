const express = require('express');
const pool = require('../db/pool');

const router = express.Router();

const VALID_STATUSES = ['active', 'paused', 'done'];

// GET /projects - lista todos los proyectos, más nuevos primero
router.get('/', async (req, res) => {
  try {
    const { rows } = await pool.query(
      'SELECT id, name, client, status, created_at FROM projects ORDER BY created_at DESC'
    );
    res.json(rows);
  } catch (err) {
    console.error('Error fetching projects', err);
    res.status(500).json({ error: 'Failed to fetch projects' });
  }
});

// POST /projects - crea un proyecto nuevo
router.post('/', async (req, res) => {
  const { name, client, status } = req.body || {};

  if (!name || typeof name !== 'string' || !name.trim()) {
    return res.status(400).json({ error: 'name is required' });
  }
  if (!client || typeof client !== 'string' || !client.trim()) {
    return res.status(400).json({ error: 'client is required' });
  }
  const finalStatus = status || 'active';
  if (!VALID_STATUSES.includes(finalStatus)) {
    return res.status(400).json({
      error: `status must be one of: ${VALID_STATUSES.join(', ')}`,
    });
  }

  try {
    const { rows } = await pool.query(
      `INSERT INTO projects (name, client, status)
       VALUES ($1, $2, $3)
       RETURNING id, name, client, status, created_at`,
      [name.trim(), client.trim(), finalStatus]
    );
    res.status(201).json(rows[0]);
  } catch (err) {
    console.error('Error creating project', err);
    res.status(500).json({ error: 'Failed to create project' });
  }
});

module.exports = router;
