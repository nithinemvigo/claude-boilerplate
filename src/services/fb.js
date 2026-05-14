const admin = require('firebase-admin');

const REQUIRED_VARS = [
  'FIREBASE_PROJECT_ID',
  'FIREBASE_PRIVATE_KEY_ID',
  'FIREBASE_PRIVATE_KEY',
  'FIREBASE_CLIENT_EMAIL',
  'FIREBASE_CLIENT_ID',
  'FIREBASE_DATABASE_URL',
];

for (const v of REQUIRED_VARS) {
  if (!process.env[v]) {
    throw new Error(`Missing required environment variable: ${v}`);
  }
}

if (!admin.apps.length) {
  admin.initializeApp({
    credential: admin.credential.cert({
      type: 'service_account',
      project_id: process.env.FIREBASE_PROJECT_ID,
      private_key_id: process.env.FIREBASE_PRIVATE_KEY_ID,
      private_key: process.env.FIREBASE_PRIVATE_KEY.replace(/\\n/g, '\n'),
      client_email: process.env.FIREBASE_CLIENT_EMAIL,
      client_id: process.env.FIREBASE_CLIENT_ID,
      auth_uri: 'https://accounts.google.com/o/oauth2/auth',
      token_uri: 'https://oauth2.googleapis.com/token',
    }),
    databaseURL: process.env.FIREBASE_DATABASE_URL,
  });
}

const db = admin.firestore();
const auth = admin.auth();

const getUserProfile = async (userId) => {
  if (!userId) {
    throw new Error('userId is required');
  }
  const doc = await db.collection('users').doc(userId).get();

  if (!doc.exists) {
    return null;
  }

  const { displayName, email, createdAt } = doc.data();
  return { displayName, email, createdAt };
};

const createUser = async (email, password, displayName) => {
  const userRecord = await auth.createUser({
    email,
    password,
    displayName,
  });

  await db.collection('users').doc(userRecord.uid).set({
    email,
    displayName,
    role: 'user',
    createdAt: new Date().toISOString(),
  });

  return userRecord;
};

const deleteUser = async (userId) => {
  // Authorization check must be done by the calling controller
  try {
    await auth.deleteUser(userId);

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

const searchUsers = async (field, value) => {
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

const updateUserSettings = async (userId, settings) => {
  const ALLOWED_SETTINGS = ['displayName', 'notificationsEnabled', 'theme'];
  const safeSettings = Object.fromEntries(
    Object.entries(settings).filter(([k]) => ALLOWED_SETTINGS.includes(k))
  );
  await db.collection('users').doc(userId).update(safeSettings);
};

const sendNotification = async (token, message) => {
  if (!token) {
    throw new Error('token is required');
  }
  try {
    await admin.messaging().send({
      token,
      notification: { title: message.title, body: message.body },
    });
  } catch (err) {
    console.error('Failed to send notification:', err);
    throw err;
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
