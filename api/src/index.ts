import {setGlobalOptions} from "firebase-functions";
import {onRequest} from "firebase-functions/https";
import {onCall, HttpsError} from "firebase-functions/v2/https";
import {user} from "firebase-functions/v1/auth";
import * as admin from "firebase-admin";
import * as logger from "firebase-functions/logger";
import {FieldValue, Timestamp} from "firebase-admin/firestore";
// eslint-disable-next-line import/no-unresolved
import Groq from "groq-sdk";
// eslint-disable-next-line import/no-unresolved
import {GROQ_API_KEY} from "./secrets/groq.secrets";
import {CHAT_PROMPT, FREE_TIER_CHAT_DAILY_LIMIT, GROQ_MAX_COMPLETION_TOKENS,
  GROQ_MODEL, GROQ_TEMPERATURE} from "./groqConfig";
import {ChatMessage, ChatRequest, ChatResponse} from "./chat.interfaces";

setGlobalOptions({maxInstances: 10});

if (admin.apps.length === 0) {
  admin.initializeApp();
}

const db = admin.firestore();
const TEST_LIVE_POST_TEXT = "Oración de prueba";
const LIVE_POST_COOLDOWN_MS = 10_000;
const USERNAME_REGEX = /^[a-z0-9._]{3,20}$/;
const USERNAME_LOCKS_COLLECTION = "username_locks";
const LEGACY_USERNAME_MAP_COLLECTION = "username_map";

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
  if (elapsed < LIVE_POST_COOLDOWN_MS) {
    const wait = Math.ceil((LIVE_POST_COOLDOWN_MS - elapsed) / 1000);
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
      displayName:
        authorProfile.displayName ??
        userSnap.get("displayName") ??
        authorProfile.username ??
        uid,
      photoURL: authorProfile.photoURL ?? userSnap.get("photoURL") ?? null,
      isPublic: userSnap.exists ? userSnap.get("isPublic") ?? true : true,
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
  if (!USERNAME_REGEX.test(trimmed)) {
    throw new HttpsError("invalid-argument", "username_invalid");
  }
  return trimmed;
};

const normalizeStoredUsername = (value: unknown): string | null => {
  if (typeof value !== "string") return null;
  const normalized = value.trim().toLowerCase();
  if (!USERNAME_REGEX.test(normalized)) return null;
  return normalized;
};

const usernameLocks = () => db.collection(USERNAME_LOCKS_COLLECTION);

const assignUsernameForUid = async (
  uid: string,
  rawUsername: string,
): Promise<string> => {
  const username = normalizeUsername(rawUsername);
  const usernameDoc = usernameLocks().doc(username);
  const userDoc = db.collection("users").doc(uid);

  await db.runTransaction(async (tx) => {
    const userSnap = await tx.get(userDoc);
    const userData = userSnap.data() ?? {};
    const prevLower = normalizeStoredUsername(userData.usernameLower) ??
      normalizeStoredUsername(userData.username) ??
      undefined;
    const usernameSnap = await tx.get(usernameDoc);
    const legacyCurrentRef = db.collection(LEGACY_USERNAME_MAP_COLLECTION)
      .doc(username);
    const legacyCurrentSnap = await tx.get(legacyCurrentRef);

    let prevDoc: FirebaseFirestore.DocumentReference | null = null;
    let prevSnap: FirebaseFirestore.DocumentSnapshot | null = null;
    let legacyPrevRef: FirebaseFirestore.DocumentReference | null = null;
    let legacyPrevSnap: FirebaseFirestore.DocumentSnapshot | null = null;

    if (prevLower && prevLower !== username) {
      prevDoc = usernameLocks().doc(prevLower);
      prevSnap = await tx.get(prevDoc);
      legacyPrevRef = db.collection(LEGACY_USERNAME_MAP_COLLECTION).doc(prevLower);
      legacyPrevSnap = await tx.get(legacyPrevRef);
    }

    if (prevLower === username) {
      tx.set(usernameDoc, {
        uid,
        updatedAt: FieldValue.serverTimestamp(),
      }, {merge: true});

      const legacyOwner = legacyCurrentSnap.exists ?
        (legacyCurrentSnap.get("uid") as string | undefined) :
        undefined;
      if (legacyOwner === uid) {
        tx.delete(legacyCurrentRef);
      }

      tx.set(userDoc, {
        username,
        usernameLower: username,
        updatedAt: FieldValue.serverTimestamp(),
      }, {merge: true});
      return;
    }

    if (usernameSnap.exists) {
      const owner = usernameSnap.get("uid") as string | undefined;
      if (owner !== uid) {
        throw new HttpsError("already-exists", "username_taken");
      }
    }

    const existingUserWithUsername = await tx.get(
      db.collection("users")
        .where("usernameLower", "==", username)
        .limit(1),
    );
    if (!existingUserWithUsername.empty) {
      const ownerUid = existingUserWithUsername.docs[0].id;
      if (ownerUid !== uid) {
        throw new HttpsError("already-exists", "username_taken");
      }
    }

    tx.set(
      usernameDoc,
      {
        uid,
        createdAt: usernameSnap.exists ?
          usernameSnap.get("createdAt") ?? FieldValue.serverTimestamp() :
          FieldValue.serverTimestamp(),
        updatedAt: FieldValue.serverTimestamp(),
      },
      {merge: false},
    );

    if (prevDoc && prevSnap) {
      const prevOwner = prevSnap.exists ?
        (prevSnap.get("uid") as string | undefined) :
        undefined;
      if (prevOwner === uid) {
        tx.delete(prevDoc);
      }

      if (legacyPrevRef && legacyPrevSnap) {
        const legacyPrevOwner = legacyPrevSnap.exists ?
          (legacyPrevSnap.get("uid") as string | undefined) :
          undefined;
        if (legacyPrevOwner === uid) {
          tx.delete(legacyPrevRef);
        }
      }

      const legacyOwner = legacyCurrentSnap.exists ?
        (legacyCurrentSnap.get("uid") as string | undefined) :
        undefined;
      if (legacyOwner === uid) {
        tx.delete(legacyCurrentRef);
      }
    }

    tx.set(userDoc, {
      username,
      usernameLower: username,
      updatedAt: FieldValue.serverTimestamp(),
    }, {merge: true});
  });

  return username;
};

const buildUsernameCandidate = (
  baseUsername: string,
  uid: string,
  attempt: number,
): string => {
  const base = normalizeUsername(baseUsername);
  const suffixSeed = `_${uid.slice(0, 4).toLowerCase()}`;
  const numbered = attempt > 0 ? `${suffixSeed}${attempt}` : suffixSeed;
  const maxBaseLength = 20 - numbered.length;
  const trimmedBase = base.slice(0, Math.max(3, maxBaseLength));
  return `${trimmedBase}${numbered}`;
};

const assignAvailableUsername = async (
  uid: string,
  preferredBase: string,
): Promise<string> => {
  for (let attempt = 0; attempt <= 50; attempt += 1) {
    const candidate = buildUsernameCandidate(preferredBase, uid, attempt);
    try {
      return await assignUsernameForUid(uid, candidate);
    } catch (error) {
      const isTaken =
        error instanceof HttpsError &&
        error.code === "already-exists" &&
        error.message === "username_taken";
      if (!isTaken) {
        throw error;
      }
    }
  }
  throw new HttpsError("resource-exhausted", "username_generation_failed");
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
  const username = await assignUsernameForUid(uid, raw);

  return {ok: true, username};
});

export const cleanupUserProfileOnDelete = user().onDelete(async (userRecord) => {
  const uid = userRecord.uid;

  const userDoc = db.collection("users").doc(uid);
  await db.runTransaction(async (tx) => {
    const userSnap = await tx.get(userDoc);
    const userData = userSnap.data() ?? {};
    const usernameLower = normalizeStoredUsername(userData.usernameLower) ??
      normalizeStoredUsername(userData.username) ??
      undefined;

    if (usernameLower) {
      const lockRef = usernameLocks().doc(usernameLower);
      const lockSnap = await tx.get(lockRef);
      const legacyRef = db.collection(LEGACY_USERNAME_MAP_COLLECTION)
        .doc(usernameLower);
      const legacySnap = await tx.get(legacyRef);

      const owner = lockSnap.exists ?
        (lockSnap.get("uid") as string | undefined) :
        undefined;
      if (owner === uid) {
        tx.delete(lockRef);
      }

      const legacyOwner = legacySnap.exists ?
        (legacySnap.get("uid") as string | undefined) :
        undefined;
      if (legacyOwner === uid) {
        tx.delete(legacyRef);
      }
    }

    if (userSnap.exists) {
      tx.delete(userDoc);
    }
  });

  const additionalLocks = await usernameLocks().where("uid", "==", uid).get();
  if (!additionalLocks.empty) {
    const batch = db.batch();
    for (const doc of additionalLocks.docs) {
      batch.delete(doc.ref);
    }
    await batch.commit();
  }

  const legacyLocks = await db.collection(LEGACY_USERNAME_MAP_COLLECTION)
    .where("uid", "==", uid)
    .get();
  if (!legacyLocks.empty) {
    const batch = db.batch();
    for (const doc of legacyLocks.docs) {
      batch.delete(doc.ref);
    }
    await batch.commit();
  }
});

type UsernameUserRecord = {
  uid: string;
  createdAtMs: number;
};

const getCreatedAtMs = (value: unknown): number => {
  if (value instanceof Timestamp) {
    return value.toMillis();
  }
  return Number.MAX_SAFE_INTEGER;
};

export const migrateDuplicateUsernames = onRequest(async (req, res) => {
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

    const body = (req.body as {dryRun?: unknown}) || {};
    const dryRun = body.dryRun === true || req.query.dryRun === "true";

    const usersSnap = await db.collection("users").get();
    const usernameOwners = new Map<string, UsernameUserRecord[]>();

    for (const doc of usersSnap.docs) {
      const data = doc.data();
      const username = normalizeStoredUsername(data.usernameLower) ??
        normalizeStoredUsername(data.username);
      if (!username) {
        continue;
      }
      const current = usernameOwners.get(username) ?? [];
      current.push({
        uid: doc.id,
        createdAtMs: getCreatedAtMs(data.createdAt),
      });
      usernameOwners.set(username, current);
    }

    const duplicateEntries = Array.from(usernameOwners.entries())
      .filter(([, owners]) => owners.length > 1);
    const renamed: Array<{uid: string; old: string; next: string}> = [];

    if (!dryRun) {
      for (const [username, owners] of duplicateEntries) {
        owners.sort((a, b) => {
          if (a.createdAtMs === b.createdAtMs) {
            return a.uid.localeCompare(b.uid);
          }
          return a.createdAtMs - b.createdAtMs;
        });

        const keeper = owners[0];
        await assignUsernameForUid(keeper.uid, username);

        for (const owner of owners.slice(1)) {
          const next = await assignAvailableUsername(owner.uid, username);
          renamed.push({uid: owner.uid, old: username, next});
        }
      }
    }

    res.json({
      ok: true,
      dryRun,
      scannedUsers: usersSnap.size,
      duplicatedUsernames: duplicateEntries.length,
      duplicateUsersAffected: duplicateEntries.reduce(
        (acc, [, owners]) => acc + owners.length,
        0,
      ),
      renamedCount: renamed.length,
      renamed,
    });
  } catch (error) {
    const message = error instanceof Error ? error.message : String(error);
    logger.error("migrateDuplicateUsernames error", {error: message});
    const status = (error as {status?: number}).status ?? 500;
    res.status(status).json({ok: false, error: message});
  }
});

export const migrateUsernameMapToLocks = onRequest(async (req, res) => {
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

    const body = (req.body as {
      dryRun?: unknown;
      deleteLegacy?: unknown;
      forceOverwrite?: unknown;
    }) || {};

    const dryRun = body.dryRun === true || req.query.dryRun === "true";
    const deleteLegacy =
      body.deleteLegacy === true || req.query.deleteLegacy === "true";
    const forceOverwrite =
      body.forceOverwrite === true || req.query.forceOverwrite === "true";

    const legacySnap = await db.collection(LEGACY_USERNAME_MAP_COLLECTION).get();
    let processed = 0;
    let migrated = 0;
    let deletedLegacy = 0;
    let skippedInvalid = 0;
    let skippedMissingUid = 0;
    let conflicts = 0;
    const conflictDetails: Array<{username: string; lockUid: string; mapUid: string}> = [];

    if (!dryRun) {
      let batch = db.batch();
      let ops = 0;
      const flush = async () => {
        if (ops === 0) return;
        await batch.commit();
        batch = db.batch();
        ops = 0;
      };

      for (const legacyDoc of legacySnap.docs) {
        processed += 1;
        const legacyData = legacyDoc.data();
        const username = normalizeStoredUsername(legacyDoc.id);
        const uid = typeof legacyData.uid === "string" ? legacyData.uid : "";

        if (!username) {
          skippedInvalid += 1;
          continue;
        }
        if (!uid) {
          skippedMissingUid += 1;
          continue;
        }

        const lockRef = usernameLocks().doc(username);
        const lockSnap = await lockRef.get();
        if (lockSnap.exists) {
          const lockUid = lockSnap.get("uid") as string | undefined;
          if (lockUid && lockUid !== uid && !forceOverwrite) {
            conflicts += 1;
            conflictDetails.push({username, lockUid, mapUid: uid});
            continue;
          }
        }

        const createdAt = legacyData.createdAt ?? FieldValue.serverTimestamp();
        batch.set(lockRef, {
          uid,
          createdAt,
          updatedAt: FieldValue.serverTimestamp(),
          migratedFrom: LEGACY_USERNAME_MAP_COLLECTION,
        }, {merge: true});
        ops += 1;
        migrated += 1;

        if (deleteLegacy) {
          batch.delete(legacyDoc.ref);
          ops += 1;
          deletedLegacy += 1;
        }

        if (ops >= 450) {
          await flush();
        }
      }

      await flush();
    } else {
      for (const legacyDoc of legacySnap.docs) {
        processed += 1;
        const legacyData = legacyDoc.data();
        const username = normalizeStoredUsername(legacyDoc.id);
        const uid = typeof legacyData.uid === "string" ? legacyData.uid : "";

        if (!username) {
          skippedInvalid += 1;
          continue;
        }
        if (!uid) {
          skippedMissingUid += 1;
          continue;
        }

        const lockRef = usernameLocks().doc(username);
        const lockSnap = await lockRef.get();
        if (lockSnap.exists) {
          const lockUid = lockSnap.get("uid") as string | undefined;
          if (lockUid && lockUid !== uid && !forceOverwrite) {
            conflicts += 1;
            conflictDetails.push({username, lockUid, mapUid: uid});
            continue;
          }
        }

        migrated += 1;
        if (deleteLegacy) {
          deletedLegacy += 1;
        }
      }
    }

    res.json({
      ok: true,
      dryRun,
      deleteLegacy,
      forceOverwrite,
      scanned: legacySnap.size,
      processed,
      migrated,
      deletedLegacy,
      conflicts,
      skippedInvalid,
      skippedMissingUid,
      conflictDetails,
    });
  } catch (error) {
    const message = error instanceof Error ? error.message : String(error);
    logger.error("migrateUsernameMapToLocks error", {error: message});
    const status = (error as {status?: number}).status ?? 500;
    res.status(status).json({ok: false, error: message});
  }
});

// ---------------------------
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

const checkChatRateLimit = async (uid: string): Promise<void> => {
  const today = toDateId(new Date());
  const userRef = db.collection("users").doc(uid);
  const chatLimitRef = userRef.collection("chat_limits").doc(today);

  const now = new Date();
  const nextResetAt = new Date(
    Date.UTC(
      now.getUTCFullYear(),
      now.getUTCMonth(),
      now.getUTCDate() + 1,
      0,
      0,
      0,
      0,
    ),
  );

  await db.runTransaction(async (tx) => {
    const limitDoc = await tx.get(chatLimitRef);
    const currentCount = limitDoc.exists ?
      (limitDoc.get("count") as number | undefined) ?? 0 : 0;

    if (currentCount >= FREE_TIER_CHAT_DAILY_LIMIT) {
      throw new HttpsError(
        "resource-exhausted",
        "Has alcanzado el límite de 5 mensajes diarios.",
        {
          resetAt: nextResetAt.toISOString(),
          resetAtEpochMs: nextResetAt.getTime(),
          timezone: "UTC",
        },
      );
    }

    // Increment counter
    if (limitDoc.exists) {
      tx.update(chatLimitRef, {
        count: FieldValue.increment(1),
        lastMessageAt: FieldValue.serverTimestamp(),
      });
    } else {
      tx.set(chatLimitRef, {
        count: 1,
        createdAt: FieldValue.serverTimestamp(),
        lastMessageAt: FieldValue.serverTimestamp(),
      });
    }
  });
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

    const uid = request.auth.uid;

    // Check rate limit
    await checkChatRateLimit(uid);

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
    // NO establecer racha aquí - solo crear el documento con contadores en 0
    // La racha solo se debe actualizar cuando se completan TODAS las misiones
    // (a través de completeAllMissions o markActiveToday)
    await statsRef.set({
      // Empezar en 0, se actualizará cuando se completen todas las misiones
      currentStreak: 0,
      bestStreak: 0,
      activeDaysMap: {},
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

    // Usar la fecha del cliente si se proporciona, sino usar la fecha
    // del servidor. Esto asegura consistencia con la fecha local del
    // dispositivo del usuario
    const clientDateId = request.data?.dateId as string | undefined;
    let today: string;
    let yesterday: string;

    if (clientDateId && /^\d{4}-\d{2}-\d{2}$/.test(clientDateId)) {
      // Usar la fecha del cliente (fecha local del dispositivo)
      today = clientDateId;
      // Calcular ayer basado en la fecha del cliente
      const [year, month, day] = clientDateId.split("-").map(Number);
      const clientDate = new Date(Date.UTC(year, month - 1, day));
      clientDate.setUTCDate(clientDate.getUTCDate() - 1);
      yesterday = formatDateId(clientDate);
      logger.info("completeAllMissions using client date", {
        uid,
        clientDateId,
        today,
        yesterday,
      });
    } else {
      // Fallback: usar fecha del servidor (UTC)
      const now = new Date();
      today = formatDateId(now);
      yesterday = formatDateId(getDaysAgo(1));
      logger.info("completeAllMissions using server date", {
        uid,
        today,
        yesterday,
      });
    }

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
