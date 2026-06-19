import 'package:flutter/material.dart';
import 'screens/chat_screen.dart';
import 'screens/upload_screen.dart';
import 'screens/quiz_screen.dart';
import 'screens/flashcard_screen.dart';

void main() {
  runApp(const StudyAgentApp());
}

class StudyAgentApp extends StatelessWidget {
  const StudyAgentApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Study Agent',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color(0xFF6750A4),
          brightness: Brightness.light,
        ),
        useMaterial3: true,
      ),
      home: const HomeScreen(),
    );
  }
}

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});
  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int _selectedIndex = 0;

  final List<Widget> _screens = [
    const ChatScreen(),
    const UploadScreen(),
    const QuizScreen(),
    const FlashcardScreen(),
  ];

  final List<NavigationDestination> _destinations = const [
    NavigationDestination(
      icon: Icon(Icons.chat_bubble_outline),
      selectedIcon: Icon(Icons.chat_bubble),
      label: 'Chat',
    ),
    NavigationDestination(
      icon: Icon(Icons.upload_file_outlined),
      selectedIcon: Icon(Icons.upload_file),
      label: 'Upload',
    ),
    NavigationDestination(
      icon: Icon(Icons.quiz_outlined),
      selectedIcon: Icon(Icons.quiz),
      label: 'Quiz',
    ),
    NavigationDestination(
      icon: Icon(Icons.style_outlined),
      selectedIcon: Icon(Icons.style),
      label: 'Flashcards',
    ),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Row(
          children: [
            Icon(Icons.school, color: Theme.of(context).colorScheme.primary),
            const SizedBox(width: 8),
            const Text('Study Agent',
                style: TextStyle(fontWeight: FontWeight.bold)),
          ],
        ),
        backgroundColor: Theme.of(context).colorScheme.surface,
        elevation: 0,
      ),
      body: IndexedStack(
        index: _selectedIndex,
        children: _screens,
      ),
      bottomNavigationBar: NavigationBar(
        selectedIndex: _selectedIndex,
        onDestinationSelected: (i) => setState(() => _selectedIndex = i),
        destinations: _destinations,
      ),
    );
  }
}
