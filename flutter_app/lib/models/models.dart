// ── Upload ────────────────────────────────────────────────────────────────
class UploadResult {
  final String filename;
  final int chunksStored;
  final bool success;
  UploadResult({required this.filename, required this.chunksStored, required this.success});
}

// ── Chat ──────────────────────────────────────────────────────────────────
class Citation {
  final String source;
  final int page;
  final String snippet;
  Citation({required this.source, required this.page, required this.snippet});
  factory Citation.fromJson(Map<String, dynamic> j) =>
      Citation(source: j['source'], page: j['page'], snippet: j['snippet']);
}

class ChatResult {
  final String answer;
  final List<Citation> citations;
  final bool usedWebSearch;
  ChatResult({required this.answer, required this.citations, required this.usedWebSearch});
  factory ChatResult.fromJson(Map<String, dynamic> j) => ChatResult(
        answer: j['answer'],
        citations: (j['citations'] as List).map((c) => Citation.fromJson(c)).toList(),
        usedWebSearch: j['used_web_search'],
      );
}

class ChatMessage {
  final String text;
  final bool isUser;
  final List<Citation> citations;
  final bool usedWebSearch;
  ChatMessage({
    required this.text,
    required this.isUser,
    this.citations = const [],
    this.usedWebSearch = false,
  });
}

// ── Quiz ──────────────────────────────────────────────────────────────────
class MCQOption {
  final String label;
  final String text;
  MCQOption({required this.label, required this.text});
  factory MCQOption.fromJson(Map<String, dynamic> j) =>
      MCQOption(label: j['label'], text: j['text']);
}

class QuizQuestion {
  final String question;
  final List<MCQOption>? options;
  final String correctAnswer;
  final String explanation;
  QuizQuestion({
    required this.question,
    this.options,
    required this.correctAnswer,
    required this.explanation,
  });
  factory QuizQuestion.fromJson(Map<String, dynamic> j) => QuizQuestion(
        question: j['question'],
        options: j['options'] != null
            ? (j['options'] as List).map((o) => MCQOption.fromJson(o)).toList()
            : null,
        correctAnswer: j['correct_answer'],
        explanation: j['explanation'],
      );
}

class QuizResult {
  final String topic;
  final List<QuizQuestion> questions;
  QuizResult({required this.topic, required this.questions});
  factory QuizResult.fromJson(Map<String, dynamic> j) => QuizResult(
        topic: j['topic'],
        questions: (j['questions'] as List).map((q) => QuizQuestion.fromJson(q)).toList(),
      );
}

// ── Flashcards ────────────────────────────────────────────────────────────
class Flashcard {
  final String front;
  final String back;
  Flashcard({required this.front, required this.back});
  factory Flashcard.fromJson(Map<String, dynamic> j) =>
      Flashcard(front: j['front'], back: j['back']);
}

class FlashcardResult {
  final String topic;
  final List<Flashcard> cards;
  FlashcardResult({required this.topic, required this.cards});
  factory FlashcardResult.fromJson(Map<String, dynamic> j) => FlashcardResult(
        topic: j['topic'],
        cards: (j['cards'] as List).map((c) => Flashcard.fromJson(c)).toList(),
      );
}
