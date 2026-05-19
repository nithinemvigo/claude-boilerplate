const adminAuth = require('./adminAuth');

const mockRes = () => {
  const res = {};
  res.writeHead = jest.fn().mockReturnValue(res);
  res.end = jest.fn().mockReturnValue(res);
  return res;
};

describe('adminAuth middleware', () => {
  const ORIG_ENV = process.env;

  beforeEach(() => {
    process.env = { ...ORIG_ENV, ADMIN_API_KEY: 'test-secret-key' };
  });

  afterEach(() => {
    process.env = ORIG_ENV;
  });

  it('calls next() when x-admin-key matches ADMIN_API_KEY', () => {
    const req = { headers: { 'x-admin-key': 'test-secret-key' } };
    const res = mockRes();
    const next = jest.fn();
    adminAuth(req, res, next);
    expect(next).toHaveBeenCalledTimes(1);
    expect(res.writeHead).not.toHaveBeenCalled();
  });

  it('returns 401 when x-admin-key is missing', () => {
    const req = { headers: {} };
    const res = mockRes();
    const next = jest.fn();
    adminAuth(req, res, next);
    expect(res.writeHead).toHaveBeenCalledWith(401);
    expect(res.end).toHaveBeenCalledWith(
      JSON.stringify({ status: 'error', message: 'Unauthorized' })
    );
    expect(next).not.toHaveBeenCalled();
  });

  it('returns 401 when x-admin-key is wrong', () => {
    const req = { headers: { 'x-admin-key': 'wrong-key' } };
    const res = mockRes();
    const next = jest.fn();
    adminAuth(req, res, next);
    expect(res.writeHead).toHaveBeenCalledWith(401);
    expect(next).not.toHaveBeenCalled();
  });

  it('returns 401 when ADMIN_API_KEY env var is not set', () => {
    delete process.env.ADMIN_API_KEY;
    const req = { headers: { 'x-admin-key': 'any-key' } };
    const res = mockRes();
    const next = jest.fn();
    adminAuth(req, res, next);
    expect(res.writeHead).toHaveBeenCalledWith(401);
    expect(next).not.toHaveBeenCalled();
  });
});
