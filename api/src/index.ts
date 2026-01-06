import {setGlobalOptions} from "firebase-functions";
import {onRequest} from "firebase-functions/https";
import {onCall, HttpsError} from "firebase-functions/v2/https";
import * as admin from "firebase-admin";
import * as logger from "firebase-functions/logger";
import {FieldValue, Timestamp} from "firebase-admin/firestore";
// eslint-disable-next-line import/no-unresolved
import Groq from "groq-sdk";
// eslint-disable-next-line import/no-unresolved
import {GROQ_API_KEY} from "./secrets/groq.secrets";
import {CHAT_PROMPT, GROQ_MAX_COMPLETION_TOKENS,
  GROQ_MODEL, GROQ_TEMPERATURE} from "./groqConfig";
import {ChatMessage, ChatRequest, ChatResponse} from "./chat.interfaces";

setGlobalOptions({maxInstances: 10});

if (admin.apps.length === 0) {
  admin.initializeApp();
}

const db = admin.firestore();
const TEST_LIVE_POST_TEXT = "Oración de prueba";

const toDateId = (date: Date): string => {
  const year = date.getUTCFullYear();
  const month = `${date.getUTCMonth() + 1}`.padStart(2, "0");
  const day = `${date.getUTCDate()}`.padStart(2, "0");
  return `${year}${month}${day}`;
};

const addSeconds = (date: Date, seconds: number): Date => {
  return new Date(date.getTime() + seconds * 1000);
};

const ensureSeedKey = (providedKey?: string): void => {
  const expected = process.env.SEED_KEY;
  if (!expected) {
    // Si no hay clave configurada, no restringir para entornos locales.
    return;
  }
  if (!providedKey || providedKey !== expected) {
    const error = new Error("Unauthorized: invalid SEED_KEY.");
    (error as {status?: number}).status = 401;
    throw error;
  }
};

export const seedFirestore = onRequest(async (req, res) => {
  logger.info("seedFirestore start", {method: req.method, path: req.path});

  try {
    if (req.method !== "POST") {
      res.status(405).json({ok: false, error: "Método no permitido"});
      return;
    }

    const providedSeedKey =
      (req.headers["x-seed-key"] as string | undefined) ||
      (req.headers.seed_key as string | undefined) ||
      (req.query.seedKey as string | undefined);
    ensureSeedKey(providedSeedKey);

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
        text: TEST_LIVE_POST_TEXT,
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
    const status = (error as {status?: number}).status ?? 500;
    res.status(status).json({ok: false, error: message});
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

type AuthorProfile = {
  username?: string;
  displayName?: string;
  photoURL?: string;
};

const resolveAuthorProfile = async (uid: string): Promise<AuthorProfile> => {
  try {
    // 1) Prefer stored username in Firestore
    const userDoc = await db.collection("users").doc(uid).get();
    const username = userDoc.exists ?
      (userDoc.get("username") as string | undefined) :
      undefined;
    const displayName = userDoc.exists ?
      (userDoc.get("displayName") as string | undefined) :
      undefined;
    const photoURL = userDoc.exists ?
      (userDoc.get("photoURL") as string | undefined) :
      undefined;
    if (username && username.trim() !== "") {
      return {username, displayName: displayName ?? username, photoURL};
    }

    // 2) Fallback to Firebase Auth profile
    const user = await admin.auth().getUser(uid);
    if (user.displayName && user.displayName.trim() !== "") {
      return {
        username: user.displayName,
        displayName: user.displayName,
        photoURL: user.photoURL ?? undefined,
      };
    }
    if (user.email && user.email.trim() !== "") {
      const emailName = user.email.split("@")[0];
      return {
        username: emailName,
        displayName: emailName,
        photoURL: user.photoURL ?? undefined,
      };
    }
    return {username: uid, displayName: uid, photoURL};
  } catch (e) {
    logger.warn("resolveAuthorName failed", e as Error);
    return {username: uid, displayName: uid};
  }
};

const createLivePostTx = async (
  uid: string,
  text: string,
): Promise<string> => {
  const now = Timestamp.now();
  const liveUntil = Timestamp.fromMillis(now.toMillis() + 60_000);
  const endAt = Timestamp.fromMillis(now.toMillis() + 24 * 60 * 60 * 1000);
  const postsRef = db.collection("live_posts");
  const userRef = db.collection("users").doc(uid);
  const authorProfile = await resolveAuthorProfile(uid);

  return db.runTransaction(async (tx) => {
    const userSnap = await tx.get(userRef);
    let lastPostAt: FirebaseFirestore.Timestamp | undefined;
    if (userSnap.exists) {
      lastPostAt = userSnap.get("lastPostAt") as FirebaseFirestore.Timestamp |
        undefined;
    }

    checkRateLimit(lastPostAt, now.toMillis());

    const postRef = postsRef.doc();
    tx.set(postRef, {
      text,
      status: "active",
      authorUid: uid,
      authorName: authorProfile.displayName ?? authorProfile.username ?? uid,
      authorUsername: authorProfile.username ?? uid,
      authorPhoto: authorProfile.photoURL ?? null,
      createdAt: FieldValue.serverTimestamp(),
      liveUntil,
      endAt,
      likeCount: 0,
      joinCount: 0,
      commentCount: 0,
    });

    const createdAt = userSnap.exists ?
      userSnap.get("createdAt") ?? FieldValue.serverTimestamp() :
      FieldValue.serverTimestamp();

    tx.set(userRef, {
      lastPostAt: now,
      plan: userSnap.exists ?
        userSnap.get("plan") ?? "free" :
        "free",
      createdAt,
      username: authorProfile.username ??
        userSnap.get("username") ??
        uid,
      displayName:
        authorProfile.displayName ??
        userSnap.get("displayName") ??
        authorProfile.username ??
        uid,
      photoURL: authorProfile.photoURL ?? userSnap.get("photoURL") ?? null,
      usernameLower: (
        authorProfile.username ??
        userSnap.get("username") ??
        uid
      ).toString().toLowerCase(),
      isPublic: userSnap.exists ? userSnap.get("isPublic") ?? true : true,
      followersCount: userSnap.exists ?
        userSnap.get("followersCount") ?? 0 :
        0,
      followingCount: userSnap.exists ?
        userSnap.get("followingCount") ?? 0 :
        0,
      postsCount: userSnap.exists ?
        FieldValue.increment(1) :
        1,
      updatedAt: FieldValue.serverTimestamp(),
    }, {merge: true});

    return postRef.id;
  });
};

// ---------------------------
// Username helpers & callable
// ---------------------------

const normalizeUsername = (username: string): string => {
  const trimmed = username.trim().toLowerCase();
  if (!/^[a-z0-9._]{3,20}$/.test(trimmed)) {
    throw new HttpsError("invalid-argument", "username_invalid");
  }
  return trimmed;
};

export const setUsername = onCall({region: "us-central1"}, async (request) => {
  const uid = request.auth?.uid;
  if (!uid) {
    throw new HttpsError("unauthenticated", "auth_required");
  }
  const raw = (request.data as {username?: unknown}).username;
  if (typeof raw !== "string") {
    throw new HttpsError("invalid-argument", "username_required");
  }
  const username = normalizeUsername(raw);
  const usernameDoc = db.collection("username_map").doc(username);
  const userDoc = db.collection("users").doc(uid);

  await db.runTransaction(async (tx) => {
    const userSnap = await tx.get(userDoc);
    let prevUsername: string | undefined;
    if (userSnap.exists) {
      prevUsername = userSnap.get("username") as string | undefined;
    }
    const prevLower = prevUsername?.toLowerCase();

    // If same username, do nothing
    if (prevLower === username) {
      return;
    }

    const usernameSnap = await tx.get(usernameDoc);
    if (usernameSnap.exists) {
      const owner = usernameSnap.get("uid") as string | undefined;
      if (owner !== uid) {
        throw new HttpsError("already-exists", "username_taken");
      }
    }

    // Reserve new username
    tx.set(
      usernameDoc,
      {uid, createdAt: FieldValue.serverTimestamp()},
      {merge: false},
    );

    // Release previous username if owned by same user
    if (prevLower && prevLower !== username) {
      const prevDoc = db.collection("username_map").doc(prevLower);
      tx.delete(prevDoc);
    }

    // Update user document
    tx.set(userDoc, {
      username,
      usernameLower: username,
      updatedAt: FieldValue.serverTimestamp(),
    }, {merge: true});
  });

  return {ok: true, username};
});

// ---------------------------
// Follow / Unfollow callables
// ---------------------------

const followerPath = (uid: string, follower: string) =>
  db.collection("users").doc(uid).collection("followers").doc(follower);
const followingPath = (uid: string, target: string) =>
  db.collection("users").doc(uid).collection("following").doc(target);

export const followUser = onCall({region: "us-central1"}, async (request) => {
  const uid = request.auth?.uid;
  if (!uid) throw new HttpsError("unauthenticated", "auth_required");

  const targetUid = (request.data as {targetUid?: unknown}).targetUid;
  if (typeof targetUid !== "string" || targetUid.trim() === "") {
    throw new HttpsError("invalid-argument", "target_required");
  }
  if (targetUid === uid) {
    throw new HttpsError("failed-precondition", "cannot_follow_self");
  }

  const targetRef = db.collection("users").doc(targetUid);
  const meRef = db.collection("users").doc(uid);
  const followerRef = followerPath(targetUid, uid);
  const followingRef = followingPath(uid, targetUid);

  await db.runTransaction(async (tx) => {
    const targetSnap = await tx.get(targetRef);
    if (!targetSnap.exists) {
      throw new HttpsError("not-found", "target_not_found");
    }

    // If already following, no-op
    const followSnap = await tx.get(followerRef);
    if (followSnap.exists) return;

    tx.set(followerRef, {createdAt: FieldValue.serverTimestamp()});
    tx.set(followingRef, {createdAt: FieldValue.serverTimestamp()});
    tx.update(targetRef, {followersCount: FieldValue.increment(1)});
    tx.update(meRef, {followingCount: FieldValue.increment(1)});
  });

  return {ok: true};
});

export const unfollowUser = onCall({region: "us-central1"}, async (request) => {
  const uid = request.auth?.uid;
  if (!uid) throw new HttpsError("unauthenticated", "auth_required");

  const targetUid = (request.data as {targetUid?: unknown}).targetUid;
  if (typeof targetUid !== "string" || targetUid.trim() === "") {
    throw new HttpsError("invalid-argument", "target_required");
  }
  if (targetUid === uid) {
    throw new HttpsError("failed-precondition", "cannot_unfollow_self");
  }

  const targetRef = db.collection("users").doc(targetUid);
  const meRef = db.collection("users").doc(uid);
  const followerRef = followerPath(targetUid, uid);
  const followingRef = followingPath(uid, targetUid);

  await db.runTransaction(async (tx) => {
    // If not following, no-op
    const followSnap = await tx.get(followerRef);
    if (!followSnap.exists) return;

    tx.delete(followerRef);
    tx.delete(followingRef);
    tx.update(targetRef, {followersCount: FieldValue.increment(-1)});
    tx.update(meRef, {followingCount: FieldValue.increment(-1)});
  });

  return {ok: true};
});

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

// expireLivePosts removed - live feed no longer expires posts
// Posts are now persistent and displayed in chronological order (newest first)

// Helper function to split response into multiple messages
const splitResponse = (content: string): string[] => {
  // Split by double newlines or specific delimiters
  const parts = content.split(/\n\n+/).filter((p) => p.trim().length > 0);
  return parts.length > 0 ? parts : [content];
};

/**
 * Firebase Function that emulates Groq chat completion.
 * Receives user text, conversation history
 * Returns AI-generated response.
 */
export const chatWithGroq = onCall(
  async (request): Promise<ChatResponse> => {
    // Validate authentication
    if (!request.auth) {
      throw new HttpsError(
        "unauthenticated",
        "User must be authenticated to use chat."
      );
    }

    const {userText, conversation} = request.data as ChatRequest;

    // Validate input
    if (!userText || typeof userText !== "string") {
      throw new HttpsError(
        "invalid-argument",
        "userText is required and must be a string."
      );
    }

    const messages: ChatMessage[] = Array.isArray(conversation) ?
      conversation : [];

    try {
      const groq = new Groq({apiKey: GROQ_API_KEY});

      const response = await groq.chat.completions.create({
        model: GROQ_MODEL,
        max_completion_tokens: GROQ_MAX_COMPLETION_TOKENS,
        temperature: GROQ_TEMPERATURE,
        messages: [
          {
            role: "system",
            content: CHAT_PROMPT,
          },
          ...messages,
          {role: "user", content: userText},
        ],
      });

      const content = response?.choices[0]?.message?.content ||
        "Error getting a response.";
      const splitMessages = splitResponse(content);

      logger.info("chatWithGroq success", {
        uid: request.auth.uid,
        messagesCount: splitMessages.length,
      });

      return {
        messages: splitMessages,
        rawContent: content,
      };
    } catch (error) {
      const message = error instanceof Error ? error.message : "Unknown error";
      logger.error("chatWithGroq failed", {error: message});
      throw new HttpsError("internal", `Chat failed: ${message}`);
    }
  }
);

// Helper functions for date formatting (YYYY-MM-DD)
const formatDateId = (date: Date): string => {
  const year = date.getUTCFullYear();
  const month = `${date.getUTCMonth() + 1}`.padStart(2, "0");
  const day = `${date.getUTCDate()}`.padStart(2, "0");
  return `${year}-${month}-${day}`;
};

const getDaysAgo = (days: number): Date => {
  const date = new Date();
  date.setUTCDate(date.getUTCDate() - days);
  return date;
};

/**
 * Marca el día actual como activo y actualiza la racha del usuario.
 * Idempotente: si ya se marcó hoy, no cambia la racha.
 * Region: us-central1, Runtime: nodejs20, Memory: 256MiB
 */
export const markActiveToday = onCall(
  {region: "us-central1", memory: "256MiB"},
  async (request) => {
    const uid = request.auth?.uid;
    if (!uid) {
      throw new HttpsError("unauthenticated", "auth_required");
    }

    const now = new Date();
    const today = formatDateId(now);
    const yesterday = formatDateId(getDaysAgo(1));

    const statsRef = db.collection("users")
      .doc(uid)
      .collection("spiritualStats")
      .doc("main");

    try {
      const statsSnap = await statsRef.get();
      const exists = statsSnap.exists;
      const currentData = statsSnap.data() ?? {};

      const lastActiveDate = currentData["lastActiveDate"] as
        string | undefined;
      let currentStreak = (currentData["currentStreak"] ?? 0) as number;
      let bestStreak = (currentData["bestStreak"] ?? 0) as number;
      const activeDaysMap = (
        currentData["activeDaysMap"] as Record<string, boolean> | undefined
      ) ?? {};

      // Lógica idempotente de racha
      if (lastActiveDate === today) {
        // Ya marcado hoy, no cambiar racha (idempotente)
        // PERO: si currentStreak es 0, establecerlo a 1 (primer día)
        if (currentStreak === 0) {
          currentStreak = 1;
        }
        activeDaysMap[today] = true;
      } else if (lastActiveDate === yesterday) {
        // Continuar racha: ayer fue activo, hoy también
        currentStreak += 1;
        activeDaysMap[today] = true;
      } else if (
        lastActiveDate === undefined ||
        lastActiveDate === null ||
        lastActiveDate === ""
      ) {
        // Primer día o no hay lastActiveDate: empezar racha en 1
        currentStreak = 1;
        activeDaysMap[today] = true;
      } else {
        // Racha rota (último día activo fue hace más de 1 día),
        // empezar de nuevo
        currentStreak = 1;
        activeDaysMap[today] = true;
      }

      // Actualizar mejor racha
      bestStreak = Math.max(bestStreak, currentStreak);

      // Limpiar activeDaysMap: mantener solo últimos 30 días
      const thirtyDaysAgo = formatDateId(getDaysAgo(30));
      const cleanedMap: Record<string, boolean> = {};
      Object.keys(activeDaysMap).forEach((dateKey) => {
        if (dateKey >= thirtyDaysAgo) {
          cleanedMap[dateKey] = true;
        }
      });

      // Valores por defecto si no existen
      const prayersCompletedTotal = (
        currentData["prayersCompletedTotal"] ?? 0
      ) as number;
      const versesReadTotal = (currentData["versesReadTotal"] ?? 0) as number;
      const postsCreatedTotal = (
        currentData["postsCreatedTotal"] ?? 0
      ) as number;

      // Actualizar o crear documento
      await statsRef.set({
        lastActiveDate: today,
        currentStreak,
        bestStreak,
        activeDaysMap: cleanedMap,
        prayersCompletedTotal,
        versesReadTotal,
        postsCreatedTotal,
        updatedAt: FieldValue.serverTimestamp(),
      }, {merge: true});

      logger.info("markActiveToday success", {
        uid,
        today,
        currentStreak,
        bestStreak,
        wasNew: !exists,
      });

      return {
        ok: true,
        today,
        currentStreak,
        bestStreak,
      };
    } catch (error) {
      const message = error instanceof Error ? error.message : "Unknown error";
      logger.error("markActiveToday failed", {uid, error: message});
      throw new HttpsError("internal", `markActiveToday failed: ${message}`);
    }
  }
);

// Helper function para incrementar contadores
const getStatsRef = (uid: string) => {
  return db.collection("users")
    .doc(uid)
    .collection("spiritualStats")
    .doc("main");
};

const ensureStatsDoc = async (
  statsRef: FirebaseFirestore.DocumentReference
) => {
  const snap = await statsRef.get();
  if (!snap.exists) {
    const today = formatDateId(new Date());
    await statsRef.set({
      lastActiveDate: today,
      currentStreak: 1, // Empezar en 1 si es el primer día
      bestStreak: 1,
      activeDaysMap: {[today]: true},
      prayersCompletedTotal: 0,
      versesReadTotal: 0,
      postsCreatedTotal: 0,
      updatedAt: FieldValue.serverTimestamp(),
    }, {merge: true});
  }
};

/**
 * Incrementa el contador de versículos leídos.
 * Region: us-central1, Runtime: nodejs20, Memory: 128MiB
 */
export const incrementVerseRead = onCall(
  {region: "us-central1", memory: "128MiB"},
  async (request) => {
    const uid = request.auth?.uid;
    if (!uid) {
      throw new HttpsError("unauthenticated", "auth_required");
    }

    const statsRef = getStatsRef(uid);
    try {
      await ensureStatsDoc(statsRef);
      await statsRef.update({
        versesReadTotal: FieldValue.increment(1),
        updatedAt: FieldValue.serverTimestamp(),
      });
      logger.info("incrementVerseRead success", {uid});
      return {ok: true};
    } catch (error) {
      const message = error instanceof Error ? error.message : "Unknown error";
      logger.error("incrementVerseRead failed", {uid, error: message});
      throw new HttpsError(
        "internal",
        `incrementVerseRead failed: ${message}`
      );
    }
  }
);

/**
 * Incrementa el contador de oraciones completadas.
 * Region: us-central1, Runtime: nodejs20, Memory: 128MiB
 */
export const incrementPrayerCompleted = onCall(
  {region: "us-central1", memory: "128MiB"},
  async (request) => {
    const uid = request.auth?.uid;
    if (!uid) {
      throw new HttpsError("unauthenticated", "auth_required");
    }

    const statsRef = getStatsRef(uid);
    try {
      await ensureStatsDoc(statsRef);
      await statsRef.update({
        prayersCompletedTotal: FieldValue.increment(1),
        updatedAt: FieldValue.serverTimestamp(),
      });
      logger.info("incrementPrayerCompleted success", {uid});
      return {ok: true};
    } catch (error) {
      const message = error instanceof Error ? error.message : "Unknown error";
      logger.error("incrementPrayerCompleted failed", {uid, error: message});
      throw new HttpsError(
        "internal",
        `incrementPrayerCompleted failed: ${message}`
      );
    }
  }
);

/**
 * Incrementa el contador de publicaciones creadas.
 * Region: us-central1, Runtime: nodejs20, Memory: 128MiB
 */
export const incrementPostCreated = onCall(
  {region: "us-central1", memory: "128MiB"},
  async (request) => {
    const uid = request.auth?.uid;
    if (!uid) {
      throw new HttpsError("unauthenticated", "auth_required");
    }

    const statsRef = getStatsRef(uid);
    try {
      await ensureStatsDoc(statsRef);
      await statsRef.update({
        postsCreatedTotal: FieldValue.increment(1),
        updatedAt: FieldValue.serverTimestamp(),
      });
      logger.info("incrementPostCreated success", {uid});
      return {ok: true};
    } catch (error) {
      const message = error instanceof Error ? error.message : "Unknown error";
      logger.error("incrementPostCreated failed", {uid, error: message});
      throw new HttpsError(
        "internal",
        `incrementPostCreated failed: ${message}`
      );
    }
  }
);

/**
 * Incrementa la racha cuando se completan todas las misiones del día.
 * Esta función asegura que la racha se incremente correctamente incluso
 * si markActiveToday ya fue llamado antes.
 * Region: us-central1, Runtime: nodejs20, Memory: 256MiB
 */
export const completeAllMissions = onCall(
  {region: "us-central1", memory: "256MiB"},
  async (request) => {
    const uid = request.auth?.uid;
    if (!uid) {
      throw new HttpsError("unauthenticated", "auth_required");
    }

    const now = new Date();
    const today = formatDateId(now);
    const yesterday = formatDateId(getDaysAgo(1));

    const statsRef = getStatsRef(uid);

    try {
      await ensureStatsDoc(statsRef);
      const statsSnap = await statsRef.get();
      const currentData = statsSnap.data() ?? {};

      const lastActiveDate = currentData["lastActiveDate"] as
        string | undefined;
      let currentStreak = (currentData["currentStreak"] ?? 0) as number;
      let bestStreak = (currentData["bestStreak"] ?? 0) as number;
      const activeDaysMap = (
        currentData["activeDaysMap"] as Record<string, boolean> | undefined
      ) ?? {};

      // Lógica de racha al completar todas las misiones
      if (lastActiveDate === today) {
        // Ya marcado hoy: si la racha es 0, establecerla a 1
        // Si la racha ya es > 0, mantenerla (ya se incrementó antes)
        if (currentStreak === 0) {
          currentStreak = 1;
        }
      } else if (lastActiveDate === yesterday) {
        // Ayer fue activo: incrementar racha
        currentStreak += 1;
      } else if (
        lastActiveDate === undefined ||
        lastActiveDate === null ||
        lastActiveDate === ""
      ) {
        // Primer día: empezar racha en 1
        currentStreak = 1;
      } else {
        // Racha rota: empezar de nuevo
        currentStreak = 1;
      }

      // Asegurar que hoy está en el mapa
      activeDaysMap[today] = true;

      // Actualizar mejor racha
      bestStreak = Math.max(bestStreak, currentStreak);

      // Limpiar activeDaysMap: mantener solo últimos 30 días
      const thirtyDaysAgo = formatDateId(getDaysAgo(30));
      const cleanedMap: Record<string, boolean> = {};
      Object.keys(activeDaysMap).forEach((dateKey) => {
        if (dateKey >= thirtyDaysAgo) {
          cleanedMap[dateKey] = true;
        }
      });

      // Preservar contadores existentes
      const prayersCompletedTotal = (
        currentData["prayersCompletedTotal"] ?? 0
      ) as number;
      const versesReadTotal = (currentData["versesReadTotal"] ?? 0) as number;
      const postsCreatedTotal = (
        currentData["postsCreatedTotal"] ?? 0
      ) as number;

      // Actualizar documento
      await statsRef.set(
        {
          lastActiveDate: today,
          currentStreak,
          bestStreak,
          activeDaysMap: cleanedMap,
          prayersCompletedTotal,
          versesReadTotal,
          postsCreatedTotal,
          updatedAt: FieldValue.serverTimestamp(),
        },
        {merge: true}
      );

      logger.info("completeAllMissions success", {
        uid,
        today,
        currentStreak,
        bestStreak,
      });

      return {
        ok: true,
        today,
        currentStreak,
        bestStreak,
      };
    } catch (error) {
      const message = error instanceof Error ? error.message : "Unknown error";
      logger.error("completeAllMissions failed", {uid, error: message});
      throw new HttpsError(
        "internal",
        `completeAllMissions failed: ${message}`
      );
    }
  }
);
