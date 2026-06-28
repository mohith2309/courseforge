import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_tts/flutter_tts.dart';

import '../models/models.dart';
import '../theme/app_theme.dart';

/// A narrated "video" lesson player. There's no real video file for AI-built
/// lessons, so the generated content plays as an auto-advancing slide reel with
/// real text-to-speech narration — title, the taught script chunked into slides,
/// then a key-point recap. It reads each slide aloud and moves on when done.
///
/// The slideshow is FREE for everyone (full lesson). The only paid distinction
/// is the small corner watermark, removed on Pro.
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
  const _Slide(this.kicker, this.body);
}

class _LessonPlayerState extends State<LessonPlayer> {
  final FlutterTts _tts = FlutterTts();
  late List<_Slide> _slides;
  int _i = 0;
  bool _playing = true;
  bool _ttsOn = true;
  bool _suppress =
      false; // ignore the completion fired by a programmatic stop()
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    _slides = _buildSlides();
    _initTts();
  }

  Future<void> _initTts() async {
    try {
      await _tts.setLanguage('en-US');
      await _tts.setSpeechRate(0.48); // natural classroom pace
      await _tts.setPitch(1.0);
      await _tts.setVolume(1.0);
      _tts.setCompletionHandler(() {
        if (!_suppress && _playing && mounted) _advanceFrom(_i);
      });
      _tts.setErrorHandler((_) {
        // TTS engine hiccup — let the backup timer carry the reel forward.
      });
    } catch (_) {/* no TTS engine — backup timer still advances */}
    if (_playing && mounted) _scheduleSlide();
  }

  @override
  void didUpdateWidget(covariant LessonPlayer old) {
    super.didUpdateWidget(old);
    if (old.lesson.id != widget.lesson.id || old.isPro != widget.isPro) {
      _slides = _buildSlides();
      _i = 0;
      if (_playing) _scheduleSlide();
    }
  }

  List<_Slide> _buildSlides() {
    final l = widget.lesson;
    final slides = <_Slide>[_Slide('LESSON', l.title)];
    if (l.summary.isNotEmpty) slides.add(_Slide('OVERVIEW', l.summary));

    // The lesson is TAUGHT here — the full script, chunked into readable,
    // narratable slides. Free for everyone (no pay wall in the slideshow).
    final chunks = _chunkScript(l.script);
    final total = chunks.length;
    for (var n = 0; n < chunks.length; n++) {
      slides.add(_Slide('LESSON · ${n + 1}/$total', chunks[n]));
    }

    // Key-point recap at the end.
    for (var n = 0; n < l.keyPoints.length; n++) {
      slides.add(_Slide('KEY POINT ${n + 1}', l.keyPoints[n]));
    }
    if (slides.length == 1) {
      slides.add(const _Slide('OVERVIEW', 'Lesson content is loading…'));
    }
    return slides;
  }

  /// Split the script into ~3-sentence teaching slides.
  List<String> _chunkScript(String script) {
    final clean = script.replaceAll(RegExp(r'\s+'), ' ').trim();
    if (clean.isEmpty) return const [];
    final sentences = clean
        .split(RegExp(r'(?<=[.!?])\s+'))
        .where((s) => s.trim().isNotEmpty)
        .toList();
    final out = <String>[];
    for (var i = 0; i < sentences.length; i += 3) {
      out.add(
          sentences.sublist(i, (i + 3).clamp(0, sentences.length)).join(' '));
    }
    return out;
  }

  /// Narrate the current slide and arm a backup timer (in case TTS never fires
  /// its completion — common on some devices), so the reel always moves on.
  Future<void> _scheduleSlide() async {
    _timer?.cancel();
    final from = _i;
    final body = _slides[_i].body.trim();
    // Backup duration ~ reading time (≈2.3 words/sec) + buffer.
    final words = body.isEmpty ? 1 : body.split(RegExp(r'\s+')).length;
    final secs = (words / 2.3 + 1.8).clamp(3.5, 32.0);
    _timer = Timer(Duration(milliseconds: (secs * 1000).round()),
        () => _advanceFrom(from));

    _suppress = true;
    try {
      await _tts.stop();
    } catch (_) {}
    _suppress = false;
    if (_playing && _ttsOn && body.isNotEmpty) {
      try {
        await _tts.speak(body);
      } catch (_) {}
    }
  }

  void _advanceFrom(int from) {
    if (!mounted || !_playing || _i != from) return;
    _next();
  }

  void _next() {
    if (_i < _slides.length - 1) {
      setState(() => _i++);
      if (_playing) _scheduleSlide();
    } else {
      setState(() => _playing = false);
      _timer?.cancel();
      _tts.stop();
    }
  }

  void _prev() {
    if (_i > 0) {
      setState(() => _i--);
      if (_playing) _scheduleSlide();
    }
  }

  void _togglePlay() {
    setState(() => _playing = !_playing);
    if (_playing) {
      _scheduleSlide();
    } else {
      _timer?.cancel();
      _tts.stop();
    }
  }

  void _toggleTts() {
    setState(() => _ttsOn = !_ttsOn);
    if (!_ttsOn) {
      _tts.stop();
    } else if (_playing) {
      _scheduleSlide();
    }
  }

  @override
  void dispose() {
    _timer?.cancel();
    _tts.stop();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final slide = _slides[_i];
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        AspectRatio(
          aspectRatio: 16 / 9,
          child: ClipRRect(
            borderRadius: BorderRadius.circular(Radii.md),
            child: Stack(
              children: [
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
                Positioned.fill(
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(20, 18, 20, 40),
                    child: AnimatedSwitcher(
                      duration: const Duration(milliseconds: 400),
                      child: _SlideView(key: ValueKey(_i), slide: slide),
                    ),
                  ),
                ),
                if (!widget.isPro)
                  const Positioned(
                    right: 10,
                    top: 8,
                    child: Opacity(
                      opacity: 0.6,
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.auto_awesome,
                              size: 12, color: Colors.white),
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
                // Tap zones: left = prev, right = next.
                Positioned.fill(
                  child: Row(
                    children: [
                      Expanded(
                        child: GestureDetector(
                          behavior: HitTestBehavior.translucent,
                          onTap: _prev,
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
                Positioned(
                  left: 0,
                  right: 0,
                  bottom: 0,
                  child: _Controls(
                    playing: _playing,
                    ttsOn: _ttsOn,
                    index: _i,
                    total: _slides.length,
                    onToggle: _togglePlay,
                    onToggleTts: _toggleTts,
                  ),
                ),
              ],
            ),
          ),
        ),
        // Narration transcript below the player (what TTS is reading).
        const SizedBox(height: 12),
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: context.surfaceAlt,
            borderRadius: BorderRadius.circular(Radii.md),
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Icon(_ttsOn ? Icons.graphic_eq : Icons.subtitles_outlined,
                  size: 18, color: AppColors.primary),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  slide.body,
                  style:
                      TextStyle(fontSize: 15, height: 1.45, color: context.fg),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _SlideView extends StatelessWidget {
  const _SlideView({super.key, required this.slide});
  final _Slide slide;

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
      ],
    );
  }
}

class _Controls extends StatelessWidget {
  const _Controls({
    required this.playing,
    required this.ttsOn,
    required this.index,
    required this.total,
    required this.onToggle,
    required this.onToggleTts,
  });
  final bool playing;
  final bool ttsOn;
  final int index;
  final int total;
  final VoidCallback onToggle;
  final VoidCallback onToggleTts;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        IconButton(
          onPressed: onToggle,
          iconSize: 22,
          tooltip: playing ? 'Pause' : 'Play',
          icon: Icon(playing ? Icons.pause : Icons.play_arrow,
              color: Colors.white),
        ),
        IconButton(
          onPressed: onToggleTts,
          iconSize: 20,
          tooltip: ttsOn ? 'Mute narration' : 'Unmute narration',
          icon: Icon(ttsOn ? Icons.volume_up : Icons.volume_off,
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
    );
  }
}
