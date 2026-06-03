import 'dart:async';
import 'package:flutter/material.dart';

import '../models/models.dart';
import '../theme/app_theme.dart';

/// An "interactive video" lesson player. Rather than a real video file (none
/// exist for AI-generated lessons), it presents the generated content as a
/// narrated, auto-advancing slide reel — title, then each key point, then a
/// recap — so the lesson actually plays and the learner *sees* what was built.
///
/// Free tier: a short version (intro + key points) with a corner watermark.
/// Pro tier: the full detailed reel (adds script passages), no watermark.
class LessonPlayer extends StatefulWidget {
  const LessonPlayer({
    super.key,
    required this.lesson,
    required this.isPro,
    required this.onUpgrade,
  });

  final Lesson lesson;
  final bool isPro;
  final VoidCallback onUpgrade;

  @override
  State<LessonPlayer> createState() => _LessonPlayerState();
}

class _Slide {
  final String kicker;
  final String body;
  final bool locked; // shown only as an upgrade prompt on free
  const _Slide(this.kicker, this.body, {this.locked = false});
}

class _LessonPlayerState extends State<LessonPlayer> {
  late List<_Slide> _slides;
  int _i = 0;
  bool _playing = true;
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    _slides = _buildSlides();
    _arm();
  }

  @override
  void didUpdateWidget(covariant LessonPlayer old) {
    super.didUpdateWidget(old);
    if (old.lesson.id != widget.lesson.id || old.isPro != widget.isPro) {
      _slides = _buildSlides();
      _i = 0;
      _arm();
    }
  }

  List<_Slide> _buildSlides() {
    final l = widget.lesson;
    final slides = <_Slide>[_Slide('LESSON', l.title)];
    if (l.summary.isNotEmpty) {
      slides.add(const _Slide('OVERVIEW', '').let(l.summary));
    }

    // The lesson is TAUGHT here: the explanation itself, chunked into readable
    // slides (~2 sentences each) so it plays like a narrated lesson.
    final chunks = _chunkScript(l.script);
    final total = chunks.length;
    // Free = shortened (first ~4 chunks) + an upgrade card; Pro = full lesson.
    final shown = widget.isPro ? chunks : chunks.take(4).toList();
    for (var n = 0; n < shown.length; n++) {
      slides.add(_Slide('LESSON · ${n + 1}/$total', shown[n]));
    }
    if (!widget.isPro && total > shown.length) {
      slides.add(_Slide(
        'PRO',
        'You\'re seeing the short version. Upgrade to watch the full lesson '
        '(${total - shown.length} more parts) with no watermark.',
        locked: true,
      ));
    }

    // Key points recap at the end.
    for (var n = 0; n < l.keyPoints.length; n++) {
      slides.add(_Slide('KEY POINT ${n + 1}', l.keyPoints[n]));
    }
    if (slides.length == 1) {
      slides.add(const _Slide('OVERVIEW', 'Lesson content is loading…'));
    }
    return slides;
  }

  /// Split the script into ~2-sentence teaching slides.
  List<String> _chunkScript(String script) {
    final clean = script.replaceAll(RegExp(r'\s+'), ' ').trim();
    if (clean.isEmpty) return const [];
    final sentences = clean
        .split(RegExp(r'(?<=[.!?])\s+'))
        .where((s) => s.trim().isNotEmpty)
        .toList();
    final out = <String>[];
    for (var i = 0; i < sentences.length; i += 2) {
      out.add(sentences.sublist(i, (i + 2).clamp(0, sentences.length)).join(' '));
    }
    return out;
  }

  void _arm() {
    _timer?.cancel();
    if (_playing) {
      _timer = Timer.periodic(const Duration(milliseconds: 3800), (_) => _next());
    }
  }

  void _next() {
    if (_i < _slides.length - 1) {
      setState(() => _i++);
    } else {
      setState(() => _playing = false);
      _timer?.cancel();
    }
  }

  void _togglePlay() {
    setState(() => _playing = !_playing);
    _arm();
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final slide = _slides[_i];
    return AspectRatio(
      aspectRatio: 16 / 9,
      child: ClipRRect(
        borderRadius: BorderRadius.circular(Radii.md),
        child: Stack(
          children: [
            // Background.
            Positioned.fill(
              child: DecoratedBox(
                decoration: const BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [AppColors.primaryDark, AppColors.secondary],
                  ),
                ),
              ),
            ),
            // Slide content (tap right half = next, left half = prev).
            Positioned.fill(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(20, 18, 20, 34),
                child: AnimatedSwitcher(
                  duration: const Duration(milliseconds: 400),
                  child: _SlideView(
                    key: ValueKey(_i),
                    slide: slide,
                    onUpgrade: widget.onUpgrade,
                  ),
                ),
              ),
            ),
            // Watermark (free only) — small, corner, like Gemini's.
            if (!widget.isPro)
              const Positioned(
                right: 10,
                top: 8,
                child: Opacity(
                  opacity: 0.6,
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.auto_awesome, size: 12, color: Colors.white),
                      SizedBox(width: 3),
                      Text('CourseForge',
                          style: TextStyle(
                              color: Colors.white,
                              fontSize: 11,
                              fontWeight: FontWeight.w600)),
                    ],
                  ),
                ),
              ),
            // Tap zones.
            Positioned.fill(
              child: Row(
                children: [
                  Expanded(
                    child: GestureDetector(
                      behavior: HitTestBehavior.translucent,
                      onTap: () => setState(() {
                        if (_i > 0) _i--;
                      }),
                    ),
                  ),
                  Expanded(
                    child: GestureDetector(
                      behavior: HitTestBehavior.translucent,
                      onTap: _next,
                    ),
                  ),
                ],
              ),
            ),
            // Controls + progress.
            Positioned(
              left: 0,
              right: 0,
              bottom: 0,
              child: _Controls(
                playing: _playing,
                index: _i,
                total: _slides.length,
                onToggle: _togglePlay,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _SlideView extends StatelessWidget {
  const _SlideView({super.key, required this.slide, required this.onUpgrade});
  final _Slide slide;
  final VoidCallback onUpgrade;

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(slide.kicker,
            style: const TextStyle(
                color: Colors.white70,
                fontSize: 12,
                fontWeight: FontWeight.w700,
                letterSpacing: 1.5)),
        const SizedBox(height: 8),
        Flexible(
          child: SingleChildScrollView(
            child: Text(
              slide.body,
              style: const TextStyle(
                  color: Colors.white,
                  fontSize: 18,
                  height: 1.4,
                  fontWeight: FontWeight.w600),
            ),
          ),
        ),
        if (slide.locked) ...[
          const SizedBox(height: 12),
          FilledButton.icon(
            style: FilledButton.styleFrom(
                backgroundColor: AppColors.accent,
                visualDensity: VisualDensity.compact),
            onPressed: onUpgrade,
            icon: const Icon(Icons.workspace_premium, size: 16),
            label: const Text('Upgrade to watch full'),
          ),
        ],
      ],
    );
  }
}

class _Controls extends StatelessWidget {
  const _Controls({
    required this.playing,
    required this.index,
    required this.total,
    required this.onToggle,
  });
  final bool playing;
  final int index;
  final int total;
  final VoidCallback onToggle;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Row(
          children: [
            IconButton(
              onPressed: onToggle,
              iconSize: 22,
              icon: Icon(playing ? Icons.pause : Icons.play_arrow,
                  color: Colors.white),
            ),
            Expanded(
              child: ClipRRect(
                borderRadius: BorderRadius.circular(99),
                child: LinearProgressIndicator(
                  value: total <= 1 ? 1 : index / (total - 1),
                  minHeight: 4,
                  backgroundColor: Colors.white24,
                  color: Colors.white,
                ),
              ),
            ),
            const SizedBox(width: 10),
            Text('${index + 1}/$total',
                style: const TextStyle(color: Colors.white, fontSize: 12)),
            const SizedBox(width: 10),
          ],
        ),
      ],
    );
  }
}

// Tiny helper so the summary slide reads naturally.
extension on _Slide {
  _Slide let(String body) => _Slide(kicker, body, locked: locked);
}
