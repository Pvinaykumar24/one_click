const { initializeApp, cert } = require('firebase-admin/app');
const { getAuth } = require('firebase-admin/auth');

// Service Account details
const serviceAccount = require("./serviceAccountKey.json");

// Initialize Firebase Admin App
initializeApp({
  credential: cert(serviceAccount)
});

// Target Firebase User UID
const targetUid = 'dkXZY1AidiRi7TSdidF6ix9EIAc2';

async function setAdminClaim(uid) {
  try {
    const auth = getAuth();
    await auth.setCustomUserClaims(uid, { admin: true });
    console.log(`Successfully set admin claim for user: ${uid}`);
    
    // Verify by fetching the user details
    const user = await auth.getUser(uid);
    console.log('User claims verification:', user.customClaims);
    process.exit(0);
  } catch (error) {
    console.error('Error setting custom claim:', error);
    process.exit(1);
  }
}

if (targetUid === 'YOUR_USER_UID_HERE') {
  console.error('ERROR: Please replace "YOUR_USER_UID_HERE" with your actual Firebase user UID.');
  process.exit(1);
}

setAdminClaim(targetUid);
