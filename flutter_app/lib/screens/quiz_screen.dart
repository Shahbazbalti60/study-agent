import 'package:flutter/material.dart';
import '../models/models.dart';
import '../services/api_service.dart';

class QuizScreen extends StatefulWidget {
  const QuizScreen({super.key});
  @override
  State<QuizScreen> createState() => _QuizScreenState();
}

class _QuizScreenState extends State<QuizScreen> {
  final _topicController = TextEditingController();
  bool _loading = false;
  QuizResult? _result;
  int _currentIndex = 0;
  String? _selectedAnswer;
  bool _answered = false;
  int _score = 0;

  Future<void> _generateQuiz() async {
    final topic = _topicController.text.trim();
    if (topic.isEmpty) return;
    setState(() { _loading = true; _result = null; _currentIndex = 0; _score = 0; });
    try {
      final result = await ApiService.generateQuiz(topic, numQuestions: 5);
      setState(() => _result = result);
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error: $e'), backgroundColor: Colors.red),
      );
    } finally {
      setState(() => _loading = false);
    }
  }

  void _selectAnswer(String label) {
    if (_answered) return;
    final correct = _result!.questions[_currentIndex].correctAnswer;
    setState(() {
      _selectedAnswer = label;
      _answered = true;
      if (label == correct) _score++;
    });
  }

  void _nextQuestion() {
    if (_currentIndex < _result!.questions.length - 1) {
      setState(() { _currentIndex++; _selectedAnswer = null; _answered = false; });
    } else {
      _showResultDialog();
    }
  }

  void _showResultDialog() {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Quiz Complete!'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text('$_score / ${_result!.questions.length}',
                style: const TextStyle(fontSize: 48, fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            Text(_score == _result!.questions.length
                ? '🎉 Perfect score!'
                : _score >= _result!.questions.length ~/ 2
                    ? '👍 Good job!'
                    : '📚 Keep studying!'),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              setState(() { _result = null; _currentIndex = 0; _score = 0; });
            },
            child: const Text('New Quiz'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_result == null) return _buildTopicInput();
    return _buildQuizView();
  }

  Widget _buildTopicInput() {
    return Padding(
      padding: const EdgeInsets.all(20),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.quiz_outlined, size: 64, color: Theme.of(context).colorScheme.primary),
          const SizedBox(height: 24),
          const Text('Generate a Quiz', style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold)),
          const SizedBox(height: 8),
          Text('Quiz will be generated from your uploaded notes',
              style: TextStyle(color: Colors.grey[600])),
          const SizedBox(height: 32),
          TextField(
            controller: _topicController,
            decoration: InputDecoration(
              hintText: 'Enter topic (e.g. Neural Networks)',
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
              prefixIcon: const Icon(Icons.topic),
            ),
          ),
          const SizedBox(height: 16),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: _loading ? null : _generateQuiz,
              icon: _loading
                  ? const SizedBox(width: 18, height: 18,
                      child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                  : const Icon(Icons.play_arrow),
              label: Text(_loading ? 'Generating...' : 'Generate Quiz'),
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildQuizView() {
    final q = _result!.questions[_currentIndex];
    final total = _result!.questions.length;

    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Progress
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('Question ${_currentIndex + 1} of $total',
                  style: const TextStyle(fontWeight: FontWeight.bold)),
              Text('Score: $_score', style: TextStyle(color: Colors.green[700])),
            ],
          ),
          const SizedBox(height: 8),
          LinearProgressIndicator(value: (_currentIndex + 1) / total),
          const SizedBox(height: 24),
          // Question
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Text(q.question, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w500)),
            ),
          ),
          const SizedBox(height: 16),
          // Options
          if (q.options != null)
            ...q.options!.map((opt) {
              Color? color;
              if (_answered) {
                if (opt.label == q.correctAnswer) color = Colors.green[100];
                else if (opt.label == _selectedAnswer) color = Colors.red[100];
              }
              return GestureDetector(
                onTap: () => _selectAnswer(opt.label),
                child: Container(
                  margin: const EdgeInsets.only(bottom: 10),
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: color ?? Theme.of(context).colorScheme.surfaceVariant,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: _selectedAnswer == opt.label
                          ? Theme.of(context).colorScheme.primary
                          : Colors.transparent,
                      width: 2,
                    ),
                  ),
                  child: Row(
                    children: [
                      CircleAvatar(radius: 12,
                          child: Text(opt.label, style: const TextStyle(fontSize: 12))),
                      const SizedBox(width: 12),
                      Expanded(child: Text(opt.text)),
                    ],
                  ),
                ),
              );
            }),
          // Explanation
          if (_answered)
            Card(
              color: Colors.blue[50],
              child: Padding(
                padding: const EdgeInsets.all(12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('Explanation', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.blue)),
                    const SizedBox(height: 4),
                    Text(q.explanation, style: const TextStyle(fontSize: 13)),
                  ],
                ),
              ),
            ),
          const SizedBox(height: 12),
          if (_answered)
            ElevatedButton(
              onPressed: _nextQuestion,
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
              child: Text(_currentIndex < total - 1 ? 'Next Question →' : 'See Results'),
            ),
        ],
      ),
    );
  }
}
