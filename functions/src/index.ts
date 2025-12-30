import * as admin from 'firebase-admin';
import { onRequest, onCall, HttpsError } from 'firebase-functions/v2/https';

admin.initializeApp();

const db = admin.firestore();
const { FieldValue, Timestamp } = admin.firestore;

const TEST_LIVE_POST_TEXT = 'Oración de prueba';
const TEST_USER_ID = 'TEST_UID';

const formatDateIdUTC = (date: Date): string => {
  const year = date.getUTCFullYear();
  const month = `${date.getUTCMonth() + 1}`.padStart(2, '0');
  const day = `${date.getUTCDate()}`.padStart(2, '0');
  return `${year}${month}${day}`;
};

const startOfUtcDay = (date: Date): Date =>
  new Date(Date.UTC(date.getUTCFullYear(), date.getUTCMonth(), date.getUTCDate()));

const addSeconds = (date: Date, seconds: number): Date => new Date(date.getTime() + seconds * 1000);

const ensureSeedKey = (providedKey: string | undefined): void => {
  const expectedKey = process.env.SEED_KEY;

  if (!expectedKey) {
    throw new Error('SEED_KEY is not configured in the environment.');
  }

  if (!providedKey || providedKey !== expectedKey) {
    const error = new Error('Unauthorized: invalid SEED_KEY.');
    // @ts-expect-error Mark for status handling downstream.
    error.status = 401;
    throw error;
  }
};

const seedDailyContent = async (todayId: string) => {
  const dailyContentRef = db.collection('daily_content').doc(todayId);

  await dailyContentRef.set(
    {
      verseRef: 'PSA 23:1',
      book: 'PSA',
      chapter: 23,
      verse: 1,
      prayerDay: '(placeholder)',
      prayerNight: '(placeholder)',
      createdAt: FieldValue.serverTimestamp(),
    },
    { merge: true },
  );

  return { docId: todayId };
};

type FirestoreTimestamp = FirebaseFirestore.Timestamp;

const seedLivePosts = async (startOfDay: FirestoreTimestamp, endAt: FirestoreTimestamp) => {
  const livePostsRef = db.collection('live_posts');
  const existing = await livePostsRef
    .where('text', '==', TEST_LIVE_POST_TEXT)
    .where('status', '==', 'active')
    .where('createdAt', '>=', startOfDay)
    .limit(1)
    .get();

  if (existing.empty) {
    const created = await livePostsRef.add({
      text: TEST_LIVE_POST_TEXT,
      status: 'active',
      createdAt: FieldValue.serverTimestamp(),
      endAt,
      likeCount: 0,
      joinCount: 0,
      commentCount: 0,
    });

    return { created: created.id };
  }

  const doc = existing.docs[0];
  await doc.ref.set(
    {
      status: 'active',
      endAt,
      likeCount: FieldValue.increment(0),
      joinCount: FieldValue.increment(0),
      commentCount: FieldValue.increment(0),
    },
    { merge: true },
  );

  return { updated: doc.id };
};

const seedTestUser = async () => {
  const userRef = db.collection('users').doc(TEST_USER_ID);

  await db.runTransaction(async (transaction) => {
    const snap = await transaction.get(userRef);

    if (!snap.exists) {
      transaction.set(userRef, {
        plan: 'free',
        createdAt: FieldValue.serverTimestamp(),
      });
      return;
    }

    transaction.set(userRef, { plan: 'free' }, { merge: true });
  });

  return { docId: TEST_USER_ID };
};

export const seedFirestore = onRequest({ region: 'us-central1' }, async (req, res) => {
  try {
    if (req.method !== 'POST') {
      res.status(405).json({ error: 'Method not allowed. Use POST.' });
      return;
    }

    const providedSeedKey =
      (req.headers['x-seed-key'] as string | undefined) ||
      (req.headers.seed_key as string | undefined) ||
      (req.query.seedKey as string | undefined);

    ensureSeedKey(providedSeedKey);

    const now = new Date();
    const todayId = formatDateIdUTC(now);
    const startOfDay = Timestamp.fromDate(startOfUtcDay(now));
    const endAt = Timestamp.fromDate(addSeconds(now, 60));

    const [dailyContentResult, livePostsResult, userResult] = await Promise.all([
      seedDailyContent(todayId),
      seedLivePosts(startOfDay, endAt),
      seedTestUser(),
    ]);

    res.json({
      ok: true,
      daily_content: dailyContentResult,
      live_posts: livePostsResult,
      users: userResult,
    });
  } catch (error) {
    const status = (error as { status?: number }).status ?? 500;
    // eslint-disable-next-line no-console
    console.error('seedFirestore failed', error);
    res.status(status).json({
      ok: false,
      error: (error as Error).message,
    });
  }
});

type CreateLivePostInput = { text?: unknown };

const validateLiveText = (text: string): string => {
  const trimmed = text.trim();
  if (trimmed.length < 10) {
    throw new HttpsError('invalid-argument', 'El texto debe tener al menos 10 caracteres.');
  }
  if (trimmed.length > 600) {
    throw new HttpsError('invalid-argument', 'El texto no puede exceder 600 caracteres.');
  }
  return trimmed;
};

export const createLivePost = onCall({ region: 'us-central1' }, async (request) => {
  if (!request.auth?.uid) {
    throw new HttpsError('unauthenticated', 'Login required');
  }

  const { text } = request.data as CreateLivePostInput;
  if (typeof text !== 'string') {
    throw new HttpsError('invalid-argument', 'Texto inválido.');
  }

  const clean = validateLiveText(text);
  const endAt = Timestamp.fromDate(addSeconds(new Date(), 60));

  const docRef = await db.collection('live_posts').add({
    text: clean,
    status: 'active',
    authorUid: request.auth.uid,
    createdAt: FieldValue.serverTimestamp(),
    endAt,
    likeCount: 0,
    joinCount: 0,
    commentCount: 0,
  });

  return { ok: true, postId: docRef.id };
});

