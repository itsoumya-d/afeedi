import 'package:flutter/material.dart';
import '../../models/content_model.dart';

class CommentsBottomSheet extends StatefulWidget {
  final Content content;
  final int commentCount;

  const CommentsBottomSheet({
    super.key,
    required this.content,
    required this.commentCount,
  });

  static Future<void> show(BuildContext context, Content content) {
    final commentCount = content.id.hashCode.abs() % 500 + 10;
    return showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) =>
          CommentsBottomSheet(content: content, commentCount: commentCount),
    );
  }

  @override
  State<CommentsBottomSheet> createState() => _CommentsBottomSheetState();
}

class _CommentsBottomSheetState extends State<CommentsBottomSheet> {
  final TextEditingController _inputController = TextEditingController();
  final List<Map<String, dynamic>> _comments = List.from(_mockComments);
  final Set<int> _likedIndices = {};

  static const List<Map<String, dynamic>> _mockComments = [
    {
      'user': 'alex_dev',
      'text': 'This is exactly what I needed, thank you!',
      'time': '2h',
      'likes': 142,
    },
    {
      'user': 'techie_sarah',
      'text': 'Wow, the explanation at 3:45 really clicked for me 🤯',
      'time': '4h',
      'likes': 89,
    },
    {
      'user': 'code_ninja',
      'text': 'Been waiting for this video for months!',
      'time': '6h',
      'likes': 67,
    },
    {
      'user': 'flutter_fan',
      'text': 'Can you make a follow-up video on advanced topics?',
      'time': '8h',
      'likes': 54,
    },
    {
      'user': 'dev_dreams',
      'text': 'The production quality here is incredible. Subscribed!',
      'time': '10h',
      'likes': 203,
    },
    {
      'user': 'maria_codes',
      'text':
          'I\'ve watched this three times already and I keep learning new things',
      'time': '12h',
      'likes': 77,
    },
    {
      'user': 'startup_guy',
      'text':
          'We implemented this at work today and saved hours of refactoring 🙌',
      'time': '1d',
      'likes': 320,
    },
    {
      'user': 'curious_learner',
      'text': 'Question: does this approach work with older versions too?',
      'time': '1d',
      'likes': 31,
    },
    {
      'user': 'pixel_wizard',
      'text': 'The animations are so smooth! What library are you using?',
      'time': '1d',
      'likes': 48,
    },
    {
      'user': 'ux_panda',
      'text': 'Great content as always. Keep it up! 💪',
      'time': '2d',
      'likes': 95,
    },
    {
      'user': 'backend_bob',
      'text': 'Finally someone explains this clearly without all the jargon',
      'time': '2d',
      'likes': 114,
    },
    {
      'user': 'open_source_fan',
      'text': 'Would love to see the GitHub repo for this demo project',
      'time': '3d',
      'likes': 60,
    },
    {
      'user': 'night_coder',
      'text': 'Watched this at 2 AM — worth every minute. No regrets.',
      'time': '3d',
      'likes': 38,
    },
    {
      'user': 'designsprint',
      'text': 'The design choices here are spot on. Really polished work 🎨',
      'time': '4d',
      'likes': 72,
    },
    {
      'user': 'newbie_dev22',
      'text': 'As a beginner this was super helpful. Thank you so much!',
      'time': '5d',
      'likes': 25,
    },
  ];

  @override
  void dispose() {
    _inputController.dispose();
    super.dispose();
  }

  void _addComment() {
    final text = _inputController.text.trim();
    if (text.isEmpty) return;
    setState(() {
      _comments.insert(0, {
        'user': 'you',
        'text': text,
        'time': 'Just now',
        'likes': 0,
      });
      _inputController.clear();
    });
  }

  @override
  Widget build(BuildContext context) {
    final bottomInset = MediaQuery.of(context).viewInsets.bottom;

    return Container(
      height: MediaQuery.of(context).size.height * 0.75 + bottomInset,
      decoration: const BoxDecoration(
        color: Color(0xFF1A1A2E),
        borderRadius: BorderRadius.only(
          topLeft: Radius.circular(20),
          topRight: Radius.circular(20),
        ),
      ),
      child: Column(
        children: [
          _buildHandle(),
          _buildHeader(),
          const Divider(color: Colors.white12, height: 1),
          Expanded(child: _buildCommentList()),
          const Divider(color: Colors.white12, height: 1),
          _buildInput(bottomInset),
        ],
      ),
    );
  }

  Widget _buildHandle() {
    return Padding(
      padding: const EdgeInsets.only(top: 10, bottom: 4),
      child: Container(
        width: 36,
        height: 4,
        decoration: BoxDecoration(
          color: Colors.white24,
          borderRadius: BorderRadius.circular(2),
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: Row(
        children: [
          const Text(
            'Comments',
            style: TextStyle(
              color: Colors.white,
              fontSize: 16,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(width: 8),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
            decoration: BoxDecoration(
              color: Colors.white12,
              borderRadius: BorderRadius.circular(10),
            ),
            child: Text(
              '${widget.commentCount}',
              style: const TextStyle(
                color: Colors.white70,
                fontSize: 12,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
          const Spacer(),
          IconButton(
            icon: const Icon(Icons.close, color: Colors.white54, size: 20),
            onPressed: () => Navigator.pop(context),
            padding: EdgeInsets.zero,
            constraints: const BoxConstraints(minWidth: 32, minHeight: 32),
          ),
        ],
      ),
    );
  }

  Widget _buildCommentList() {
    return ListView.builder(
      padding: const EdgeInsets.symmetric(vertical: 4),
      itemCount: _comments.length,
      itemBuilder: (context, index) => _buildCommentTile(index),
    );
  }

  Widget _buildCommentTile(int index) {
    final comment = _comments[index];
    final user = comment['user'] as String;
    final text = comment['text'] as String;
    final time = comment['time'] as String;
    final likes =
        (comment['likes'] as int) + (_likedIndices.contains(index) ? 1 : 0);
    final initial = user.isNotEmpty ? user[0].toUpperCase() : '?';

    final colors = [
      const Color(0xFF6C63FF),
      const Color(0xFF00D4FF),
      const Color(0xFFFF6B9D),
      const Color(0xFF4CAF50),
      const Color(0xFFFF9800),
      const Color(0xFFE91E63),
    ];
    final avatarColor = colors[user.hashCode.abs() % colors.length];

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          CircleAvatar(
            radius: 18,
            backgroundColor: avatarColor.withValues(alpha: 0.2),
            child: Text(
              initial,
              style: TextStyle(
                color: avatarColor,
                fontSize: 13,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Text(
                      user,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(width: 6),
                    Text(
                      time,
                      style: const TextStyle(
                        color: Colors.white38,
                        fontSize: 11,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 3),
                Text(
                  text,
                  style: const TextStyle(
                    color: Colors.white70,
                    fontSize: 13,
                    height: 1.4,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          GestureDetector(
            onTap: () {
              setState(() {
                if (_likedIndices.contains(index)) {
                  _likedIndices.remove(index);
                } else {
                  _likedIndices.add(index);
                }
              });
            },
            child: Column(
              children: [
                Icon(
                  _likedIndices.contains(index)
                      ? Icons.favorite
                      : Icons.favorite_border,
                  size: 16,
                  color: _likedIndices.contains(index)
                      ? Colors.red
                      : Colors.white38,
                ),
                const SizedBox(height: 2),
                Text(
                  '$likes',
                  style: const TextStyle(color: Colors.white38, fontSize: 10),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInput(double bottomInset) {
    return Padding(
      padding: EdgeInsets.only(
        left: 12,
        right: 12,
        top: 10,
        bottom: 10 + bottomInset,
      ),
      child: Row(
        children: [
          Expanded(
            child: Container(
              height: 42,
              decoration: BoxDecoration(
                color: Colors.white10,
                borderRadius: BorderRadius.circular(21),
                border: Border.all(color: Colors.white12),
              ),
              child: TextField(
                controller: _inputController,
                style: const TextStyle(color: Colors.white, fontSize: 14),
                decoration: const InputDecoration(
                  hintText: 'Add a comment...',
                  hintStyle: TextStyle(color: Colors.white38, fontSize: 14),
                  border: InputBorder.none,
                  contentPadding: EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 11,
                  ),
                ),
                textInputAction: TextInputAction.send,
                onSubmitted: (_) => _addComment(),
              ),
            ),
          ),
          const SizedBox(width: 8),
          GestureDetector(
            onTap: _addComment,
            child: Container(
              width: 42,
              height: 42,
              decoration: const BoxDecoration(
                color: Color(0xFF00D4FF),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.send_rounded,
                color: Colors.white,
                size: 18,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
