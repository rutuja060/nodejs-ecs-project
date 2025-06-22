const request = require('supertest');
const app = require('../index');
const pool = require('../db'); // make sure this is your pg pool

describe('API Endpoints', () => {
  let dbAvailable = false;

  // Test database connection before running tests
  beforeAll(async () => {
    try {
      await pool.query('SELECT 1');
      dbAvailable = true;
      console.log('Database connected successfully');
      
      // Create the todos table if it doesn't exist
      await pool.query(`
        CREATE TABLE IF NOT EXISTS todos (
          id SERIAL PRIMARY KEY,
          task TEXT NOT NULL,
          completed BOOLEAN DEFAULT false
        );
      `);
      console.log('Todos table created/verified successfully');
    } catch (error) {
      console.log('Database not available in CI/CD environment - skipping database tests');
      console.log('Error:', error.message);
      dbAvailable = false;
    }
  });

  it('should return health check', async () => {
    const res = await request(app).get('/health');
    expect(res.statusCode).toEqual(200);
    expect(res.body).toHaveProperty('message', 'API is healthy!');
  });

  it('should create a new todo', async () => {
    if (!dbAvailable) {
      console.log('Skipping todo creation test - database not available');
      return;
    }
    
    const res = await request(app).post('/todos').send({ task: 'Test Docker' });
    expect(res.statusCode).toEqual(201);
    expect(res.body).toHaveProperty('task', 'Test Docker');
    expect(res.body).toHaveProperty('completed', false);
  });

  it('should fail to create todo if task is missing', async () => {
    const res = await request(app).post('/todos').send({});
    expect(res.statusCode).toEqual(400);
    expect(res.body).toHaveProperty('error', 'Task is required');
  });

  it('should return greeting message', async () => {
    const res = await request(app).post('/data').send({ name: 'Rutuja' });
    expect(res.statusCode).toEqual(201);
    expect(res.body).toHaveProperty('message', 'Hello, Rutuja');
  });
  
  it('should return error if name is missing', async () => {
    const res = await request(app).post('/data').send({});
    expect(res.statusCode).toEqual(400);
    expect(res.body).toHaveProperty('error', 'Name is required');
  });
  
});

afterAll(async () => {
  await pool.end(); // closes DB connection
});
