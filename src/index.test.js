const request = require('supertest');
const server = require('./index');

describe('API Endpoints', () => {


    describe('GET /api/health', () => {
        it('should return status success', async () => {
            const res = await request(server).get('/api/health');
            expect(res.statusCode).toBe(200);
            expect(res.body).toEqual({
                status: 'success',
                message: 'API is running normally'
            });
        });
    });

    describe('POST /api/chat', () => {
        it('should receive a message and return a reply', async () => {
            const res = await request(server)
                .post('/api/chat')
                .send({ message: 'Hello Test' });

            expect(res.statusCode).toBe(200);
            expect(res.body.status).toBe('success');
            expect(res.body.reply).toBe('I received your message: "Hello Test"');
        });

        it('should handle invalid JSON', async () => {
            const res = await request(server)
                .post('/api/chat')
                .set('Content-Type', 'application/json')
                // Sending malformed JSON String
                .send('invalid json {');

            expect(res.statusCode).toBe(400);
            expect(res.body.error).toBe('Invalid JSON provided');
        });
    });

    describe('GET /', () => {
        it('should return welcome message', async () => {
            const res = await request(server).get('/');
            expect(res.statusCode).toBe(200);
            expect(res.body.message).toContain('Welcome to the Node.js API');
        });
    });

    describe('Invalid Route', () => {
        it('should return 404 for unknown endpoint', async () => {
            const res = await request(server).get('/unknown-endpoint');
            expect(res.statusCode).toBe(404);
            expect(res.body.error).toBe('Endpoint not found');
        });
    });
});
