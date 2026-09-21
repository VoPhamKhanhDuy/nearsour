import 'dart:async';
import 'dart:math';

import 'package:flutter/material.dart';

import '../../mock/mock_data.dart';
import '../../mock/mock_questions.dart';
import '../../models/match.dart';
import '../../models/user.dart';
import '../../theme/app_colors.dart';
import '../../utils/quiz_scoring.dart';
import '../../widgets/cosmic_background.dart';
import '../../widgets/onboarding_header.dart';
import '../../widgets/primary_button.dart';
import '../result/match_result_screen.dart';
import '../main/main_shell.dart';

/// Thông báo trung tính khi phiên kết thúc: không nói lý do (thoát, hết giờ hay người kia rời đi).
const kConnectionEndedMessage = 'Kết nối đã kết thúc, tiếp tục quét...';

/// AI Quiz: 3 câu trắc nghiệm (2 đáp án, tính điểm) rồi 2 câu tự luận (mở đầu chat, không tính điểm).
/// Mỗi câu có đồng hồ riêng (hết giờ thì tự khóa đáp án và sang câu sau); cả phiên tối đa 5 phút.
class QuizScreen extends StatefulWidget {
  final Match match;
  final AppUser me;
  final AppUser partner;

  /// Bộ câu hỏi; mặc định chọn ngẫu nhiên theo mã match để hai người trong cặp nhận cùng một bộ.
  final List<QuizQuestion>? questions;

  /// Cách người kia làm Quiz; mặc định lấy từ dữ liệu mock của người đó.
  final QuizBehavior? partnerBehavior;

  final Duration multipleChoiceTime;
  final Duration freeTextTime;
  final Duration sessionLimit;

  const QuizScreen({
    super.key,
    required this.match,
    required this.me,
    required this.partner,
    this.questions,
    this.partnerBehavior,
    this.multipleChoiceTime = kMultipleChoiceTime,
    this.freeTextTime = kFreeTextTime,
    this.sessionLimit = MockUserStore.quizSessionLimit,
  });

  @override
  State<QuizScreen> createState() => _QuizScreenState();
}

class _QuizScreenState extends State<QuizScreen> {
  late final List<QuizQuestion> _questions =
      widget.questions ??
      pickQuizQuestions(random: Random(widget.match.id.hashCode));
  // Lấy ngay khi vào màn (không đợi nhịp giây đầu) để nếu dữ liệu mock hỏng thì lỗi hiện ra ngay,
  // thay vì làm đồng hồ đứng yên trong im lặng.
  late final QuizBehavior _partner;

  // Mỗi ô nhập có controller riêng, sở hữu ở đây và truyền vào widget con.
  final _textCtrl = TextEditingController();

  final _mcAnswers = <int>[];
  final _texts = <String>[];

  int _index = 0;
  int? _selected;
  int _questionLeft = 0;
  int _elapsed = 0; // giây kể từ lúc vào Quiz
  bool _waiting = false; // đã gửi hết 5 câu, chờ người kia
  bool _partnerDone = false;
  bool _ended = false;
  Timer? _ticker;

  QuizQuestion get _question => _questions[_index];

  int _timeFor(QuizQuestion q) =>
      (q.isMultipleChoice ? widget.multipleChoiceTime : widget.freeTextTime)
          .inSeconds;

  @override
  void initState() {
    super.initState();
    _partner =
        widget.partnerBehavior ??
        MockUserStore.quizBehaviorFor(widget.partner.id);
    _questionLeft = _timeFor(_question);
    _ticker = Timer.periodic(const Duration(seconds: 1), _onTick);
  }

  @override
  void dispose() {
    _ticker?.cancel();
    _textCtrl.dispose();
    super.dispose();
  }

  void _onTick(Timer timer) {
    if (_ended) return;
    _elapsed++;

    // Người kia rời đi, hoặc cả phiên quá giờ: hủy phiên (người còn lại chỉ thấy thông báo trung tính).
    final leaveAfter = _partner.leaveAfter;
    if (leaveAfter != null &&
        _elapsed >= leaveAfter.inSeconds &&
        !_partnerDone) {
      return _endSession();
    }
    if (_elapsed >= widget.sessionLimit.inSeconds) return _endSession();

    final finishAfter = _partner.finishAfter;
    if (finishAfter != null && _elapsed >= finishAfter.inSeconds) {
      _partnerDone = true;
    }

    if (_waiting) {
      if (_partnerDone) _complete();
      return;
    }

    setState(() => _questionLeft--);
    if (_questionLeft <= 0) {
      _submit(); // hết giờ: khóa đáp án hiện có rồi sang câu tiếp
    }
  }

  bool get _canSubmit {
    if (_waiting) return false;
    return _question.isMultipleChoice
        ? _selected != null
        : isFreeTextValid(_textCtrl.text);
  }

  /// Ghi đáp án câu hiện tại (chưa chọn/chưa nhập thì ghi rỗng) rồi sang câu kế tiếp.
  void _submit() {
    if (_waiting || _ended) return;

    if (_question.isMultipleChoice) {
      _mcAnswers.add(_selected ?? -1);
    } else {
      _texts.add(_textCtrl.text.trim());
    }
    FocusScope.of(context).unfocus();

    if (_index == _questions.length - 1) {
      setState(() => _waiting = true);
      if (_partnerDone) _complete();
      return;
    }
    setState(() {
      _index++;
      _selected = null;
      _textCtrl.clear();
      _questionLeft = _timeFor(_question);
    });
  }

  void _complete() {
    if (_ended) return;
    _ended = true;
    _ticker?.cancel();

    final partnerMc = [
      for (var i = 0; i < kMultipleChoiceCount; i++)
        i < _partner.mcAnswers.length ? _partner.mcAnswers[i] : -1,
    ];
    final score = countMatchingAnswers(_mcAnswers, partnerMc);
    final matched = isQuizMatch(score);

    MockUserStore.completeQuiz(
      widget.match,
      userId: widget.me.id,
      partnerId: widget.partner.id,
      myAnswers: _mcAnswers,
      partnerAnswers: partnerMc,
      myTexts: _texts,
      partnerTexts: _partner.textAnswers,
      freeTextQuestions: [
        for (final q in _questions)
          if (!q.isMultipleChoice) q.text,
      ],
      score: score,
      matched: matched,
    );

    if (matched) {
      // Báo kết quả trước; người dùng chọn mở phòng chat hoặc hủy kết quả ở đó.
      Navigator.of(context).pushAndRemoveUntil(
        MaterialPageRoute<void>(
          builder: (_) => MatchResultScreen(
            match: widget.match,
            me: widget.me,
            partner: widget.partner,
          ),
        ),
        (_) => false,
      );
    } else {
      _backToRadar();
    }
  }

  /// Thoát, hết giờ hoặc người kia rời đi: hủy phiên, không lưu đáp án dở dang.
  void _endSession() {
    if (_ended) return;
    _ended = true;
    _ticker?.cancel();
    MockUserStore.expireMatch(widget.match.id);
    _backToRadar();
  }

  void _backToRadar() {
    // "Tiếp tục quét...": radar tự quét lại ngay khi về tab Radar.
    widget.me.isScanning = true;
    Navigator.of(context).pushAndRemoveUntil(
      MaterialPageRoute<void>(
        builder: (_) => const MainShell(notice: kConnectionEndedMessage),
      ),
      (_) => false,
    );
  }

  Future<void> _confirmCancel() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: AppColors.fieldBg,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        title: const Text(
          'Hủy kết nối?',
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.w700),
        ),
        content: const Text(
          'Phiên Quiz sẽ kết thúc và đáp án của bạn không được lưu lại.',
          style: TextStyle(color: Color(0xFFCDC3D5), height: 1.4),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Ở lại'),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            style: TextButton.styleFrom(foregroundColor: AppColors.error),
            child: const Text('Hủy kết nối'),
          ),
        ],
      ),
    );
    if (confirmed == true && mounted) _endSession();
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, _) {
        if (!didPop) _confirmCancel();
      },
      child: Scaffold(
        body: CosmicBackground(
          style: CosmicStyle.onboarding,
          child: SafeArea(
            child: Column(
              children: [
                OnboardingHeader(
                  onBack: _confirmCancel,
                  trailing: _CancelPill(onTap: _confirmCancel),
                ),
                Expanded(
                  child: _waiting
                      ? const _WaitingView()
                      : SingleChildScrollView(
                          padding: const EdgeInsets.fromLTRB(24, 20, 24, 16),
                          child: Column(
                            children: [
                              _QuizHeader(
                                step: _index + 1,
                                total: _questions.length,
                                secondsLeft: _questionLeft,
                              ),
                              const SizedBox(height: 24),
                              _QuestionCard(text: _question.text),
                              const SizedBox(height: 20),
                              if (_question.isMultipleChoice) ...[
                                for (
                                  var i = 0;
                                  i < _question.options!.length;
                                  i++
                                ) ...[
                                  if (i > 0) const SizedBox(height: 12),
                                  _OptionTile(
                                    key: ValueKey('option_$i'),
                                    text: _question.options![i],
                                    selected: _selected == i,
                                    onTap: () => setState(() => _selected = i),
                                  ),
                                ],
                                const SizedBox(height: 20),
                                const _Note(
                                  'Đáp án của bạn sẽ được ẩn cho đến khi cả hai hoàn thành.',
                                ),
                              ] else
                                _EssayBox(
                                  key: ValueKey('essay_$_index'),
                                  controller: _textCtrl,
                                  onChanged: () => setState(() {}),
                                ),
                            ],
                          ),
                        ),
                ),
                if (!_waiting)
                  Padding(
                    padding: const EdgeInsets.fromLTRB(24, 8, 24, 20),
                    child: Column(
                      children: [
                        PrimaryButton(
                          label: 'Gửi câu trả lời',
                          dimWhenDisabled: true,
                          onPressed: _canSubmit ? _submit : null,
                        ),
                        const SizedBox(height: 12),
                        Text(
                          'AI chỉ dùng câu trả lời để gợi mở cuộc trò chuyện phù hợp.',
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            color: const Color(0xFFCDC3D5)
                                .withValues(alpha: 0.5),
                            fontSize: 11,
                            fontStyle: FontStyle.italic,
                          ),
                        ),
                      ],
                    ),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _CancelPill extends StatelessWidget {
  final VoidCallback onTap;

  const _CancelPill({required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.white.withValues(alpha: 0.05),
      shape: StadiumBorder(
        side: BorderSide(color: Colors.white.withValues(alpha: 0.12)),
      ),
      child: InkWell(
        customBorder: const StadiumBorder(),
        onTap: onTap,
        child: const Padding(
          padding: EdgeInsets.symmetric(horizontal: 12, vertical: 6),
          child: Text(
            'Hủy kết nối',
            style: TextStyle(
              color: AppColors.error,
              fontSize: 11,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
      ),
    );
  }
}

/// Tiêu đề, "Câu n/5", đồng hồ của câu hiện tại, thanh tiến trình và dòng giải thích hết giờ.
class _QuizHeader extends StatelessWidget {
  final int step;
  final int total;
  final int secondsLeft;

  const _QuizHeader({
    required this.step,
    required this.total,
    required this.secondsLeft,
  });

  static String _format(int seconds) {
    final s = seconds < 0 ? 0 : seconds;
    return '${(s ~/ 60).toString().padLeft(2, '0')}:${(s % 60).toString().padLeft(2, '0')}';
  }

  @override
  Widget build(BuildContext context) {
    final urgent = secondsLeft <= 5;
    final chipColor = urgent ? AppColors.error : AppColors.cyan;

    return Column(
      children: [
        const Text(
          'AI Quiz',
          style: TextStyle(
            color: Colors.white,
            fontSize: 24,
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 6),
        Text(
          'Câu $step/$total',
          style: const TextStyle(
            color: AppColors.cyan,
            fontSize: 12,
            fontWeight: FontWeight.w600,
            letterSpacing: 0.6,
          ),
        ),
        const SizedBox(height: 12),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: 0.06),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: chipColor.withValues(alpha: 0.4)),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.schedule, size: 14, color: chipColor),
              const SizedBox(width: 6),
              Text(
                _format(secondsLeft),
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 1,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 12),
        ClipRRect(
          borderRadius: BorderRadius.circular(3),
          child: Container(
            height: 6,
            width: double.infinity,
            color: const Color(0xFF201B3B),
            alignment: Alignment.centerLeft,
            child: FractionallySizedBox(
              widthFactor: step / total,
              child: Container(
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [AppColors.cyan, AppColors.purple],
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: AppColors.cyan.withValues(alpha: 0.4),
                      blurRadius: 10,
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
        const SizedBox(height: 10),
        Text(
          'Hết giờ, hệ thống tự khóa đáp án và chuyển câu tiếp theo.',
          textAlign: TextAlign.center,
          style: TextStyle(
            color: const Color(0xFFCDC3D5).withValues(alpha: 0.6),
            fontSize: 11,
          ),
        ),
      ],
    );
  }
}

class _QuestionCard extends StatelessWidget {
  final String text;

  const _QuestionCard({required this.text});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: const Color(0x99241850),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(
          color: AppColors.lilac.withValues(alpha: 0.25),
          width: 0.8,
        ),
      ),
      child: Text(
        text,
        textAlign: TextAlign.center,
        style: const TextStyle(
          color: Colors.white,
          fontSize: 18,
          height: 1.5,
          fontWeight: FontWeight.w500,
        ),
      ),
    );
  }
}

class _OptionTile extends StatelessWidget {
  final String text;
  final bool selected;
  final VoidCallback onTap;

  const _OptionTile({
    super.key,
    required this.text,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      selected: selected,
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 180),
          constraints: const BoxConstraints(minHeight: 56),
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
          decoration: BoxDecoration(
            color: selected
                ? AppColors.deepPurple.withValues(alpha: 0.4)
                : const Color(0x99241850),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: selected
                  ? AppColors.cyan
                  : AppColors.lilac.withValues(alpha: 0.2),
              width: selected ? 1.2 : 0.8,
            ),
            boxShadow: selected
                ? [
                    BoxShadow(
                      color: AppColors.cyan.withValues(alpha: 0.3),
                      blurRadius: 15,
                    ),
                  ]
                : null,
          ),
          child: Row(
            children: [
              Expanded(
                child: Text(
                  text,
                  style: TextStyle(
                    color: selected ? Colors.white : const Color(0xFFCDC3D5),
                    fontSize: 16,
                    fontWeight: selected ? FontWeight.w600 : FontWeight.w400,
                  ),
                ),
              ),
              if (selected)
                const Icon(Icons.check_circle, color: AppColors.cyan, size: 22),
            ],
          ),
        ),
      ),
    );
  }
}

/// Ô nhập câu trả lời tự luận: tối thiểu 20, tối đa 300 ký tự. Controller do màn hình sở hữu.
class _EssayBox extends StatelessWidget {
  final TextEditingController controller;
  final VoidCallback onChanged;

  const _EssayBox({
    super.key,
    required this.controller,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    final length = controller.text.trim().length;

    return Column(
      children: [
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: const Color(0x99241850),
            borderRadius: BorderRadius.circular(24),
            border: Border.all(
              color: AppColors.lilac.withValues(alpha: 0.25),
              width: 0.8,
            ),
          ),
          child: Column(
            children: [
              TextField(
                controller: controller,
                onChanged: (_) => onChanged(),
                maxLength: kMaxFreeTextLength,
                maxLines: 6,
                minLines: 6,
                cursorColor: AppColors.cyan,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 15,
                  height: 1.5,
                ),
                decoration: InputDecoration(
                  border: InputBorder.none,
                  counterText: '',
                  isCollapsed: true,
                  hintText: 'Nhập câu trả lời của bạn...',
                  hintStyle: TextStyle(
                    color: const Color(0xFFCDC3D5).withValues(alpha: 0.5),
                  ),
                ),
              ),
              const SizedBox(height: 12),
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: Text(
                      'Câu trả lời sẽ được ẩn cho đến khi cả hai hoàn thành.',
                      style: TextStyle(
                        color: const Color(0xFFCDC3D5).withValues(alpha: 0.6),
                        fontSize: 11,
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Text(
                    '${controller.text.length}/$kMaxFreeTextLength',
                    style: TextStyle(
                      color: const Color(0xFFCDC3D5).withValues(alpha: 0.6),
                      fontSize: 11,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
        const SizedBox(height: 10),
        // Chưa đủ 20 ký tự: nói rõ còn thiếu bao nhiêu (nút gửi đang mờ).
        Text(
          length < kMinFreeTextLength
              ? 'Cần thêm ${kMinFreeTextLength - length} ký tự để gửi (tối thiểu $kMinFreeTextLength).'
              : 'Đã đủ độ dài, bạn có thể gửi.',
          style: TextStyle(
            color: length < kMinFreeTextLength
                ? const Color(0xFFCDC3D5).withValues(alpha: 0.7)
                : AppColors.cyan,
            fontSize: 12,
          ),
        ),
      ],
    );
  }
}

class _Note extends StatelessWidget {
  final String text;

  const _Note(this.text);

  @override
  Widget build(BuildContext context) {
    return Text(
      text,
      textAlign: TextAlign.center,
      style: TextStyle(
        color: const Color(0xFFCDC3D5).withValues(alpha: 0.6),
        fontSize: 12,
      ),
    );
  }
}

/// Đã gửi hết câu trả lời, chờ người kia xong.
class _WaitingView extends StatelessWidget {
  const _WaitingView();

  @override
  Widget build(BuildContext context) {
    return const Center(
      child: Padding(
        padding: EdgeInsets.symmetric(horizontal: 32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            SizedBox(
              width: 36,
              height: 36,
              child: CircularProgressIndicator(
                strokeWidth: 3,
                color: AppColors.cyan,
              ),
            ),
            SizedBox(height: 24),
            Text(
              'Đã gửi câu trả lời của bạn',
              textAlign: TextAlign.center,
              style: TextStyle(
                color: Colors.white,
                fontSize: 22,
                fontWeight: FontWeight.w700,
              ),
            ),
            SizedBox(height: 8),
            Text(
              'Đang chờ đối phương hoàn thành...',
              textAlign: TextAlign.center,
              style: TextStyle(color: Color(0xFFCDC3D5), fontSize: 15),
            ),
            SizedBox(height: 16),
            Text(
              'Đáp án của bạn sẽ được ẩn cho đến khi cả hai hoàn thành.',
              textAlign: TextAlign.center,
              style: TextStyle(color: Color(0x99CDC3D5), fontSize: 12),
            ),
          ],
        ),
      ),
    );
  }
}
