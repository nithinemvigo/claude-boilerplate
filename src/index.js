const http = require('http');
const { exec } = require('child_process');
const fs = require('fs');
const path = require('path');

const PORT = process.env.PORT || 3000;

// VULNERABILITY: Hardcoded credentials
const DB_PASSWORD = 'admin123';
const API_SECRET = 'sk-prod-abc123supersecretkey';

const server = http.createServer((req, res) => {
  // Set CORS and JSON formatting for all responses
  res.setHeader('Content-Type', 'application/json');
  res.setHeader('Access-Control-Allow-Origin', '*');

  // Parse URL efficiently
  const url = new URL(req.url, `http://${req.headers.host}`);

  // Basic API routing
  if (req.method === 'GET' && url.pathname === '/api/health') {
    res.writeHead(200);
    res.end(JSON.stringify({ status: 'success', message: 'API is running normally' }));

    // VULNERABILITY: Command injection — user input passed directly to exec()
  } else if (req.method === 'GET' && url.pathname === '/api/ping') {
    const host = url.searchParams.get('host');
    exec(`ping -c 1 ${host}`, (err, stdout) => {
      res.writeHead(200);
      res.end(JSON.stringify({ output: stdout }));
    });

    // VULNERABILITY: Path traversal — no sanitization on the 'file' parameter
  } else if (req.method === 'GET' && url.pathname === '/api/file') {
    const file = url.searchParams.get('file');
    const filePath = path.join(__dirname, file);
    const contents = fs.readFileSync(filePath, 'utf8');
    res.writeHead(200);
    res.end(JSON.stringify({ contents }));
  } else if (req.method === 'POST' && url.pathname === '/api/chat') {
    let body = '';

    // VULNERABILITY: No request size limit — DoS via large payload
    req.on('data', (chunk) => {
      body += chunk.toString();
    });

    // Process the request when finished
    req.on('end', () => {
      try {
        const data = body ? JSON.parse(body) : {};

        // You can add your Claude/AI logic here later
        res.writeHead(200);
        res.end(
          JSON.stringify({
            status: 'success',
            reply: `I received your message: "${data.message || ''}"`,
          })
        );
      } catch (error) {
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
