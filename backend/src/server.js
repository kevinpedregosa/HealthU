import 'dotenv/config';
import cors from 'cors';
import crypto from 'node:crypto';
import express from 'express';
import { createRemoteJWKSet, jwtVerify, SignJWT } from 'jose';
import { v4 as uuidv4 } from 'uuid';

const app = express();
app.use(cors());
app.use(express.json());

const PORT = Number(process.env.PORT || 4000);
const SESSION_TTL_SECONDS = 60 * 60 * 8;
const AUTH_FLOW_TTL_MS = 10 * 60 * 1000;

const REQUIRED_ENV = [
  'APP_SESSION_SECRET',
  'UCI_ISSUER',
  'UCI_AUTHORIZATION_ENDPOINT',
  'UCI_TOKEN_ENDPOINT',
  'UCI_JWKS_URI',
  'UCI_CLIENT_ID',
  'UCI_REDIRECT_URI',
  'CALLBACK_SCHEME'
];
for (const key of REQUIRED_ENV) {
  if (!process.env[key]) {
    throw new Error(`Missing required env: ${key}`);
  }
}

const pendingAuthStates = new Map();
const usersBySub = new Map();

const jwks = createRemoteJWKSet(new URL(process.env.UCI_JWKS_URI));
const sessionSecret = new TextEncoder().encode(process.env.APP_SESSION_SECRET);

app.get('/health', (_req, res) => {
  res.json({ ok: true });
});

app.get('/auth/uci/start', (req, res) => {
  const state = randomURLSafe(32);
  const nonce = randomURLSafe(32);
  const codeVerifier = randomURLSafe(64);
  const codeChallenge = base64URLEncode(sha256(codeVerifier));

  pendingAuthStates.set(state, {
    nonce,
    codeVerifier,
    createdAt: Date.now()
  });

  const scopes = process.env.UCI_SCOPES || 'openid profile email';
  const emailHint = typeof req.query.email_hint === 'string' ? req.query.email_hint : undefined;

  const authorizationURL = new URL(process.env.UCI_AUTHORIZATION_ENDPOINT);
  authorizationURL.searchParams.set('client_id', process.env.UCI_CLIENT_ID);
  authorizationURL.searchParams.set('response_type', 'code');
  authorizationURL.searchParams.set('redirect_uri', process.env.UCI_REDIRECT_URI);
  authorizationURL.searchParams.set('scope', scopes);
  authorizationURL.searchParams.set('state', state);
  authorizationURL.searchParams.set('nonce', nonce);
  authorizationURL.searchParams.set('code_challenge', codeChallenge);
  authorizationURL.searchParams.set('code_challenge_method', 'S256');
  if (emailHint) {
    authorizationURL.searchParams.set('login_hint', emailHint);
  }

  res.json({
    authorizationUrl: authorizationURL.toString(),
    state,
    callbackScheme: process.env.CALLBACK_SCHEME
  });
});

app.post('/auth/uci/callback', async (req, res) => {
  try {
    const { code, state, redirectUri } = req.body || {};
    if (!code || !state) {
      return res.status(400).send('Missing code/state');
    }

    const pending = pendingAuthStates.get(state);
    pendingAuthStates.delete(state);

    if (!pending) {
      return res.status(400).send('Invalid state');
    }

    if (Date.now() - pending.createdAt > AUTH_FLOW_TTL_MS) {
      return res.status(400).send('Authentication request expired');
    }

    const tokenResponse = await exchangeCodeForToken({
      code,
      codeVerifier: pending.codeVerifier,
      redirectUri: redirectUri || process.env.UCI_REDIRECT_URI
    });

    if (!tokenResponse.id_token) {
      return res.status(400).send('Missing id_token from provider');
    }

    const claims = await verifyIDToken(tokenResponse.id_token, pending.nonce);
    const email = normalizeEmail(claims.email);
    if (!email.endsWith('@uci.edu')) {
      return res.status(403).send('Only @uci.edu accounts are allowed');
    }

    if (typeof claims.email_verified !== 'undefined' && claims.email_verified !== true) {
      return res.status(403).send('Email must be verified');
    }

    const isStudent = hasStudentAffiliation(claims);
    if ((process.env.REQUIRE_STUDENT_CLAIM || 'true') === 'true' && !isStudent) {
      return res.status(403).send('Student affiliation required');
    }

    if ((process.env.REQUIRE_MFA || 'true') === 'true' && !hasMFA(claims)) {
      return res.status(403).send('MFA/Duo confirmation missing in token claims');
    }

    const sub = String(claims.sub);
    let user = usersBySub.get(sub);
    if (!user) {
      user = { id: uuidv4(), sub, email, isStudent, createdAt: Date.now() };
      usersBySub.set(sub, user);
    } else {
      user.email = email;
      user.isStudent = isStudent;
      user.lastLoginAt = Date.now();
    }

    const now = Math.floor(Date.now() / 1000);
    const sessionToken = await new SignJWT({
      userId: user.id,
      email: user.email,
      isStudent: user.isStudent
    })
      .setProtectedHeader({ alg: 'HS256', typ: 'JWT' })
      .setIssuedAt(now)
      .setExpirationTime(now + SESSION_TTL_SECONDS)
      .setIssuer(process.env.APP_BASE_URL || `http://localhost:${PORT}`)
      .setAudience('healthu-mobile')
      .sign(sessionSecret);

    res.json({
      sessionToken,
      expiresIn: SESSION_TTL_SECONDS,
      email: user.email,
      isStudent: user.isStudent
    });
  } catch (error) {
    console.error(error);
    res.status(500).send('Authentication failed');
  }
});

app.get('/me', async (req, res) => {
  try {
    const authHeader = req.headers.authorization || '';
    const token = authHeader.startsWith('Bearer ') ? authHeader.slice(7) : '';
    if (!token) {
      return res.status(401).send('Missing bearer token');
    }

    const { payload } = await jwtVerify(token, sessionSecret, {
      issuer: process.env.APP_BASE_URL || `http://localhost:${PORT}`,
      audience: 'healthu-mobile'
    });

    res.json({
      userId: payload.userId,
      email: payload.email,
      isStudent: payload.isStudent
    });
  } catch {
    res.status(401).send('Invalid session token');
  }
});

app.listen(PORT, () => {
  console.log(`HealthU auth backend listening on port ${PORT}`);
});

async function exchangeCodeForToken({ code, codeVerifier, redirectUri }) {
  const form = new URLSearchParams();
  form.set('grant_type', 'authorization_code');
  form.set('code', code);
  form.set('redirect_uri', redirectUri);
  form.set('client_id', process.env.UCI_CLIENT_ID);
  form.set('code_verifier', codeVerifier);
  if (process.env.UCI_CLIENT_SECRET) {
    form.set('client_secret', process.env.UCI_CLIENT_SECRET);
  }

  const response = await fetch(process.env.UCI_TOKEN_ENDPOINT, {
    method: 'POST',
    headers: { 'Content-Type': 'application/x-www-form-urlencoded' },
    body: form.toString()
  });

  if (!response.ok) {
    const details = await response.text();
    throw new Error(`Token exchange failed: ${response.status} ${details}`);
  }

  return response.json();
}

async function verifyIDToken(idToken, expectedNonce) {
  const { payload } = await jwtVerify(idToken, jwks, {
    issuer: process.env.UCI_ISSUER,
    audience: process.env.UCI_CLIENT_ID
  });

  if (payload.nonce !== expectedNonce) {
    throw new Error('Nonce mismatch');
  }

  return payload;
}

function normalizeEmail(email) {
  return String(email || '').trim().toLowerCase();
}

function hasStudentAffiliation(claims) {
  const candidates = [
    claims.eduPersonAffiliation,
    claims.affiliation,
    claims.roles,
    claims.role
  ]
    .flatMap((value) => (Array.isArray(value) ? value : [value]))
    .filter(Boolean)
    .map((v) => String(v).toLowerCase());

  return candidates.some((v) => v.includes('student'));
}

function hasMFA(claims) {
  const amr = claims.amr;
  const values = (Array.isArray(amr) ? amr : [amr]).filter(Boolean).map((v) => String(v).toLowerCase());
  if (values.length === 0) {
    return false;
  }

  const acceptedIndicators = ['mfa', 'duo', 'otp', 'pwd+otp', 'sms', 'authenticator'];
  return values.some((value) => acceptedIndicators.some((indicator) => value.includes(indicator)));
}

function sha256(input) {
  return crypto.createHash('sha256').update(input).digest();
}

function randomURLSafe(bytes) {
  return base64URLEncode(crypto.randomBytes(bytes));
}

function base64URLEncode(buffer) {
  return Buffer.from(buffer)
    .toString('base64')
    .replace(/\+/g, '-')
    .replace(/\//g, '_')
    .replace(/=+$/g, '');
}
