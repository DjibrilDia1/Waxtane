// ignore_for_file: deprecated_member_use

import 'package:flutter/material.dart';
import 'package:firebase_database/firebase_database.dart';
import '../Services/chat_services.dart';

class ChatScreen extends StatefulWidget {
  const ChatScreen({
    super.key,
    required this.currentEmail,
    required this.contactEmail,
    required this.contactName,
  });

  final String currentEmail;
  final String contactEmail;
  final String contactName;

  @override
  State<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen> {
  final _chatService = ChatService();
  final _controller = TextEditingController();
  final _scrollController = ScrollController();
  String _currentUserName = '';

  @override
  void initState() {
    super.initState();
    _loadCurrentUserName();
  }

  // Charger le nom de l'utilisateur connecté
  Future<void> _loadCurrentUserName() async {
    try {
      final encodedEmail = _encodeEmail(widget.currentEmail);
      final snapshot = await FirebaseDatabase.instance
          .ref('users/$encodedEmail')
          .get();
      
      if (snapshot.exists) {
        final data = snapshot.value as Map<dynamic, dynamic>;
        setState(() {
          _currentUserName = data['username']?.toString() ?? 'Vous';
        });
      }
    } catch (e) {
      // ignore: avoid_print
      print('Erreur chargement nom: $e');
    }
  }

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

  Future<void> _sendMessage() async {
    final msg = _controller.text.trim();
    if (msg.isEmpty) return;

    try {
      await _chatService.sendMessage(
        senderId: widget.currentEmail,
        receiverId: widget.contactEmail,
        text: msg,
      );
      _controller.clear();
      
      // Scroller vers le bas
      Future.delayed(const Duration(milliseconds: 100), () {
        if (_scrollController.hasClients) {
          _scrollController.animateTo(
            _scrollController.position.maxScrollExtent,
            duration: const Duration(milliseconds: 300),
            curve: Curves.easeOut,
          );
        }
      });
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Erreur: $e')),
        );
      }
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: const Color(0xFF3AB78D),
        foregroundColor: Colors.white,
        title: Row(
          children: [
            CircleAvatar(
              backgroundColor: Colors.white,
              child: Text(
                widget.contactName.isNotEmpty 
                    ? widget.contactName[0].toUpperCase() 
                    : 'U',
                style: const TextStyle(
                  color: Color(0xFF3AB78D),
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    widget.contactName,
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  Text(
                    widget.contactEmail,
                    style: const TextStyle(
                      fontSize: 12,
                      color: Colors.white70,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
      body: Column(
        children: [
          Expanded(
            child: StreamBuilder<DatabaseEvent>(
              stream: _chatService.conversationMessagesStream(
                widget.currentEmail,
                widget.contactEmail,
              ),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }
                
                if (snapshot.hasError) {
                  return Center(child: Text('Erreur: ${snapshot.error}'));
                }

                final raw = snapshot.data?.snapshot.value as Map<dynamic, dynamic>?;
                
                if (raw == null || raw.isEmpty) {
                  return Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.chat_bubble_outline,
                          size: 64,
                          color: Colors.grey.shade300,
                        ),
                        const SizedBox(height: 16),
                        const Text(
                          "Aucun message",
                          style: TextStyle(
                            fontSize: 18,
                            color: Colors.grey,
                          ),
                        ),
                        const SizedBox(height: 8),
                        const Text(
                          "Envoyez le premier message !",
                          style: TextStyle(
                            fontSize: 14,
                            color: Colors.grey,
                          ),
                        ),
                      ],
                    ),
                  );
                }

                final messages = raw.entries
                    .map((e) {
                      final data = e.value as Map<dynamic, dynamic>;
                      final sender = data['senderId']?.toString() ?? '';
                      final text = data['text']?.toString() ?? '';
                      final tsRaw = data['timestamp'];
                      
                      int ts = 0;
                      if (tsRaw is int) {
                        ts = tsRaw;
                      } else if (tsRaw is String) {
                        ts = DateTime.tryParse(tsRaw)?.millisecondsSinceEpoch ?? 0;
                      }
                      
                      return {
                        'id': e.key.toString(),
                        'sender': sender,
                        'text': text,
                        'timestamp': ts,
                      };
                    })
                    .toList()
                  ..sort((a, b) => (a['timestamp'] as int).compareTo(b['timestamp'] as int));

                WidgetsBinding.instance.addPostFrameCallback((_) {
                  if (_scrollController.hasClients) {
                    _scrollController.jumpTo(_scrollController.position.maxScrollExtent);
                  }
                });

                return ListView.builder(
                  controller: _scrollController,
                  padding: const EdgeInsets.all(12),
                  itemCount: messages.length,
                  itemBuilder: (context, index) {
                    final msg = messages[index];
                    final sender = msg['sender'] as String;
                    final isMe = sender.toLowerCase() == widget.currentEmail.toLowerCase();
                    
                    return Align(
                      alignment: isMe ? Alignment.centerRight : Alignment.centerLeft,
                      child: Container(
                        margin: const EdgeInsets.symmetric(vertical: 4),
                        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                        constraints: BoxConstraints(
                          maxWidth: MediaQuery.of(context).size.width * 0.7,
                        ),
                        decoration: BoxDecoration(
                          color: isMe ? const Color(0xFF3AB78D) : Colors.grey.shade300,
                          borderRadius: BorderRadius.only(
                            topLeft: const Radius.circular(12),
                            topRight: const Radius.circular(12),
                            bottomLeft: isMe ? const Radius.circular(12) : Radius.zero,
                            bottomRight: isMe ? Radius.zero : const Radius.circular(12),
                          ),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withOpacity(0.1),
                              blurRadius: 3,
                              offset: const Offset(0, 1),
                            ),
                          ],
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            // Afficher le nom de l'expéditeur
                            Text(
                              isMe 
                                  ? (_currentUserName.isNotEmpty ? _currentUserName : 'Vous')
                                  : widget.contactName,
                              style: TextStyle(
                                color: isMe ? Colors.white : Colors.black87,
                                fontSize: 11,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              msg['text'] as String,
                              style: TextStyle(
                                color: isMe ? Colors.white : Colors.black87,
                                fontSize: 15,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              _formatTime(msg['timestamp'] as int),
                              style: TextStyle(
                                color: isMe ? Colors.white70 : Colors.black54,
                                fontSize: 11,
                              ),
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                );
              },
            ),
          ),

          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: Colors.white,
              boxShadow: [
                BoxShadow(
                  color: Colors.grey.shade300,
                  blurRadius: 4,
                  offset: const Offset(0, -2),
                ),
              ],
            ),
            child: SafeArea(
              child: Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: _controller,
                      decoration: InputDecoration(
                        hintText: 'Écrire un message...',
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(25),
                          borderSide: BorderSide.none,
                        ),
                        filled: true,
                        fillColor: Colors.grey.shade100,
                        contentPadding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 10,
                        ),
                      ),
                      maxLines: null,
                      textInputAction: TextInputAction.send,
                      onSubmitted: (_) => _sendMessage(),
                    ),
                  ),
                  const SizedBox(width: 8),
                  CircleAvatar(
                    backgroundColor: const Color(0xFF3AB78D),
                    child: IconButton(
                      icon: const Icon(Icons.send, color: Colors.white, size: 20),
                      onPressed: _sendMessage,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  String _formatTime(int timestamp) {
    final date = DateTime.fromMillisecondsSinceEpoch(timestamp);
    final now = DateTime.now();
    
    if (date.day == now.day && date.month == now.month && date.year == now.year) {
      return '${date.hour.toString().padLeft(2, '0')}:${date.minute.toString().padLeft(2, '0')}';
    } else {
      return '${date.day}/${date.month} ${date.hour.toString().padLeft(2, '0')}:${date.minute.toString().padLeft(2, '0')}';
    }
  }
}