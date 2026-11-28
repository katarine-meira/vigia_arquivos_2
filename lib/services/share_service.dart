import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/file_model.dart';
import '../models/share_model.dart';

class ShareService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  CollectionReference get _sharesCollection => _firestore.collection('shares');

  Future<List<ShareModel>> createShares({
    required FileModel file,
    required String ownerId,
    required String ownerEmail,
    required List<String> recipientEmails,
    required bool canView,
    required bool canDownload,
    required bool canReshare,
    bool viewOnce = false,
    DateTime? expiresAt,
  }) async {
    final created = <ShareModel>[];

    for (final recipient in recipientEmails) {
      final shareData = {
        'fileId': file.id,
        'fileName': file.fileName,
        'fileSize': file.fileSize,
        'mimeType': file.mimeType,
        'localPath': file.localPath,
        'ownerId': ownerId,
        'ownerEmail': ownerEmail.toLowerCase().trim(),
        'recipientEmail': recipient.toLowerCase().trim(),
        'permissions': {
          'canView': canView,
          'canDownload': canDownload,
          'canReshare': canReshare,
          'viewOnce': viewOnce,
        },
        'expiresAt': expiresAt != null ? Timestamp.fromDate(expiresAt) : null,
        'isRevoked': false,
        'hasOpened': false,
        'createdAt': FieldValue.serverTimestamp(),
      };

      final docRef = await _sharesCollection.add(shareData);
      final docSnapshot = await docRef.get();
      created.add(ShareModel.fromFirestore(docSnapshot));
    }

    return created;
  }

  // atualiza permissões, validade ou reativa um compartilhamento existente
  Future<void> updateShare({
    required String shareId,
    required bool canView,
    required bool canDownload,
    required bool canReshare,
    DateTime? expiresAt,
    bool? isRevoked,
  }) async {
    final updateData = <String, dynamic>{
      'permissions': {
        'canView': canView,
        'canDownload': canDownload,
        'canReshare': canReshare,
      },
      'expiresAt': expiresAt != null ? Timestamp.fromDate(expiresAt) : null,
    };

    if (isRevoked != null) {
      updateData['isRevoked'] = isRevoked;
    }

    await _sharesCollection.doc(shareId).update(updateData);
  }

  // Retorna compartilhamentos criados por mim
  Stream<List<ShareModel>> getMySharesStream(String ownerId) {
    return _sharesCollection
        .where('ownerId', isEqualTo: ownerId)
        .snapshots()
        .map((snapshot) {
      final list = snapshot.docs.map((doc) => ShareModel.fromFirestore(doc)).toList();
      list.sort((a, b) => b.createdAt.compareTo(a.createdAt));
      return list;
    });
  }

  // Retorna arquivos compartilhados comigo
  Stream<List<ShareModel>> getSharesWithMeStream(String myEmail) {
    final cleanEmail = myEmail.toLowerCase().trim();
    return _sharesCollection
        .where('recipientEmail', isEqualTo: cleanEmail)
        .snapshots()
        .map((snapshot) {
      final list = snapshot.docs.map((doc) => ShareModel.fromFirestore(doc)).toList();
      list.sort((a, b) => b.createdAt.compareTo(a.createdAt));
      return list;
    });
  }

  // Revoga o acesso a um arquivo compartilhado
  Future<void> revokeShare(String shareId) async {
    await _sharesCollection.doc(shareId).update({
      'isRevoked': true,
    });
  }

  // Marca que o destinatário visualizou o compartilhamento
  Future<void> markShareAsViewed(String shareId) async {
    try {
      await _sharesCollection.doc(shareId).update({
        'isViewed': true,
        'viewedAt': FieldValue.serverTimestamp(),
      });
    } catch (_) {}
  }

  // Marca que o documento de visualização única foi aberto
  Future<void> markViewOnceConsumed(String shareId) async {
    try {
      await _sharesCollection.doc(shareId).update({
        'hasOpened': true,
        'openedAt': FieldValue.serverTimestamp(),
      });
    } catch (_) {}
  }

  // Exclui o registro de compartilhamento
  Future<void> deleteShare(String shareId) async {
    await _sharesCollection.doc(shareId).delete();
  }
}
