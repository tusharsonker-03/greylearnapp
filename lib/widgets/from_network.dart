

import 'dart:async';
import 'dart:convert';
import 'package:academy_app/models/lesson.dart';
import 'package:http/http.dart' as http;
import 'package:pod_player/pod_player.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../constants.dart';
import '../providers/my_courses.dart';
import '../providers/shared_pref_helper.dart';

class PlayVideoFromNetwork extends StatefulWidget {
  static const routeName = '/fromNetwork';
  final int courseId;
  final int? lessonId;
  final String videoUrl;
  final String language;

  const PlayVideoFromNetwork({
    super.key,
    required this.courseId,
    this.lessonId,
    required this.videoUrl,
    this.language = 'english',
  });

  @override
  State<PlayVideoFromNetwork> createState() => _PlayVideoFromAssetState();
}

class _PlayVideoFromAssetState extends State<PlayVideoFromNetwork> {
  // --- CONFIG ---
  // static const double LOCAL_END_AT = 0.995; // ~99.5%
  static const double LOCAL_END_AT = 1.0; // ✅ only when fully completed

  bool _popped = false; // 👈 once-only guard


  // --- STATE ---
  PodPlayerController? _c;
  bool _localEnd = false;
  bool _serverCompleted = false;
  bool _switching = false;
  Timer? _timer;

  // current lesson/url
  late int _currentLessonId;
  late String _currentUrl;

  @override
  void initState() {
    super.initState();
    _currentLessonId = widget.lessonId ?? 0;
    _currentUrl = widget.videoUrl;
    debugPrint("[INIT] lessonId=$_currentLessonId url=$_currentUrl");
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      debugPrint("[INIT] post-frame → _initAndAutoplay()");
      await _initAndAutoplay(_currentUrl);
      _startTick();
    });
  }


  void _onPlaybackProgress(Duration position, Duration total) {
    if (_popped) return;
    if (total.inMilliseconds <= 0) return;

    final p = position.inMilliseconds / total.inMilliseconds;
    if (p >= 0.97) {          // ~97% dekh liya => complete
      _popped = true;
      Navigator.pop(context, {'completed': true}); // 👈 parent ko result
    }
  }

  void _onPlaybackCompleted() {
    if (_popped) return;
    _popped = true;
    Navigator.pop(context, {'completed': true});   // 👈 safety for exact end
  }

  // --- Player init + autoplay (REVISED ORDER) ---
  Future<void> _initAndAutoplay(String url) async {
    debugPrint("[PLAYER] reinit requested for URL=$url");
    _stopTick();

    // 1) old cleanup
    try { _c?.removeListener(_onTick); debugPrint("[PLAYER] old listener removed"); } catch (_) {}
    final old = _c; // keep local to dispose after publish to avoid races
    _c = null;      // prevent "used after dispose" during rebuild
    setState(() {}); // detach old controller from UI
    try { old?.dispose(); debugPrint("[PLAYER] old controller disposed"); } catch (_) {}

    // 2) create new (DO NOT initialise yet)
    final isHls = url.toLowerCase().endsWith('.m3u8');
    debugPrint("[PLAYER] isHls=$isHls");
    final ctrl = isHls
        ? PodPlayerController(playVideoFrom: PlayVideoFrom.network(url))
        : PodPlayerController(
      playVideoFrom: PlayVideoFrom.networkQualityUrls(videoUrls: [
        VideoQalityUrls(quality: 360, url: url),
        VideoQalityUrls(quality: 720, url: url),
      ]),
    );

    // reset flags for new video
    _localEnd = false;
    _serverCompleted = false;
    debugPrint("[FLAGS] reset: localEnd=false, serverCompleted=false");

    // 3) publish controller first → so PodVideoPlayer builds & registers GetX
    _c = ctrl;
    setState(() {}); // now PodVideoPlayer (with new controller) is in the tree

    // 4) next frame: initialise + play (GetX now available)
    await Future.delayed(Duration.zero);
    debugPrint("[PLAYER] calling initialise()");
    await _c!.initialise();
    debugPrint("[PLAYER] initialise() done; calling play()");
    try { _c!.play(); debugPrint("[PLAYER] play() called"); } catch (e) { debugPrint("[PLAYER] play() threw: $e"); }

    // 5) attach listener & start timer
    _c!.addListener(_onTick);
    debugPrint("[LISTENER] attached");
    _startTick();
  }

  // ---------- Player listener ----------
  void _onTick() {
    if (!mounted || _c == null) return;
    final total = _c!.totalVideoLength;
    final pos = _c!.currentVideoPosition;
    if (total.inMilliseconds <= 0) return;

    final pct = pos.inMilliseconds / total.inMilliseconds;
    if ((pct >= 0.25 && pct < 0.26) || (pct >= 0.50 && pct < 0.51) || (pct >= 0.75 && pct < 0.76)) {
      debugPrint("[TICK] lesson=$_currentLessonId progress=${(pct*100).toStringAsFixed(1)}% (${pos.inSeconds}/${total.inSeconds}s)");
    }

    final remain = total.inSeconds - pos.inSeconds;
    if (!_localEnd && pct >= 1.0) { // ✅ only at 100%
      _localEnd = true;
      debugPrint("🏁 [LOCAL-END] TRUE at 100%");
      _pushProgress();
      // ❌ pop mat karo yahan; next decide _tryAutoNext() karega
      _tryAutoNext();
    }
  }

  // ---------- Timer ----------
  void _startTick() {
    _timer?.cancel();
    debugPrint("[TIMER] start 5s periodic");
    _timer = Timer.periodic(const Duration(seconds: 5), (_) {
      // backup → localEnd mark yahi se bhi (sirf progress based)
      final c = _c;
      if (c != null) {
        final t = c.totalVideoLength;
        final p = c.currentVideoPosition;
        if (t.inMilliseconds > 0 && !_localEnd) {
          final pct = p.inMilliseconds / t.inMilliseconds;
          final remain = t - p;
          if (pct >= 1.0)  {
            _localEnd = true;
            debugPrint("🏁 [LOCAL-END:TIMER] TRUE via timer (pct=${(pct*100).toStringAsFixed(2)}%, remain=${remain.inSeconds}s)");
            _tryAutoNext();
          }
        }
      }

      debugPrint("[TIMER] tick → pushProgress + tryAutoNext");
      _pushProgress();
      _tryAutoNext();
    });
  }

  void _stopTick() {
    try { _timer?.cancel(); } catch (_) {}
    _timer = null;
    debugPrint("[TIMER] stopped");
  }

  // ---------- Server sync ----------
  Future<void> _pushProgress() async {
    if (_c == null || _currentLessonId == 0) return;
    final t = _c!.totalVideoLength;
    final p = _c!.currentVideoPosition;
    if (t.inMilliseconds <= 0) return;

    // listener miss safety → UWH me bhi localEnd mark (sirf progress se)
    final pctNow = t.inMilliseconds > 0 ? (p.inMilliseconds / t.inMilliseconds) : 0.0;
    final remainNow = t - p;
    // ✅ Trigger only when video is truly 100% completed
    // if (!_localEnd && pctNow >= 1.0) {
    //   _localEnd = true;
    //   debugPrint("🏁 [LOCAL-END:UWH] TRUE via UWH (fully completed, pct=${(pctNow*100).toStringAsFixed(2)}%)");
    //   _tryAutoNext();
    // }

    if (!_localEnd && (pctNow >= LOCAL_END_AT || remainNow <= const Duration(seconds: 3))) {
      _localEnd = true;
      debugPrint("🏁 [LOCAL-END:UWH] TRUE via UWH (pct=${(pctNow*100).toStringAsFixed(2)}%, remain=${remainNow.inSeconds}s)");
      _tryAutoNext();
    }

    final token = await SharedPreferenceHelper().getAuthToken();
    if (token == null || token.isEmpty) { debugPrint("[UWH] token missing → skip"); return; }

    final uri = Uri.parse("$BASE_URL/api/update_watch_history");
    final body = {
      'auth_token': token,
      'course_id': widget.courseId.toString(),
      'lesson_id': _currentLessonId.toString(),
      'current_duration': p.inSeconds.toString(),
    };

    debugPrint("🚀 [UWH] POST → $uri (lesson=$_currentLessonId t=${p.inSeconds}s)");
    final res = await http.post(
      uri,
      headers: const {
        'Accept':'application/json',
        'Content-Type':'application/x-www-form-urlencoded; charset=UTF-8'
      },
      body: body,
    );
    debugPrint("📡 [UWH] status=${res.statusCode} len=${res.body.length}");

    if (res.statusCode >= 200 && res.statusCode < 300 &&
        (res.headers['content-type'] ?? '').toLowerCase().contains('application/json')) {
      final data = json.decode(res.body);
      debugPrint("📄 [UWH] json=$data");

      // stale guard
      final respId = '${data is Map ? data['lesson_id'] : ''}';
      if (respId.isNotEmpty && respId != _currentLessonId.toString()) {
        debugPrint("↩️ [UWH] stale resp for lesson=$respId (current=$_currentLessonId) → ignore");
        return;
      }

      final before = _serverCompleted;
      _serverCompleted = (data is Map && (data['is_completed'] == 1 || data['is_completed'] == '1'));
      if (_serverCompleted != before) debugPrint("✅ [UWH] serverCompleted changed → ${_serverCompleted}");

      // if (_serverCompleted) {
      //   try {
      //     Provider.of<MyCourses>(context, listen: false).updateDripContendLesson(
      //         widget.courseId, data['course_progress'], data['number_of_completed_lessons']);
      //     debugPrint("↻ [UWH] provider counters updated");
      //   } catch (e) { debugPrint("⚠️ [UWH] provider update err: $e"); }
      // }
      if (_serverCompleted) {
        try {
          Provider.of<MyCourses>(context, listen: false).updateDripContendLesson(
              widget.courseId, data['course_progress'], data['number_of_completed_lessons']);
          debugPrint("↻ [UWH] provider counters updated");

          // ✅ SERVER se is_completed=1 aate hi sections reload karo (UI turant refresh)
          await Provider.of<MyCourses>(context, listen: false)
              .fetchCourseSections(widget.courseId, widget.language.toLowerCase());
          debugPrint("✅ [UWH] sections refreshed after completion");
        } catch (e) {
          debugPrint("⚠️ [UWH] provider refresh err: $e");
        }
      }


      // NOTE: yahan pe AB hum localEnd ko force TRUE **NAHI** kar rahe.
      // Auto-next tabhi chalega jab:
      //   _serverCompleted == true  AND  _localEnd == true (progress-based).
    } else {
      debugPrint("⚠️ [UWH] bad response: ct=${res.headers['content-type']}");
    }
  }

  // ---------- Two-flag gate → auto-next ----------
  Future<void> _tryAutoNext() async {

    if (_popped) {
      debugPrint("[AUTONEXT] skipped (already popped)");
      return;
    }

    // Strict gate: BOTH required
    if (!_localEnd || !_serverCompleted) {
      debugPrint("… [AUTONEXT] wait (localEnd=$_localEnd, serverCompleted=$_serverCompleted)");
      return;
    }
    if (_switching) { debugPrint("… [AUTONEXT] already switching"); return; }
    _switching = true;
    debugPrint("[AUTONEXT] GO → fetch sections");

    try {
      await Provider.of<MyCourses>(context, listen: false)
          .fetchCourseSections(widget.courseId, widget.language.toLowerCase());
      debugPrint("[AUTONEXT] sections fetched");
    } catch (e) {
      debugPrint("❌ [AUTONEXT] fetch sections failed: $e");
    }
    if (!mounted) return;

    final sections = Provider.of<MyCourses>(context, listen: false).sectionItems;

    Lesson? cur; Lesson? next;
    for (final sec in sections) {
      for (int i = 0; i < (sec.mLesson?.length ?? 0); i++) {
        final l = sec.mLesson![i];
        if ((l.id ?? -1) == _currentLessonId) {
          cur = l;
          if (i + 1 < sec.mLesson!.length) {
            next = sec.mLesson![i + 1];
          } else {
            final idx = sections.indexOf(sec);
            if (idx + 1 < sections.length && (sections[idx + 1].mLesson?.isNotEmpty ?? false)) {
              next = sections[idx + 1].mLesson!.first;
            }
          }
          break;
        }
      }
    }
    debugPrint("[AUTONEXT] cur=${cur?.id} next=${next?.id}");

    if (next == null) {
      debugPrint("✅ [AUTONEXT] no next → finish & pop");
      _finishAndPop();
      _switching = false;
      return;
    }

    if ((next.lessonType ?? '').toLowerCase() == 'quiz') {
      debugPrint("ℹ️ [AUTONEXT] next is quiz → pop with signal (no auto-next)");
      _popped = true;          // guard
      _stopTick();
      try { _c?.removeListener(_onTick); } catch (_) {}
      final tmp = _c; _c = null; try { tmp?.dispose(); } catch (_) {}
      if (mounted) Navigator.pop(context, {'completed': true, 'next_is_quiz': true});
      _switching = false;
      return;
    }


    // defensive: ensure server shows current completed (unlock)
    final v = cur?.isCompleted;
    final curOk = (v is int && v == 1) || (v is String && v.trim() == '1');
    debugPrint("[AUTONEXT] cur.isCompleted=${cur?.isCompleted} → ok=$curOk");
    if (!curOk) { _switching = false; debugPrint("⏳ [AUTONEXT] server not yet reflecting → wait"); return; }

    final nextUrl = (next.videoUrlWeb ?? next.videoUrl ?? '').trim();
    if (nextUrl.isEmpty) {
      debugPrint("❌ [AUTONEXT] nextUrl empty → finish & pop");
      _finishAndPop();
      _switching = false;
      return;
    }

    debugPrint("[AUTONEXT] cooldown 300ms then play next=${next.id}");
    await Future.delayed(const Duration(milliseconds: 300)); // Exo cool-down

    _currentLessonId = next.id!;
    _currentUrl = nextUrl;
    debugPrint("[AUTONEXT] switching to lesson=$_currentLessonId url=$_currentUrl");
    await _initAndAutoplay(_currentUrl);  // re-init + play
    _switching = false;
  }

  // ---------- Exit ----------
  Future<void> _finishAndPop() async {
    debugPrint("[FINISH] exit player (completed=true)");
    _stopTick();
    try { _c?.removeListener(_onTick); } catch (_) {}
    final tmp = _c;
    _c = null; // prevent any late tick from using disposed controller
    try { tmp?.dispose(); } catch (_) {}
    if (mounted) Navigator.pop(context, {'completed': true});
  }

  @override
  void dispose() {
    debugPrint("[DISPOSE] called");
    _stopTick();
    try { _c?.removeListener(_onTick); } catch (_) {}
    final tmp = _c;
    _c = null; // guards every use after this point
    try { tmp?.dispose(); } catch (_) {}
    super.dispose();
  }

  // ---------- UI ----------
  @override
  Widget build(BuildContext context) {
    if (_c == null) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }
    return Scaffold(
      appBar: AppBar(elevation: 0, backgroundColor: kBackgroundColor, iconTheme: const IconThemeData(color: Colors.black)),
      backgroundColor: kBackgroundColor,
      body: SafeArea(
        child: Center(
          child: PodVideoPlayer(
            key: ValueKey(_currentLessonId), // 👈 IMPORTANT so widget rebuilds per lesson
            controller: _c!,
            podProgressBarConfig: const PodProgressBarConfig(
              padding: kIsWeb ? EdgeInsets.zero : EdgeInsets.only(bottom: 20, left: 20, right: 20),
              playingBarColor: Colors.blue,
              circleHandlerColor: Colors.blue,
              backgroundColor: Colors.blueGrey,
            ),
          ),
        ),
      ),
    );
  }
}
