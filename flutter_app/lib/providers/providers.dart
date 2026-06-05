import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/models.dart';
import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

import '../services/ai_service.dart';
import '../services/api_client.dart';
import '../services/content_repository.dart';
import '../services/gemini_service.dart';
import '../services/google_auth_service.dart';
import '../services/generated_courses_store.dart';
import '../services/nim_service.dart';
import '../services/payment_service.dart';
import '../services/progress_store.dart';
import '../services/razorpay_checkout.dart';
import '../services/upi_payment.dart';

// ---- Services ----------------------------------------------------------

final contentRepositoryProvider =
    Provider<ContentRepository>((ref) => ContentRepository());

final geminiServiceProvider =
    Provider<GeminiService>((ref) => GeminiService());

final nimServiceProvider = Provider<NimService>((ref) => NimService());

final apiClientProvider = Provider<ApiClient>((ref) => ApiClient());

final razorpayCheckoutProvider =
    Provider<RazorpayCheckout>((ref) => RazorpayCheckout());

final upiPaymentProvider = Provider<UpiPayment>((ref) => UpiPayment());

/// Multi-provider AI router. Routes through the backend when BACKEND_URL is
/// set; otherwise uses the on-device Gemini + NIM providers.
final aiServiceProvider = Provider<AiService>((ref) => AiService(
      gemini: ref.watch(geminiServiceProvider),
      nim: ref.watch(nimServiceProvider),
      api: ref.watch(apiClientProvider),
    ));

final paymentServiceProvider =
    Provider<PaymentService>((ref) => PaymentService());

final progressStoreProvider =
    Provider<ProgressStore>((ref) => ProgressStore());

final generatedCoursesStoreProvider =
    Provider<GeneratedCoursesStore>((ref) => GeneratedCoursesStore());

// ---- Course library ----------------------------------------------------

/// Holds every course: AI-generated ones (persisted locally) first, then the
/// bundled sample courses. Mutable so a freshly generated course appears
/// instantly across the app.
class CourseLibraryNotifier extends StateNotifier<AsyncValue<List<Course>>> {
  CourseLibraryNotifier(this._repo, this._store)
      : super(const AsyncValue.loading()) {
    _load();
  }

  final ContentRepository _repo;
  final GeneratedCoursesStore _store;

  Future<void> _load() async {
    try {
      final bundled = await _repo.getCourses();
      final generated = await _store.load();
      state = AsyncValue.data([...generated, ...bundled]);
    } catch (e, st) {
      state = AsyncValue.error(e, st);
    }
  }

  Future<void> addCourse(Course course) async {
    await _store.add(course);
    final current = state.value ?? const [];
    state = AsyncValue.data([
      course,
      ...current.where((c) => c.id != course.id),
    ]);
  }

  Future<void> removeCourse(String id) async {
    await _store.remove(id);
    final current = state.value ?? const [];
    state = AsyncValue.data(current.where((c) => c.id != id).toList());
  }

  /// Replaces one lesson's content (used by lazy per-lesson AI generation).
  /// Only called for AI-generated courses, so it's safe to persist.
  Future<void> updateLesson(
      String courseId, String lessonId, Map<String, dynamic> patch) async {
    final list = state.value ?? const [];
    final idx = list.indexWhere((c) => c.id == courseId);
    if (idx < 0) return;
    final j = list[idx].toJson();
    for (final mod in (j['modules'] as List)) {
      for (final les in ((mod as Map)['lessons'] as List)) {
        if ((les as Map)['id'] == lessonId) {
          les.addAll(patch);
        }
      }
    }
    final updated = Course.fromJson(j);
    if (updated.aiGenerated) await _store.add(updated);
    state = AsyncValue.data(
        [for (final c in list) c.id == courseId ? updated : c]);
  }
}

final coursesProvider =
    StateNotifierProvider<CourseLibraryNotifier, AsyncValue<List<Course>>>(
        (ref) {
  return CourseLibraryNotifier(
    ref.watch(contentRepositoryProvider),
    ref.watch(generatedCoursesStoreProvider),
  );
});

final categoriesProvider = Provider<AsyncValue<List<String>>>((ref) {
  return ref.watch(coursesProvider).whenData((courses) {
    final set = <String>{};
    for (final c in courses) {
      set.add(c.category);
    }
    return ['All', ...set];
  });
});

/// Look a course up from the live library (so AI courses are found too).
final courseProvider = Provider.family<AsyncValue<Course?>, String>((ref, id) {
  return ref.watch(coursesProvider).whenData((courses) {
    for (final c in courses) {
      if (c.id == id) return c;
    }
    return null;
  });
});

final creatorProvider =
    FutureProvider.family<Creator?, String>((ref, id) async {
  return ref.watch(contentRepositoryProvider).getCreator(id);
});

// ---- AI course generation ----------------------------------------------

/// Tracks an in-flight generation so the UI can show progress.
final courseGenerationProvider =
    StateNotifierProvider<CourseGenerationNotifier, AsyncValue<Course?>>((ref) {
  return CourseGenerationNotifier(ref);
});

class CourseGenerationNotifier extends StateNotifier<AsyncValue<Course?>> {
  CourseGenerationNotifier(this._ref) : super(const AsyncValue.data(null));
  final Ref _ref;

  Future<Course?> generate(String goal) async {
    state = const AsyncValue.loading();
    try {
      final course = await _ref.read(aiServiceProvider).generateCourse(goal);
      await _ref.read(coursesProvider.notifier).addCourse(course);
      // Auto-enroll — the learner asked for it, they're already "in".
      await _ref.read(progressProvider.notifier).enroll(course.id);
      state = AsyncValue.data(course);
      return course;
    } catch (e, st) {
      state = AsyncValue.error(e, st);
      return null;
    }
  }

  void reset() => state = const AsyncValue.data(null);
}

/// Search/category UI state for the marketplace.
final searchQueryProvider = StateProvider<String>((ref) => '');
final selectedCategoryProvider = StateProvider<String>((ref) => 'All');

final filteredCoursesProvider = Provider<AsyncValue<List<Course>>>((ref) {
  final coursesAsync = ref.watch(coursesProvider);
  final query = ref.watch(searchQueryProvider).trim().toLowerCase();
  final category = ref.watch(selectedCategoryProvider);

  return coursesAsync.whenData((courses) {
    return courses.where((c) {
      final matchesCategory = category == 'All' || c.category == category;
      final matchesQuery = query.isEmpty ||
          c.title.toLowerCase().contains(query) ||
          c.subtitle.toLowerCase().contains(query) ||
          c.tags.any((t) => t.toLowerCase().contains(query));
      return matchesCategory && matchesQuery;
    }).toList();
  });
});

// ---- Progress (the app's mutable student state) ------------------------

class ProgressNotifier extends StateNotifier<ProgressState> {
  ProgressNotifier(this._store) : super(const ProgressState()) {
    _init();
  }

  final ProgressStore _store;

  Future<void> _init() async {
    state = await _store.load();
  }

  Future<void> _persist() => _store.save(state);

  void _markActiveToday() {
    final today = ProgressState.fmtToday();
    if (state.activeDays.contains(today)) return;
    state = state.copyWith(activeDays: [...state.activeDays, today]);
  }

  Future<void> enroll(String courseId) async {
    state = state.copyWith(
      enrolledCourseIds: {...state.enrolledCourseIds, courseId},
    );
    _markActiveToday();
    await _persist();
  }

  bool isEnrolled(String courseId) =>
      state.enrolledCourseIds.contains(courseId);

  /// Adds XP to lifetime + today's tally. Last awarded amount is exposed via
  /// [lastXpGain] so screens can show a "+N XP" toast.
  int lastXpGain = 0;
  void _addXp(int amount) {
    if (amount <= 0) return;
    final today = ProgressState.fmtToday();
    final dailyBase = state.dailyXpDay == today ? state.dailyXp : 0;
    lastXpGain = amount;
    state = state.copyWith(
      xp: state.xp + amount,
      dailyXp: dailyBase + amount,
      dailyXpDay: today,
    );
  }

  Future<void> completeLesson(String lessonId, int lessonMinutes) async {
    if (state.completedLessonIds.contains(lessonId)) return;
    state = state.copyWith(
      completedLessonIds: {...state.completedLessonIds, lessonId},
      timeSpentMinutes: state.timeSpentMinutes + lessonMinutes,
    );
    _addXp(15); // +15 XP per lesson finished
    _markActiveToday();
    await _persist();
  }

  bool isLessonComplete(String lessonId) =>
      state.completedLessonIds.contains(lessonId);

  Future<void> recordQuizScore(String quizId, int percent) async {
    final best = state.quizScores[quizId] ?? 0;
    if (percent <= best) return;
    state = state.copyWith(
      quizScores: {...state.quizScores, quizId: percent},
    );
    // XP for a new best: +30 for passing, +20 bonus for a perfect score.
    if (percent >= 60) _addXp(30 + (percent >= 100 ? 20 : 0));
    _markActiveToday();
    await _persist();
  }

  /// Spend a heart (wrong practice answer). No-op effect for Pro is handled by
  /// the caller. Returns hearts remaining.
  Future<int> useHeart() async {
    final today = ProgressState.fmtToday();
    final used = state.heartsDay == today ? state.heartsUsedToday : 0;
    state = state.copyWith(heartsUsedToday: used + 1, heartsDay: today);
    await _persist();
    return state.heartsRemaining;
  }

  Future<void> toggleBookmark(String lessonId) async {
    final set = {...state.bookmarkedLessonIds};
    if (!set.add(lessonId)) set.remove(lessonId);
    state = state.copyWith(bookmarkedLessonIds: set);
    await _persist();
  }

  bool isBookmarked(String lessonId) =>
      state.bookmarkedLessonIds.contains(lessonId);

  Future<void> saveNote(String lessonId, String text) async {
    final notes = {...state.notes};
    if (text.trim().isEmpty) {
      notes.remove(lessonId);
    } else {
      notes[lessonId] = text;
    }
    state = state.copyWith(notes: notes);
    await _persist();
  }

  /// 0.0–1.0 completion for a course given its lesson list.
  double completionFor(Course course) {
    if (course.totalLessons == 0) return 0;
    final done = course.allLessons
        .where((l) => state.completedLessonIds.contains(l.id))
        .length;
    return done / course.totalLessons;
  }
}

final progressProvider =
    StateNotifierProvider<ProgressNotifier, ProgressState>((ref) {
  return ProgressNotifier(ref.watch(progressStoreProvider));
});

/// Theme mode toggle (light/dark/system).
final themeModeProvider = StateProvider<ThemeModeChoice>(
  (ref) => ThemeModeChoice.system,
);

enum ThemeModeChoice { system, light, dark }

// ---- Subscription tier -------------------------------------------------

/// Everything core is free. Pro removes the lesson-video watermark, unlocks
/// full-length detailed video lessons, and unlimited AI practice quizzes.
/// Persisted locally; a real payment flow (Razorpay) slots in behind upgrade().
class SubscriptionNotifier extends StateNotifier<bool> {
  SubscriptionNotifier() : super(false) {
    _load();
  }
  static const _key = 'courseforge_is_pro_v1';

  Future<void> _load() async {
    final prefs = await SharedPreferences.getInstance();
    state = prefs.getBool(_key) ?? false;
  }

  Future<void> setPro(bool value) async {
    state = value;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_key, value);
  }
}

/// true = CourseForge Pro.
final isProProvider =
    StateNotifierProvider<SubscriptionNotifier, bool>((ref) {
  return SubscriptionNotifier();
});

/// Holds a freshly AI-generated practice question set to hand to the quiz
/// screen in practice mode. Free users get one set per lesson visit; Pro is
/// unlimited (enforced in the UI).
final practiceQuizProvider = StateProvider<List<Question>>((ref) => const []);

// ---- Accounts (optional) -----------------------------------------------

final googleAuthServiceProvider =
    Provider<GoogleAuthService>((ref) => GoogleAuthService());

class AuthState {
  final String? token;
  final String? userId;
  final String? name;
  final String? photoUrl;
  final bool google; // signed in via Google
  const AuthState({
    this.token,
    this.userId,
    this.name,
    this.photoUrl,
    this.google = false,
  });
  bool get signedIn => token != null && userId != null;
}

/// Accounts are optional — the app is fully usable signed out. Signing in
/// (against the backend) is required only to publish a course. Persisted
/// locally; the token is opaque to the client.
class AuthNotifier extends StateNotifier<AuthState> {
  AuthNotifier(this._api, this._google) : super(const AuthState()) {
    _load();
  }
  final ApiClient _api;
  final GoogleAuthService _google;
  static const _k = 'courseforge_auth_v1';

  Future<void> _load() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_k);
    if (raw == null) return;
    final j = jsonDecode(raw) as Map<String, dynamic>;
    state = AuthState(
      token: j['token'] as String?,
      userId: j['userId'] as String?,
      name: j['name'] as String?,
      photoUrl: j['photoUrl'] as String?,
      google: j['google'] as bool? ?? false,
    );
    _api.setAuthToken(state.token); // restore bearer for protected calls
  }

  Future<void> _persist() async {
    final prefs = await SharedPreferences.getInstance();
    if (!state.signedIn) {
      await prefs.remove(_k);
    } else {
      await prefs.setString(
          _k,
          jsonEncode({
            'token': state.token,
            'userId': state.userId,
            'name': state.name,
            'photoUrl': state.photoUrl,
            'google': state.google,
          }));
    }
  }

  /// Sign in with Google (Firebase). Returns null on success, error/cancel msg.
  Future<String?> signInWithGoogle() async {
    try {
      final u = await _google.signIn();
      if (u == null) return 'cancelled';
      // Exchange the Google ID token for a SERVER token so protected endpoints
      // (publish/pay) accept this user. Falls back to local-only if no backend.
      String? serverToken;
      if (_api.isConfigured && u.idToken != null) {
        final ex = await _api.exchangeGoogle(u.idToken!);
        if (ex.ok) serverToken = ex.token;
      }
      state = AuthState(
        token: serverToken ?? u.uid,
        userId: u.uid,
        name: u.name,
        photoUrl: u.photoUrl,
        google: true,
      );
      _api.setAuthToken(state.token);
      await _persist();
      return null;
    } catch (e) {
      return 'Google sign-in failed: $e';
    }
  }

  /// Returns null on success, or an error message.
  Future<String?> register(String email, String password, String name) async {
    final r = await _api.register(email, password, name);
    if (!r.ok) return r.error;
    state = AuthState(token: r.token, userId: r.userId, name: r.name);
    _api.setAuthToken(state.token);
    await _persist();
    return null;
  }

  Future<String?> login(String email, String password) async {
    final r = await _api.login(email, password);
    if (!r.ok) return r.error;
    state = AuthState(token: r.token, userId: r.userId, name: r.name);
    _api.setAuthToken(state.token);
    await _persist();
    return null;
  }

  Future<void> signOut() async {
    if (state.google) {
      try {
        await _google.signOut();
      } catch (_) {/* ignore */}
    }
    state = const AuthState();
    _api.setAuthToken(null);
    await _persist();
  }
}

final authProvider = StateNotifierProvider<AuthNotifier, AuthState>((ref) {
  return AuthNotifier(
      ref.watch(apiClientProvider), ref.watch(googleAuthServiceProvider));
});

// ---- Community marketplace (published courses) -------------------------

class PublishedListing {
  final Map<String, dynamic> raw;
  final Course course;
  final int priceInr;
  final String publisherName;
  final bool publisherVerified;
  final int enrollmentsCount;

  PublishedListing.fromMap(this.raw)
      : course = Course.fromJson(raw),
        priceInr = (raw['priceInr'] as num?)?.toInt() ?? 0,
        publisherName = raw['publisherName']?.toString() ?? 'Unknown',
        publisherVerified = raw['publisherVerified'] as bool? ?? false,
        enrollmentsCount = (raw['enrollmentsCount'] as num?)?.toInt() ?? 0;

  /// The course as the buyer will own it (not an AI draft, credited to seller).
  Course ownedCopy() => Course.fromJson({
        ...raw,
        'aiGenerated': false,
      });
}

final publishedCoursesProvider =
    FutureProvider.autoDispose<List<PublishedListing>>((ref) async {
  final api = ref.watch(apiClientProvider);
  if (!api.isConfigured) return [];
  final raw = await api.publishedCourses();
  return raw.map(PublishedListing.fromMap).toList();
});

/// Marketplace purchase via Razorpay (Route): the server creates an order that
/// auto-splits the creator's 70% to their linked account and keeps the 30%
/// platform fee. Opens the native checkout, verifies, then owns + enrolls.
/// Returns null on success, or an error/cancel message.
Future<String?> buyListing(WidgetRef ref, PublishedListing listing) async {
  final api = ref.read(apiClientProvider);
  final auth = ref.read(authProvider);
  final checkout = ref.read(razorpayCheckoutProvider);
  final buyerId = auth.userId ?? 'guest';

  // Server ties orders (and the Route split) to a signed-in buyer.
  if (api.isConfigured && !auth.signedIn) {
    return 'Please sign in to buy this course.';
  }

  // 1. Server order (carries the creator/platform transfer split).
  String? orderId;
  String? keyId;
  bool mockOrder = true;
  if (api.isConfigured) {
    final order = await api.createOrder(
      courseId: listing.course.id,
      amountInr: listing.priceInr,
      buyerId: buyerId,
    );
    if (order == null) return 'Could not start checkout. Try again.';
    orderId = order.orderId;
    keyId = order.keyId;
    mockOrder = order.mock;
  }

  // 2. Native Razorpay checkout.
  final result = await checkout.pay(
    amountInr: listing.priceInr,
    description: listing.course.title,
    orderId: orderId,
    keyId: keyId,
  );
  if (!result.success) return result.error ?? 'Payment cancelled';

  // 3. Verify (server). Simulated when no real signature is present.
  if (api.isConfigured && orderId != null) {
    final ok = await api.verifyPayment(
      orderId: orderId,
      courseId: listing.course.id,
      buyerId: buyerId,
      paymentId: result.paymentId,
      signature: result.signature,
      mock: result.simulated || mockOrder || result.signature == null,
    );
    if (!ok) return 'Payment could not be verified.';
  }

  // 4. Own it (locally + record the id so it survives sign-in migration).
  final owned = listing.ownedCopy();
  await ref.read(coursesProvider.notifier).addCourse(owned);
  await ref.read(progressProvider.notifier).enroll(owned.id);
  await recordOwnedLocally(listing.course.id);
  return null;
}

// ---- Entitlements (server is the source of truth) ----------------------

const _ownedKey = 'courseforge_owned_v1';

/// Remember a purchased course id locally so a guest's purchase can be claimed
/// onto their account when they later sign in.
Future<void> recordOwnedLocally(String courseId) async {
  final prefs = await SharedPreferences.getInstance();
  final list = prefs.getStringList(_ownedKey) ?? <String>[];
  if (!list.contains(courseId)) {
    list.add(courseId);
    await prefs.setStringList(_ownedKey, list);
  }
}

/// Sync entitlements with the server. On sign-in pass [claim] = true to attach
/// guest purchases + Pro to the account; on launch pass false to just pull the
/// authoritative state. The server wins for Pro + ownership (anti-tamper), and
/// any owned course missing locally is fetched from the marketplace.
Future<void> syncEntitlements(WidgetRef ref, {bool claim = false}) async {
  final api = ref.read(apiClientProvider);
  final auth = ref.read(authProvider);
  if (!api.isConfigured || !auth.signedIn) return;
  final prefs = await SharedPreferences.getInstance();
  final localOwned = prefs.getStringList(_ownedKey) ?? <String>[];
  final localPro = prefs.getBool('courseforge_is_pro_v1') ?? false;

  final ent = claim
      ? await api.claimEntitlements(localOwned, localPro)
      : await api.getEntitlements();
  if (ent == null) return;

  await ref.read(isProProvider.notifier).setPro(ent.pro);
  await prefs.setStringList(_ownedKey, ent.owned);

  // Make owned courses appear in the library (e.g. on a fresh device).
  final lib = ref.read(coursesProvider).value ?? const [];
  final have = lib.map((c) => c.id).toSet();
  final missing = ent.owned.where((id) => !have.contains(id)).toList();
  if (missing.isNotEmpty) {
    final listings =
        (await api.publishedCourses()).map(PublishedListing.fromMap).toList();
    for (final id in missing) {
      final match = listings.where((l) => l.course.id == id);
      if (match.isNotEmpty) {
        final owned = match.first.ownedCopy();
        await ref.read(coursesProvider.notifier).addCourse(owned);
        await ref.read(progressProvider.notifier).enroll(owned.id);
      }
    }
  }
}

// ---- Admin review ------------------------------------------------------

/// Admin token (entered in the Admin screen). Session-scoped.
final adminTokenProvider = StateProvider<String>((ref) => '');

final adminPendingProvider =
    FutureProvider.autoDispose<List<Map<String, dynamic>>>((ref) async {
  final token = ref.watch(adminTokenProvider);
  if (token.isEmpty) return [];
  return ref.watch(apiClientProvider).adminPending(token);
});
