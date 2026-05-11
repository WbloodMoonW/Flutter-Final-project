import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '../../core/localization.dart';
import '../../services/api_service.dart';
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
  final Color primaryTeal = const Color(0xFF006D5B);
  List<ChatMessage> _messages = [];
  String? _activeConvId;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _activeConvId = widget.conversationId;
    _initializeChat();
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
      setState(() {
        _messages = msgs;
        _isLoading = false;
      });
    } else {
      setState(() => _isLoading = false);
    }
  }

  void _sendMessage() async {
    final text = _messageController.text.trim();
    if (text.isEmpty || _activeConvId == null) return;
    
    _messageController.clear();
    final sent = await ApiService.sendMessage(_activeConvId!, text);
    if (sent != null) {
      setState(() {
        _messages.add(sent);
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final authVM = Provider.of<AuthViewModel>(context);
    final myId = authVM.currentUser?.id ?? '';

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
                widget.receiverName.isNotEmpty ? widget.receiverName.substring(0, 1).toUpperCase() : '?',
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
            textDirection: AppLocalization.isArabic ? TextDirection.rtl : TextDirection.ltr,
            child: Column(
              children: [
                Expanded(
                  child: ListView.builder(
                    padding: const EdgeInsets.all(20),
                    itemCount: _messages.length,
                    itemBuilder: (context, index) {
                      final msg = _messages[index];
                      final isMe = msg.senderId == myId;
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
                textAlign: AppLocalization.isArabic ? TextAlign.right : TextAlign.left,
                decoration: InputDecoration(
                  hintText: AppLocalization.isArabic ? 'اكتب رسالة...' : 'Type a message...',
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
