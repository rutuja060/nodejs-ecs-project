const request = require('supertest');
const app = require('../index');

describe('API Endpoints', () => {
  it('should return health check', async () => {
    const res = await request(app).get('/health');
    expect(res.statusCode).toEqual(200);
    expect(res.body).toHaveProperty('message', 'API is healthy!');
  });

  it('should create a new todo', async () => {
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
});
