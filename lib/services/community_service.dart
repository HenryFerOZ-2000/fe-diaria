import 'dart:math';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';

class CommunityService {
  CommunityService._();
  static final CommunityService _instance = CommunityService._();
  factory CommunityService() => _instance;

  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  Stream<DocumentSnapshot<Map<String, dynamic>>> communityStream(
    String communityId,
  ) {
    return _firestore.collection('communities').doc(communityId).snapshots();
  }

  Stream<QuerySnapshot<Map<String, dynamic>>> communityMembersStream(
    String communityId, {
    int limit = 200,
  }) {
    return _firestore
        .collection('users')
        .where('communityId', isEqualTo: communityId)
        .limit(limit)
        .snapshots();
  }

  /// Feed interno: solo filtro por [communityId] (índice simple automático).
  /// Orden descendente en cliente para no depender de índice compuesto ni de
  /// `orderBy(createdAt)` cuando el timestamp del servidor aún no está indexado.
  Stream<List<QueryDocumentSnapshot<Map<String, dynamic>>>>
  communityPostsStream(String communityId, {int limit = 50}) {
    const fetchCap = 120;
    return _firestore
        .collection('community_posts')
        .where('communityId', isEqualTo: communityId)
        .limit(fetchCap)
        .snapshots(includeMetadataChanges: true)
        .map((snapshot) {
          if (kDebugMode) {
            final sampleIds = snapshot.docs
                .take(3)
                .map((d) => d.data()['communityId']?.toString() ?? '?')
                .join(', ');
            debugPrint(
              '[Verbum/community_posts] filtro communityId=$communityId '
              'rawDocs=${snapshot.docs.length} pending=${snapshot.metadata.hasPendingWrites} '
              'muestraCommunityIdEnDocs=[$sampleIds]',
            );
          }
          final list = List<QueryDocumentSnapshot<Map<String, dynamic>>>.from(
            snapshot.docs,
          );
          list.sort((a, b) {
            final ka = _communityPostSortKey(a.data());
            final kb = _communityPostSortKey(b.data());
            return kb.compareTo(ka);
          });
          if (list.length > limit) {
            return list.sublist(0, limit);
          }
          return list;
        });
  }

  static int _communityPostSortKey(Map<String, dynamic> d) {
    final o = d['createdAtOrder'];
    if (o is int) return o;
    if (o is num) return o.toInt();
    final t = d['createdAt'];
    if (t is Timestamp) return t.millisecondsSinceEpoch;
    return 0;
  }

  Future<String?> findCommunityIdByInviteCode(String inviteCode) async {
    final code = inviteCode.trim().toUpperCase();
    if (code.isEmpty) return null;

    final query = await _firestore
        .collection('communities')
        .where('inviteCode', isEqualTo: code)
        .limit(1)
        .get();
    if (query.docs.isEmpty) return null;
    return query.docs.first.id;
  }

  Future<Map<String, dynamic>?> findCommunityByInviteCode(
    String inviteCode,
  ) async {
    final code = inviteCode.trim().toUpperCase();
    if (code.isEmpty) return null;
    final query = await _firestore
        .collection('communities')
        .where('inviteCode', isEqualTo: code)
        .limit(1)
        .get();
    if (query.docs.isEmpty) return null;
    return <String, dynamic>{
      'id': query.docs.first.id,
      ...query.docs.first.data(),
    };
  }

  /// Caracteres legibles (sin 0/O, 1/I/I confusión).
  static const _inviteAlphabet = 'ABCDEFGHJKLMNPQRSTUVWXYZ23456789';

  /// Genera un código corto y comprueba unicidad contra `communities.inviteCode`.
  Future<String> _generateUniqueInviteCode() async {
    final random = Random.secure();
    for (var attempt = 0; attempt < 15; attempt++) {
      final length = attempt < 10 ? 6 : 8;
      final code = List.generate(
        length,
        (_) => _inviteAlphabet[random.nextInt(_inviteAlphabet.length)],
      ).join();
      final snap = await _firestore
          .collection('communities')
          .where('inviteCode', isEqualTo: code)
          .limit(1)
          .get();
      if (snap.docs.isEmpty) return code;
    }
    throw Exception(
      'No se pudo generar un codigo unico. Intenta de nuevo en unos segundos.',
    );
  }

  /// Crea comunidad, asigna admin al creador y enlaza [users/{uid}.communityId].
  Future<String> createCommunity({
    required String uid,
    String? currentCommunityId,
    required String name,
    required String city,
    required String description,
    String? priestName,
    String? imageUrl,
  }) async {
    if ((currentCommunityId ?? '').trim().isNotEmpty) {
      throw Exception('Ya perteneces a una comunidad. No puedes crear otra.');
    }

    final n = name.trim();
    final c = city.trim();
    final d = description.trim();
    if (n.isEmpty || c.isEmpty) {
      throw Exception('Completa el nombre y la ciudad.');
    }

    final inviteCode = await _generateUniqueInviteCode();
    final communityRef = _firestore.collection('communities').doc();
    final userRef = _firestore.collection('users').doc(uid);

    final batch = _firestore.batch();
    batch.set(communityRef, {
      'name': n,
      'city': c,
      'description': d.isEmpty
          ? 'Una comunidad para crecer y compartir la fe.'
          : d,
      'priestName': (priestName ?? '').trim(),
      'imageUrl': (imageUrl ?? '').trim(),
      'inviteCode': inviteCode,
      'createdAt': FieldValue.serverTimestamp(),
      'createdBy': uid,
      'adminIds': <String>[uid],
      'membersCanPost': true,
      'isVerified': false,
    });
    batch.set(userRef, {
      'communityId': communityRef.id,
      'updatedAt': FieldValue.serverTimestamp(),
    }, SetOptions(merge: true));

    await batch.commit();
    return communityRef.id;
  }

  Future<String> joinCommunityWithCode({
    required String uid,
    required String inviteCode,
    String? currentCommunityId,
  }) async {
    if ((currentCommunityId ?? '').trim().isNotEmpty) {
      throw Exception('Ya perteneces a una comunidad.');
    }

    final communityId = await findCommunityIdByInviteCode(inviteCode);
    if (communityId == null) {
      throw Exception('Codigo no valido. Verifica e intenta nuevamente.');
    }

    await _firestore.collection('users').doc(uid).set({
      'communityId': communityId,
      'updatedAt': FieldValue.serverTimestamp(),
    }, SetOptions(merge: true));

    return communityId;
  }

  Future<void> createCommunityPost({
    required String communityId,
    required String authorId,
    required String text,
    String? authorName,
    String? authorPhotoUrl,
  }) async {
    final trimmedText = text.trim();
    if (trimmedText.isEmpty) {
      throw Exception('Escribe un mensaje para publicar.');
    }

    final communityDoc = await _firestore
        .collection('communities')
        .doc(communityId)
        .get();
    if (!communityDoc.exists) {
      throw Exception('La comunidad no existe.');
    }
    final communityData = communityDoc.data() ?? <String, dynamic>{};
    final adminIdsRaw = (communityData['adminIds'] as List?) ?? const [];
    final adminIds = adminIdsRaw
        .map((id) => id?.toString() ?? '')
        .where((id) => id.isNotEmpty)
        .toSet();
    final isAdmin = adminIds.contains(authorId);
    final membersCanPost = (communityData['membersCanPost'] as bool?) ?? true;

    final userDoc = await _firestore.collection('users').doc(authorId).get();
    final userCommunityId =
        (userDoc.data()?['communityId'] as String?)?.trim() ?? '';
    if (userCommunityId != communityId) {
      throw Exception('Debes pertenecer a esta comunidad para publicar.');
    }
    if (!isAdmin && !membersCanPost) {
      throw Exception(
        'Solo los administradores pueden publicar en esta comunidad.',
      );
    }

    final createdAtOrder = DateTime.now().millisecondsSinceEpoch;
    final ref = await _firestore.collection('community_posts').add({
      'communityId': communityId,
      'authorId': authorId,
      'authorName': (authorName ?? '').trim(),
      'authorPhotoUrl': (authorPhotoUrl ?? '').trim(),
      'text': trimmedText,
      'createdAt': FieldValue.serverTimestamp(),
      'createdAtOrder': createdAtOrder,
      'likeCount': 0,
      'commentCount': 0,
    });
    if (kDebugMode) {
      debugPrint(
        '[Verbum/community_posts] create ok id=${ref.id} '
        'communityId=$communityId createdAtOrder=$createdAtOrder',
      );
    }
  }

  Future<void> deleteCommunityPost({
    required String postId,
    required String actorUid,
  }) async {
    final postRef = _firestore.collection('community_posts').doc(postId);
    final postSnap = await postRef.get();
    if (!postSnap.exists) {
      throw Exception('La publicacion no existe.');
    }
    final postData = postSnap.data() ?? <String, dynamic>{};
    final communityId = (postData['communityId'] as String?)?.trim() ?? '';
    final authorId = (postData['authorId'] as String?)?.trim() ?? '';
    if (communityId.isEmpty) {
      throw Exception('La publicacion no tiene comunidad asociada.');
    }

    final communitySnap = await _firestore
        .collection('communities')
        .doc(communityId)
        .get();
    final communityData = communitySnap.data() ?? <String, dynamic>{};
    final adminIdsRaw = (communityData['adminIds'] as List?) ?? const [];
    final adminIds = adminIdsRaw
        .map((id) => id?.toString() ?? '')
        .where((id) => id.isNotEmpty)
        .toSet();
    final isAdmin = adminIds.contains(actorUid);
    final isAuthor = authorId == actorUid;
    if (!isAdmin && !isAuthor) {
      throw Exception('No tienes permiso para eliminar esta publicacion.');
    }

    // Eliminacion segura en cliente: primero subcolecciones conocidas, luego post.
    await _deleteCollection(postRef.collection('likes'));
    final commentsSnap = await postRef.collection('comments').get();
    for (final comment in commentsSnap.docs) {
      await _deleteCollection(comment.reference.collection('likes'));
      await comment.reference.delete();
    }
    await postRef.delete();
  }

  Future<void> _deleteCollection(
    CollectionReference<Map<String, dynamic>> collectionRef,
  ) async {
    while (true) {
      final snap = await collectionRef.limit(200).get();
      if (snap.docs.isEmpty) break;
      final batch = _firestore.batch();
      for (final doc in snap.docs) {
        batch.delete(doc.reference);
      }
      await batch.commit();
    }
  }

  Future<void> updateCommunityBasicInfo({
    required String communityId,
    required String editorUid,
    required String description,
    required String priestName,
    bool? membersCanPost,
  }) async {
    final communityRef = _firestore.collection('communities').doc(communityId);
    final communityDoc = await communityRef.get();
    if (!communityDoc.exists) {
      throw Exception('La comunidad no existe.');
    }

    final data = communityDoc.data() ?? <String, dynamic>{};
    final adminIdsRaw = (data['adminIds'] as List?) ?? const [];
    final adminIds = adminIdsRaw
        .map((id) => id?.toString() ?? '')
        .where((id) => id.isNotEmpty)
        .toSet();
    if (!adminIds.contains(editorUid)) {
      throw Exception('Solo los administradores pueden editar la comunidad.');
    }

    await communityRef.set({
      'description': description.trim(),
      'priestName': priestName.trim(),
      if (membersCanPost != null) 'membersCanPost': membersCanPost,
      'updatedAt': FieldValue.serverTimestamp(),
    }, SetOptions(merge: true));
  }

  Future<void> addCommunityAdmin({
    required String communityId,
    required String actorUid,
    required String targetUid,
  }) async {
    final cleanTarget = targetUid.trim();
    if (cleanTarget.isEmpty) {
      throw Exception('Ingresa un UID valido.');
    }

    final communityRef = _firestore.collection('communities').doc(communityId);
    final userRef = _firestore.collection('users').doc(cleanTarget);

    await _firestore.runTransaction((tx) async {
      final communitySnap = await tx.get(communityRef);
      if (!communitySnap.exists) {
        throw Exception('La comunidad no existe.');
      }
      final data = communitySnap.data() ?? <String, dynamic>{};
      final createdBy = (data['createdBy'] as String?)?.trim() ?? '';
      if (createdBy != actorUid) {
        throw Exception(
          'Solo el responsable principal puede gestionar administradores.',
        );
      }

      final userSnap = await tx.get(userRef);
      if (!userSnap.exists) {
        throw Exception('El UID ingresado no existe en users.');
      }

      final adminIdsRaw = (data['adminIds'] as List?) ?? const [];
      final adminIds = adminIdsRaw
          .map((id) => id?.toString() ?? '')
          .where((id) => id.isNotEmpty)
          .toSet();
      if (adminIds.contains(cleanTarget)) {
        throw Exception('Ese usuario ya es administrador.');
      }

      tx.update(communityRef, {
        'adminIds': FieldValue.arrayUnion([cleanTarget]),
        'updatedAt': FieldValue.serverTimestamp(),
      });
    });
  }

  Future<void> removeCommunityAdmin({
    required String communityId,
    required String actorUid,
    required String targetUid,
  }) async {
    final cleanTarget = targetUid.trim();
    if (cleanTarget.isEmpty) {
      throw Exception('Ingresa un UID valido.');
    }

    final communityRef = _firestore.collection('communities').doc(communityId);
    await _firestore.runTransaction((tx) async {
      final communitySnap = await tx.get(communityRef);
      if (!communitySnap.exists) {
        throw Exception('La comunidad no existe.');
      }
      final data = communitySnap.data() ?? <String, dynamic>{};
      final createdBy = (data['createdBy'] as String?)?.trim() ?? '';
      if (createdBy != actorUid) {
        throw Exception(
          'Solo el responsable principal puede gestionar administradores.',
        );
      }
      if (cleanTarget == createdBy) {
        throw Exception('No puedes quitar al responsable principal.');
      }

      final adminIdsRaw = (data['adminIds'] as List?) ?? const [];
      final adminIds = adminIdsRaw
          .map((id) => id?.toString() ?? '')
          .where((id) => id.isNotEmpty)
          .toSet();
      if (!adminIds.contains(cleanTarget)) {
        throw Exception('Ese usuario no es administrador.');
      }
      if (adminIds.length <= 1) {
        throw Exception('La comunidad debe tener al menos un administrador.');
      }

      tx.update(communityRef, {
        'adminIds': FieldValue.arrayRemove([cleanTarget]),
        'updatedAt': FieldValue.serverTimestamp(),
      });
    });
  }

  Future<void> transferCommunityLeadership({
    required String communityId,
    required String actorUid,
    required String newOwnerUid,
  }) async {
    final cleanNewOwner = newOwnerUid.trim();
    if (cleanNewOwner.isEmpty) {
      throw Exception('Selecciona un administrador valido.');
    }

    final communityRef = _firestore.collection('communities').doc(communityId);
    await _firestore.runTransaction((tx) async {
      final communitySnap = await tx.get(communityRef);
      if (!communitySnap.exists) {
        throw Exception('La comunidad no existe.');
      }
      final data = communitySnap.data() ?? <String, dynamic>{};
      final createdBy = (data['createdBy'] as String?)?.trim() ?? '';
      if (createdBy != actorUid) {
        throw Exception(
          'Solo el responsable principal puede transferir el liderazgo.',
        );
      }
      if (cleanNewOwner == createdBy) {
        throw Exception('Ese usuario ya es el responsable principal.');
      }

      final adminIdsRaw = (data['adminIds'] as List?) ?? const [];
      final adminIds = adminIdsRaw
          .map((id) => id?.toString() ?? '')
          .where((id) => id.isNotEmpty)
          .toSet();
      if (!adminIds.contains(cleanNewOwner)) {
        throw Exception('Solo puedes transferir a un administrador existente.');
      }

      tx.update(communityRef, {
        'createdBy': cleanNewOwner,
        'adminIds': FieldValue.arrayUnion([cleanNewOwner, createdBy]),
        'updatedAt': FieldValue.serverTimestamp(),
      });
    });
  }

  Future<void> leaveCommunity({
    required String communityId,
    required String uid,
  }) async {
    final communityRef = _firestore.collection('communities').doc(communityId);
    final userRef = _firestore.collection('users').doc(uid);

    await _firestore.runTransaction((tx) async {
      final communitySnap = await tx.get(communityRef);
      if (!communitySnap.exists) {
        throw Exception('La comunidad no existe.');
      }

      final data = communitySnap.data() ?? <String, dynamic>{};
      final createdBy = (data['createdBy'] as String?)?.trim() ?? '';
      if (createdBy == uid) {
        throw Exception(
          'Debes transferir el liderazgo principal antes de salir de la comunidad.',
        );
      }

      final adminIdsRaw = (data['adminIds'] as List?) ?? const [];
      final adminIds = adminIdsRaw
          .map((id) => id?.toString() ?? '')
          .where((id) => id.isNotEmpty)
          .toSet();
      final isAdmin = adminIds.contains(uid);

      tx.set(userRef, {
        'communityId': null,
        'updatedAt': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));

      if (isAdmin) {
        tx.update(communityRef, {
          'adminIds': FieldValue.arrayRemove([uid]),
          'updatedAt': FieldValue.serverTimestamp(),
        });
      }
    });
  }
}
