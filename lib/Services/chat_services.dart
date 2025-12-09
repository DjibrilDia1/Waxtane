import 'package:firebase_database/firebase_database.dart';

class ChatService {
  final DatabaseReference _db = FirebaseDatabase.instance.ref();

  String _encodeEmail(String email) {
    return email
        .toLowerCase()
        .replaceAll('.', ',')
        .replaceAll('@', '_at_')
        .replaceAll('#', '_hash_')
        .replaceAll('\$', '_dollar_')
        .replaceAll('[', '_')
        .replaceAll(']', '_');
  }

  /// Génère un ID de conversation unique pour deux utilisateurs
  /// Toujours dans le même ordre alphabétique pour garantir l'unicité
  String _getConversationId(String email1, String email2) {
    final normalized1 = email1.toLowerCase();
    final normalized2 = email2.toLowerCase();
    
    // Trier alphabétiquement pour avoir toujours le même ID
    final emails = [normalized1, normalized2]..sort();
    
    return '${_encodeEmail(emails[0])}_${_encodeEmail(emails[1])}';
  }

  /// Envoie un message dans une conversation partagée
  Future<void> sendMessage({
    required String senderId,
    required String receiverId,
    required String text,
  }) async {
    try {
      final normalizedSenderId = senderId.toLowerCase();
      final normalizedReceiverId = receiverId.toLowerCase();
      
      // Générer l'ID de conversation
      final conversationId = _getConversationId(normalizedSenderId, normalizedReceiverId);
      
      // Générer un ID unique pour le message
      final msgId = _db.child("conversations/$conversationId/messages").push().key!;
      
      final payload = {
        "msgId": msgId,
        "senderId": normalizedSenderId,
        "receiverId": normalizedReceiverId,
        "text": text,
        "timestamp": ServerValue.timestamp,
      };

      // Écrire le message dans la conversation partagée
      await _db.child("conversations/$conversationId/messages/$msgId").set(payload);
      
      // Mettre à jour les métadonnées de la conversation
      await _db.child("conversations/$conversationId/metadata").set({
        "participants": [normalizedSenderId, normalizedReceiverId],
        "lastMessage": text,
        "lastMessageTime": ServerValue.timestamp,
        "lastSender": normalizedSenderId,
      });
      
    } catch (e) {
      throw Exception("Erreur lors de l'envoi du message: $e");
    }
  }

  /// Stream des messages pour une conversation entre deux utilisateurs
  Stream<DatabaseEvent> conversationMessagesStream(String userId, String contactId) {
    final conversationId = _getConversationId(userId, contactId);
    return _db
        .child("conversations/$conversationId/messages")
        .orderByChild("timestamp")
        .onValue;
  }

  /// Récupère la liste des conversations d'un utilisateur
  Future<List<Map<String, dynamic>>> getUserConversations(String userId) async {
    final normalizedUserId = userId.toLowerCase();
    final encodedUserId = _encodeEmail(normalizedUserId);
    
    // Récupérer toutes les conversations
    final snapshot = await _db.child("conversations").get();
    
    if (!snapshot.exists) return [];

    final data = snapshot.value as Map<dynamic, dynamic>?;
    if (data == null) return [];

    List<Map<String, dynamic>> conversations = [];

    // Filtrer les conversations où l'utilisateur participe
    for (var entry in data.entries) {
      final conversationId = entry.key.toString();
      final conversationData = entry.value as Map<dynamic, dynamic>;
      
      // Vérifier si l'utilisateur fait partie de cette conversation
      if (conversationId.contains(encodedUserId)) {
        final metadata = conversationData['metadata'] as Map<dynamic, dynamic>?;
        
        if (metadata != null) {
          final participants = (metadata['participants'] as List<dynamic>?)
              ?.map((e) => e.toString())
              .toList() ?? [];
          
          // Trouver l'autre participant
          final otherUser = participants.firstWhere(
            (p) => p.toLowerCase() != normalizedUserId,
            orElse: () => '',
          );
          
          if (otherUser.isNotEmpty) {
            conversations.add({
              'conversationId': conversationId,
              'otherUser': otherUser,
              'lastMessage': metadata['lastMessage']?.toString() ?? '',
              'lastMessageTime': metadata['lastMessageTime'] as int? ?? 0,
              'lastSender': metadata['lastSender']?.toString() ?? '',
            });
          }
        }
      }
    }

    // Trier par date du dernier message (plus récent en premier)
    conversations.sort((a, b) => 
      (b['lastMessageTime'] as int).compareTo(a['lastMessageTime'] as int)
    );

    return conversations;
  }
}