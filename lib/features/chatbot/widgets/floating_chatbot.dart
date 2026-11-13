import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../models/chat_message.dart';
import '../services/chatbot_service.dart';

const Color _brown = Color(0xFF4B2E2B);
const Color _gold = Color(0xFFC69C6D);
const Color _border = Color(0xFFE8D5C4);
const Color _inputBorder = Color(0xFFD4C5B5);
const Color _chatBackground = Color(0xFFFAF7F3);

const ChatMessage _greeting = ChatMessage(
  role: 'assistant',
  content:
      'Halo! Saya **CafeBot**, asisten AI dari C.A.F.E. Job Portal.\n\n'
      'Saya bisa membantu kamu:\n'
      '- Mencari lowongan pekerjaan cafe\n'
      '- Melihat rating & rekomendasi cafe\n'
      '- Tips karir dan wawancara\n'
      '- Menjawab pertanyaan seputar platform\n\n'
      'Ada yang bisa saya bantu?',
);

class FloatingChatbot extends StatefulWidget {
  const FloatingChatbot({super.key});

  @override
  State<FloatingChatbot> createState() => _FloatingChatbotState();
}

class _FloatingChatbotState extends State<FloatingChatbot> {
  final List<ChatMessage> _messages = [_greeting];
  final TextEditingController _inputController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  final FocusNode _inputFocus = FocusNode();

  Timer? _tooltipTimer;
  bool _isOpen = false;
  bool _isLoading = false;
  bool _showTooltip = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _inputController.addListener(_handleInputChanged);
    _tooltipTimer = Timer(const Duration(seconds: 5), () {
      if (mounted) {
        setState(() => _showTooltip = false);
      }
    });
  }

  @override
  void dispose() {
    _tooltipTimer?.cancel();
    _inputController.removeListener(_handleInputChanged);
    _inputController.dispose();
    _scrollController.dispose();
    _inputFocus.dispose();
    super.dispose();
  }

  void _handleInputChanged() {
    if (mounted && _isOpen) {
      setState(() {});
    }
  }

  void _toggleChat() {
    if (_isOpen) {
      _closeChat();
      return;
    }

    setState(() {
      _isOpen = true;
      _showTooltip = false;
    });

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      _inputFocus.requestFocus();
      _scrollToBottom(jump: true);
    });
  }

  void _closeChat() {
    _inputFocus.unfocus();
    setState(() => _isOpen = false);
  }

  void _scrollToBottom({bool jump = false}) {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!_scrollController.hasClients) return;

      final target = _scrollController.position.maxScrollExtent;
      if (jump) {
        _scrollController.jumpTo(target);
      } else {
        _scrollController.animateTo(
          target,
          duration: const Duration(milliseconds: 250),
          curve: Curves.easeOut,
        );
      }
    });
  }

  Future<void> _sendMessage() async {
    final text = _inputController.text.trim();

    if (text.isEmpty) {
      setState(() => _error = 'Pertanyaan tidak boleh kosong');
      _scrollToBottom();
      return;
    }

    if (_isLoading) return;

    final userMessage = ChatMessage(role: 'user', content: text);
    final history = [..._messages, userMessage];

    setState(() {
      _messages.add(userMessage);
      _inputController.clear();
      _error = null;
      _isLoading = true;
    });
    _scrollToBottom();

    try {
      final reply = await ChatbotService.sendMessage(history);
      if (!mounted) return;

      setState(() {
        _messages.add(reply);
        _isLoading = false;
      });
      _scrollToBottom();
    } catch (error) {
      if (!mounted) return;

      final message = error
          .toString()
          .replaceFirst(RegExp(r'^Exception:\s*'), '')
          .trim();

      setState(() {
        _error = message.isEmpty
            ? 'Gagal mengirim pesan. Silakan coba lagi.'
            : message;
        _isLoading = false;
      });
      _scrollToBottom();
    }
  }

  @override
  Widget build(BuildContext context) {
    final media = MediaQuery.of(context);
    final keyboardHeight = media.viewInsets.bottom;
    final bottomNavigationSpace = media.padding.bottom + 114;
    final width = math.min(media.size.width - 24, 400.0);
    final isKeyboardVisible = keyboardHeight > 0;

    final panelHeight = isKeyboardVisible
        ? (media.size.height -
                  media.padding.top -
                  keyboardHeight -
                  8 -
                  12)
              .clamp(240.0, 560.0)
              .toDouble()
        : (media.size.height -
                  media.padding.top -
                  bottomNavigationSpace -
                  56 -
                  10 -
                  12)
              .clamp(240.0, 560.0)
              .toDouble();

    return Stack(
      children: [
        if (_isOpen)
          Positioned.fill(
            child: GestureDetector(
              behavior: HitTestBehavior.opaque,
              onTap: _closeChat,
              child: Container(
                color: Colors.black.withValues(alpha: 0.2),
              ),
            ),
          ),
        if (_isOpen && isKeyboardVisible)
          Positioned(
            right: 12,
            bottom: keyboardHeight + 8,
            child: _buildWindow(width: width, height: panelHeight),
          )
        else if (_isOpen)
          Positioned(
            right: 12,
            bottom: bottomNavigationSpace,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                _buildWindow(width: width, height: panelHeight),
                const SizedBox(height: 10),
                _buildChatButton(),
              ],
            ),
          )
        else
          Positioned(
            right: 12,
            bottom: bottomNavigationSpace,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                if (_showTooltip) ...[
                  _buildTooltip(),
                  const SizedBox(height: 8),
                ],
                _buildChatButton(),
              ],
            ),
          ),
      ],
    );
  }

  Widget _buildChatButton() {
    final icon = Image.asset(
      'assets/icon_chatbot.png',
      width: 52,
      height: 52,
      fit: BoxFit.contain,
    );

    final content = SizedBox(
      width: 64,
      height: 64,
      child: Center(child: icon),
    );

    return Semantics(
      button: true,
      label: _isOpen ? 'Tutup bantuan AI' : 'Buka bantuan AI - CafeBot',
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: _toggleChat,
        child: AnimatedRotation(
          turns: _isOpen ? 0.125 : 0,
          duration: const Duration(milliseconds: 250),
          child: _isOpen ? content : _PulseRing(child: content),
        ),
      ),
    );
  }

  Widget _buildTooltip() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: _brown,
        borderRadius: BorderRadius.circular(8),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.15),
            blurRadius: 8,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: const Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            'Bantuan AI - CafeBot',
            style: TextStyle(
              color: Colors.white,
              fontSize: 12,
              fontWeight: FontWeight.w600,
            ),
          ),
          SizedBox(width: 6),
          Icon(Icons.arrow_upward_rounded, color: Colors.white, size: 14),
        ],
      ),
    );
  }

  Widget _buildWindow({required double width, required double height}) {
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0, end: 1),
      duration: const Duration(milliseconds: 220),
      curve: Curves.easeOut,
      builder: (context, value, child) {
        return Opacity(
          opacity: value,
          child: Transform.scale(
            scale: 0.95 + (0.05 * value),
            alignment: Alignment.bottomRight,
            child: child,
          ),
        );
      },
      child: Material(
        color: Colors.transparent,
        child: Container(
          width: width,
          height: height,
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: _border),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.2),
                blurRadius: 24,
                offset: const Offset(0, 10),
              ),
            ],
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(16),
            child: Column(
              children: [
                _buildHeader(),
                Expanded(child: _buildMessageList(width)),
                _buildInputArea(),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 12, 12, 12),
      decoration: const BoxDecoration(
        color: _brown,
        border: Border(
          bottom: BorderSide(color: Color(0x4DC69C6D)),
        ),
      ),
      child: Row(
        children: [
          Container(
            width: 40,
            height: 40,
            padding: const EdgeInsets.all(9),
            decoration: BoxDecoration(
              color: _gold.withValues(alpha: 0.2),
              shape: BoxShape.circle,
            ),
            child: Image.asset(
              'assets/icon_chatbot.png',
              fit: BoxFit.contain,
            ),
          ),
          const SizedBox(width: 12),
          const Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Bantuan AI - CafeBot',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                SizedBox(height: 2),
                Text(
                  'Online • Biasanya balas dalam detik',
                  style: TextStyle(
                    color: Colors.white70,
                    fontSize: 11,
                  ),
                ),
              ],
            ),
          ),
          SizedBox(
            width: 32,
            height: 32,
            child: Material(
              color: Colors.white.withValues(alpha: 0.1),
              shape: const CircleBorder(),
              child: InkWell(
                customBorder: const CircleBorder(),
                onTap: _closeChat,
                child: const Icon(
                  Icons.close_rounded,
                  color: Colors.white,
                  size: 20,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMessageList(double panelWidth) {
    final extraCount = (_isLoading ? 1 : 0) + (_error != null ? 1 : 0);

    return Container(
      color: _chatBackground,
      child: ListView.builder(
        controller: _scrollController,
        padding: const EdgeInsets.all(16),
        itemCount: _messages.length + extraCount,
        itemBuilder: (context, index) {
          if (index < _messages.length) {
            return _buildBubble(_messages[index], panelWidth);
          }

          final extraIndex = index - _messages.length;
          if (_isLoading && extraIndex == 0) {
            return _buildTypingIndicator();
          }

          return _buildError();
        },
      ),
    );
  }

  Widget _buildBubble(ChatMessage message, double panelWidth) {
    final isUser = message.role == 'user';

    return Align(
      alignment: isUser ? Alignment.centerRight : Alignment.centerLeft,
      child: Container(
        constraints: BoxConstraints(maxWidth: panelWidth * 0.8),
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        decoration: BoxDecoration(
          color: isUser ? _brown : Colors.white,
          border: isUser ? null : Border.all(color: _border),
          borderRadius: BorderRadius.only(
            topLeft: const Radius.circular(16),
            topRight: const Radius.circular(16),
            bottomLeft: Radius.circular(isUser ? 16 : 6),
            bottomRight: Radius.circular(isUser ? 6 : 16),
          ),
          boxShadow: isUser
              ? null
              : [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.04),
                    blurRadius: 4,
                    offset: const Offset(0, 2),
                  ),
                ],
        ),
        child: Text.rich(
          TextSpan(
            style: TextStyle(
              fontSize: 13.5,
              height: 1.45,
              color: isUser ? Colors.white : const Color(0xFF3E3E3E),
            ),
            children: _formatMessage(message.content),
          ),
        ),
      ),
    );
  }

  List<InlineSpan> _formatMessage(String text) {
    final normalized = text.replaceAll(
      RegExp(r'^(\s*)- ', multiLine: true),
      r'$1• ',
    );
    final spans = <InlineSpan>[];
    final boldPattern = RegExp(r'\*\*(.+?)\*\*', dotAll: true);
    var cursor = 0;

    for (final match in boldPattern.allMatches(normalized)) {
      if (match.start > cursor) {
        spans.add(TextSpan(text: normalized.substring(cursor, match.start)));
      }
      spans.add(
        TextSpan(
          text: match.group(1),
          style: const TextStyle(fontWeight: FontWeight.w700),
        ),
      );
      cursor = match.end;
    }

    if (cursor < normalized.length) {
      spans.add(TextSpan(text: normalized.substring(cursor)));
    }

    return spans;
  }

  Widget _buildTypingIndicator() {
    return Align(
      alignment: Alignment.centerLeft,
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: BoxDecoration(
          color: Colors.white,
          border: Border.all(color: _border),
          borderRadius: const BorderRadius.only(
            topLeft: Radius.circular(16),
            topRight: Radius.circular(16),
            bottomLeft: Radius.circular(6),
            bottomRight: Radius.circular(16),
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.04),
              blurRadius: 4,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: const _TypingDots(),
      ),
    );
  }

  Widget _buildError() {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: const Color(0xFFFEF2F2),
        border: const Border(
          left: BorderSide(color: Color(0xFFEF4444), width: 3),
        ),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text(
        _error ?? 'Gagal mengirim pesan. Silakan coba lagi.',
        style: const TextStyle(
          fontSize: 12.5,
          color: Color(0xFFB91C1C),
          height: 1.4,
        ),
      ),
    );
  }

  Widget _buildInputArea() {
    final canSend =
        !_isLoading && _inputController.text.trim().isNotEmpty;

    return Container(
      padding: const EdgeInsets.fromLTRB(12, 10, 12, 10),
      decoration: const BoxDecoration(
        color: Colors.white,
        border: Border(top: BorderSide(color: _border)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          Expanded(
            child: TextField(
              controller: _inputController,
              focusNode: _inputFocus,
              minLines: 1,
              maxLines: 4,
              textInputAction: TextInputAction.send,
              textCapitalization: TextCapitalization.sentences,
              onSubmitted: (_) => _sendMessage(),
              cursorColor: _brown,
              style: const TextStyle(
                fontSize: 13.5,
                color: Color(0xFF3E3E3E),
              ),
              decoration: InputDecoration(
                hintText: 'Ketik pesan di sini...',
                hintStyle: TextStyle(
                  color: Colors.grey.shade500,
                  fontSize: 13,
                ),
                isDense: true,
                filled: true,
                fillColor: Colors.white,
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: 14,
                  vertical: 12,
                ),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10),
                  borderSide: const BorderSide(color: _inputBorder),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10),
                  borderSide: const BorderSide(color: _inputBorder),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10),
                  borderSide: const BorderSide(color: _gold, width: 1.5),
                ),
              ),
            ),
          ),
          const SizedBox(width: 8),
          SizedBox(
            height: 44,
            child: ElevatedButton(
              onPressed: canSend ? _sendMessage : null,
              style: ElevatedButton.styleFrom(
                backgroundColor: _brown,
                foregroundColor: Colors.white,
                disabledBackgroundColor: _brown.withValues(alpha: 0.4),
                disabledForegroundColor: Colors.white70,
                elevation: 0,
                padding: const EdgeInsets.symmetric(horizontal: 16),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
              child: _isLoading
                  ? const SizedBox(
                      width: 16,
                      height: 16,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: Colors.white,
                      ),
                    )
                  : const Text(
                      'Kirim',
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
            ),
          ),
        ],
      ),
    );
  }
}

class _PulseRing extends StatefulWidget {
  const _PulseRing({required this.child});

  final Widget child;

  @override
  State<_PulseRing> createState() => _PulseRingState();
}

class _PulseRingState extends State<_PulseRing>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1600),
    )..repeat();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) {
        final progress = Curves.easeOut.transform(_controller.value);

        return SizedBox(
          width: 64,
          height: 64,
          child: Stack(
            alignment: Alignment.center,
            children: [
              Opacity(
                opacity: (1 - progress) * 0.35,
                child: Transform.scale(
                  scale: 0.8 + (progress * 0.65),
                  child: Container(
                    width: 48,
                    height: 48,
                    decoration: const BoxDecoration(
                      color: _gold,
                      shape: BoxShape.circle,
                    ),
                  ),
                ),
              ),
              child!,
            ],
          ),
        );
      },
      child: widget.child,
    );
  }
}

class _TypingDots extends StatefulWidget {
  const _TypingDots();

  @override
  State<_TypingDots> createState() => _TypingDotsState();
}

class _TypingDotsState extends State<_TypingDots>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1100),
    )..repeat();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) {
        return Row(
          mainAxisSize: MainAxisSize.min,
          children: List.generate(3, (index) {
            final phase = (_controller.value + (index * 0.16)) % 1.0;
            final wave = math.sin((phase * math.pi * 2) - (math.pi / 2));
            final bounce = (wave + 1) / 2;

            return Transform.translate(
              offset: Offset(0, -3 * bounce),
              child: Container(
                width: 7,
                height: 7,
                margin: const EdgeInsets.symmetric(horizontal: 2),
                decoration: BoxDecoration(
                  color: _gold.withValues(alpha: 0.5 + (0.5 * bounce)),
                  shape: BoxShape.circle,
                ),
              ),
            );
          }),
        );
      },
    );
  }
}
