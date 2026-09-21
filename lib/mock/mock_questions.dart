import 'dart:math';

enum QuestionType { multipleChoice, freeText }

class QuizQuestion {
  final String id;
  final String text;
  final QuestionType type;

  /// Chỉ có với [QuestionType.multipleChoice], luôn đúng 2 phần tử.
  final List<String>? options;

  const QuizQuestion({
    required this.id,
    required this.text,
    required this.type,
    this.options,
  });

  bool get isMultipleChoice => type == QuestionType.multipleChoice;
}

/// Một phiên Quiz gồm 3 câu trắc nghiệm (tính điểm) rồi 2 câu tự luận (mở đầu cuộc trò chuyện).
const kMultipleChoiceCount = 3;
const kFreeTextCount = 2;
const kQuestionsPerQuiz = kMultipleChoiceCount + kFreeTextCount;

const kMultipleChoiceBank = <QuizQuestion>[
  QuizQuestion(
    id: 'mc1',
    text: 'Nếu có một buổi chiều rảnh cùng một người mới quen, bạn thích làm gì nhất?',
    type: QuestionType.multipleChoice,
    options: ['Đi cà phê và trò chuyện', 'Đi dạo và ngắm phố'],
  ),
  QuizQuestion(
    id: 'mc2',
    text: 'Nếu hôm nay được rủ đi cà phê với một người lạ thú vị, bạn muốn nói về điều gì?',
    type: QuestionType.multipleChoice,
    options: ['Ước mơ tương lai', 'Một câu chuyện cá nhân'],
  ),
  QuizQuestion(
    id: 'mc3',
    text: 'Khi gặp một người mới, điều gì khiến bạn cảm thấy dễ mở lòng nhất?',
    type: QuestionType.multipleChoice,
    options: ['Người đó biết lắng nghe', 'Có cùng chủ đề quan tâm'],
  ),
  QuizQuestion(
    id: 'mc4',
    text: 'Cuối tuần lý tưởng của bạn là gì?',
    type: QuestionType.multipleChoice,
    options: ['Ở nhà nghỉ ngơi thật thoải mái', 'Ra ngoài khám phá nơi mới'],
  ),
  QuizQuestion(
    id: 'mc5',
    text: 'Bạn thích kiểu quán nào hơn?',
    type: QuestionType.multipleChoice,
    options: ['Yên tĩnh, ít người', 'Nhộn nhịp, nhiều năng lượng'],
  ),
  QuizQuestion(
    id: 'mc6',
    text: 'Bạn thường chọn thể loại nào để thư giãn?',
    type: QuestionType.multipleChoice,
    options: ['Âm nhạc', 'Phim ảnh'],
  ),
  QuizQuestion(
    id: 'mc7',
    text: 'Khi có chuyện buồn, bạn thường làm gì?',
    type: QuestionType.multipleChoice,
    options: ['Tâm sự với ai đó', 'Tự mình suy nghĩ một mình'],
  ),
  QuizQuestion(
    id: 'mc8',
    text: 'Bạn là người của buổi nào trong ngày?',
    type: QuestionType.multipleChoice,
    options: ['Buổi sáng sớm', 'Đêm khuya'],
  ),
  QuizQuestion(
    id: 'mc9',
    text: 'Nếu được chọn một chuyến đi, bạn sẽ chọn?',
    type: QuestionType.multipleChoice,
    options: ['Biển', 'Núi'],
  ),
  QuizQuestion(
    id: 'mc10',
    text: 'Trong một cuộc trò chuyện, bạn thích điều gì hơn?',
    type: QuestionType.multipleChoice,
    options: ['Chuyện nghiêm túc, sâu sắc', 'Chuyện nhẹ nhàng, vui vẻ'],
  ),
  QuizQuestion(
    id: 'mc11',
    text: 'Bạn thích lên kế hoạch hay để mọi thứ tự nhiên?',
    type: QuestionType.multipleChoice,
    options: ['Lên kế hoạch kỹ', 'Tùy hứng theo cảm xúc'],
  ),
  QuizQuestion(
    id: 'mc12',
    text: 'Món đồ uống nào hợp với bạn hơn?',
    type: QuestionType.multipleChoice,
    options: ['Cà phê', 'Trà'],
  ),
];

const kFreeTextBank = <QuizQuestion>[
  QuizQuestion(
    id: 'ft1',
    text: 'Hãy chia sẻ một điều nhỏ gần đây khiến bạn cảm thấy vui hoặc được chữa lành.',
    type: QuestionType.freeText,
  ),
  QuizQuestion(
    id: 'ft2',
    text: 'Một nơi hoặc một khoảnh khắc khiến bạn thấy bình yên là gì?',
    type: QuestionType.freeText,
  ),
  QuizQuestion(
    id: 'ft3',
    text: 'Điều gì ở một cuộc trò chuyện khiến bạn nhớ mãi?',
    type: QuestionType.freeText,
  ),
  QuizQuestion(
    id: 'ft4',
    text: 'Nếu có thể học thêm một điều mới ngay bây giờ, bạn sẽ chọn gì và vì sao?',
    type: QuestionType.freeText,
  ),
  QuizQuestion(
    id: 'ft5',
    text: 'Bạn muốn người đối diện hôm nay biết điều gì về bạn?',
    type: QuestionType.freeText,
  ),
  QuizQuestion(
    id: 'ft6',
    text: 'Kể về một lần bạn được ai đó làm cho bất ngờ theo cách dễ thương.',
    type: QuestionType.freeText,
  ),
  QuizQuestion(
    id: 'ft7',
    text: 'Một bài hát hoặc bộ phim bạn có thể xem đi xem lại mà không chán là gì?',
    type: QuestionType.freeText,
  ),
  QuizQuestion(
    id: 'ft8',
    text: 'Điều gì khiến ngày hôm nay của bạn khác với những ngày còn lại trong tuần?',
    type: QuestionType.freeText,
  ),
];

/// Chọn ngẫu nhiên 3 câu trắc nghiệm + 2 câu tự luận. Cùng [random] (cùng seed) thì cùng bộ câu hỏi,
/// nên hai người trong một cặp có thể dùng chung seed (ví dụ theo mã match) để nhận đúng cùng một bộ.
List<QuizQuestion> pickQuizQuestions({Random? random}) {
  final rnd = random ?? Random();
  final mc = [...kMultipleChoiceBank]..shuffle(rnd);
  final ft = [...kFreeTextBank]..shuffle(rnd);
  return [...mc.take(kMultipleChoiceCount), ...ft.take(kFreeTextCount)];
}
