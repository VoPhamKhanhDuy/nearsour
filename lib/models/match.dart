enum MatchStatus {
  pending,
  quiz,
  chatting,
  metPending,
  completedSaved,
  completedEnded,
  expired,
  rejected,
}

class Match {
  final String id;
  final String userA;
  final String userB;
  MatchStatus status;
  Map<String, List<int>> quizAnswers; // { userId: [answerIndex, ...] }
  Map<String, List<String>>
  freeTextAnswers; // câu tự luận: chỉ hiện cho nhau sau khi match thành công
  List<String> freeTextQuestions; // nội dung các câu tự luận đó, để làm chủ đề mở lời trong chat
  int quizScore;
  DateTime? requestExpiresAt; // now + 30s khi status chuyển sang pending
  DateTime? chatExpiresAt; // now + 48h khi vào trạng thái chatting
  String? meetRequestedBy; // ai đã bấm "Gặp nhau ngoài đời" (đề nghị hai chiều, chờ người kia xác nhận)
  String? keepRequestedBy; // ai đã bấm "Giữ kết nối" sau buổi gặp (đề nghị hai chiều, chờ người kia xác nhận)
  DateTime? hiddenUntil; // không khớp Quiz: hai người ẩn khỏi radar của nhau tới lúc này (now + 24h)
  DateTime createdAt;

  Match({
    required this.id,
    required this.userA,
    required this.userB,
    this.status = MatchStatus.pending,
    Map<String, List<int>>? quizAnswers,
    Map<String, List<String>>? freeTextAnswers,
    List<String>? freeTextQuestions,
    this.quizScore = 0,
    this.requestExpiresAt,
    this.chatExpiresAt,
    this.meetRequestedBy,
    this.keepRequestedBy,
    this.hiddenUntil,
    DateTime? createdAt,
  }) : quizAnswers = quizAnswers ?? {},
       freeTextAnswers = freeTextAnswers ?? {},
       freeTextQuestions = freeTextQuestions ?? [],
       createdAt = createdAt ?? DateTime.now();
}
