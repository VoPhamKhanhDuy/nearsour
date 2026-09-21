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
  int quizScore;
  DateTime? chatExpiresAt; // now + 48h khi vào trạng thái chatting
  DateTime createdAt;

  Match({
    required this.id,
    required this.userA,
    required this.userB,
    this.status = MatchStatus.pending,
    Map<String, List<int>>? quizAnswers,
    this.quizScore = 0,
    this.chatExpiresAt,
    DateTime? createdAt,
  })  : quizAnswers = quizAnswers ?? {},
        createdAt = createdAt ?? DateTime.now();
}
