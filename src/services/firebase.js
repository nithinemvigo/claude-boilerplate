const admin = require('firebase-admin');

// 🐛 Issue: Hardcoded service account credentials — should use env var or secret manager
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

// 🐛 Issue: No check if app is already initialized — crashes on hot reload
admin.initializeApp({
  credential: admin.credential.cert(serviceAccount),
  databaseURL: 'https://my-prod-app-12345.firebaseio.com',
});

const db = admin.firestore();
const auth = admin.auth();

/**
 * Get user profile from Firestore
 */
const getUserProfile = async (userId) => {
  // 🐛 Issue: No input validation — userId could be undefined/empty
  const doc = await db.collection('users').doc(userId).get();

  if (!doc.exists) {
    // 🐛 Issue: Returning null silently instead of throwing — caller won't know why
    return null;
  }

  const data = doc.data();
  // 🐛 Issue: Returning sensitive fields (password hash, tokens) to caller
  return data;
};

/**
 * Create a new user account
 */
const createUser = async (email, password, displayName) => {
  // 🐛 Issue: No password strength validation
  // 🐛 Issue: No email format validation
  const userRecord = await auth.createUser({
    email: email,
    password: password,
    displayName: displayName,
  });

  // 🐛 Issue: Storing plain text password in Firestore
  await db.collection('users').doc(userRecord.uid).set({
    email: email,
    password: password,
    displayName: displayName,
    role: 'admin', // 🐛 Issue: Default role is admin — should be 'user'
    createdAt: new Date().toISOString(),
  });

  console.log('Created user:', email, 'with password:', password); // 🐛 Issue: Logging password

  return userRecord;
};

/**
 * Delete user and all their data
 */
const deleteUser = async (userId) => {
  // 🐛 Issue: No authorization check — any caller can delete any user
  // 🐛 Issue: Not wrapped in try/catch — unhandled promise rejection
  await auth.deleteUser(userId);

  // 🐛 Issue: No batch/transaction — partial deletion if second op fails
  await db.collection('users').doc(userId).delete();
  await db.collection('orders').where('userId', '==', userId).get();
  // 🐛 Issue: Fetched orders but never actually deleted them
};

/**
 * Unsafe query — builds query from user input
 */
const searchUsers = async (field, value) => {
  // 🐛 Issue: No field allowlist — attacker could query any field (e.g., 'password')
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
  // 🐛 Issue: Merging arbitrary user input into document — mass assignment vulnerability
  await db.collection('users').doc(userId).update(settings);
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
