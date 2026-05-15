// Mock firebase-admin (not installed as devDependency)
jest.mock(
  'firebase-admin',
  () => ({
    get apps() {
      return [];
    },
    credential: { cert: jest.fn((o) => o) },
    initializeApp: jest.fn(),
    firestore: jest.fn(() => ({
      collection: jest.fn(() => ({ doc: jest.fn(() => ({ get: jest.fn(), set: jest.fn() })) })),
    })),
    auth: jest.fn(() => ({ createUser: jest.fn() })),
  }),
  { virtual: true }
);

// Provide required Firebase env vars
process.env.FIREBASE_PROJECT_ID = 'test-project';
process.env.FIREBASE_PRIVATE_KEY_ID = 'test-key-id';
process.env.FIREBASE_PRIVATE_KEY = 'test-private-key';
process.env.FIREBASE_CLIENT_EMAIL = 'test@test.iam.gserviceaccount.com';
process.env.FIREBASE_CLIENT_ID = 'test-client-id';
process.env.FIREBASE_DATABASE_URL = 'https://test.firebaseio.com';
process.env.ADMIN_API_KEY = 'test-admin-key';

const request = require('supertest');
const server = require('./index');

describe('API Endpoints', () => {
  describe('GET /api/health', () => {
    it('should return status success', async () => {
      const res = await request(server).get('/api/health');
      expect(res.statusCode).toBe(200);
      expect(res.body).toEqual({ status: 'success', message: 'API is running normally' });
    });
  });

  describe('POST /api/chat', () => {
    it('should receive a message and return a reply', async () => {
      const res = await request(server).post('/api/chat').send({ message: 'Hello Test' });
      expect(res.statusCode).toBe(200);
      expect(res.body.status).toBe('success');
      expect(res.body.reply).toBe('I received your message: "Hello Test"');
    });

    it('should handle invalid JSON', async () => {
      const res = await request(server)
        .post('/api/chat')
        .set('Content-Type', 'application/json')
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

  describe('POST /api/admin/users', () => {
    it('returns 401 without admin key', async () => {
      const res = await request(server)
        .post('/api/admin/users')
        .send({ email: 'a@b.com', password: 'pass', displayName: 'Admin' });
      expect(res.statusCode).toBe(401);
    });

    it('returns 400 with valid key but missing fields', async () => {
      const res = await request(server)
        .post('/api/admin/users')
        .set('x-admin-key', 'test-admin-key')
        .send({ email: 'a@b.com' });
      expect(res.statusCode).toBe(400);
    });
  });
});
