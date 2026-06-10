import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:teguk/providers/consultation_provider.dart';
import 'package:teguk/presentation/screens/consultation/camera_screen.dart';
import 'package:permission_handler/permission_handler.dart';
import 'dart:convert';

class ChatScreen extends StatefulWidget {
  final String consultationId;
  final String peerName;

  const ChatScreen({
    super.key,
    required this.consultationId,
    required this.peerName,
  });

  @override
  State<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen> {
  final _messageController = TextEditingController();
  final _scrollController = ScrollController();
  String? _myFullName;

  @override
  void initState() {
    super.initState();
    _loadMyName();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context
          .read<ConsultationProvider>()
          .fetchMessages(widget.consultationId)
          .then((_) => _scrollToBottom());
    });
  }

  Future<void> _loadMyName() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() => _myFullName = prefs.getString('fullname'));
  }

  void _scrollToBottom() {
    if (_scrollController.hasClients) {
      _scrollController.animateTo(
        _scrollController.position.maxScrollExtent,
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeOut,
      );
    }
  }

  Future<void> _openCamera() async {
    final status = await Permission.camera.request();
    if (status.isGranted) {
      if (!mounted) return;
      final base64Image = await Navigator.push<String>(
        context,
        MaterialPageRoute(builder: (_) => const CameraScreen()),
      );
      if (base64Image != null && base64Image.isNotEmpty) {
        if (!mounted) return;
        final success = await context
            .read<ConsultationProvider>()
            .sendMessage(widget.consultationId, base64Image);
        if (success) {
          WidgetsBinding.instance.addPostFrameCallback((_) => _scrollToBottom());
        } else {
          if (!mounted) return;
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Gagal mengirim gambar'), backgroundColor: Colors.red),
          );
        }
      }
    } else {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Izin kamera ditolak')),
      );
    }
  }

  Future<void> _sendMessage() async {
    final text = _messageController.text.trim();
    if (text.isEmpty) return;
    _messageController.clear();

    final success = await context
        .read<ConsultationProvider>()
        .sendMessage(widget.consultationId, text);

    if (success) {
      WidgetsBinding.instance
          .addPostFrameCallback((_) => _scrollToBottom());
    } else if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Gagal mengirim pesan'),
          behavior: SnackBarBehavior.floating,
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  @override
  void dispose() {
    _messageController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        title: Row(
          children: [
            CircleAvatar(
              radius: 16,
              backgroundColor: Colors.white.withValues(alpha: 0.3),
              child: const Icon(Icons.person, size: 18, color: Colors.white),
            ),
            const SizedBox(width: 8),
            Text(widget.peerName,
                style: const TextStyle(fontSize: 16)),
          ],
        ),
        backgroundColor: const Color(0xFF2196F3),
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () => context
                .read<ConsultationProvider>()
                .fetchMessages(widget.consultationId)
                .then((_) => _scrollToBottom()),
          ),
        ],
      ),
      body: Column(
        children: [
          Expanded(
            child: Consumer<ConsultationProvider>(
              builder: (context, provider, _) {
                if (provider.isLoading && provider.messages.isEmpty) {
                  return const Center(child: CircularProgressIndicator());
                }
                if (provider.messages.isEmpty) {
                  return Center(
                    child: Text('Belum ada pesan. Mulai percakapan!',
                        style: TextStyle(color: Colors.grey[500])),
                  );
                }
                return ListView.builder(
                  controller: _scrollController,
                  padding: const EdgeInsets.all(16),
                  itemCount: provider.messages.length,
                  itemBuilder: (context, i) {
                    final m = provider.messages[i] as Map<String, dynamic>;
                    final sender = m['sender'] as String? ?? '';
                    final message = m['message'] as String? ?? '';
                    final sentAt = m['sentAt'] as String?;
                    final isMe = sender == _myFullName;

                    return _MessageBubble(
                      sender: sender,
                      message: message,
                      sentAt: sentAt,
                      isMe: isMe,
                    );
                  },
                );
              },
            ),
          ),
          _buildInputBar(),
        ],
      ),
    );
  }

  Widget _buildInputBar() {
    return SafeArea(
      child: Container(
        padding: const EdgeInsets.only(left: 16, right: 8, top: 8, bottom: 8),
        decoration: BoxDecoration(
          color: Colors.white,
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.06),
              blurRadius: 8, offset: const Offset(0, -2),
            ),
          ],
        ),
        child: Row(
          children: [
            IconButton(
              icon: const Icon(Icons.camera_alt, color: Colors.grey),
              onPressed: _openCamera,
            ),
            Expanded(
              child: TextField(
                controller: _messageController,
                decoration: InputDecoration(
                  hintText: 'Ketik pesan...',
                  border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(24),
                      borderSide: BorderSide.none),
                  filled: true,
                  fillColor: Colors.grey[100],
                  contentPadding: const EdgeInsets.symmetric(
                      horizontal: 16, vertical: 10),
                ),
                textCapitalization: TextCapitalization.sentences,
                maxLines: null,
                onSubmitted: (_) => _sendMessage(),
              ),
            ),
            const SizedBox(width: 8),
            Consumer<ConsultationProvider>(
              builder: (_, provider, _) => IconButton(
                onPressed: provider.isLoading ? null : _sendMessage,
                icon: provider.isLoading
                    ? const SizedBox(
                        height: 20, width: 20,
                        child: CircularProgressIndicator(strokeWidth: 2))
                    : const Icon(Icons.send, color: Color(0xFF2196F3)),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _MessageBubble extends StatelessWidget {
  final String sender;
  final String message;
  final String? sentAt;
  final bool isMe;

  const _MessageBubble({
    required this.sender,
    required this.message,
    required this.sentAt,
    required this.isMe,
  });

  String _formatTime(String? iso) {
    if (iso == null) return '';
    final dt = DateTime.parse(iso).toLocal();
    final h = dt.hour.toString().padLeft(2, '0');
    final m = dt.minute.toString().padLeft(2, '0');
    return '$h:$m';
  }

  @override
  Widget build(BuildContext context) {
    final isImage = message.startsWith('data:image/');
    
    return Align(
      alignment: isMe ? Alignment.centerRight : Alignment.centerLeft,
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        constraints: BoxConstraints(
            maxWidth: MediaQuery.of(context).size.width * 0.72),
        child: Column(
          crossAxisAlignment:
              isMe ? CrossAxisAlignment.end : CrossAxisAlignment.start,
          children: [
            if (!isMe)
              Padding(
                padding: const EdgeInsets.only(left: 4, bottom: 2),
                child: Text(sender,
                    style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                        color: Colors.grey[600])),
              ),
            Container(
              padding: isImage ? EdgeInsets.zero : const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
              decoration: BoxDecoration(
                color: isMe ? const Color(0xFF2196F3) : Colors.white,
                borderRadius: BorderRadius.only(
                  topLeft: const Radius.circular(16),
                  topRight: const Radius.circular(16),
                  bottomLeft: Radius.circular(isMe ? 16 : 4),
                  bottomRight: Radius.circular(isMe ? 4 : 16),
                ),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.06),
                    blurRadius: 4, offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.only(
                  topLeft: const Radius.circular(16),
                  topRight: const Radius.circular(16),
                  bottomLeft: Radius.circular(isMe ? 16 : 4),
                  bottomRight: Radius.circular(isMe ? 4 : 16),
                ),
                child: isImage 
                    ? Image.memory(
                        base64Decode(message.split(',').last),
                        fit: BoxFit.cover,
                      )
                    : Text(message,
                        style: TextStyle(
                            color: isMe ? Colors.white : Colors.black87,
                            fontSize: 14)),
              ),
            ),
            Padding(
              padding: const EdgeInsets.only(top: 2, left: 4, right: 4),
              child: Text(_formatTime(sentAt),
                  style: TextStyle(fontSize: 10, color: Colors.grey[400])),
            ),
          ],
        ),
      ),
    );
  }
}
