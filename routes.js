const express = require('express');
const pool = require('./db');
const router = express.Router();

router.get('/', (_, res) => {
  res.status(200).json({ message: 'Welcome to the To-Do List API!' });
});

router.get('/health', (_, res) => {
  res.status(200).json({ message: 'API is healthy!' });
});

router.get('/todos', async (_, res) => {
  try {
    const { rows } = await pool.query('SELECT * FROM todos');
    res.json(rows);
  } catch (error) {
    res.status(500).json({ error: 'Database connection failed' });
  }
});

router.post('/todos', async (req, res) => {
  const { task } = req.body;
  if (!task) return res.status(400).json({ error: 'Task is required' });

  try {
    const result = await pool.query(
      'INSERT INTO todos (task, completed) VALUES ($1, false) RETURNING *',
      [task]
    );
    res.status(201).json(result.rows[0]);
  } catch (error) {
    res.status(500).json({ error: 'Database connection failed' });
  }
});

router.put('/todos/:id', async (req, res) => {
  const { id } = req.params;
  const { task, completed } = req.body;

  try {
    const result = await pool.query(
      'UPDATE todos SET task = $1, completed = $2 WHERE id = $3 RETURNING *',
      [task, completed, id]
    );

    if (result.rows.length === 0) return res.status(404).json({ error: 'Todo not found' });
    res.json(result.rows[0]);
  } catch (error) {
    res.status(500).json({ error: 'Database connection failed' });
  }
});

router.delete('/todos/:id', async (req, res) => {
  const { id } = req.params;
  try {
    const result = await pool.query('DELETE FROM todos WHERE id = $1 RETURNING *', [id]);

    if (result.rows.length === 0) return res.status(404).json({ error: 'Todo not found' });
    res.json(result.rows[0]);
  } catch (error) {
    res.status(500).json({ error: 'Database connection failed' });
  }
});

router.post('/data', (req, res) => {
    const { name } = req.body;
    if (!name) {
      return res.status(400).json({ error: 'Name is required' });
    }
    res.status(201).json({ message: `Hello, ${name}` });
  });

module.exports = router;
