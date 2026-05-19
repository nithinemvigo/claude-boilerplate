const fb = require('../services/fb');

jest.mock('../middleware/adminAuth', () => jest.fn((req, res, next) => next()));
jest.mock('../services/fb', () => ({
  createAdminUser: jest.fn(),
}));

const { handleAdminCreateUser } = require('./admin');

const mockReq = (body = {}, headers = {}) => ({ body, headers });
const mockRes = () => {
  const res = {};
  res.writeHead = jest.fn().mockReturnValue(res);
  res.end = jest.fn().mockReturnValue(res);
  return res;
};

describe('POST /api/admin/users', () => {
  beforeEach(() => jest.clearAllMocks());

  it('returns 201 and uid on success', async () => {
    fb.createAdminUser.mockResolvedValue({ uid: 'uid-1', email: 'a@b.com', displayName: 'Admin' });
    const res = mockRes();
    await handleAdminCreateUser(
      mockReq({ email: 'a@b.com', password: 'Secure1!', displayName: 'Admin' }),
      res
    );
    expect(res.writeHead).toHaveBeenCalledWith(201);
    const body = JSON.parse(res.end.mock.calls[0][0]);
    expect(body.status).toBe('success');
    expect(body.data.uid).toBe('uid-1');
    expect(body.data).not.toHaveProperty('password');
  });

  it('returns 400 when email is missing', async () => {
    const res = mockRes();
    await handleAdminCreateUser(mockReq({ password: 'Secure1!', displayName: 'Admin' }), res);
    expect(res.writeHead).toHaveBeenCalledWith(400);
  });

  it('returns 400 when password is missing', async () => {
    const res = mockRes();
    await handleAdminCreateUser(mockReq({ email: 'a@b.com', displayName: 'Admin' }), res);
    expect(res.writeHead).toHaveBeenCalledWith(400);
  });

  it('returns 400 when displayName is missing', async () => {
    const res = mockRes();
    await handleAdminCreateUser(mockReq({ email: 'a@b.com', password: 'Secure1!' }), res);
    expect(res.writeHead).toHaveBeenCalledWith(400);
  });

  it('returns 409 when Firebase says email already exists', async () => {
    fb.createAdminUser.mockRejectedValue({ code: 'auth/email-already-exists' });
    const res = mockRes();
    await handleAdminCreateUser(
      mockReq({ email: 'dup@b.com', password: 'Secure1!', displayName: 'Admin' }),
      res
    );
    expect(res.writeHead).toHaveBeenCalledWith(409);
  });

  it('returns 500 on unexpected Firebase error', async () => {
    fb.createAdminUser.mockRejectedValue(new Error('firebase down'));
    const res = mockRes();
    await handleAdminCreateUser(
      mockReq({ email: 'a@b.com', password: 'Secure1!', displayName: 'Admin' }),
      res
    );
    expect(res.writeHead).toHaveBeenCalledWith(500);
  });
});
