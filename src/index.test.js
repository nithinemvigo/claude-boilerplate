const request = require('supertest');
const server = require('./index');

afterAll(() => server.close());

describe('Response headers', () => {
    it('sets Content-Type to application/json on all routes', async () => {
        const res = await request(server).get('/api/health');
        expect(res.headers['content-type']).toMatch(/application\/json/);
    });

    it('sets Access-Control-Allow-Origin to * on all routes', async () => {
        const res = await request(server).get('/api/health');
        expect(res.headers['access-control-allow-origin']).toBe('*');
    });
});

describe('GET /api/health', () => {
    it('returns 200 with success status', async () => {
        const res = await request(server).get('/api/health');
        expect(res.status).toBe(200);
        expect(res.body).toEqual({ status: 'success', message: 'API is running normally' });
    });
});

describe('POST /api/chat', () => {
    it('echoes the message from a valid JSON body', async () => {
        const res = await request(server)
            .post('/api/chat')
            .send({ message: 'hello API' });
        expect(res.status).toBe(200);
        expect(res.body).toEqual({
            status: 'success',
            reply: 'I received your message: "hello API"'
        });
    });

    it('handles missing message field with an empty string', async () => {
        const res = await request(server)
            .post('/api/chat')
            .send({});
        expect(res.status).toBe(200);
        expect(res.body).toEqual({
            status: 'success',
            reply: 'I received your message: ""'
        });
    });

    it('handles an empty body gracefully', async () => {
        const res = await request(server)
            .post('/api/chat')
            .set('Content-Type', 'application/json')
            .send('');
        expect(res.status).toBe(200);
        expect(res.body.reply).toBe('I received your message: ""');
    });

    it('returns 400 for malformed JSON', async () => {
        const res = await request(server)
            .post('/api/chat')
            .set('Content-Type', 'application/json')
            .send('{ not valid json }');
        expect(res.status).toBe(400);
        expect(res.body).toEqual({ error: 'Invalid JSON provided' });
    });
});

describe('GET /', () => {
    it('returns 200 with welcome message', async () => {
        const res = await request(server).get('/');
        expect(res.status).toBe(200);
        expect(res.body.message).toMatch(/Welcome to the Node\.js API/);
    });
});

describe('Unknown routes', () => {
    it('returns 404 for an unrecognised path', async () => {
        const res = await request(server).get('/does-not-exist');
        expect(res.status).toBe(404);
        expect(res.body).toEqual({ error: 'Endpoint not found' });
    });

    it('returns 404 for POST /api/health (wrong method)', async () => {
        const res = await request(server).post('/api/health').send({});
        expect(res.status).toBe(404);
        expect(res.body).toEqual({ error: 'Endpoint not found' });
    });

    it('returns 404 for GET /api/chat (wrong method)', async () => {
        const res = await request(server).get('/api/chat');
        expect(res.status).toBe(404);
        expect(res.body).toEqual({ error: 'Endpoint not found' });
    });
});
