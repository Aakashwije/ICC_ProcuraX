import fetch from 'node-fetch';

async function main() {
  const loginRes = await fetch('http://localhost:5002/auth/login', {
    method: 'POST',
    headers: { 'Content-Type': 'application/json' },
    body: JSON.stringify({ email: 'testuser@example.com', password: 'password' }),
  });

  console.log('login status', loginRes.status);
  const loginBody = await loginRes.json();
  console.log('login body', loginBody);

  if (!loginBody.token) {
    console.error('No token returned; aborting');
    process.exit(1);
  }

  const token = loginBody.token;

  const meRes = await fetch('http://localhost:5002/api/users/me', {
    method: 'GET',
    headers: { Authorization: `Bearer ${token}` },
  });
  console.log('me status', meRes.status);
  console.log('me body', await meRes.text());

  const updateRes = await fetch('http://localhost:5002/api/users/profile', {
    method: 'PUT',
    headers: {
      Authorization: `Bearer ${token}`,
      'Content-Type': 'application/json',
    },
    body: JSON.stringify({ firstName: 'Test', lastName: 'User', phone: '+1234567890' }),
  });

  console.log('update status', updateRes.status);
  console.log('update body', await updateRes.text());
}

main().catch((e) => {
  console.error('error', e);
  process.exit(1);
});
