const express = require('express');
const pool = require('./db');
const router = express.Router();

// Structured logging function
const log = (level, type, message, data = {}) => {
  console.log(JSON.stringify({
    timestamp: new Date().toISOString(),
    level,
    type,
    message,
    ...data
  }));
};

// Structured logging middleware
const logRequest = (req, res, next) => {
  const logData = {
    method: req.method,
    url: req.url,
    ip: req.ip,
    userAgent: req.get('User-Agent'),
    requestId: req.headers['x-request-id'] || Math.random().toString(36).substr(2, 9)
  };
  
  log('INFO', 'api_request', 'API request received', logData);
  
  // Add request ID to response headers
  res.setHeader('X-Request-ID', logData.requestId);
  
  next();
};

router.use(logRequest);

router.get('/', (_, res) => {
  log('INFO', 'api_response', 'Welcome endpoint called');
  res.status(200).json({ message: 'Welcome to the To-Do List API!' });
});

router.get('/health', (_, res) => {
  log('INFO', 'api_response', 'Health check endpoint called');
  res.status(200).json({ message: 'API is healthy!' });
});

router.get('/todos', async (req, res) => {
  try {
    const { rows } = await pool.query('SELECT * FROM todos ORDER BY created_at DESC');
    log('INFO', 'api_response', 'Todos retrieved successfully', {
      count: rows.length,
      requestId: req.headers['x-request-id']
    });
    res.json(rows);
  } catch (error) {
    log('ERROR', 'api_error', 'Failed to retrieve todos', {
      error: {
        message: error.message,
        code: error.code
      },
      requestId: req.headers['x-request-id']
    });
    res.status(500).json({ error: 'Database connection failed', details: error.message });
  }
});

router.post('/todos', async (req, res) => {
  const { task } = req.body;
  if (!task) {
    log('WARN', 'api_validation', 'Todo creation failed - task is required', {
      requestId: req.headers['x-request-id']
    });
    return res.status(400).json({ error: 'Task is required' });
  }

  try {
    const result = await pool.query(
      'INSERT INTO todos (task, completed) VALUES ($1, false) RETURNING *',
      [task]
    );
    log('INFO', 'api_response', 'Todo created successfully', {
      todoId: result.rows[0].id,
      task: task,
      requestId: req.headers['x-request-id']
    });
    res.status(201).json(result.rows[0]);
  } catch (error) {
    log('ERROR', 'api_error', 'Failed to create todo', {
      error: {
        message: error.message,
        code: error.code
      },
      task: task,
      requestId: req.headers['x-request-id']
    });
    res.status(500).json({ error: 'Database connection failed', details: error.message });
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

    if (result.rows.length === 0) {
      log('WARN', 'api_not_found', 'Todo not found for update', {
        todoId: id,
        requestId: req.headers['x-request-id']
      });
      return res.status(404).json({ error: 'Todo not found' });
    }
    
    log('INFO', 'api_response', 'Todo updated successfully', {
      todoId: id,
      task: task,
      completed: completed,
      requestId: req.headers['x-request-id']
    });
    res.json(result.rows[0]);
  } catch (error) {
    log('ERROR', 'api_error', 'Failed to update todo', {
      error: {
        message: error.message,
        code: error.code
      },
      todoId: id,
      requestId: req.headers['x-request-id']
    });
    res.status(500).json({ error: 'Database connection failed', details: error.message });
  }
});

router.delete('/todos/:id', async (req, res) => {
  const { id } = req.params;
  try {
    const result = await pool.query('DELETE FROM todos WHERE id = $1 RETURNING *', [id]);

    if (result.rows.length === 0) {
      log('WARN', 'api_not_found', 'Todo not found for deletion', {
        todoId: id,
        requestId: req.headers['x-request-id']
      });
      return res.status(404).json({ error: 'Todo not found' });
    }
    
    log('INFO', 'api_response', 'Todo deleted successfully', {
      todoId: id,
      task: result.rows[0].task,
      requestId: req.headers['x-request-id']
    });
    res.json(result.rows[0]);
  } catch (error) {
    log('ERROR', 'api_error', 'Failed to delete todo', {
      error: {
        message: error.message,
        code: error.code
      },
      todoId: id,
      requestId: req.headers['x-request-id']
    });
    res.status(500).json({ error: 'Database connection failed', details: error.message });
  }
});

router.post('/data', (req, res) => {
    const { name } = req.body;
    if (!name) {
      log('WARN', 'api_validation', 'Greeting failed - name is required', {
        requestId: req.headers['x-request-id']
      });
      return res.status(400).json({ error: 'Name is required' });
    }
    
    log('INFO', 'api_response', 'Greeting request processed', {
      name: name,
      requestId: req.headers['x-request-id']
    });
    res.status(201).json({ message: `Hello, ${name}` });
  });

module.exports = router;
