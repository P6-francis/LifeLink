let cachedAccessToken = null;

const jsonHeaders = {
  'Content-Type': 'application/json; charset=utf-8',
  'Access-Control-Allow-Origin': '*',
  'Access-Control-Allow-Headers': 'Authorization, Content-Type',
  'Access-Control-Allow-Methods': 'POST, OPTIONS',
};

function response(status, body) {
  return new Response(JSON.stringify(body), {status, headers: jsonHeaders});
}

function base64Url(value) {
  const bytes = value instanceof Uint8Array ? value : new TextEncoder().encode(value);
  let binary = '';
  for (const byte of bytes) binary += String.fromCharCode(byte);
  return btoa(binary).replaceAll('+', '-').replaceAll('/', '_').replace(/=+$/, '');
}

function pemToBytes(pem) {
  const binary = atob(pem.replace(/-----(BEGIN|END) PRIVATE KEY-----|\s/g, ''));
  return Uint8Array.from(binary, (character) => character.charCodeAt(0));
}

async function googleAccessToken(serviceAccountJson) {
  if (cachedAccessToken && cachedAccessToken.expiresAt > Date.now() + 60000) {
    return cachedAccessToken.value;
  }

  const serviceAccount = JSON.parse(serviceAccountJson);
  const now = Math.floor(Date.now() / 1000);
  const unsignedJwt = `${base64Url(JSON.stringify({alg: 'RS256', typ: 'JWT'}))}.${base64Url(JSON.stringify({
    iss: serviceAccount.client_email,
    scope: 'https://www.googleapis.com/auth/firebase.messaging https://www.googleapis.com/auth/datastore',
    aud: 'https://oauth2.googleapis.com/token',
    iat: now,
    exp: now + 3600,
  }))}`;
  const key = await crypto.subtle.importKey(
    'pkcs8',
    pemToBytes(serviceAccount.private_key),
    {name: 'RSASSA-PKCS1-v1_5', hash: 'SHA-256'},
    false,
    ['sign'],
  );
  const signature = await crypto.subtle.sign(
    {name: 'RSASSA-PKCS1-v1_5'},
    key,
    new TextEncoder().encode(unsignedJwt),
  );
  const assertion = `${unsignedJwt}.${base64Url(new Uint8Array(signature))}`;
  const tokenResponse = await fetch('https://oauth2.googleapis.com/token', {
    method: 'POST',
    headers: {'Content-Type': 'application/x-www-form-urlencoded'},
    body: new URLSearchParams({
      grant_type: 'urn:ietf:params:oauth:grant-type:jwt-bearer',
      assertion,
    }),
  });
  const token = await tokenResponse.json();
  if (!tokenResponse.ok || !token.access_token) throw new Error('Google authorization failed.');
  cachedAccessToken = {
    value: token.access_token,
    expiresAt: Date.now() + ((token.expires_in ?? 3600) * 1000),
  };
  return cachedAccessToken.value;
}

async function firebaseDocument(path, projectId, accessToken) {
  const encodedPath = path.split('/').map(encodeURIComponent).join('/');
  const request = await fetch(
    `https://firestore.googleapis.com/v1/projects/${encodeURIComponent(projectId)}/databases/(default)/documents/${encodedPath}`,
    {headers: {Authorization: `Bearer ${accessToken}`}},
  );
  return request.ok ? request.json() : null;
}

async function createNotification(projectId, accessToken, recipientId, fields) {
  const path = `users/${recipientId}/notifications`;
  const encodedPath = path.split('/').map(encodeURIComponent).join('/');
  const request = await fetch(
    `https://firestore.googleapis.com/v1/projects/${encodeURIComponent(projectId)}/databases/(default)/documents/${encodedPath}?documentId=${encodeURIComponent(crypto.randomUUID())}`,
    {
      method: 'POST',
      headers: {
        Authorization: `Bearer ${accessToken}`,
        'Content-Type': 'application/json',
      },
      body: JSON.stringify({fields}),
    },
  );
  if (!request.ok) throw new Error('Could not save notification history.');
}

function stringField(document, field) {
  return document?.fields?.[field]?.stringValue ?? '';
}

function participants(document) {
  return (document?.fields?.participants?.arrayValue?.values ?? [])
    .map((value) => value.stringValue ?? '')
    .filter(Boolean);
}

async function authenticatedUser(request, apiKey) {
  const authorization = request.headers.get('Authorization') ?? '';
  const match = authorization.match(/^Bearer\s+(.+)$/i);
  if (!match) return null;
  const verified = await fetch(
    `https://identitytoolkit.googleapis.com/v1/accounts:lookup?key=${encodeURIComponent(apiKey)}`,
    {
      method: 'POST',
      headers: {'Content-Type': 'application/json'},
      body: JSON.stringify({idToken: match[1]}),
    },
  );
  if (!verified.ok) return null;
  const identity = await verified.json();
  return identity.users?.[0]?.localId ?? null;
}

export default {
  async fetch(request, env) {
    if (request.method === 'OPTIONS') return new Response(null, {headers: jsonHeaders});
    if (request.method !== 'POST') return response(405, {error: 'POST is required.'});
    if (!env.FIREBASE_PROJECT_ID || !env.FIREBASE_WEB_API_KEY || !env.FIREBASE_SERVICE_ACCOUNT_JSON) {
      return response(500, {error: 'Worker configuration is missing.'});
    }

    let input;
    try {
      input = await request.json();
    } catch (_) {
      return response(400, {error: 'A JSON body is required.'});
    }
    const chatId = String(input.chatId ?? '').trim();
    const requestId = String(input.requestId ?? '').trim();
    const recipientId = String(input.recipientId ?? '').trim();
    const preview = String(input.message ?? '').trim().slice(0, 140);
    if ((!chatId && !requestId) || !recipientId) return response(422, {error: 'chatId or requestId, and recipientId are required.'});

    try {
      const senderId = await authenticatedUser(request, env.FIREBASE_WEB_API_KEY);
      if (!senderId) return response(401, {error: 'Your sign-in session is invalid.'});

      const accessToken = await googleAccessToken(env.FIREBASE_SERVICE_ACCOUNT_JSON);
      if (requestId) {
        const bloodRequest = await firebaseDocument(requestId, env.FIREBASE_PROJECT_ID, accessToken);
        const requestOwner = stringField(bloodRequest, 'ownerId');
        const acceptedDonor = stringField(bloodRequest, 'acceptedDonorId');
        if (!bloodRequest || requestOwner !== recipientId || acceptedDonor !== senderId) {
          return response(403, {error: 'You cannot notify this requester.'});
        }
        const donorName = stringField(bloodRequest, 'acceptedDonorName') || 'A donor';
        const body = `${donorName} responded to your blood request.`;
        await createNotification(env.FIREBASE_PROJECT_ID, accessToken, recipientId, {
          type: {stringValue: 'request_response'},
          title: {stringValue: 'Request response'},
          body: {stringValue: body},
          requestId: {stringValue: requestId},
          donorId: {stringValue: senderId},
          donorName: {stringValue: donorName},
          read: {booleanValue: false},
          createdAt: {timestampValue: new Date().toISOString()},
        });
        return response(200, {sent: false, saved: true});
      }
      const chat = await firebaseDocument(`chats/${chatId}`, env.FIREBASE_PROJECT_ID, accessToken);
      const chatParticipants = participants(chat);
      if (!chatParticipants.includes(senderId) || !chatParticipants.includes(recipientId)) {
        return response(403, {error: 'You cannot notify this user from this conversation.'});
      }

      const device = await firebaseDocument(
        `users/${recipientId}/pushDevices/current`,
        env.FIREBASE_PROJECT_ID,
        accessToken,
      );
      const registrationToken = stringField(device, 'token');
      const senderName = chat?.fields?.participantNames?.mapValue?.fields?.[senderId]?.stringValue ?? 'LifeLink user';
      const recipientDonor = await firebaseDocument(`donors/${recipientId}`, env.FIREBASE_PROJECT_ID, accessToken);
      const notificationType = recipientDonor ? 'donor_contact' : 'chat';
      const body = preview || 'Sent you a message on LifeLink.';
      await createNotification(env.FIREBASE_PROJECT_ID, accessToken, recipientId, {
        type: {stringValue: notificationType},
        title: {stringValue: senderName},
        body: {stringValue: body},
        chatId: {stringValue: chatId},
        senderId: {stringValue: senderId},
        senderName: {stringValue: senderName},
        read: {booleanValue: false},
        createdAt: {timestampValue: new Date().toISOString()},
      });
      if (!registrationToken) return response(200, {sent: false, saved: true, reason: 'Notifications are off.'});

      const sent = await fetch(
        `https://fcm.googleapis.com/v1/projects/${encodeURIComponent(env.FIREBASE_PROJECT_ID)}/messages:send`,
        {
          method: 'POST',
          headers: {
            Authorization: `Bearer ${accessToken}`,
            'Content-Type': 'application/json',
          },
          body: JSON.stringify({
            message: {
              token: registrationToken,
              notification: {
                title: senderName,
                body,
              },
              data: {type: notificationType, chatId, senderId},
              android: {priority: 'high'},
            },
          }),
        },
      );
      if (!sent.ok) return response(502, {error: 'FCM did not accept the notification.'});
      return response(200, {sent: true, saved: true});
    } catch (_) {
      return response(500, {error: 'Notification service failed.'});
    }
  },
};
