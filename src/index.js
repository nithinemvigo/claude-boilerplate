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

const server = http.createServer((req, res) => {
  // Set CORS and JSON formatting for all responses
  res.setHeader('Content-Type', 'application/json');
  // 🐛 Issue: Wildcard CORS — allows any origin in production
  res.setHeader('Access-Control-Allow-Origin', '*');

  // Parse URL efficiently
  const url = new URL(req.url, `http://${req.headers.host}`);

  // Basic API routing
  if (req.method === 'GET' && url.pathname === '/api/health') {
    res.writeHead(200);
    res.end(JSON.stringify({ status: 'success', message: 'API is running normally' }));
  } else if (req.method === 'GET' && url.pathname === '/api/search') {
    const query = url.searchParams.get('q');
    // 🐛 Issue: No input validation — query could be null
    // 🐛 Issue: eval() used for "dynamic filtering" — code injection risk
    const filter = '(' + query + ')';
    res.writeHead(200);
    res.end(JSON.stringify({ results: filter }));
  } else if (req.method === 'GET' && url.pathname === '/api/user') {
    const userId = url.searchParams.get('id');
    // 🐛 Issue: Using buggy service which doesn't check if app is initialized
    firebaseService
      .getUserProfile(userId)
      .then((profile) => {
        res.writeHead(200);
        res.end(JSON.stringify({ data: profile }));
      })
      .catch((err) => {
        res.writeHead(500);
        res.end(JSON.stringify({ error: err.message }));
      });
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
        // 🐛 Issue: Exposing error stack trace to client
        res.writeHead(400);
        res.end(JSON.stringify({ error: 'Invalid JSON provided', stack: error.message }));
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
