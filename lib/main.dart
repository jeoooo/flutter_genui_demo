import 'package:flutter/material.dart';
import 'package:genui/genui.dart';
import 'package:google_generative_ai/google_generative_ai.dart';

import 'widgets/quiz_catalog.dart';
import 'utils/api_key_helper.dart';

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
  static const _suggestions = [
    'World War II',
    'Flutter Basics',
    'The Human Body',
    'Solar System',
    'Ancient Rome',
  ];

  final _controller = TextEditingController();
  final _scrollController = ScrollController();

  Conversation? _conversation;
  SurfaceController? _surfaceController;
  A2uiTransportAdapter? _transport;

  final List<String> _surfaceIds = [];

  String? _topic;
  bool _isLoading = false;
  int _correct = 0;
  int _answered = 0;

  @override
  void dispose() {
    _controller.dispose();
    _scrollController.dispose();
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
      _correct = 0;
      _answered = 0;
    });

    final catalog = buildQuizCatalog(
      onAnswered: (isCorrect) => setState(() {
        _answered++;
        if (isCorrect) _correct++;
      }),
    );

    final promptBuilder = PromptBuilder.chat(
      catalog: catalog,
      systemPromptFragments: [_systemFragments(topic)],
    );
    final systemPrompt = promptBuilder.systemPromptJoined();

    final model = GenerativeModel(
      model: 'models/gemini-2.0-flash',
      apiKey: getApiKey(),
      systemInstruction: Content.text(systemPrompt),
    );

    _surfaceController = SurfaceController(catalogs: [catalog]);

    late A2uiTransportAdapter transport;
    transport = A2uiTransportAdapter(
      onSend: (message) async {
        try {
          final response = model.generateContentStream(
            [Content.text(message.text)],
          );
          await for (final chunk in response) {
            transport.addChunk(chunk.text ?? '');
          }
        } catch (e) {
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
            _isLoading = false;
          });
          _scrollToBottom();
        case ConversationError():
          setState(() => _isLoading = false);
        default:
          break;
      }
    });

    _conversation!.sendRequest(
      ChatMessage.user(
        'Give me 5 quiz questions about: $topic. Mix the formats.',
      ),
    );
  }

  void _reset() {
    _disposeConversation();
    setState(() {
      _topic = null;
      _surfaceIds.clear();
      _isLoading = false;
    });
  }

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });
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
                if (_answered > 0)
                  Text(
                    '$_correct / $_answered correct',
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
    return Column(
      children: [
        if (_isLoading) const LinearProgressIndicator(),
        if (_surfaceIds.isEmpty && _isLoading)
          const Expanded(
            child: Center(child: Text('Generating questions…')),
          )
        else
          Expanded(
            child: ListView.builder(
              controller: _scrollController,
              padding: const EdgeInsets.all(12),
              itemCount: _surfaceIds.length,
              itemBuilder: (context, i) => Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: Surface(
                  key: ValueKey(_surfaceIds[i]),
                  surfaceContext: _surfaceController!.contextFor(_surfaceIds[i]),
                ),
              ),
            ),
          ),
      ],
    );
  }

  // ── Prompt ────────────────────────────────────────────────────────────────

  String _systemFragments(String topic) =>
      'You are a quiz generator for "$topic". '
      'Output all 5 questions at once without waiting. '
      'Keep explanations short (1 sentence). Mix difficulty.';
}
