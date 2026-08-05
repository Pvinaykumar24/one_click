const functions = require('firebase-functions');
const admin = require('firebase-admin');

// Initialize admin if not already done
if (admin.apps.length === 0) {
  admin.initializeApp();
}

const db = admin.firestore();

/**
 * Callable function to safely wipe all user data, enforcing admin custom claim check on the server side.
 */
exports.wipeAllUserData = functions.https.onCall(async (data, context) => {
  // 1. Enforce Authentication and Custom Claim check on the server
  if (!context.auth) {
    throw new functions.https.HttpsError(
      'unauthenticated', 
      'The function must be called while authenticated.'
    );
  }
  
  if (context.auth.token.admin !== true) {
    throw new functions.https.HttpsError(
      'permission-denied', 
      'The function can only be called by an administrator.'
    );
  }

  console.log(`[WIPE] Wipe request initiated by admin: ${context.auth.uid}`);

  try {
    // 2. Fetch all user documents
    const usersSnapshot = await db.collection('users').get();
    
    // In Firebase, we can batch writes but a single batch is limited to 500 operations.
    // To handle arbitrary users, we commit batches as we accumulate deletions.
    let batch = db.batch();
    let operationCount = 0;
    const batchPromises = [];

    const commitBatchIfNeeded = async (force = false) => {
      if (operationCount >= 400 || (force && operationCount > 0)) {
        console.log(`[WIPE] Committing batch of ${operationCount} deletions...`);
        batchPromises.push(batch.commit());
        batch = db.batch();
        operationCount = 0;
      }
    };

    const subcollections = ['finances', 'cgpa', 'attendance', 'timetable', 'notifications', 'assignments'];

    for (const userDoc of usersSnapshot.docs) {
      const uid = userDoc.id;

      // Queue subcollection deletions
      for (const sub of subcollections) {
        const subSnap = await db.collection('users').doc(uid).collection(sub).get();
        for (const doc of subSnap.docs) {
          batch.delete(doc.reference);
          operationCount++;
          await commitBatchIfNeeded();
        }
      }

      // Queue parent user document deletion
      batch.delete(userDoc.reference);
      operationCount++;
      await commitBatchIfNeeded();
    }

    // Force commit any remaining operations
    await commitBatchIfNeeded(true);
    
    // Wait for all batches to finish executing
    await Promise.all(batchPromises);
    
    console.log('[WIPE] Successfully completed wiping all user data.');
    return { success: true, message: 'All user data has been wiped successfully.' };
  } catch (error) {
    console.error('[WIPE ERROR] Failed to wipe user data:', error);
    throw new functions.https.HttpsError(
      'internal', 
      `An internal error occurred while wiping data: ${error.message}`
    );
  }
});
