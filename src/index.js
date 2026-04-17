const http = require('http');

const PORT = process.env.PORT || 3000;

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

    } else if (req.method === 'POST' && url.pathname === '/api/chat') {
        let body = '';

        // Collect incoming data
        req.on('data', chunk => {
            body += chunk.toString();
        });

        // Process the request when finished
        req.on('end', () => {
            try {
                const data = body ? JSON.parse(body) : {};

                // You can add your Claude/AI logic here later
                res.writeHead(200);
                res.end(JSON.stringify({
                    status: 'success',
                    reply: `I received your message: "${data.message || ''}"`
                }));
            } catch (error) {
                res.writeHead(400);
                res.end(JSON.stringify({ error: 'Invalid JSON provided' }));
            }
        });

    } else if (url.pathname === '/') {
        res.writeHead(200);
        res.end(JSON.stringify({ message: 'Welcome to the Node.js API. Visit /api/health to check status.' }));
    } else {
        res.writeHead(404);
        res.end(JSON.stringify({ error: 'Endpoint not found' }));
    }
});

server.listen(PORT, () => {
    console.log(`Server is running at http://localhost:${PORT}`);
    console.log(`\nYou can test it using these commands:`);
    console.log(`1. Health check:  curl http://localhost:${PORT}/api/health`);
    console.log(`2. Chat endpoint: curl -X POST -H "Content-Type: application/json" -d '{"message":"hello API"}' http://localhost:${PORT}/api/chat`);
});
