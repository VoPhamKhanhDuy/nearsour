import '../mock/mock_questions.dart' show kMultipleChoiceCount;

/// Cần trùng ít nhất từng này trên tổng số câu trắc nghiệm thì mở chat.
const kMatchThreshold = 2;

/// Độ dài tối thiểu của câu trả lời tự luận mới cho gửi.
const kMinFreeTextLength = 20;

/// Độ dài tối đa của câu trả lời tự luận.
const kMaxFreeTextLength = 300;

/// Số câu trắc nghiệm hai người chọn cùng đáp án. Câu chưa trả lời (-1) không bao giờ được tính là trùng.
int countMatchingAnswers(List<int> a, List<int> b) {
  var matches = 0;
  for (var i = 0; i < a.length && i < b.length; i++) {
    if (a[i] >= 0 && a[i] == b[i]) matches++;
  }
  return matches;
}

bool isQuizMatch(int matchingAnswers) => matchingAnswers >= kMatchThreshold;

/// Câu tự luận đủ dài để được gửi (không tính khoảng trắng thừa ở hai đầu).
bool isFreeTextValid(String text) => text.trim().length >= kMinFreeTextLength;

/// Đồng hồ từng câu: hết giờ thì tự khóa đáp án hiện có và sang câu sau.
const kMultipleChoiceTime = Duration(seconds: 15);
const kFreeTextTime = Duration(seconds: 45);

/// Mức độ phù hợp (0-100) theo số câu trắc nghiệm trùng: 2/3 → 67%, 3/3 → 100%.
int matchPercent(int matchingAnswers, {int total = kMultipleChoiceCount}) =>
    total <= 0 ? 0 : (matchingAnswers * 100 / total).round().clamp(0, 100);
