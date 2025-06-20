const request = require('supertest');
const app = require('../index');

describe('GET /health', () => {
    it('should return API is healthy', async () => {
      const res = await request(app).get('/health');
      expect(res.statusCode).toEqual(200);
      expect(res.body).toHaveProperty('message', 'API is healthy!');
    });
  });
  

describe('POST /data', () => {
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
