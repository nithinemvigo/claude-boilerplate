const adminAuth = require('../middleware/adminAuth');
const { createAdminUser } = require('../services/fb');

/**
 * POST /api/admin/users
 * Creates an admin user. Requires x-admin-key header.
 * Private/internal — not exposed publicly.
 */
const handleAdminCreateUser = async (req, res) => {
  const { email, password, displayName } = req.body || {};

  if (!email || !password || !displayName) {
    res.writeHead(400);
    return res.end(
      JSON.stringify({ status: 'error', message: 'email, password, and displayName are required' })
    );
  }

  try {
    const user = await createAdminUser(email, password, displayName);
    res.writeHead(201);
    res.end(
      JSON.stringify({
        status: 'success',
        data: { uid: user.uid, email: user.email, displayName: user.displayName },
      })
    );
  } catch (err) {
    if (err.code === 'auth/email-already-exists') {
      res.writeHead(409);
      return res.end(JSON.stringify({ status: 'error', message: 'Email already in use' }));
    }
    console.error('createAdminUser failed', { error: err.message });
    res.writeHead(500);
    res.end(JSON.stringify({ status: 'error', message: 'Failed to create admin user' }));
  }
};

/**
 * Route matcher — called from index.js
 */
const handleAdminRoutes = (req, res, url) => {
  if (req.method === 'POST' && url.pathname === '/api/admin/users') {
    adminAuth(req, res, () => handleAdminCreateUser(req, res));
    return true; // route matched — response handled by auth or handler
  }
  return false; // no route matched
};

module.exports = { handleAdminRoutes, handleAdminCreateUser };
