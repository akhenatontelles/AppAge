import 'dart:async'; // Import necessário para usar Timer
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../services/api_service.dart';
import '../models/message_model.dart';

class ChatScreen extends StatefulWidget {
  final String token;

  const ChatScreen({super.key, required this.token});

  @override
  _ChatScreenState createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen> {
  final ApiService apiService = ApiService('https://api.testelab.me');
  final TextEditingController _messageController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  List<Message> _messages = [];
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    _loadMessages();
    _startPolling();
  }

  @override
  void dispose() {
    _timer?.cancel();
    _messageController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  void _startPolling() {
    _timer = Timer.periodic(const Duration(seconds: 3), (timer) async {
      try {
        final newMessages = await apiService.fetchMessages(widget.token);

        if (newMessages.isNotEmpty &&
            (newMessages.length != _messages.length ||
                newMessages.last.id != _messages.last.id)) {
          setState(() {
            _messages = newMessages;
          });

          // Rola para a última mensagem ao carregar novas mensagens
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
      } catch (e) {
        print("Erro ao carregar mensagens: $e");
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Erro ao carregar mensagens')),
        );
      }
    });
  }

  /// Atualização do método _loadMessages para marcar mensagens como lidas
  Future<void> _loadMessages() async {
    try {
      final newMessages = await apiService.fetchMessages(widget.token);

      if (_messages.isEmpty) {
        setState(() {
          _messages = newMessages;
        });
      } else if (newMessages.length > _messages.length) {
        final latestMessages = newMessages.sublist(_messages.length);
        setState(() {
          _messages.addAll(latestMessages);
        });
      }

      // Marcar as mensagens como lidas
      for (var message in _messages) {
        if (!message.isRead && message.sender != 'user') {
          await apiService.markAsRead(widget.token, message.id);
        }
      }

      // Rola para a última mensagem ao carregar novas mensagens
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (_scrollController.hasClients) {
          _scrollController.animateTo(
            _scrollController.position.maxScrollExtent,
            duration: const Duration(milliseconds: 300),
            curve: Curves.easeOut,
          );
        }
      });
    } catch (e) {
      print("Erro ao carregar mensagens: $e");
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Erro ao carregar mensagens')),
      );
    }
  }

  Future<void> _sendMessage() async {
    if (_messageController.text.isNotEmpty) {
      try {
        final success = await apiService.sendMessage(
          widget.token,
          _messageController.text,
        );
        if (success) {
          _messageController.clear();
          _loadMessages(); // Recarrega as mensagens após enviar
        } else {
          print("Erro ao enviar mensagem");
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Erro ao enviar mensagem')),
          );
        }
      } catch (e) {
        print("Erro ao enviar mensagem: $e");
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Erro ao enviar mensagem')),
        );
      }
    }
  }

  String _formatTimestamp(DateTime timestamp) {
    final DateFormat formatter = DateFormat('dd/MM/yyyy HH:mm');
    return formatter.format(timestamp);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 2,
        shadowColor: Colors.black.withOpacity(0.1),
        title: const Text(
          'Bate-papo',
          style: TextStyle(
            color: Color(0xFF2e604a),
            fontSize: 20,
            fontWeight: FontWeight.w600,
          ),
        ),
        centerTitle: true,
        leading: IconButton(
          icon: const Icon(
            Icons.arrow_back_rounded,
            color: Color(0xFF2e604a),
          ),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      backgroundColor: const Color(0xFFF5F1ED),
      body: Column(
        children: [
          Expanded(
            child: ListView.builder(
              controller: _scrollController,
              padding: const EdgeInsets.all(16),
              itemCount: _messages.length,
              itemBuilder: (context, index) {
                final message = _messages[index];
                final isSentByUser = message.sender == 'user';

                return Align(
                  alignment: isSentByUser
                      ? Alignment.centerRight
                      : Alignment.centerLeft,
                  child: Padding(
                    padding: const EdgeInsets.symmetric(vertical: 4.0),
                    child: Container(
                      padding: const EdgeInsets.all(12.0),
                      constraints: BoxConstraints(
                        maxWidth: MediaQuery.of(context).size.width * 0.75,
                      ),
                      decoration: BoxDecoration(
                        color: isSentByUser
                            ? const Color(0xFF2e604a)
                            : Colors.white,
                        borderRadius: BorderRadius.circular(16),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.05),
                            spreadRadius: 1,
                            blurRadius: 8,
                            offset: const Offset(0, 4),
                          ),
                        ],
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            message.message,
                            style: TextStyle(
                              fontSize: 16,
                              color:
                                  isSentByUser ? Colors.white : Colors.black87,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            _formatTimestamp(message.timestamp),
                            style: TextStyle(
                              fontSize: 12,
                              color: isSentByUser
                                  ? Colors.white.withOpacity(0.7)
                                  : Colors.grey[600],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                );
              },
            ),
          ),
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white,
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.05),
                  offset: const Offset(0, -4),
                  blurRadius: 8,
                ),
              ],
            ),
            child: Row(
              children: [
                Expanded(
                  child: Container(
                    decoration: BoxDecoration(
                      color: Colors.grey.shade100,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: TextField(
                      controller: _messageController,
                      decoration: const InputDecoration(
                        hintText: 'Digite sua mensagem...',
                        contentPadding: EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 12,
                        ),
                        border: InputBorder.none,
                      ),
                      onSubmitted: (_) => _sendMessage(),
                      textInputAction: TextInputAction.send,
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Container(
                  decoration: BoxDecoration(
                    color: const Color(0xFF2e604a),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: IconButton(
                    icon: const Icon(Icons.send_rounded, color: Colors.white),
                    onPressed: _sendMessage,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
