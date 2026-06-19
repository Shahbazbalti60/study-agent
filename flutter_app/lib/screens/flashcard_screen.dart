import 'package:flutter/material.dart';
import '../models/models.dart';
import '../services/api_service.dart';

class FlashcardScreen extends StatefulWidget {
  const FlashcardScreen({super.key});
  @override
  State<FlashcardScreen> createState() => _FlashcardScreenState();
}

class _FlashcardScreenState extends State<FlashcardScreen> {
  final _topicController = TextEditingController();
  bool _loading = false;
  FlashcardResult? _result;
  int _currentIndex = 0;
  bool _flipped = false;

  Future<void> _generateFlashcards() async {
    final topic = _topicController.text.trim();
    if (topic.isEmpty) return;
    setState(() { _loading = true; _result = null; _currentIndex = 0; _flipped = false; });
    try {
      final result = await ApiService.generateFlashcards(topic, numCards: 10);
      setState(() => _result = result);
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error: $e'), backgroundColor: Colors.red),
      );
    } finally {
      setState(() => _loading = false);
    }
  }

  void _flip() => setState(() => _flipped = !_flipped);

  void _next() {
    if (_currentIndex < _result!.cards.length - 1) {
      setState(() { _currentIndex++; _flipped = false; });
    }
  }

  void _prev() {
    if (_currentIndex > 0) {
      setState(() { _currentIndex--; _flipped = false; });
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_result == null) return _buildTopicInput();
    return _buildCardView();
  }

  Widget _buildTopicInput() {
    return Padding(
      padding: const EdgeInsets.all(20),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.style_outlined, size: 64, color: Theme.of(context).colorScheme.primary),
          const SizedBox(height: 24),
          const Text('Generate Flashcards',
              style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold)),
          const SizedBox(height: 8),
          Text('Flashcards will be created from your uploaded notes',
              style: TextStyle(color: Colors.grey[600])),
          const SizedBox(height: 32),
          TextField(
            controller: _topicController,
            decoration: InputDecoration(
              hintText: 'Enter topic (e.g. Machine Learning)',
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
              prefixIcon: const Icon(Icons.topic),
            ),
          ),
          const SizedBox(height: 16),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: _loading ? null : _generateFlashcards,
              icon: _loading
                  ? const SizedBox(
                      width: 18, height: 18,
                      child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                  : const Icon(Icons.auto_awesome),
              label: Text(_loading ? 'Generating...' : 'Generate Flashcards'),
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

  Widget _buildCardView() {
    final card = _result!.cards[_currentIndex];
    final total = _result!.cards.length;

    return Padding(
      padding: const EdgeInsets.all(20),
      child: Column(
        children: [
          // Progress
          Text('${_currentIndex + 1} / $total',
              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
          const SizedBox(height: 4),
          LinearProgressIndicator(value: (_currentIndex + 1) / total),
          const SizedBox(height: 8),
          Text('Tap card to flip', style: TextStyle(color: Colors.grey[500], fontSize: 12)),
          const SizedBox(height: 24),

          // Flashcard
          Expanded(
            child: GestureDetector(
              onTap: _flip,
              child: AnimatedSwitcher(
                duration: const Duration(milliseconds: 300),
                child: _flipped
                    ? _buildCardFace(card.back, isBack: true, key: const ValueKey('back'))
                    : _buildCardFace(card.front, isBack: false, key: const ValueKey('front')),
              ),
            ),
          ),

          const SizedBox(height: 24),
          // Navigation buttons
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              ElevatedButton.icon(
                onPressed: _currentIndex > 0 ? _prev : null,
                icon: const Icon(Icons.arrow_back),
                label: const Text('Prev'),
              ),
              TextButton(
                onPressed: () => setState(() {
                  _result = null;
                  _currentIndex = 0;
                  _flipped = false;
                }),
                child: const Text('New Topic'),
              ),
              ElevatedButton.icon(
                onPressed: _currentIndex < total - 1 ? _next : null,
                icon: const Icon(Icons.arrow_forward),
                label: const Text('Next'),
                iconAlignment: IconAlignment.end,
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildCardFace(String text, {required bool isBack, required Key key}) {
    return Container(
      key: key,
      width: double.infinity,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: isBack
              ? [Colors.green[400]!, Colors.green[700]!]
              : [Theme.of(context).colorScheme.primary,
                 Theme.of(context).colorScheme.primaryContainer],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(color: Colors.black26, blurRadius: 12, offset: const Offset(0, 6)),
        ],
      ),
      child: Center(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                isBack ? 'ANSWER' : 'QUESTION',
                style: const TextStyle(
                    color: Colors.white70, fontSize: 12, letterSpacing: 2),
              ),
              const SizedBox(height: 16),
              Text(
                text,
                textAlign: TextAlign.center,
                style: const TextStyle(
                    color: Colors.white, fontSize: 20, fontWeight: FontWeight.w600),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
