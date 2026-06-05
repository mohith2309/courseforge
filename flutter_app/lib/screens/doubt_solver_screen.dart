import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/models.dart';
import '../providers/providers.dart';
import '../theme/app_theme.dart';

class _Msg {
  final String text;
  final bool fromUser;
  _Msg(this.text, this.fromUser);
}

class DoubtSolverScreen extends ConsumerStatefulWidget {
  const DoubtSolverScreen({
    super.key,
    required this.courseId,
    required this.lessonId,
  });
  final String courseId;
  final String lessonId;

  @override
  ConsumerState<DoubtSolverScreen> createState() => _DoubtSolverScreenState();
}

class _DoubtSolverScreenState extends ConsumerState<DoubtSolverScreen> {
  final _controller = TextEditingController();
  final _scrollController = ScrollController();
  final List<_Msg> _messages = [];
  bool _thinking = false;
  Lesson? _lesson;

  Future<void> _send() async {
    final text = _controller.text.trim();
    if (text.isEmpty || _thinking || _lesson == null) return;
    setState(() {
      _messages.add(_Msg(text, true));
      _thinking = true;
      _controller.clear();
    });
    _scrollToEnd();

    String answer;
    try {
      answer = await ref
          .read(aiServiceProvider)
          .answerDoubt(question: text, lesson: _lesson!);
    } catch (_) {
      answer =
          'Sorry — I couldn\'t reach the tutor just now. Please check your '
          'connection and try asking again.';
    }

    if (!mounted) return;
    setState(() {
      _messages.add(_Msg(answer, false));
      _thinking = false;
    });
    _scrollToEnd();
  }

  void _scrollToEnd() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 250),
          curve: Curves.easeOut,
        );
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final courseAsync = ref.watch(courseProvider(widget.courseId));
    final live = ref.watch(aiServiceProvider).isLive;

    return courseAsync.when(
      loading: () =>
          const Scaffold(body: Center(child: CircularProgressIndicator())),
      error: (e, _) => Scaffold(body: Center(child: Text('$e'))),
      data: (course) {
        if (course == null) {
          return const Scaffold(body: Center(child: Text('Not found')));
        }
        _lesson = course.allLessons.firstWhere((l) => l.id == widget.lessonId);
        return Scaffold(
          appBar: AppBar(
            title: const Text('AI Doubt Solver'),
            bottom: PreferredSize(
              preferredSize: const Size.fromHeight(28),
              child: Padding(
                padding: const EdgeInsets.only(bottom: Gap.sm, left: Gap.md),
                child: Align(
                  alignment: Alignment.centerLeft,
                  child: Text(
                    'About: ${_lesson!.title}'
                    '${live ? '' : '  ·  offline mode'}',
                    style: const TextStyle(fontSize: 12),
                  ),
                ),
              ),
            ),
          ),
          body: Column(
            children: [
              Expanded(
                child: _messages.isEmpty
                    ? _Suggestions(onPick: (q) {
                        _controller.text = q;
                        _send();
                      })
                    : ListView.builder(
                        controller: _scrollController,
                        padding: const EdgeInsets.all(Gap.md),
                        itemCount: _messages.length + (_thinking ? 1 : 0),
                        itemBuilder: (_, i) {
                          if (i == _messages.length) {
                            return const _Bubble(
                              text: 'Thinking…',
                              fromUser: false,
                            );
                          }
                          final m = _messages[i];
                          return _Bubble(text: m.text, fromUser: m.fromUser);
                        },
                      ),
              ),
              SafeArea(
                top: false,
                child: Padding(
                  padding: const EdgeInsets.all(Gap.md),
                  child: Row(
                    children: [
                      Expanded(
                        child: TextField(
                          controller: _controller,
                          minLines: 1,
                          maxLines: 4,
                          textInputAction: TextInputAction.send,
                          onSubmitted: (_) => _send(),
                          decoration: const InputDecoration(
                            hintText: 'Ask about this lesson…',
                          ),
                        ),
                      ),
                      const SizedBox(width: Gap.sm),
                      FilledButton(
                        onPressed: _thinking ? null : _send,
                        style: FilledButton.styleFrom(
                          minimumSize: const Size(52, 52),
                          padding: EdgeInsets.zero,
                          backgroundColor: AppColors.primary,
                        ),
                        child: const Icon(Icons.send, color: Colors.white),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

class _Suggestions extends StatelessWidget {
  const _Suggestions({required this.onPick});
  final ValueChanged<String> onPick;

  static const _qs = [
    'Can you explain this lesson in simpler terms?',
    'What are the most exam-relevant points here?',
    'Give me a quick example to remember this.',
    'How is this likely to be asked in Prelims?',
  ];

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.all(Gap.lg),
      children: [
        const Icon(Icons.psychology_alt_outlined,
            size: 56, color: AppColors.primary),
        const SizedBox(height: Gap.md),
        Text('Ask anything about this lesson',
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.titleMedium),
        const SizedBox(height: Gap.sm),
        Text(
          'The AI answers using the lesson content so explanations stay on-topic.',
          textAlign: TextAlign.center,
          style: TextStyle(color: context.muted),
        ),
        const SizedBox(height: Gap.lg),
        for (final q in _qs)
          Padding(
            padding: const EdgeInsets.only(bottom: Gap.sm),
            child: OutlinedButton(
              onPressed: () => onPick(q),
              style: OutlinedButton.styleFrom(
                alignment: Alignment.centerLeft,
                padding: const EdgeInsets.all(Gap.md),
              ),
              child: Text(q, textAlign: TextAlign.left),
            ),
          ),
      ],
    );
  }
}

class _Bubble extends StatelessWidget {
  const _Bubble({required this.text, required this.fromUser});
  final String text;
  final bool fromUser;

  @override
  Widget build(BuildContext context) {
    return Align(
      alignment: fromUser ? Alignment.centerRight : Alignment.centerLeft,
      child: Container(
        constraints: BoxConstraints(
            maxWidth: MediaQuery.of(context).size.width * 0.82),
        margin: const EdgeInsets.only(bottom: Gap.sm),
        padding: const EdgeInsets.all(Gap.md),
        decoration: BoxDecoration(
          color: fromUser ? AppColors.primary : context.surfaceAlt,
          borderRadius: BorderRadius.only(
            topLeft: const Radius.circular(Radii.md),
            topRight: const Radius.circular(Radii.md),
            bottomLeft: Radius.circular(fromUser ? Radii.md : 4),
            bottomRight: Radius.circular(fromUser ? 4 : Radii.md),
          ),
        ),
        child: Text(
          text,
          style: TextStyle(
            // Explicit colors both ways so text never matches its bubble.
            color: fromUser ? Colors.white : context.fg,
            height: 1.5,
          ),
        ),
      ),
    );
  }
}
