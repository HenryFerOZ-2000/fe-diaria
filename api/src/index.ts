import {setGlobalOptions} from "firebase-functions";
import {onRequest} from "firebase-functions/https";
import {onCall, HttpsError} from "firebase-functions/v2/https";
import {onSchedule} from "firebase-functions/v2/scheduler";
import * as admin from "firebase-admin";
import * as logger from "firebase-functions/logger";
import {FieldValue, Timestamp} from "firebase-admin/firestore";

setGlobalOptions({maxInstances: 10});

if (admin.apps.length === 0) {
  admin.initializeApp();
}

const db = admin.firestore();

const toDateId = (date: Date): string => {
  const year = date.getUTCFullYear();
  const month = `${date.getUTCMonth() + 1}`.padStart(2, "0");
  const day = `${date.getUTCDate()}`.padStart(2, "0");
  return `${year}${month}${day}`;
};

const addSeconds = (date: Date, seconds: number): Date => {
  return new Date(date.getTime() + seconds * 1000);
};

export const seedFirestore = onRequest(async (req, res) => {
  logger.info("seedFirestore start", {method: req.method, path: req.path});

  try {
    const now = new Date();
    const todayId = toDateId(now);
    const endAt = Timestamp.fromDate(addSeconds(now, 60));

    const batch = db.batch();

    batch.set(
      db.collection("daily_content").doc(todayId),
      {createdAt: FieldValue.serverTimestamp()},
      {merge: true},
    );

    batch.set(
      db.collection("users").doc("TEST_UID"),
      {plan: "free", createdAt: FieldValue.serverTimestamp()},
      {merge: true},
    );

    batch.set(
      db.collection("live_posts").doc("seed_oracion_prueba"),
      {
        text: "Oración de prueba",
        status: "active",
        createdAt: FieldValue.serverTimestamp(),
        endAt,
        likeCount: 0,
        joinCount: 0,
        commentCount: 0,
      },
      {merge: true},
    );

    await batch.commit();

    res.json({ok: true});
  } catch (error) {
    const message = error instanceof Error ? error.message : String(error);
    logger.error("seedFirestore error", {error: message});
    res.status(500).json({ok: false, error: message});
  }
});

type CreateLivePostInput = {text?: unknown};

const parseAuthHeader = (authHeader?: string): string | null => {
  if (!authHeader) return null;
  const parts = authHeader.split(" ");
  if (parts.length !== 2 || parts[0] !== "Bearer") return null;
  return parts[1];
};

const validateText = (text: string): string => {
  const trimmed = text.trim();
  if (trimmed.length < 10) {
    throw new HttpsError(
      "invalid-argument",
      "El texto debe tener al menos 10 caracteres.",
    );
  }
  if (trimmed.length > 600) {
    throw new HttpsError(
      "invalid-argument",
      "El texto no puede exceder 600 caracteres.",
    );
  }
  return trimmed;
};

const checkRateLimit = (
  lastPostAt: FirebaseFirestore.Timestamp | undefined,
  nowMs: number,
) => {
  if (!lastPostAt) return;
  const elapsed = nowMs - lastPostAt.toMillis();
  if (elapsed < 60_000) {
    const wait = Math.ceil((60_000 - elapsed) / 1000);
    throw new Error(`Espera ${wait}s antes de publicar de nuevo.`);
  }
};

const resolveAuthorName = async (uid: string): Promise<string> => {
  try {
    // 1) Prefer stored username in Firestore
    const userDoc = await db.collection("users").doc(uid).get();
    const username = userDoc.exists ?
      (userDoc.get("username") as string | undefined) :
      undefined;
    if (username && username.trim() !== "") {
      return username;
    }

    // 2) Fallback to Firebase Auth profile
    const user = await admin.auth().getUser(uid);
    if (user.displayName && user.displayName.trim() !== "") {
      return user.displayName;
    }
    if (user.email && user.email.trim() !== "") {
      return user.email.split("@")[0];
    }
    return uid;
  } catch (e) {
    logger.warn("resolveAuthorName failed", e as Error);
    return uid;
  }
};

const createLivePostTx = async (
  uid: string,
  text: string,
): Promise<string> => {
  const now = Timestamp.now();
  const liveUntil = Timestamp.fromMillis(now.toMillis() + 60_000);
  const expiresAt = Timestamp.fromMillis(now.toMillis() + 24 * 60 * 60 * 1000);
  const postsRef = db.collection("live_posts");
  const userRef = db.collection("users").doc(uid);
  const authorName = await resolveAuthorName(uid);

  return db.runTransaction(async (tx) => {
    const userSnap = await tx.get(userRef);
    const lastPostAt = userSnap.exists ?
      (userSnap.get("lastPostAt") as FirebaseFirestore.Timestamp | undefined) :
      undefined;

    checkRateLimit(lastPostAt, now.toMillis());

    const postRef = postsRef.doc();
    tx.set(postRef, {
      text,
      status: "active",
      authorUid: uid,
      authorName,
      createdAt: FieldValue.serverTimestamp(),
      liveUntil,
      expiresAt,
      likeCount: 0,
      joinCount: 0,
      commentCount: 0,
    });

    const createdAt = userSnap.exists ?
      userSnap.get("createdAt") ?? FieldValue.serverTimestamp() :
      FieldValue.serverTimestamp();

    tx.set(userRef, {
      lastPostAt: now,
      plan: userSnap.exists ? userSnap.get("plan") ?? "free" : "free",
      createdAt,
    }, {merge: true});

    return postRef.id;
  });
};

const authenticate = async (idToken: string | null): Promise<string> => {
  if (!idToken) {
    throw new Error("Auth token requerido.");
  }
  const decoded = await admin.auth().verifyIdToken(idToken);
  if (!decoded.uid) {
    throw new Error("Token inválido.");
  }
  return decoded.uid;
};

export const createLivePost = onCall(
  {region: "us-central1"},
  async (request) => {
    logger.info("createLivePost called", {
      hasAuth: !!request.auth,
      uid: request.auth?.uid ?? null,
    });

    const data = request.data as CreateLivePostInput | undefined;
    const textValue = data?.text;

    if (typeof textValue !== "string") {
      throw new HttpsError("invalid-argument", "text requerido");
    }

    const clean = validateText(textValue);

    if (!request.auth?.uid) {
      throw new HttpsError("unauthenticated", "login requerido");
    }

    try {
      const postId = await createLivePostTx(request.auth.uid, clean);
      logger.info("createLivePost success", {postId});
      return {ok: true, postId};
    } catch (error) {
      if (error instanceof HttpsError) {
        throw error;
      }
      logger.error("createLivePost error", error);
      throw new HttpsError("internal", "createLivePost failed");
    }
  },
);

export const createLivePostHttp = onRequest(async (req, res) => {
  try {
    if (req.method !== "POST") {
      res.status(405).json({ok: false, error: "Método no permitido"});
      return;
    }
    const token = parseAuthHeader(
      req.headers.authorization as string | undefined,
    );
    const uid = await authenticate(token);
    const text = (req.body as CreateLivePostInput | undefined)?.text;
    if (typeof text !== "string") {
      res.status(400).json({ok: false, error: "Texto inválido"});
      return;
    }
    const clean = validateText(text);
    const postId = await createLivePostTx(uid, clean);
    res.json({ok: true, postId});
  } catch (error) {
    const message = error instanceof Error ? error.message : "Error";
    logger.error("createLivePostHttp failed", {error: message});
    res.status(400).json({ok: false, error: message});
  }
});

export const expireLivePosts = onSchedule("* * * * *", async () => {
  const now = admin.firestore.Timestamp.now();
  const snapshot = await db.collection("live_posts")
    .where("status", "==", "active")
    .where("endAt", "<=", now)
    .limit(50)
    .get();

  if (snapshot.empty) return;

  const batch = db.batch();
  snapshot.docs.forEach((doc) => {
    batch.update(doc.ref, {status: "ended"});
  });

  await batch.commit();
  logger.info("expireLivePosts updated", {count: snapshot.size});
});
