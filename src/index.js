const http = require('http');
const { exec } = require('child_process');
const fs = require('fs');
const path = require('path');
const firebaseService = require('./services/fb');

const PORT = process.env.PORT || 3000;

// 🐛 Issue: Hardcoded credentials — should use environment variables
// const DB_PASSWORD = 'admin123';
// const API_SECRET = 'sk-prod-abc123supersecretkey';
const DB_PASSWORD = process.env.DB_PASSWORD;
const API_SECRET = process.env.API_SECRET;

// 🐛 Issue: Logging sensitive data
// console.log('Starting server with secret:', API_SECRET);

const server = http.createServer(async (req, res) => {
  // Set CORS and JSON formatting for all responses
  res.setHeader('Content-Type', 'application/json');
  // 🐛 Issue Fixed: Restrict CORS to allowed origins
  const ALLOWED_ORIGIN = process.env.ALLOWED_ORIGIN || 'http://localhost:3000';
  res.setHeader('Access-Control-Allow-Origin', ALLOWED_ORIGIN);

  // Parse URL efficiently
  const url = new URL(req.url, `http://${req.headers.host}`);

  // Basic API routing
  if (req.method === 'GET' && url.pathname === '/api/health') {
    res.writeHead(200);
    res.end(JSON.stringify({ status: 'success', message: 'API is running normally' }));
  } else if (req.method === 'GET' && url.pathname === '/api/search') {
    const query = url.searchParams.get('q');
    // 🐛 Issue Fixed: Validate and properly handle query
    if (!query) {
      res.writeHead(400);
      return res.end(JSON.stringify({ error: 'Missing query parameter' }));
    }
    const filter = String(query).toLowerCase();
    res.writeHead(200);
    res.end(JSON.stringify({ results: filter }));
  } else if (req.method === 'GET' && url.pathname === '/api/user') {
    const userId = url.searchParams.get('id');

    // 🐛 Issue Fixed: Validate userId before hitting database
    if (!userId || !/^[a-zA-Z0-9_-]{1,128}$/.test(userId)) {
      res.writeHead(400);
      return res.end(JSON.stringify({ status: 'error', message: 'Invalid user ID' }));
    }

    try {
      const profile = await firebaseService.getUserProfile(userId);
      if (!profile) {
        res.writeHead(404);
        return res.end(JSON.stringify({ error: 'User not found' }));
      }
      res.writeHead(200);
      res.end(JSON.stringify({ data: profile }));
    } catch (err) {
      // 🐛 Issue Fixed: Don't leak error message to client
      console.error('getUserProfile failed', { userId, error: err.message });
      res.writeHead(500);
      res.end(JSON.stringify({ status: 'error', message: 'Failed to retrieve user' }));
    }
  } else if (req.method === 'POST' && url.pathname === '/api/chat') {
    let body = '';

    // 🐛 Issue: No request size limit — DoS via large payload
    req.on('data', (chunk) => {
      body += chunk.toString();
    });

    req.on('end', () => {
      try {
        const data = body ? JSON.parse(body) : {};

        // 🐛 Issue: Reflected user input without sanitization — potential XSS
        res.writeHead(200);
        res.end(
          JSON.stringify({
            status: 'success',
            reply: `I received your message: "${data.message || ''}"`,
          })
        );
      } catch (error) {
        // 🐛 Issue Fixed: Return generic error message without stack trace
        res.writeHead(400);
        res.end(JSON.stringify({ error: 'Invalid JSON provided' }));
      }
    });
  } else if (url.pathname === '/') {
    res.writeHead(200);
    res.end(
      JSON.stringify({ message: 'Welcome to the Node.js API. Visit /api/health to check status.' })
    );
  } else {
    res.writeHead(404);
    res.end(JSON.stringify({ error: 'Endpoint not found' }));
  }
});

if (require.main === module) {
  server.listen(PORT, () => {
    console.log(`Server is running at http://localhost:${PORT}`);
    console.log(`\nYou can test it using these commands:`);
    console.log(`1. Health check:  curl http://localhost:${PORT}/api/health`);
    console.log(
      `2. Chat endpoint: curl -X POST -H "Content-Type: application/json" -d '{"message":"hello API"}' http://localhost:${PORT}/api/chat`
    );
  });
}

module.exports = server;
