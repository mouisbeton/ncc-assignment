const express = require('express');
const cors = require('cors');

const app = express();

// Middleware
app.use(cors());
app.use(express.json());
app.use(express.urlencoded({ extended: true }));

// Health check endpoint
app.get('/health', (req, res) => {
  res.status(200).json({
    status: 'OK',
    timestamp: new Date().toISOString(),
    uptime: process.uptime(),
    message: 'Service is running and healthy'
  });
});

// Basic info endpoint
app.get('/info', (req, res) => {
  res.status(200).json({
    service: 'Health Check Service',
    message: 'Made by Uwais Achmad (5025241103)',
    version: '1.0.0',
    timestamp: new Date().toISOString()
  });
});

// Root endpoint
app.get('/', (req, res) => {
  res.status(200).json({
    message: 'Welcome to Health Check Service',
    endpoints: {
      health: '/health',
      info: '/info'
    }
  });
});

// Error handling middleware
app.use((err, req, res, next) => {
  console.error(err.stack);
  res.status(500).json({
    status: 'ERROR',
    message: 'Internal server error'
  });
});

module.exports = app;
