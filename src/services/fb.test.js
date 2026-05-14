const fs = require('fs');
const path = require('path');

const SOURCE_PATH = path.join(__dirname, 'fb.js');

// Virtual mock — firebase-admin is not in devDependencies
jest.mock(
  'firebase-admin',
  () => {
    const mockCert = jest.fn((obj) => obj);
    const mockInitializeApp = jest.fn();
    const mockFirestore = jest.fn(() => ({}));
    const mockAuth = jest.fn(() => ({}));
    return {
      get apps() {
        return [];
      },
      credential: { cert: mockCert },
      initializeApp: mockInitializeApp,
      firestore: mockFirestore,
      auth: mockAuth,
    };
  },
  { virtual: true }
);

describe('fb (Firebase service)', () => {
  const REQUIRED_ENV_VARS = [
    'FIREBASE_PROJECT_ID',
    'FIREBASE_PRIVATE_KEY_ID',
    'FIREBASE_PRIVATE_KEY',
    'FIREBASE_CLIENT_EMAIL',
    'FIREBASE_CLIENT_ID',
    'FIREBASE_DATABASE_URL',
  ];

  beforeEach(() => {
    jest.resetModules();
    REQUIRED_ENV_VARS.forEach((v) => {
      process.env[v] = `test-${v}`;
    });
  });

  afterEach(() => {
    REQUIRED_ENV_VARS.forEach((v) => delete process.env[v]);
  });

  describe('source code — no hardcoded credentials', () => {
    let source;

    beforeAll(() => {
      source = fs.readFileSync(SOURCE_PATH, 'utf8');
    });

    it('should not contain hardcoded production project ID', () => {
      expect(source).not.toMatch(/my-prod-app-12345/);
    });

    it('should not contain hardcoded private key material', () => {
      expect(source).not.toMatch(/BEGIN RSA PRIVATE KEY/);
    });

    it('should not contain hardcoded client email', () => {
      expect(source).not.toMatch(/firebase-adminsdk@my-prod-app/);
    });

    it('should not contain hardcoded client ID', () => {
      expect(source).not.toMatch(/'123456789'/);
    });

    it('should not contain hardcoded databaseURL', () => {
      expect(source).not.toMatch(/https:\/\/my-prod-app-12345\.firebaseio\.com/);
    });
  });

  describe('initialization — reads from environment variables', () => {
    it('should pass project_id from env to credential.cert', () => {
      const fbAdmin = require('firebase-admin');
      require('./fb');
      const certArg = fbAdmin.credential.cert.mock.calls[0][0];
      expect(certArg.project_id).toBe('test-FIREBASE_PROJECT_ID');
    });

    it('should pass client_email from env to credential.cert', () => {
      const fbAdmin = require('firebase-admin');
      require('./fb');
      const certArg = fbAdmin.credential.cert.mock.calls[0][0];
      expect(certArg.client_email).toBe('test-FIREBASE_CLIENT_EMAIL');
    });

    it('should throw when required env vars are missing', () => {
      REQUIRED_ENV_VARS.forEach((v) => delete process.env[v]);
      expect(() => require('./fb')).toThrow(/Missing required environment variable/);
    });
  });
});
