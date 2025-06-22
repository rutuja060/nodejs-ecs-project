// index.js
const express = require('express');
const dotenv = require('dotenv');
const routes = require('./routes');

dotenv.config();
const app = express();
const port = process.env.PORT || 3000;

// Structured JSON logging middleware
app.use((req, res, next) => {
  const start = Date.now();
  
  // Log request
  console.log(JSON.stringify({
    timestamp: new Date().toISOString(),
    level: 'INFO',
    type: 'request',
    method: req.method,
    url: req.url,
    ip: req.ip,
    userAgent: req.get('User-Agent'),
    headers: {
      'content-type': req.get('Content-Type'),
      'accept': req.get('Accept')
    }
  }));

  // Override res.end to log response
  const originalEnd = res.end;
  res.end = function(chunk, encoding) {
    const duration = Date.now() - start;
    
    console.log(JSON.stringify({
      timestamp: new Date().toISOString(),
      level: 'INFO',
      type: 'response',
      method: req.method,
      url: req.url,
      statusCode: res.statusCode,
      duration: `${duration}ms`,
      contentLength: res.get('Content-Length') || 0
    }));
    
    originalEnd.call(this, chunk, encoding);
  };
  
  next();
});

// Middleware and routes
app.use(express.json());
app.use('/', routes);

// Global error handler
app.use((err, req, res, next) => {
  console.error(JSON.stringify({
    timestamp: new Date().toISOString(),
    level: 'ERROR',
    type: 'unhandled_error',
    method: req.method,
    url: req.url,
    error: {
      message: err.message,
      stack: err.stack,
      name: err.name
    }
  }));
  
  res.status(500).json({ 
    error: 'Internal server error',
    message: process.env.NODE_ENV === 'production' ? 'Something went wrong' : err.message
  });
});

// 404 handler
app.use('*', (req, res) => {
  console.log(JSON.stringify({
    timestamp: new Date().toISOString(),
    level: 'WARN',
    type: 'not_found',
    method: req.method,
    url: req.url,
    ip: req.ip
  }));
  
  res.status(404).json({ error: 'Route not found' });
});

// Graceful shutdown
process.on('SIGTERM', () => {
  console.log(JSON.stringify({
    timestamp: new Date().toISOString(),
    level: 'INFO',
    type: 'shutdown',
    message: 'SIGTERM received, shutting down gracefully'
  }));
  
  process.exit(0);
});

process.on('SIGINT', () => {
  console.log(JSON.stringify({
    timestamp: new Date().toISOString(),
    level: 'INFO',
    type: 'shutdown',
    message: 'SIGINT received, shutting down gracefully'
  }));
  
  process.exit(0);
});

// Only start the server if this file is run directly
if (require.main === module) {
  app.listen(port, () => {
    console.log(JSON.stringify({
      timestamp: new Date().toISOString(),
      level: 'INFO',
      type: 'startup',
      message: 'Server started successfully',
      port: port,
      environment: process.env.NODE_ENV || 'development',
      nodeVersion: process.version
    }));
  });
}

module.exports = app;
