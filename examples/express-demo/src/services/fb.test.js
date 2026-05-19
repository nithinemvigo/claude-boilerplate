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

// Mock must be declared at module scope — factory cannot reference outer variables
jest.mock(
  'firebase-admin',
  () => ({
    get apps() {
      return [];
    },
    credential: { cert: jest.fn((obj) => obj) },
    initializeApp: jest.fn(),
    firestore: jest.fn(() => ({
      collection: jest.fn(() => ({
        doc: jest.fn(() => ({ set: jest.fn().mockResolvedValue({}) })),
      })),
    })),
    auth: jest.fn(() => ({
      createUser: jest.fn().mockResolvedValue({ uid: 'uid-123', email: 'admin@test.com' }),
    })),
  }),
  { virtual: true }
);

describe('createAdminUser()', () => {
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

  it('should create a user with role locked to admin', async () => {
    const { createAdminUser } = require('./fb');
    const result = await createAdminUser('admin@test.com', 'SecurePass1!', 'Admin User');
    expect(result.uid).toBe('uid-123');
    expect(result.email).toBe('admin@test.com');
  });

  it('should NOT store password and role must be locked to admin (static)', () => {
    // Static analysis: verify the createAdminUser function body
    // does not pass password to .set() and always uses role: 'admin'
    const src = require('fs').readFileSync(require('path').join(__dirname, 'fb.js'), 'utf8');
    const fnStart = src.indexOf('const createAdminUser');
    const fnEnd = src.indexOf('\nmodule.exports');
    const fnBody = src.slice(fnStart, fnEnd);
    // password must not appear in .set() call
    expect(fnBody).not.toMatch(/set\(\s*\{[^}]*password/);
    // role must be hardcoded to 'admin'
    expect(fnBody).toMatch(/role:\s*'admin'/);
  });

  it('should throw if email is missing', async () => {
    const { createAdminUser } = require('./fb');
    await expect(createAdminUser('', 'pass', 'Name')).rejects.toThrow('email');
  });

  it('should throw if password is missing', async () => {
    const { createAdminUser } = require('./fb');
    await expect(createAdminUser('a@b.com', '', 'Name')).rejects.toThrow('password');
  });
});
