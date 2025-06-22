const { Pool } = require('pg');
require('dotenv').config();

async function testConnection() {
  console.log('Testing database connection...');
  console.log('Environment variables:');
  console.log('DB_USER:', process.env.DB_USER);
  console.log('DB_HOST:', process.env.DB_HOST);
  console.log('DB_NAME:', process.env.DB_NAME);
  console.log('DB_PORT:', process.env.DB_PORT);
  console.log('DB_PASSWORD:', process.env.DB_PASSWORD ? '***' : 'NOT SET');

  const pool = new Pool({
    user: process.env.DB_USER,
    host: process.env.DB_HOST,
    database: process.env.DB_NAME,
    password: process.env.DB_PASSWORD,
    port: process.env.DB_PORT,
    connectionTimeoutMillis: 10000,
  });

  try {
    const client = await pool.connect();
    console.log('✅ Database connection successful!');
    
    const result = await client.query('SELECT NOW() as current_time, version() as db_version');
    console.log('Current time:', result.rows[0].current_time);
    console.log('Database version:', result.rows[0].db_version);
    
    // Test if todos table exists
    const tableResult = await client.query(`
      SELECT EXISTS (
        SELECT FROM information_schema.tables 
        WHERE table_schema = 'public' 
        AND table_name = 'todos'
      );
    `);
    
    if (tableResult.rows[0].exists) {
      console.log('✅ Todos table exists');
      
      // Test inserting a record
      const insertResult = await client.query(
        'INSERT INTO todos (task, completed) VALUES ($1, false) RETURNING *',
        ['Test task from connection test']
      );
      console.log('✅ Insert test successful:', insertResult.rows[0]);
      
      // Clean up test record
      await client.query('DELETE FROM todos WHERE task = $1', ['Test task from connection test']);
      console.log('✅ Cleanup successful');
    } else {
      console.log('❌ Todos table does not exist');
    }
    
    client.release();
  } catch (error) {
    console.error('❌ Database connection failed:', error.message);
    console.error('Error details:', error);
  } finally {
    await pool.end();
  }
}

testConnection(); 