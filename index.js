// index.js
const express = require('express');
const dotenv = require('dotenv');
const routes = require('./routes');

dotenv.config();
const app = express();
const port = process.env.PORT || 3000;

// Middleware and routes
app.use(express.json());
app.use('/', routes);

// Only start the server if this file is run directly
if (require.main === module) {
  app.listen(port, () => {
    console.log(`Server running on port ${port}`);
  });
}

module.exports = app;
