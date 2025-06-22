const { Pool } = require('pg');
require('dotenv').config();

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

// Log database configuration (without password)
log('INFO', 'database_config', 'Database configuration loaded', {
  user: process.env.DB_USER,
  host: process.env.DB_HOST,
  database: process.env.DB_NAME,
  port: process.env.DB_PORT,
  // password: '***' // Don't log password
});

const pool = new Pool({
  user: process.env.DB_USER,
  host: process.env.DB_HOST,
  database: process.env.DB_NAME,
  password: process.env.DB_PASSWORD,
  port: process.env.DB_PORT,
  connectionTimeoutMillis: 5000, // Increased timeout
  idleTimeoutMillis: 30000,
  max: 20, // Maximum number of clients in the pool
  min: 2,  // Minimum number of clients in the pool
  ssl: {
    rejectUnauthorized: false // Required for RDS SSL connections
  }
});

// Handle pool errors
pool.on('error', (err) => {
  log('ERROR', 'database_pool_error', 'Unexpected error on idle client', {
    error: {
      message: err.message,
      code: err.code,
      stack: err.stack
    }
  });
});

// Handle pool connection events
pool.on('connect', (client) => {
  log('INFO', 'database_connect', 'New client connected to database');
});

pool.on('acquire', (client) => {
  log('DEBUG', 'database_acquire', 'Client acquired from pool');
});

pool.on('release', (client) => {
  log('DEBUG', 'database_release', 'Client released back to pool');
});

// Initialize database tables
async function initializeDatabase() {
  try {
    const client = await pool.connect();
    
    // Create todos table if it doesn't exist
    await client.query(`
      CREATE TABLE IF NOT EXISTS todos (
        id SERIAL PRIMARY KEY,
        task TEXT NOT NULL,
        completed BOOLEAN DEFAULT false,
        created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
      );
    `);
    
    log('INFO', 'database_init', 'Database tables initialized successfully');
    client.release();
  } catch (error) {
    log('ERROR', 'database_init_error', 'Database initialization failed', {
      error: {
        message: error.message,
        code: error.code,
        stack: error.stack
      }
    });
  }
}

// Test connection on startup
pool.query('SELECT NOW()', (err, res) => {
  if (err) {
    log('ERROR', 'database_connection_test', 'Database connection test failed', {
      error: {
        message: err.message,
        code: err.code,
        stack: err.stack
      }
    });
  } else {
    log('INFO', 'database_connection_test', 'Database connected successfully', {
      serverTime: res.rows[0].now
    });
    // Initialize tables after successful connection
    initializeDatabase();
  }
});

module.exports = pool;
