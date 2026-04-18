import 'dart:io';
import 'package:emoji_picker_flutter/emoji_picker_flutter.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../services/local_db.dart';

class ChatScreen extends StatefulWidget {
  final int chatId;
  final String title;

  const ChatScreen({super.key, required this.chatId, required this.title});

  @override
  State<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen> {
  final TextEditingController _textController = TextEditingController();
  final ScrollController _scrollController = ScrollController();

  List<Map<String, dynamic>> _messages = [];
  bool _showEmoji = false;

  @override
  void initState() {
    super.initState();
    _loadMessages();
  }

  Future<void> _loadMessages() async {
    final data = await LocalDb.instance.getMessages(widget.chatId);
    if (!mounted) return;
    setState(() => _messages = data);
    
    // Scroll auto vers le bas
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });
  }

  Future<void> _sendText() async {
    final text = _textController.text.trim();
    if (text.isEmpty) return;

    await LocalDb.instance.addMessage(
      chatId: widget.chatId,
      body: text,
      type: 'text',
      isMine: true,
    );

    _textController.clear();
    await _loadMessages();
  }

  Future<void> _pickMedia(String kind) async {
    final result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['gif', 'jpg', 'png', 'webp'],
    );

    if (result == null || result.files.single.path == null) return;

    await LocalDb.instance.addMessage(
      chatId: widget.chatId,
      body: kind == 'gif' ? '🖼️ GIF' : '📸 Image',
      mediaPath: result.files.single.path!,
      type: kind,
      isMine: true,
    );

    await _loadMessages();
  }

  String _formatTs(int ms) => DateFormat('HH:mm').format(DateTime.fromMillisecondsSinceEpoch(ms));

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0F172A),
      appBar: AppBar(
        backgroundColor: const Color(0xFF1E293B),
        elevation: 0,
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(widget.title, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.white)),
            const Text('En ligne (Local-first)', style: TextStyle(fontSize: 12, color: Colors.greenAccent)),
          ],
        ),
        actions: [
          IconButton(icon: const Icon(Icons.videocam_outlined, color: Colors.white70), onPressed: () {}),
        ],
      ),
      body: Column(
        children: [
          Expanded(
            child: ListView.builder(
              controller: _scrollController,
              padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 8),
              itemCount: _messages.length,
              itemBuilder: (context, index) => _buildBubble(_messages[index]),
            ),
          ),
          _buildComposer(),
        ],
      ),
    );
  }

  Widget _buildBubble(Map<String, dynamic> msg) {
    final isMine = (msg['isMine'] as int) == 1;
    final type = msg['type'] as String;
    final body = msg['body']?.toString() ?? '';
    final mediaPath = msg['mediaPath']?.toString();

    return Align(
      alignment: isMine ? Alignment.centerRight : Alignment.centerLeft,
      child: Container(
        margin: const EdgeInsets.symmetric(vertical: 4),
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: isMine ? Colors.indigoAccent : const Color(0xFF1E293B),
          borderRadius: BorderRadius.only(
            topLeft: const Radius.circular(16),
            topRight: const Radius.circular(16),
            bottomLeft: Radius.circular(isMine ? 16 : 0),
            bottomRight: Radius.circular(isMine ? 0 : 16),
          ),
        ),
        constraints: BoxConstraints(maxWidth: MediaQuery.of(context).size.width * 0.75),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (mediaPath != null) 
              Padding(
                padding: const EdgeInsets.bottom(8.0),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(12),
                  child: Image.file(File(mediaPath), fit: BoxFit.cover),
                ),
              ),
            if (body.isNotEmpty)
              Text(body, style: const TextStyle(color: Colors.white, fontSize: 15)),
            const SizedBox(height: 4),
            Text(_formatTs(msg['createdAt']), style: const TextStyle(color: Colors.white38, fontSize: 10)),
          ],
        ),
      ),
    );
  }

  Widget _buildComposer() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
      color: const Color(0xFF1E293B),
      child: SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Row(
              children: [
                IconButton(icon: const Icon(Icons.emoji_emotions_outlined, color: Colors.indigoAccent), 
                  onPressed: () => setState(() => _showEmoji = !_showEmoji)),
                IconButton(icon: const Icon(Icons.gif_box_outlined, color: Colors.indigoAccent), 
                  onPressed: () => _pickMedia('gif')),
                Expanded(
                  child: TextField(
                    controller: _textController,
                    style: const TextStyle(color: Colors.white),
                    decoration: InputDecoration(
                      hintText: 'Message...',
                      hintStyle: const TextStyle(color: Colors.white24),
                      filled: true,
                      fillColor: const Color(0xFF0F172A),
                      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(24), borderSide: BorderSide.none),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                CircleAvatar(
                  backgroundColor: Colors.indigoAccent,
                  child: IconButton(icon: const Icon(Icons.send, color: Colors.white, size: 20), onPressed: _sendText),
                ),
              ],
            ),
            if (_showEmoji) 
              SizedBox(height: 250, child: EmojiPicker(
                onEmojiSelected: (category, emoji) => _textController.text += emoji.emoji,
                config: const Config(height: 256, emojiViewConfig: EmojiViewConfig(columns: 7, emojiSizeMax: 24)),
              )),
          ],
        ),
      ),
    );
  }
}
