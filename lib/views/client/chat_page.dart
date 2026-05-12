import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '../../core/localization.dart';
import '../../services/api_service.dart';
import '../../services/socket_service.dart';
import '../../models/chat_models.dart';
import '../../viewmodels/auth_viewmodel.dart';

class ChatPage extends StatefulWidget {
  final String receiverId;
  final String receiverName;
  final String? conversationId;

  const ChatPage({
    super.key,
    required this.receiverId,
    required this.receiverName,
    this.conversationId,
  });

  @override
  State<ChatPage> createState() => _ChatPageState();
}

class _ChatPageState extends State<ChatPage> {
  final TextEditingController _messageController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  final Color primaryTeal = const Color(0xFF006D5B);
  List<ChatMessage> _messages = [];
  String? _activeConvId;
  bool _isLoading = true;
  String _myId = '';

  @override
  void initState() {
    super.initState();
    _activeConvId = widget.conversationId;
    _myId = Provider.of<AuthViewModel>(context, listen: false).currentUser?.id ?? '';
    _initializeChat();
  }

  @override
  void dispose() {
    _messageController.dispose();
    _scrollController.dispose();
    final socket = SocketService.socket;
    if (socket != null && _activeConvId != null) {
      socket.emit('chat:read', {'conversationId': _activeConvId});
      socket.off('chat:message');
      socket.off('ai:stream');
    }
    super.dispose();
  }

  Future<void> _initializeChat() async {
    if (_activeConvId == null) {
      final conv = await ApiService.findOrCreateConversation(widget.receiverId);
      if (conv != null) {
        _activeConvId = conv.id;
      }
    }

    if (_activeConvId != null) {
      final msgs = await ApiService.getMessages(_activeConvId!);
      if (mounted) {
        setState(() {
          _messages = msgs;
          _isLoading = false;
        });
      }
      _scrollToBottom();
      await _setupSocket();
    } else {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _setupSocket() async {
    final socket = await SocketService.connect();

    socket.emit('chat:join', {'conversationId': _activeConvId});

    socket.on('chat:message', (data) {
      if (!mounted) return;
      final msg = ChatMessage.fromJson(data is Map ? Map<String, dynamic>.from(data) : {});
      // Only add messages from others; own messages are added optimistically in _sendMessage
      if (msg.senderId != _myId && msg.conversationId == _activeConvId) {
        setState(() => _messages.add(msg));
        _scrollToBottom();
      }
    });

    socket.on('ai:stream', (data) {
      if (!mounted) return;
      final token = data is Map ? (data['token'] ?? data['content'] ?? '').toString() : data.toString();
      if (token.isEmpty) return;
      setState(() {
        if (_messages.isNotEmpty && _messages.last.senderId == 'ai') {
          final last = _messages.last;
          _messages[_messages.length - 1] = ChatMessage(
            id: last.id,
            conversationId: last.conversationId,
            senderId: last.senderId,
            text: last.text + token,
            createdAt: last.createdAt,
          );
        } else {
          _messages.add(ChatMessage(
            id: 'ai-stream',
            conversationId: _activeConvId ?? '',
            senderId: 'ai',
            text: token,
            createdAt: DateTime.now(),
          ));
        }
      });
      _scrollToBottom();
    });
  }

  void _sendMessage() {
    final text = _messageController.text.trim();
    if (text.isEmpty || _activeConvId == null) return;

    _messageController.clear();

    // Optimistic local update
    final optimistic = ChatMessage(
      id: 'local-${DateTime.now().millisecondsSinceEpoch}',
      conversationId: _activeConvId!,
      senderId: _myId,
      text: text,
      createdAt: DateTime.now(),
    );
    setState(() => _messages.add(optimistic));
    _scrollToBottom();

    ApiService.sendMessage(_activeConvId!, text, _myId);
  }

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 200),
          curve: Curves.easeOut,
        );
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 1,
        leading: IconButton(
          icon: Icon(Icons.arrow_back, color: primaryTeal),
          onPressed: () => Navigator.pop(context),
        ),
        title: Row(
          children: [
            CircleAvatar(
              backgroundColor: primaryTeal.withOpacity(0.1),
              child: Text(
                widget.receiverName.isNotEmpty
                    ? widget.receiverName.substring(0, 1).toUpperCase()
                    : '?',
                style: TextStyle(color: primaryTeal, fontWeight: FontWeight.bold),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                widget.receiverName,
                style: GoogleFonts.cairo(
                  color: Colors.black87,
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
      ),
      body: _isLoading
          ? Center(child: CircularProgressIndicator(color: primaryTeal))
          : Directionality(
              textDirection:
                  AppLocalization.isArabic ? TextDirection.rtl : TextDirection.ltr,
              child: Column(
                children: [
                  Expanded(
                    child: ListView.builder(
                      controller: _scrollController,
                      padding: const EdgeInsets.all(20),
                      itemCount: _messages.length,
                      itemBuilder: (context, index) {
                        final msg = _messages[index];
                        final isMe = msg.senderId == _myId;
                        return _buildMessageBubble(msg.text, isMe);
                      },
                    ),
                  ),
                  _buildInputArea(),
                ],
              ),
            ),
    );
  }

  Widget _buildMessageBubble(String text, bool isMe) {
    return Align(
      alignment: isMe ? Alignment.centerRight : Alignment.centerLeft,
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        decoration: BoxDecoration(
          color: isMe ? primaryTeal : Colors.white,
          borderRadius: BorderRadius.circular(16).copyWith(
            bottomRight: isMe ? const Radius.circular(0) : const Radius.circular(16),
            bottomLeft: isMe ? const Radius.circular(16) : const Radius.circular(0),
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.05),
              blurRadius: 5,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Text(
          text,
          style: GoogleFonts.cairo(
            color: isMe ? Colors.white : Colors.black87,
            fontSize: 14,
          ),
        ),
      ),
    );
  }

  Widget _buildInputArea() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, -2),
          ),
        ],
      ),
      child: Row(
        children: [
          Expanded(
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              decoration: BoxDecoration(
                color: const Color(0xFFF1F5F9),
                borderRadius: BorderRadius.circular(30),
              ),
              child: TextField(
                controller: _messageController,
                textAlign:
                    AppLocalization.isArabic ? TextAlign.right : TextAlign.left,
                onSubmitted: (_) => _sendMessage(),
                decoration: InputDecoration(
                  hintText: AppLocalization.isArabic
                      ? 'اكتب رسالة...'
                      : 'Type a message...',
                  hintStyle: GoogleFonts.cairo(color: Colors.grey[400], fontSize: 14),
                  border: InputBorder.none,
                ),
              ),
            ),
          ),
          const SizedBox(width: 12),
          GestureDetector(
            onTap: _sendMessage,
            child: Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: primaryTeal,
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.send_rounded, color: Colors.white, size: 24),
            ),
          ),
        ],
      ),
    );
  }
}
