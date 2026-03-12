import fs from 'fs';
import path from 'path';
import fetch from 'node-fetch';

const BACKEND = 'http://localhost:5002';

async function login() {
  const res = await fetch(`${BACKEND}/auth/login`, {
    method: 'POST',
    headers: { 'Content-Type': 'application/json' },
    body: JSON.stringify({ email: 'testuser@example.com', password: 'password' }),
  });
  const body = await res.json();
  if (!res.ok) throw new Error(`Login failed: ${res.status} ${JSON.stringify(body)}`);
  return body.token;
}

async function uploadImage(token) {
  const filePath = path.join(process.cwd(), 'scripts', 'upload_test.png');

  // Create a tiny valid PNG if it doesn't exist yet
  if (!fs.existsSync(filePath)) {
    const png = Buffer.from(
      '89504e470d0a1a0a0000000d49484452000000010000000108020000009077' +
        '53de0000000a49444154789c6360000002000100f0ff03b5f5a5da00000000' +
        '049454e44ae426082',
      'hex',
    );
    fs.writeFileSync(filePath, png);
  }

  const formData = new FormData();
  formData.append('profileImage', fs.createReadStream(filePath));

  const res = await fetch(`${BACKEND}/api/upload/profile-image`, {
    method: 'POST',
    headers: {
      Authorization: `Bearer ${token}`,
    },
    body: formData,
  });

  const text = await res.text();
  console.log('upload status', res.status);
  console.log('upload response', text);
}

async function main() {
  const token = await login();
  console.log('token length', token.length);
  await uploadImage(token);
}

main().catch((err) => {
  console.error('ERROR', err);
  process.exit(1);
});
