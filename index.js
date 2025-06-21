// index.js
const express = require('express');
const app = express();

// Middleware and routes
app.use(express.json());

// Routes
app.get('/health', (req, res) => {
  res.status(200).send('OK');
});

module.exports = app;
