import '../models/match.dart';
import '../models/message.dart';
import '../models/user.dart';

/// Ô nhập mà lỗi auth gắn vào.
enum AuthField { email, password, confirm }

class AuthException implements Exception {
  final String message;
  final AuthField field;
  const AuthException(this.message, this.field);

  @override
  String toString() => message;
}

/// Kho user trong bộ nhớ — chỉ để giả lập auth ở giai đoạn FE, mất hết khi tắt app.
class MockUserStore {
  MockUserStore._();

  static final List<AppUser> _users = [
    AppUser(
      id: 'u1',
      email: 'nearsoul.test@gmail.com',
      password: '123456',
      nickname: 'Tester',
      birthYear: 2000,
      gender: 'male',
      avatarId: 1,
    ),
    AppUser(
      id: 'u2',
      email: 'phamkhanhduyvo@gmail.com',
      password: '123456',
      nickname: 'Duy',
      birthYear: 2003,
      gender: 'male',
      avatarId: 4,
    ),
    AppUser(
      id: 'u4',
      email: 'linh.tran@gmail.com',
      password: '123456',
      nickname: 'Linh',
      birthYear: 2002,
      gender: 'female',
      avatarId: 3,
    ),
    AppUser(
      id: 'u5',
      email: 'minh.nguyen@outlook.com',
      password: '123456',
      nickname: 'Minh',
      birthYear: 2001,
      gender: 'other',
      avatarId: 6,
    ),
    // Chưa có hồ sơ ẩn danh: đăng nhập sẽ đi qua màn "Tạo hồ sơ của bạn".
    AppUser(id: 'u6', email: 'chuacohoso@gmail.com', password: '123456'),
  ];

  static int _nextUserId = 100; // tránh trùng id với các tài khoản mẫu

  static AppUser? _current;
  static AppUser? get currentUser => _current;

  static String _normalize(String email) => email.trim().toLowerCase();

  static AppUser? findByEmail(String email) {
    final key = _normalize(email);
    for (final u in _users) {
      if (u.email == key) return u;
    }
    return null;
  }

  static AppUser login(String email, String password) {
    final user = findByEmail(email);
    if (user == null) {
      throw const AuthException('Email không đúng', AuthField.email);
    }
    if (user.password != password) {
      throw const AuthException('Mật khẩu không đúng', AuthField.password);
    }
    return _current = user;
  }

  static AppUser register(String email, String password) {
    if (findByEmail(email) != null) {
      throw const AuthException('Email này đã được đăng ký', AuthField.email);
    }
    final user = AppUser(
      id: 'u${_nextUserId++}',
      email: _normalize(email),
      password: password,
    );
    _users.add(user);
    return _current = user;
  }

  static void logout() => _current = null;

  /// Lưu hồ sơ ẩn danh cho user đang đăng nhập.
  static void updateProfile({
    required String nickname,
    required int birthYear,
    required String gender,
    required int avatarId,
  }) {
    final user = _current;
    if (user == null) return;
    user
      ..nickname = nickname.trim()
      ..birthYear = birthYear
      ..gender = gender
      ..avatarId = avatarId;
  }

  // ---- Radar: người ở gần (mock) ----

  /// Những người "đang online quanh bạn" mà radar có thể tìm thấy, theo thứ tự tìm thấy.
  static final List<NearbyPerson> nearby = [
    NearbyPerson(
      distanceMeters: 120,
      user: AppUser(
        id: 's1',
        email: 'may.nho@nearsoul.mock',
        password: '',
        nickname: 'Mây Nhỏ',
        birthYear: DateTime.now().year - 21,
        gender: 'female',
        avatarId: 11,
        bio: 'Thích những cuộc trò chuyện sâu sắc và những quán cà phê yên tĩnh.',
        isOnline: true,
      ),
    ),
    NearbyPerson(
      distanceMeters: 85,
      response: MockResponse.decline, // giả lập: từ chối
      quiz: const QuizBehavior(mcAnswers: [1, 1, 1]),
      user: AppUser(
        id: 's2',
        email: 'nang.mai@nearsoul.mock',
        password: '',
        nickname: 'Nắng Mai',
        birthYear: DateTime.now().year - 24,
        gender: 'female',
        avatarId: 7,
        bio: 'Mê sách cũ, nhạc acoustic và những buổi chiều đi bộ quanh hồ.',
        isOnline: true,
      ),
    ),
    NearbyPerson(
      distanceMeters: 170,
      response: MockResponse.ignore, // giả lập: im lặng, để yêu cầu tự hết hạn
      quiz: const QuizBehavior(mcAnswers: [0, 1, 0]),
      user: AppUser(
        id: 's3',
        email: 'gio.dong@nearsoul.mock',
        password: '',
        nickname: 'Gió Đông',
        birthYear: DateTime.now().year - 26,
        gender: 'male',
        avatarId: 5,
        bio: 'Thích khám phá quán ăn nhỏ và trò chuyện về những điều giản dị.',
        isOnline: true,
      ),
    ),
  ];

  /// Yêu cầu kết nối đã gửi trong phiên này.
  static final List<Match> matches = [];

  static const double radarRadiusMeters = 200;

  /// Người phù hợp kế tiếp theo bộ lọc an toàn: online, dưới 200m, không bị chặn, chưa bị bỏ qua.
  static NearbyPerson? nextNearby({Set<String> skipped = const {}}) {
    final blocked = _current?.blockedUsers ?? const <String>[];
    for (final p in nearby) {
      if (!p.user.isOnline || p.distanceMeters > radarRadiusMeters) continue;
      if (blocked.contains(p.user.id) || skipped.contains(p.user.id)) continue;
      if (isHiddenFromRadar(p.user.id)) continue;
      return p;
    }
    return null;
  }

  static void blockUser(String userId) {
    final user = _current;
    if (user == null || user.blockedUsers.contains(userId)) return;
    user.blockedUsers.add(userId);
  }

  // ---- Quiz ----

  /// Hết phiên Quiz sau ngần này kể từ lúc bắt đầu, dù đã xong hay chưa.
  static const quizSessionLimit = Duration(minutes: 5);

  /// Không khớp Quiz: hai người ẩn khỏi radar của nhau trong ngần này.
  static const hideAfterNoMatch = Duration(hours: 24);

  /// Chat mở sau khi khớp Quiz kéo dài ngần này.
  static const chatDuration = Duration(hours: 48);

  static final Map<String, DateTime> _hiddenUntil = {};

  static bool isHiddenFromRadar(String userId) {
    final until = _hiddenUntil[userId];
    return until != null && until.isAfter(DateTime.now());
  }

  static void hideFromRadar(String userId, Duration duration) {
    _hiddenUntil[userId] = DateTime.now().add(duration);
  }

  /// Xoá các người đang bị ẩn (dùng khi test).
  static void clearHidden() => _hiddenUntil.clear();

  /// Cách [userId] làm Quiz nếu là một người mock; người khác dùng hành vi mặc định.
  static QuizBehavior quizBehaviorFor(String userId) {
    for (final p in [...nearby, incomingRequester]) {
      if (p.user.id == userId) return p.quiz;
    }
    return const QuizBehavior();
  }

  /// Match đang ở giai đoạn Quiz với [partnerId]; chưa có thì tạo mới (ví dụ khi mở thẳng màn Quiz).
  static Match quizMatchWith(String partnerId) {
    for (final m in matches.reversed) {
      final involved = m.userA == partnerId || m.userB == partnerId;
      if (involved && m.status == MatchStatus.quiz) return m;
    }
    final match = Match(
      id: 'm${matches.length + 1}',
      userA: _current?.id ?? '',
      userB: partnerId,
      status: MatchStatus.quiz,
    );
    matches.add(match);
    return match;
  }

  /// Kết thúc phiên trước khi xong (thoát, hết giờ, người kia rời đi): không lưu lại đáp án dở dang.
  static void expireMatch(String matchId) {
    for (final m in matches) {
      if (m.id != matchId) continue;
      if (m.status == MatchStatus.pending || m.status == MatchStatus.quiz) {
        m.status = MatchStatus.expired;
        m.quizAnswers.clear();
        m.freeTextAnswers.clear();
      }
    }
  }

  /// Người dùng chọn "Quay lại Radar" ở màn kết quả: hủy kết quả, phòng chat không mở và không lưu gì lại.
  static void cancelMatchResult(String matchId) {
    for (final m in matches) {
      if (m.id != matchId || m.status != MatchStatus.chatting) continue;
      m
        ..status = MatchStatus.expired
        ..chatExpiresAt = null
        ..quizScore = 0
        ..quizAnswers = {}
        ..freeTextAnswers = {}
        ..freeTextQuestions = [];
      messages.removeWhere((msg) => msg.matchId == matchId);
    }
  }

  /// Cả hai đã làm xong: lưu đáp án và điểm. Khớp thì mở chat 48 giờ; không khớp thì ẩn nhau 24 giờ.
  static void completeQuiz(
    Match match, {
    required String userId,
    required String partnerId,
    required List<int> myAnswers,
    required List<int> partnerAnswers,
    required List<String> myTexts,
    required List<String> partnerTexts,
    required List<String> freeTextQuestions,
    required int score,
    required bool matched,
  }) {
    match
      ..quizAnswers = {userId: myAnswers, partnerId: partnerAnswers}
      ..freeTextAnswers = {userId: myTexts, partnerId: partnerTexts}
      ..freeTextQuestions = freeTextQuestions
      ..quizScore = score;
    if (matched) {
      match
        ..status = MatchStatus.chatting
        ..chatExpiresAt = DateTime.now().add(chatDuration);
    } else {
      match
        ..status = MatchStatus.rejected
        ..hiddenUntil = DateTime.now().add(hideAfterNoMatch)
        // Không lưu câu tự luận của phiên không khớp.
        ..freeTextAnswers = {}
        ..freeTextQuestions = [];
      hideFromRadar(partnerId, hideAfterNoMatch);
    }
  }

  // ---- Chat 48 giờ ----

  static final List<Message> messages = [];
  static int _nextMessageId = 1;

  /// Người dùng (tài khoản, người ở gần hoặc người gửi yêu cầu đến) theo mã.
  static AppUser? userById(String id) {
    for (final u in _users) {
      if (u.id == id) return u;
    }
    for (final p in [...nearby, incomingRequester]) {
      if (p.user.id == id) return p.user;
    }
    return null;
  }

  /// Tin nhắn của một cuộc trò chuyện theo thứ tự cũ → mới.
  static List<Message> messagesFor(String matchId) =>
      messages.where((m) => m.matchId == matchId).toList()
        ..sort((a, b) => a.createdAt.compareTo(b.createdAt));

  static Message addMessage({
    required String matchId,
    required String senderId,
    required String text,
    DateTime? at,
  }) {
    final message = Message(
      id: 'msg${_nextMessageId++}',
      matchId: matchId,
      senderId: senderId,
      text: text.trim(),
      createdAt: at ?? DateTime.now(),
    );
    messages.add(message);
    return message;
  }

  /// Các cuộc trò chuyện 48 giờ còn hiệu lực của người đang đăng nhập, mới mở gần nhất trước.
  static List<Match> activeChats({DateTime? now}) {
    final me = _current?.id;
    final time = now ?? DateTime.now();
    return matches
        .where(
          (m) =>
              m.status == MatchStatus.chatting &&
              (m.userA == me || m.userB == me) &&
              (m.chatExpiresAt?.isAfter(time) ?? false),
        )
        .toList()
      ..sort((a, b) => b.chatExpiresAt!.compareTo(a.chatExpiresAt!));
  }

  /// Người còn lại trong một match, tính từ phía người đang đăng nhập.
  static AppUser? partnerOf(Match match) =>
      userById(match.userA == _current?.id ? match.userB : match.userA);

  /// Lời đáp giả lập của người kia (chưa có backend), lần lượt theo thứ tự.
  static const partnerReplies = [
    'Chào bạn! Mình cũng vừa nghĩ tới chuyện đó luôn.',
    'Nghe hay đó, bạn kể thêm đi.',
    'Mình cũng thích vậy, hiếm ai cùng gu như thế.',
    'Hôm nay bạn đang ở khu nào vậy?',
    'Vui quá, nói chuyện với bạn dễ chịu ghê.',
  ];

  static String partnerReply(int index) =>
      partnerReplies[index % partnerReplies.length];

  /// Thời hạn chờ người kia phản hồi một yêu cầu kết nối.
  static const requestTimeout = Duration(seconds: 30);

  /// Bạn gửi yêu cầu: ở trạng thái chờ phản hồi và hết hạn sau [requestTimeout].
  static Match sendRequest(String userId) {
    final now = DateTime.now();
    final match = Match(
      id: 'm${matches.length + 1}',
      userA: _current?.id ?? '',
      userB: userId,
      status: MatchStatus.pending,
      requestExpiresAt: now.add(requestTimeout),
      createdAt: now,
    );
    matches.add(match);
    return match;
  }

  /// Người gửi yêu cầu đến bạn (giả lập, vì chưa có backend đẩy sự kiện).
  static final NearbyPerson incomingRequester = NearbyPerson(
    distanceMeters: 60,
    user: AppUser(
      id: 's4',
      email: 'trang.non@nearsoul.mock',
      password: '',
      nickname: 'Trăng Non',
      birthYear: DateTime.now().year - 23,
      gender: 'female',
      avatarId: 10,
      bio:
          'Thích đi dạo buổi tối, nghe nhạc nhẹ và những câu chuyện không vội.',
      isOnline: true,
    ),
  );

  /// Có người gửi yêu cầu kết nối đến bạn: bạn là bên nhận, hết hạn sau [requestTimeout].
  static Match receiveRequest(String fromUserId) {
    final now = DateTime.now();
    final match = Match(
      id: 'm${matches.length + 1}',
      userA: fromUserId,
      userB: _current?.id ?? '',
      status: MatchStatus.pending,
      requestExpiresAt: now.add(requestTimeout),
      createdAt: now,
    );
    matches.add(match);
    return match;
  }

  static void _setPendingStatus(String matchId, MatchStatus status) {
    for (final m in matches) {
      if (m.id == matchId && m.status == MatchStatus.pending) m.status = status;
    }
  }

  /// Đồng ý: cặp bước vào giai đoạn Quiz (sau màn Get Ready).
  static void acceptRequest(String matchId) =>
      _setPendingStatus(matchId, MatchStatus.quiz);

  /// Từ chối (bên nhận bấm "Từ chối"/"Chặn ngay"): yêu cầu bị hủy.
  static void declineRequest(String matchId) =>
      _setPendingStatus(matchId, MatchStatus.rejected);

  /// Hết hạn mà không ai phản hồi.
  static void expireRequest(String matchId) =>
      _setPendingStatus(matchId, MatchStatus.expired);
}

/// Cách người kia phản hồi một yêu cầu kết nối (chỉ để giả lập khi chưa có backend).
enum MockResponse { accept, decline, ignore }

/// Cách người kia làm Quiz (chỉ để giả lập khi chưa có backend): đáp án trắc nghiệm theo thứ tự câu 1-3,
/// hai câu tự luận, và bao lâu (tính từ lúc bắt đầu Quiz) thì làm xong hoặc rời đi. Null = không bao giờ.
class QuizBehavior {
  final List<int> mcAnswers;
  final List<String> textAnswers;
  final Duration? finishAfter;
  final Duration? leaveAfter;

  const QuizBehavior({
    this.mcAnswers = const [0, 0, 0],
    this.textAnswers = const [
      'Mình thích ngồi im lặng nhìn mưa rơi ngoài cửa sổ và nghe nhạc.',
      'Hôm nay có người nhường chỗ cho mình trên xe buýt, vui cả buổi.',
    ],
    this.finishAfter = const Duration(seconds: 45),
    this.leaveAfter,
  });
}

/// Một người ở gần bạn và khoảng cách tới bạn.
class NearbyPerson {
  final AppUser user;
  final int distanceMeters;

  /// Mock: người này sẽ đồng ý, từ chối hay im lặng khi bạn gửi yêu cầu, và phản hồi sau bao lâu.
  final MockResponse response;
  final Duration responseDelay;

  /// Mock: cách người này làm Quiz sau khi hai bên đã kết nối.
  ///
  /// Lưu bằng trường nullable + getter có giá trị mặc định để hot reload không làm hỏng các người mock đã
  /// được tạo từ trước khi trường này tồn tại (hot reload không điền trường mới cho đối tượng cũ).
  final QuizBehavior? _quiz;

  QuizBehavior get quiz => _quiz ?? const QuizBehavior();

  const NearbyPerson({
    required this.user,
    required this.distanceMeters,
    this.response = MockResponse.accept,
    this.responseDelay = const Duration(seconds: 3),
    QuizBehavior quiz = const QuizBehavior(),
    // ignore: prefer_initializing_formals -- tham số tên "quiz" (công khai), trường lưu là "_quiz".
  }) : _quiz = quiz;

  int get age => DateTime.now().year - (user.birthYear ?? DateTime.now().year);
}
