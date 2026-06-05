import 'dart:convert';
import 'package:http/http.dart' as http;
import '../models/models.dart';
import 'course_parser.dart';

class AuthResult {
  final bool ok;
  final String? token;
  final String? userId;
  final String? name;
  final String? error;
  const AuthResult({
    required this.ok,
    this.token,
    this.userId,
    this.name,
    this.error,
  });
}

/// Talks to the CourseForge backend (server/). When [baseUrl] is empty the
/// app runs fully on-device (embedded keys + local stores); set it with
/// --dart-define=BACKEND_URL=http://localhost:8788 to route through the server.
class ApiClient {
  ApiClient({String? baseUrl})
      : _base = (baseUrl ??
                const String.fromEnvironment('BACKEND_URL', defaultValue: ''))
            .replaceAll(RegExp(r'/$'), '');

  final String _base;

  // Shared secret gating the AI proxy (matches server APP_KEY). Raises the bar
  // for raw-URL abuse; the per-IP rate limit caps damage either way.
  static const _appKey = String.fromEnvironment('APP_KEY',
      defaultValue: 'cfapp_63d2aac1bd27443980dae80524b88a2f475510fb');

  // Server-issued bearer token (set by AuthNotifier on sign-in).
  String? _authToken;
  void setAuthToken(String? t) => _authToken = t;

  bool get isConfigured => _base.isNotEmpty;

  Uri _u(String path) => Uri.parse('$_base$path');

  Map<String, String> get _ai =>
      {'Content-Type': 'application/json', 'x-app-key': _appKey};
  Map<String, String> get _authed => {
        'Content-Type': 'application/json',
        if (_authToken != null) 'Authorization': 'Bearer $_authToken',
      };

  Future<bool> health() async {
    try {
      final r = await http
          .get(_u('/health'))
          .timeout(const Duration(seconds: 5));
      return r.statusCode == 200;
    } catch (_) {
      return false;
    }
  }

  // ---- Auth -------------------------------------------------------------
  Future<AuthResult> register(String email, String password, String name) =>
      _auth('/auth/register', {'email': email, 'password': password, 'name': name});

  Future<AuthResult> login(String email, String password) =>
      _auth('/auth/login', {'email': email, 'password': password});

  /// Exchange a verified Google/Firebase ID token for a server bearer token,
  /// so Google sign-in users can also use protected endpoints (publish/pay).
  Future<AuthResult> exchangeGoogle(String idToken) =>
      _auth('/auth/exchange', {'idToken': idToken});

  Future<AuthResult> _auth(String path, Map<String, dynamic> body) async {
    try {
      final r = await http.post(_u(path),
          headers: {'Content-Type': 'application/json'},
          body: jsonEncode(body));
      final j = jsonDecode(r.body) as Map<String, dynamic>;
      if (r.statusCode == 200) {
        return AuthResult(
          ok: true,
          token: j['token'] as String?,
          userId: j['userId'] as String?,
          name: j['name'] as String?,
        );
      }
      return AuthResult(ok: false, error: j['error']?.toString() ?? 'failed');
    } catch (e) {
      return AuthResult(ok: false, error: 'Network error — is the server running?');
    }
  }

  // ---- AI proxies (keys stay on the server) -----------------------------
  Future<Course> generateCourse(String goal) async {
    final r = await http
        .post(_u('/ai/generate-course'),
            headers: _ai,
            body: jsonEncode({'goal': goal}))
        .timeout(const Duration(seconds: 120));
    if (r.statusCode != 200) throw Exception('generate-course ${r.statusCode}');
    return courseFromAiJson(jsonDecode(r.body) as Map<String, dynamic>, goal);
  }

  /// Generates a full, in-depth taught lesson (500ish words + key points +
  /// quiz) for one lesson — called lazily when the learner opens it.
  Future<Map<String, dynamic>?> generateLesson({
    required String courseTitle,
    required String moduleTitle,
    required String lessonTitle,
    required String summary,
  }) async {
    final r = await http
        .post(_u('/ai/lesson'),
            headers: _ai,
            body: jsonEncode({
              'courseTitle': courseTitle,
              'moduleTitle': moduleTitle,
              'lessonTitle': lessonTitle,
              'summary': summary,
            }))
        .timeout(const Duration(seconds: 120));
    if (r.statusCode != 200) return null;
    return jsonDecode(r.body) as Map<String, dynamic>;
  }

  Future<String> answerDoubt({
    required String question,
    required Lesson lesson,
  }) async {
    final r = await http
        .post(_u('/ai/doubt'),
            headers: _ai,
            body: jsonEncode({
              'question': question,
              'lessonTitle': lesson.title,
              'lessonText': lesson.script,
            }))
        .timeout(const Duration(seconds: 60));
    if (r.statusCode != 200) throw Exception('doubt ${r.statusCode}');
    return (jsonDecode(r.body) as Map<String, dynamic>)['text']?.toString() ?? '';
  }

  Future<List<Question>> practice({
    required Lesson lesson,
    int count = 5,
    String difficulty = 'medium',
  }) async {
    final r = await http.post(_u('/ai/practice'),
        headers: _ai,
        body: jsonEncode({
          'lessonTitle': lesson.title,
          'lessonText': lesson.script,
          'count': count,
          'difficulty': difficulty,
        }));
    if (r.statusCode != 200) throw Exception('practice ${r.statusCode}');
    final list =
        (jsonDecode(r.body) as Map<String, dynamic>)['questions'] as List? ?? [];
    return list
        .map((q) => Question.fromJson(q as Map<String, dynamic>))
        .toList();
  }

  // ---- Publishing -------------------------------------------------------
  Future<String?> publishCourse({
    required Course course,
    required int priceInr,
    required String publisherId,
  }) async {
    try {
      final r = await http.post(_u('/courses/publish'),
          headers: _authed,
          body: jsonEncode({
            'course': course.toJson(),
            'priceInr': priceInr,
            'publisherId': publisherId,
          }));
      if (r.statusCode == 200) return null; // success
      final j = jsonDecode(r.body) as Map<String, dynamic>;
      return j['error']?.toString() ?? 'Publish failed (${r.statusCode})';
    } catch (_) {
      return 'Network error — is the server running?';
    }
  }

  /// Save the creator's Razorpay linked account id (acc_…) so their course
  /// sales auto-split to them via Razorpay Route. Returns null on success.
  Future<String?> setPayoutAccount(String accountId) async {
    try {
      final r = await http.post(_u('/publisher/payout-account'),
          headers: _authed, body: jsonEncode({'accountId': accountId}));
      if (r.statusCode == 200) return null;
      final j = jsonDecode(r.body) as Map<String, dynamic>;
      return j['error']?.toString() ?? 'Failed (${r.statusCode})';
    } catch (_) {
      return 'Network error — is the server running?';
    }
  }

  Future<String?> getPayoutAccount() async {
    try {
      final r = await http.get(_u('/publisher/payout-account'), headers: _authed);
      if (r.statusCode != 200) return null;
      return (jsonDecode(r.body) as Map<String, dynamic>)['accountId']
          ?.toString();
    } catch (_) {
      return null;
    }
  }

  Future<List<Map<String, dynamic>>> publishedCourses() async {
    try {
      final r = await http.get(_u('/courses/published'));
      final j = jsonDecode(r.body) as Map<String, dynamic>;
      return (j['courses'] as List? ?? [])
          .cast<Map<String, dynamic>>();
    } catch (_) {
      return [];
    }
  }

  // ---- Payments (Razorpay) ----------------------------------------------
  Future<OrderInfo?> createOrder({
    required String courseId,
    required int amountInr,
    required String buyerId,
  }) async {
    try {
      final r = await http.post(_u('/payments/create-order'),
          headers: _authed,
          body: jsonEncode(
              {'courseId': courseId, 'amountInr': amountInr, 'buyerId': buyerId}));
      if (r.statusCode != 200) return null;
      final j = jsonDecode(r.body) as Map<String, dynamic>;
      return OrderInfo(
        orderId: j['orderId'] as String,
        amountPaise: (j['amount'] as num).toInt(),
        keyId: j['keyId']?.toString() ?? '',
        mock: j['mock'] as bool? ?? true,
      );
    } catch (_) {
      return null;
    }
  }

  /// Confirms payment. [paymentId]/[signature] come from the Razorpay checkout
  /// SDK in a real build; omitted here for a test-mode (simulated) completion.
  Future<bool> verifyPayment({
    required String orderId,
    required String courseId,
    required String buyerId,
    String? paymentId,
    String? signature,
    bool mock = true,
  }) async {
    final r = await http.post(_u('/payments/verify'),
        headers: _authed,
        body: jsonEncode({
          'orderId': orderId,
          'courseId': courseId,
          'buyerId': buyerId,
          'paymentId': paymentId,
          'signature': signature,
          'mock': mock,
        }));
    if (r.statusCode != 200) return false;
    return (jsonDecode(r.body) as Map<String, dynamic>)['ok'] == true;
  }

  // ---- Admin ------------------------------------------------------------
  Future<List<Map<String, dynamic>>> adminPending(String adminToken) async {
    try {
      final r = await http.get(_u('/admin/pending'),
          headers: {'x-admin-token': adminToken});
      if (r.statusCode != 200) return [];
      return ((jsonDecode(r.body) as Map<String, dynamic>)['courses'] as List? ??
              [])
          .cast<Map<String, dynamic>>();
    } catch (_) {
      return [];
    }
  }

  Future<String?> adminReview(
      String adminToken, String courseId, String action) async {
    try {
      final r = await http.post(_u('/admin/review'),
          headers: {
            'Content-Type': 'application/json',
            'x-admin-token': adminToken
          },
          body: jsonEncode({'courseId': courseId, 'action': action}));
      if (r.statusCode == 200) return null;
      return (jsonDecode(r.body) as Map<String, dynamic>)['error']?.toString() ??
          'failed';
    } catch (_) {
      return 'Network error';
    }
  }

  Future<String?> adminVerifyPublisher(
      String adminToken, String userId) async {
    try {
      final r = await http.post(_u('/admin/verify-publisher'),
          headers: {
            'Content-Type': 'application/json',
            'x-admin-token': adminToken
          },
          body: jsonEncode({'userId': userId}));
      if (r.statusCode == 200) return null;
      return (jsonDecode(r.body) as Map<String, dynamic>)['error']?.toString() ??
          'failed';
    } catch (_) {
      return 'Network error';
    }
  }
}

class OrderInfo {
  final String orderId;
  final int amountPaise;
  final String keyId;
  final bool mock;
  const OrderInfo({
    required this.orderId,
    required this.amountPaise,
    required this.keyId,
    required this.mock,
  });
}
