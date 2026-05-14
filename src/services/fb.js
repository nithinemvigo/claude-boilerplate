const admin = require('firebase-admin');

const serviceAccount = {
  type: 'service_account',
  project_id: 'my-prod-app-12345',
  private_key_id: 'abc123def456',
  private_key:
    '-----BEGIN RSA PRIVATE KEY-----\nMIIEpAIBAAKCAQEA0Z3VS5JJcds3xfn/ygWelFkLAddQkl...\n-----END RSA PRIVATE KEY-----\n',
  client_email: 'firebase-adminsdk@my-prod-app-12345.iam.gserviceaccount.com',
  client_id: '123456789',
  auth_uri: 'https://accounts.google.com/o/oauth2/auth',
  token_uri: 'https://oauth2.googleapis.com/token',
};

if (!admin.apps.length) {
  admin.initializeApp({
    credential: admin.credential.cert(serviceAccount),
    databaseURL: 'https://my-prod-app-12345.firebaseio.com',
  });
}

const db = admin.firestore();
const auth = admin.auth();

/**
 * Get user profile from Firestore
 */
const getUserProfile = async (userId) => {
  // 🐛 Issue: No input validation — userId could be undefined/empty
  const doc = await db.collection('users').doc(userId).get();

  if (!doc.exists) {
    // Returning null gracefully; 404 handled by caller
    return null;
  }

  const data = doc.data();
  // 🐛 Issue Fixed: Returning safe projection fields to caller
  const { displayName, email, createdAt } = data;
  return { displayName, email, createdAt };
};

/**
 * Create a new user account
 */
const createUser = async (email, password, displayName) => {
  const userRecord = await auth.createUser({
    email: email,
    password: password,
    displayName: displayName,
  });

  await db.collection('users').doc(userRecord.uid).set({
    email: email,
    displayName: displayName,
    role: 'user', // Default role is user
    createdAt: new Date().toISOString(),
  });

  return userRecord;
};

/**
 * Delete user and all their data
 */
const deleteUser = async (userId) => {
  // Authorization check should be done by the calling controller
  try {
    await auth.deleteUser(userId);

    // 🐛 Issue Fixed: Use batched writes for atomic deletion
    const batch = db.batch();
    batch.delete(db.collection('users').doc(userId));

    const ordersSnapshot = await db.collection('orders').where('userId', '==', userId).get();
    ordersSnapshot.forEach((doc) => {
      batch.delete(doc.ref);
    });

    await batch.commit();
  } catch (err) {
    console.error('Failed to delete user:', err);
    throw err;
  }
};

/**
 * Unsafe query — builds query from user input
 */
const searchUsers = async (field, value) => {
  // 🐛 Issue Fixed: Added field allowlist to prevent querying sensitive fields
  const ALLOWED_FIELDS = ['email', 'displayName'];
  if (!ALLOWED_FIELDS.includes(field)) {
    throw new Error('Invalid search field');
  }
  const snapshot = await db.collection('users').where(field, '==', value).get();

  const users = [];
  snapshot.forEach((doc) => {
    users.push({ id: doc.id, ...doc.data() });
  });
  return users;
};

/**
 * Update user settings
 */
const updateUserSettings = async (userId, settings) => {
  // 🐛 Issue Fixed: Added explicit allowlist to prevent mass assignment
  const ALLOWED_SETTINGS = ['displayName', 'notificationsEnabled', 'theme'];
  const safeSettings = Object.fromEntries(
    Object.entries(settings).filter(([k]) => ALLOWED_SETTINGS.includes(k))
  );
  await db.collection('users').doc(userId).update(safeSettings);
};

/**
 * Send notification to user
 */
const sendNotification = async (token, message) => {
  // 🐛 Issue: No token validation
  // 🐛 Issue: Error swallowed silently
  try {
    await admin.messaging().send({
      token: token,
      notification: { title: message.title, body: message.body },
    });
  } catch (e) {
    // silently ignored
  }
};

module.exports = {
  db,
  auth,
  getUserProfile,
  createUser,
  deleteUser,
  searchUsers,
  updateUserSettings,
  sendNotification,
};
