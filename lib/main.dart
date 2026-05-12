import 'dart:convert';
import 'dart:math';

import 'package:flutter/material.dart';
import 'package:genui/genui.dart';
import 'package:google_generative_ai/google_generative_ai.dart';

import 'widgets/quiz_catalog.dart';
import 'utils/api_key_helper.dart';
import 'utils/logger.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await loadEnv();
  runApp(const QuizApp());
}

class QuizApp extends StatelessWidget {
  const QuizApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Dynamic Quiz',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepPurple),
        useMaterial3: true,
      ),
      home: const QuizPage(),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────

class QuizPage extends StatefulWidget {
  const QuizPage({super.key});

  @override
  State<QuizPage> createState() => _QuizPageState();
}

class _QuizPageState extends State<QuizPage> {
  static const _totalQuestions = 3;
  static const _allFormats = [
    'MultipleChoiceCard',
    'TrueFalseCard',
    'FillInTheBlankCard',
    'OrderTheStepsCard',
    'WordBankCard',
    'SliderCard',
  ];

  static const _suggestions = [
    'Philippines',
    'Flutter Basics',
    'The Human Body',
    'Solar System',
    'Google',
  ];

  final _controller = TextEditingController();

  Conversation? _conversation;
  SurfaceController? _surfaceController;
  A2uiTransportAdapter? _transport;

  final List<String> _surfaceIds = [];

  String? _topic;
  bool _isLoading = false;
  int _currentIndex = 0;
  bool _answeredCurrent = false;
  bool _showResults = false;
  int _correct = 0;
  int _answered = 0;

  @override
  void dispose() {
    _controller.dispose();
    _disposeConversation();
    super.dispose();
  }

  void _disposeConversation() {
    _conversation?.dispose();
    _transport?.dispose();
    _conversation = null;
    _surfaceController = null;
    _transport = null;
  }

  // ── Start / Reset ─────────────────────────────────────────────────────────

  void _startQuiz(String topic) {
    if (topic.isEmpty) return;
    _disposeConversation();

    setState(() {
      _topic = topic;
      _isLoading = true;
      _surfaceIds.clear();
      _currentIndex = 0;
      _answeredCurrent = false;
      _showResults = false;
      _correct = 0;
      _answered = 0;
    });

    final catalog = buildQuizCatalog(
      onAnswered: (isCorrect) {
        if (_answeredCurrent) return;
        setState(() {
          _answeredCurrent = true;
          _answered++;
          if (isCorrect) _correct++;
        });
      },
    );

    final formats = [..._allFormats]..shuffle(Random());
    final assignedFormats = formats.take(_totalQuestions).toList();

    final promptBuilder = PromptBuilder.chat(
      catalog: catalog,
      systemPromptFragments: [_systemFragments(topic, assignedFormats)],
    );
    final systemPrompt = promptBuilder.systemPromptJoined();

    final model = GenerativeModel(
      model: 'gemini-2.5-flash-lite',
      apiKey: getApiKey(),
      systemInstruction: Content.text(systemPrompt),
    );

    _surfaceController = SurfaceController(catalogs: [catalog]);

    late A2uiTransportAdapter transport;
    transport = A2uiTransportAdapter(
      onSend: (message) async {
        AiLogger.request('gemini-2.5-flash-lite', message.text);
        try {
          await withRetry(() async {
            final response = model.generateContentStream(
              [Content.text(message.text)],
            );
            final buffer = StringBuffer();
            int chunkCount = 0;
            await for (final chunk in response) {
              final text = chunk.text ?? '';
              buffer.write(text);
              chunkCount++;
            }

            String fullText = buffer.toString().trim();
            if (fullText.startsWith('```')) {
              fullText = fullText
                  .replaceFirst(RegExp(r'^```\w*\n?'), '')
                  .replaceFirst(RegExp(r'\n?```$'), '')
                  .trim();
            }

            // genui requires createSurface before updateComponents.
            // Inject one for every surfaceId found in the response.
            final surfaceIds = <String>{};
            final regex = RegExp(r'"surfaceId"\s*:\s*"([^"]+)"');
            for (final m in regex.allMatches(fullText)) {
              surfaceIds.add(m.group(1)!);
            }
            // Fallback: try parsing a single JSON object
            if (surfaceIds.isEmpty) {
              try {
                final decoded = jsonDecode(fullText) as Map<String, dynamic>;
                final update = decoded['updateComponents'];
                if (update is Map && update['surfaceId'] is String) {
                  surfaceIds.add(update['surfaceId'] as String);
                }
              } catch (_) {}
            }
            for (final id in surfaceIds) {
              transport.addMessage(
                CreateSurface(surfaceId: id, catalogId: basicCatalogId),
              );
            }

            // Bail out if the user navigated away and disposed this transport.
            if (transport != _transport) return;

            transport.addChunk(fullText);
            AiLogger.response(chunkCount, buffer.length, fullText);
          });
        } catch (e) {
          AiLogger.error(e);
          if (mounted) setState(() => _isLoading = false);
          rethrow;
        }
      },
    );
    _transport = transport;

    _conversation = Conversation(
      controller: _surfaceController!,
      transport: transport,
    );

    _conversation!.events.listen((event) {
      if (!mounted) return;
      switch (event) {
        case ConversationSurfaceAdded(:final surfaceId):
          setState(() {
            _surfaceIds.add(surfaceId);
            if (_surfaceIds.length == _totalQuestions) {
              _surfaceIds.shuffle(Random());
            }
            _isLoading = false;
          });
        case ConversationError():
          setState(() => _isLoading = false);
        default:
          break;
      }
    });

    _conversation!.sendRequest(
      ChatMessage.user(
        'Give me 3 quiz questions about: $topic. Mix the formats.',
      ),
    );
  }

  void _reset() {
    _disposeConversation();
    setState(() {
      _topic = null;
      _surfaceIds.clear();
      _isLoading = false;
      _currentIndex = 0;
      _answeredCurrent = false;
      _showResults = false;
      _correct = 0;
      _answered = 0;
    });
  }

  void _nextQuestion() {
    if (_currentIndex >= _surfaceIds.length - 1) {
      setState(() => _showResults = true);
    } else {
      setState(() {
        _currentIndex++;
        _answeredCurrent = false;
      });
    }
  }

  // ── Build ─────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: _buildAppBar(),
      body: _topic == null ? _buildWelcome() : _buildQuiz(),
    );
  }

  AppBar _buildAppBar() {
    return AppBar(
      backgroundColor: Theme.of(context).colorScheme.inversePrimary,
      title: _topic == null
          ? const Text('Dynamic Quiz')
          : Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  _topic!,
                  style: const TextStyle(fontWeight: FontWeight.bold),
                ),
                if (_showResults)
                  Text(
                    '$_correct / $_answered correct',
                    style: Theme.of(context).textTheme.labelSmall,
                  )
                else if (_surfaceIds.isNotEmpty)
                  Text(
                    'Question ${_currentIndex + 1} of ${_surfaceIds.length}',
                    style: Theme.of(context).textTheme.labelSmall,
                  ),
              ],
            ),
      actions: [
        if (_topic != null)
          TextButton.icon(
            onPressed: _reset,
            icon: const Icon(Icons.refresh_rounded),
            label: const Text('New Topic'),
          ),
      ],
    );
  }

  Widget _buildWelcome() {
    final colors = Theme.of(context).colorScheme;
    return Center(
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            CircleAvatar(
              radius: 48,
              backgroundColor: colors.primaryContainer,
              child: Icon(
                Icons.quiz_rounded,
                size: 48,
                color: colors.onPrimaryContainer,
              ),
            ),
            const SizedBox(height: 24),
            Text(
              'Dynamic Quiz',
              style: Theme.of(context)
                  .textTheme
                  .headlineMedium
                  ?.copyWith(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            Text(
              'Type any topic — Gemini generates the questions.',
              style: TextStyle(color: Colors.grey[600]),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 12),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Icon(Icons.info_outline_rounded, size: 14, color: Colors.grey[500]),
                const SizedBox(width: 4),
                Flexible(
                  child: Text(
                    'Questions and answers are AI-generated and may sometimes be inaccurate.',
                    style: TextStyle(fontSize: 12, color: Colors.grey[500]),
                    textAlign: TextAlign.center,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 32),
            Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _controller,
                    decoration: const InputDecoration(
                      hintText: 'Enter a topic…',
                      border: OutlineInputBorder(),
                    ),
                    onSubmitted: _startQuiz,
                  ),
                ),
                const SizedBox(width: 8),
                FilledButton(
                  onPressed: () => _startQuiz(_controller.text.trim()),
                  child: const Text('Start'),
                ),
              ],
            ),
            const SizedBox(height: 20),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              alignment: WrapAlignment.center,
              children: _suggestions
                  .map(
                    (t) => ActionChip(
                      label: Text(t),
                      onPressed: () => _startQuiz(t),
                    ),
                  )
                  .toList(),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildQuiz() {
    if (_showResults) return _buildResults();

    return Column(
      children: [
        if (_isLoading) const LinearProgressIndicator(),
        if (_surfaceIds.isEmpty && _isLoading)
          const Expanded(
            child: Center(child: Text('Generating questions…')),
          )
        else if (_surfaceIds.isNotEmpty)
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
              child: Surface(
                key: ValueKey(_surfaceIds[_currentIndex]),
                surfaceContext:
                    _surfaceController!.contextFor(_surfaceIds[_currentIndex]),
              ),
            ),
          ),
        if (_surfaceIds.isNotEmpty && _answeredCurrent)
          SafeArea(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: SizedBox(
                width: double.infinity,
                child: FilledButton.icon(
                  onPressed: _nextQuestion,
                  icon: Icon(
                    _currentIndex >= _surfaceIds.length - 1
                        ? Icons.bar_chart_rounded
                        : Icons.arrow_forward_rounded,
                  ),
                  label: Text(
                    _currentIndex >= _surfaceIds.length - 1
                        ? 'See Results'
                        : 'Next Question',
                  ),
                ),
              ),
            ),
          ),
      ],
    );
  }

  Widget _buildResults() {
    final colors = Theme.of(context).colorScheme;
    final total = _answered > 0 ? _answered : 1;
    final pct = _correct / total;

    final String headline;
    final String sub;
    final IconData icon;
    if (pct == 1.0) {
      headline = 'Perfect!';
      sub = 'You nailed every question.';
      icon = Icons.emoji_events_rounded;
    } else if (pct >= 0.67) {
      headline = 'Good job!';
      sub = 'Almost there — keep it up.';
      icon = Icons.thumb_up_rounded;
    } else {
      headline = 'Keep practicing!';
      sub = 'Review the topic and try again.';
      icon = Icons.menu_book_rounded;
    }

    return Center(
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            CircleAvatar(
              radius: 48,
              backgroundColor: colors.primaryContainer,
              child: Icon(icon, size: 48, color: colors.onPrimaryContainer),
            ),
            const SizedBox(height: 24),
            Text(
              '$_correct / $_answered',
              style: Theme.of(context).textTheme.displayMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: colors.primary,
                  ),
            ),
            const SizedBox(height: 4),
            Text(
              headline,
              style: Theme.of(context)
                  .textTheme
                  .titleLarge
                  ?.copyWith(fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: 8),
            Text(
              sub,
              style: TextStyle(color: Colors.grey[600]),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 40),
            SizedBox(
              width: double.infinity,
              child: FilledButton.icon(
                onPressed: () => _startQuiz(_topic!),
                icon: const Icon(Icons.refresh_rounded),
                label: const Text('Try Again'),
              ),
            ),
            const SizedBox(height: 12),
            SizedBox(
              width: double.infinity,
              child: OutlinedButton.icon(
                onPressed: _reset,
                icon: const Icon(Icons.topic_rounded),
                label: const Text('New Topic'),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ── Prompt ────────────────────────────────────────────────────────────────

  String _systemFragments(String topic, List<String> formats) {
    final assignments = List.generate(
      formats.length,
      (i) => 'q${i + 1} → ${formats[i]}',
    ).join(', ');
    return 'You are a quiz generator for "$topic". '
        'Output exactly ${formats.length} separate JSON messages — one per question, each on its own line. '
        'Use these exact surfaceId-to-component assignments: $assignments. '
        'The root component IS the question card — no Column wrapper. '
        'Format: {"version":"v0.9","updateComponents":{"surfaceId":"q1","components":[{"id":"root","component":"<TYPE>",<PROPS>}]}} '
        'Keep explanations to 1 sentence. '
        'Output raw JSON only — no markdown fences, no extra text before or after.';
  }
}
