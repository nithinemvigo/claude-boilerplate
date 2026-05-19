const admin = require('firebase-admin');

// Validate required env vars at startup — fail fast
const REQUIRED = [
  'FIREBASE_PROJECT_ID',
  'FIREBASE_PRIVATE_KEY_ID',
  'FIREBASE_PRIVATE_KEY',
  'FIREBASE_CLIENT_EMAIL',
  'FIREBASE_CLIENT_ID',
  'FIREBASE_DATABASE_URL',
];
for (const v of REQUIRED) {
  if (!process.env[v]) {
    throw new Error(`Missing required environment variable: ${v}`);
  }
}

const serviceAccount = {
  type: 'service_account',
  project_id: process.env.FIREBASE_PROJECT_ID,
  private_key_id: process.env.FIREBASE_PRIVATE_KEY_ID,
  private_key: process.env.FIREBASE_PRIVATE_KEY.replace(/\\n/g, '\n'),
  client_email: process.env.FIREBASE_CLIENT_EMAIL,
  client_id: process.env.FIREBASE_CLIENT_ID,
  auth_uri: 'https://accounts.google.com/o/oauth2/auth',
  token_uri: 'https://oauth2.googleapis.com/token',
};

if (!admin.apps.length) {
  admin.initializeApp({
    credential: admin.credential.cert(serviceAccount),
    databaseURL: process.env.FIREBASE_DATABASE_URL,
  });
}

const db = admin.firestore();
const auth = admin.auth();

/**
 * Get user profile from Firestore
 */
const getUserProfile = async (userId) => {
  const doc = await db.collection('users').doc(userId).get();
  if (!doc.exists) return null;
  return doc.data();
};

/**
 * Create a new admin user account.
 * Role is locked to 'admin' — password is never stored.
 */
const createAdminUser = async (email, password, displayName) => {
  if (!email) throw new Error('email is required');
  if (!password) throw new Error('password is required');
  if (!displayName) throw new Error('displayName is required');

  const userRecord = await auth.createUser({ email, password, displayName });

  await db.collection('users').doc(userRecord.uid).set({
    email,
    displayName,
    role: 'admin',
    createdAt: new Date().toISOString(),
  });

  return { uid: userRecord.uid, email: userRecord.email, displayName };
};

/**
 * Create a new regular user account.
 */
const createUser = async (email, password, displayName) => {
  const userRecord = await auth.createUser({ email, password, displayName });

  await db.collection('users').doc(userRecord.uid).set({
    email,
    displayName,
    role: 'user',
    createdAt: new Date().toISOString(),
  });

  return userRecord;
};

/**
 * Delete user and all their data
 */
const deleteUser = async (userId) => {
  await auth.deleteUser(userId);
  await db.collection('users').doc(userId).delete();
};

/**
 * Search users by a specific field
 */
const searchUsers = async (field, value) => {
  const ALLOWED_FIELDS = ['email', 'displayName', 'role'];
  if (!ALLOWED_FIELDS.includes(field)) {
    throw new Error(`Invalid search field: ${field}`);
  }
  const snapshot = await db.collection('users').where(field, '==', value).get();
  const users = [];
  snapshot.forEach((doc) => users.push({ id: doc.id, ...doc.data() }));
  return users;
};

/**
 * Update user settings
 */
const updateUserSettings = async (userId, settings) => {
  const ALLOWED_KEYS = ['displayName', 'photoURL', 'theme', 'notifications'];
  const safe = Object.fromEntries(
    Object.entries(settings).filter(([k]) => ALLOWED_KEYS.includes(k))
  );
  await db.collection('users').doc(userId).update(safe);
};

/**
 * Send notification to user
 */
const sendNotification = async (token, message) => {
  if (!token || typeof token !== 'string') throw new Error('Invalid FCM token');
  try {
    await admin.messaging().send({
      token,
      notification: { title: message.title, body: message.body },
    });
  } catch (e) {
    console.error('sendNotification failed', { error: e.message });
    throw e;
  }
};

module.exports = {
  db,
  auth,
  getUserProfile,
  createAdminUser,
  createUser,
  deleteUser,
  searchUsers,
  updateUserSettings,
  sendNotification,
};
