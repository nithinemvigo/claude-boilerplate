/**
 * Admin API key middleware for internal/private endpoints.
 * Validates the x-admin-key header against ADMIN_API_KEY env var.
 */
const adminAuth = (req, res, next) => {
  const providedKey = req.headers['x-admin-key'];
  const expectedKey = process.env.ADMIN_API_KEY;

  if (!expectedKey || !providedKey || providedKey !== expectedKey) {
    res.writeHead(401);
    res.end(JSON.stringify({ status: 'error', message: 'Unauthorized' }));
    return;
  }

  next();
};

module.exports = adminAuth;
