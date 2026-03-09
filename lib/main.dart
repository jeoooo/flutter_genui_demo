import 'dart:async';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:genui/genui.dart';
import 'package:genui_google_generative_ai/genui_google_generative_ai.dart';
import 'package:json_schema_builder/json_schema_builder.dart';
import 'package:logging/logging.dart';

import 'utils/api_key_helper.dart';

// ---------------------------------------------------------------------------
// FlashCard CatalogItem — the custom GenUI widget the AI will generate
// ---------------------------------------------------------------------------

final _flashCardSchema = S.object(
  properties: {
    'front': S.string(
      description: 'The question, term, or concept shown on the front of the card.',
    ),
    'back': S.string(
      description: 'The answer, definition, or explanation revealed on the back of the card.',
    ),
    'topic': S.string(
      description: 'The subject or category this flashcard belongs to (e.g. "Biology").',
    ),
  },
  required: ['front', 'back'],
);

final flashCardCatalogItem = CatalogItem(
  name: 'FlashCard',
  dataSchema: _flashCardSchema,
  widgetBuilder: (itemContext) {
    final json = itemContext.data as Map<String, Object?>;
    return _FlashCardWidget(
      front: json['front'] as String? ?? '',
      back: json['back'] as String? ?? '',
      topic: json['topic'] as String? ?? '',
    );
  },
);

// ---------------------------------------------------------------------------
// Flip-card widget with 3-D rotation animation
// ---------------------------------------------------------------------------

class _FlashCardWidget extends StatefulWidget {
  final String front;
  final String back;
  final String topic;

  const _FlashCardWidget({
    required this.front,
    required this.back,
    required this.topic,
  });

  @override
  State<_FlashCardWidget> createState() => _FlashCardWidgetState();
}

class _FlashCardWidgetState extends State<_FlashCardWidget>
    with SingleTickerProviderStateMixin {
  bool _showBack = false;
  late final AnimationController _controller;
  late final Animation<double> _animation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 450),
    );
    _animation = Tween<double>(begin: 0, end: pi).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeInOut),
    );
  }

  void _flip() {
    if (_showBack) {
      _controller.reverse();
    } else {
      _controller.forward();
    }
    setState(() => _showBack = !_showBack);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: _flip,
      child: AnimatedBuilder(
        animation: _animation,
        builder: (context, _) {
          final angle = _animation.value;
          final isFront = angle <= pi / 2;

          Widget face;
          if (isFront) {
            face = _buildFace(
              context,
              label: widget.topic.isNotEmpty ? widget.topic : 'Question',
              content: widget.front,
              color: Theme.of(context).colorScheme.primaryContainer,
              textColor: Theme.of(context).colorScheme.onPrimaryContainer,
              icon: Icons.help_outline_rounded,
            );
          } else {
            face = Transform(
              alignment: Alignment.center,
              transform: Matrix4.identity()..rotateY(pi),
              child: _buildFace(
                context,
                label: 'Answer',
                content: widget.back,
                color: Theme.of(context).colorScheme.secondaryContainer,
                textColor: Theme.of(context).colorScheme.onSecondaryContainer,
                icon: Icons.lightbulb_outline_rounded,
              ),
            );
          }

          return Transform(
            alignment: Alignment.center,
            transform: Matrix4.identity()
              ..setEntry(3, 2, 0.001)
              ..rotateY(angle),
            child: face,
          );
        },
      ),
    );
  }

  Widget _buildFace(
    BuildContext context, {
    required String label,
    required String content,
    required Color color,
    required Color textColor,
    required IconData icon,
  }) {
    return Container(
      width: double.infinity,
      constraints: const BoxConstraints(minHeight: 160),
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.12),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: textColor.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(icon, size: 12, color: textColor),
                    const SizedBox(width: 4),
                    Text(
                      label,
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.bold,
                        color: textColor,
                        letterSpacing: 0.5,
                      ),
                    ),
                  ],
                ),
              ),
              const Spacer(),
              Icon(
                Icons.touch_app_rounded,
                size: 16,
                color: textColor.withValues(alpha: 0.4),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Text(
            content,
            style: TextStyle(
              fontSize: 17,
              color: textColor,
              fontWeight: FontWeight.w500,
              height: 1.5,
            ),
          ),
        ],
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// App entry point
// ---------------------------------------------------------------------------

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await loadEnv();
  configureGenUiLogging(level: Level.ALL);
  runApp(const FlashCardsApp());
}

class FlashCardsApp extends StatelessWidget {
  const FlashCardsApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'GenUI Flashcards',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.indigo),
        useMaterial3: true,
      ),
      home: const FlashCardsScreen(),
    );
  }
}

// ---------------------------------------------------------------------------
// Main screen
// ---------------------------------------------------------------------------

class FlashCardsScreen extends StatefulWidget {
  const FlashCardsScreen({super.key});

  @override
  State<FlashCardsScreen> createState() => _FlashCardsScreenState();
}

class _FlashCardsScreenState extends State<FlashCardsScreen> {
  final _textController = TextEditingController();
  final _scrollController = ScrollController();
  final List<ChatMessage> _messages = [];

  late GenUiConversation _genUiConversation;
  late A2uiMessageProcessor _a2uiMessageProcessor;

  static const _suggestedTopics = [
    'The Solar System',
    'World War II',
    'Python Basics',
    'Human Anatomy',
    'Spanish Vocabulary',
    'Climate Change',
  ];

  @override
  void initState() {
    super.initState();
    _initConversation();
  }

  void _initConversation() {
    try {
      final catalog =
          CoreCatalogItems.asCatalog().copyWith([flashCardCatalogItem]);
      _a2uiMessageProcessor = A2uiMessageProcessor(catalogs: [catalog]);

      const systemInstruction = '''
You are an expert flashcard generation assistant. When the user provides a topic or subject,
generate a set of educational FlashCard components to help them study and memorize key concepts.

Each FlashCard must have:
- front: A clear, concise question, term, or concept for the user to recall
- back: The precise answer, definition, or explanation (keep it brief but complete)
- topic: The subject category (e.g. "Biology", "History", "Programming")

Generate between 4 and 6 flashcards per request. Present them in a Column so they stack
vertically. Make the cards progressively increase in complexity within the set.

IMPORTANT: Always create a new surface with a unique surfaceId for each response.
Never reuse or update existing surfaceIds.

${GenUiPromptFragments.basicChat}''';

      final contentGenerator = GoogleGenerativeAiContentGenerator(
        catalog: catalog,
        systemInstruction: systemInstruction,
        apiKey: getApiKey(),
      );

      _genUiConversation = GenUiConversation(
        a2uiMessageProcessor: _a2uiMessageProcessor,
        contentGenerator: contentGenerator,
        onSurfaceAdded: _onSurfaceAdded,
        onSurfaceUpdated: _onSurfaceUpdated,
        onTextResponse: _onTextResponse,
        onError: (error) {
          genUiLogger.severe(
              'Content generator error', error.error, error.stackTrace);
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text('AI Error: ${error.error}')),
            );
          }
        },
      );
    } catch (e, st) {
      genUiLogger.severe('Initialization error', e, st);
      if (mounted) {
        WidgetsBinding.instance.addPostFrameCallback((_) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Init error: $e')),
          );
        });
      }
    }
  }

  void _resetConversation() {
    _genUiConversation.dispose();
    setState(() {
      _messages.clear();
      _initConversation();
    });
  }

  void _onSurfaceAdded(SurfaceAdded update) {
    if (!mounted) return;
    setState(() {
      _messages.add(AiUiMessage(
        definition: update.definition,
        surfaceId: update.surfaceId,
      ));
    });
    _scrollToBottom();
  }

  void _onSurfaceUpdated(SurfaceUpdated update) {
    if (!mounted) return;
    setState(() {});
    _scrollToBottom();
  }

  void _onTextResponse(String text) {
    if (!mounted || text.trim().isEmpty) return;
    setState(() => _messages.add(AiTextMessage.text(text)));
    _scrollToBottom();
  }

  void _sendMessage([String? override]) {
    final text = (override ?? _textController.text).trim();
    if (text.isEmpty || _genUiConversation.isProcessing.value) return;
    _textController.clear();

    setState(() => _messages.add(UserMessage.text(text)));
    _scrollToBottom();

    unawaited(_genUiConversation.sendRequest(UserMessage.text(text)));
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('GenUI Flashcards'),
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
        actions: [
          if (_messages.isNotEmpty)
            IconButton(
              icon: const Icon(Icons.delete_sweep_rounded),
              tooltip: 'Clear chat',
              onPressed: () {
                showDialog<bool>(
                  context: context,
                  builder: (ctx) => AlertDialog(
                    title: const Text('Clear flashcards?'),
                    content: const Text(
                      'This will reset the conversation and remove all generated flashcards.',
                    ),
                    actions: [
                      TextButton(
                        onPressed: () => Navigator.pop(ctx, false),
                        child: const Text('Cancel'),
                      ),
                      FilledButton(
                        onPressed: () => Navigator.pop(ctx, true),
                        child: const Text('Clear'),
                      ),
                    ],
                  ),
                ).then((confirmed) {
                  if (confirmed == true) _resetConversation();
                });
              },
            ),
        ],
      ),
      body: SafeArea(
        child: Column(
          children: [
            // Welcome / empty state
            if (_messages.isEmpty) _buildWelcome(context),

            // Message list
            if (_messages.isNotEmpty)
              Expanded(
                child: ListView.builder(
                  controller: _scrollController,
                  padding: const EdgeInsets.symmetric(vertical: 8),
                  itemCount: _messages.length,
                  itemBuilder: (context, index) {
                    final msg = _messages[index];
                    return switch (msg) {
                      AiUiMessage() => Padding(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 16, vertical: 6),
                          child: GenUiSurface(
                            key: msg.uiKey,
                            host: _genUiConversation.host,
                            surfaceId: msg.surfaceId,
                          ),
                        ),
                      AiTextMessage() =>
                        _ChatBubble(text: msg.text, isUser: false),
                      UserMessage() =>
                        _ChatBubble(text: msg.text, isUser: true),
                      _ => const SizedBox.shrink(),
                    };
                  },
                ),
              ),

            // Loading bar
            ValueListenableBuilder<bool>(
              valueListenable: _genUiConversation.isProcessing,
              builder: (_, processing, _) => processing
                  ? const LinearProgressIndicator()
                  : const SizedBox.shrink(),
            ),

            // Input row
            _buildInputRow(context),
          ],
        ),
      ),
    );
  }

  Widget _buildWelcome(BuildContext context) {
    return Expanded(
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const SizedBox(height: 24),
            Icon(
              Icons.style_rounded,
              size: 80,
              color: Theme.of(context).colorScheme.primary.withValues(alpha: 0.7),
            ),
            const SizedBox(height: 20),
            Text(
              'AI Flashcard Generator',
              style: Theme.of(context)
                  .textTheme
                  .headlineSmall
                  ?.copyWith(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 12),
            Text(
              'Type any topic and I\'ll generate interactive flashcards to help you study.\nTap a card to flip it and reveal the answer!',
              textAlign: TextAlign.center,
              style: Theme.of(context)
                  .textTheme
                  .bodyMedium
                  ?.copyWith(color: Colors.grey[600], height: 1.5),
            ),
            const SizedBox(height: 28),
            Text(
              'Try one of these:',
              style: Theme.of(context)
                  .textTheme
                  .labelMedium
                  ?.copyWith(color: Colors.grey[500]),
            ),
            const SizedBox(height: 12),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              alignment: WrapAlignment.center,
              children: _suggestedTopics
                  .map((topic) => ActionChip(
                        label: Text(topic),
                        onPressed: () => _sendMessage(topic),
                      ))
                  .toList(),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInputRow(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(8),
      child: Row(
        children: [
          Expanded(
            child: ValueListenableBuilder<bool>(
              valueListenable: _genUiConversation.isProcessing,
              builder: (_, processing, _) => TextField(
                controller: _textController,
                enabled: !processing,
                decoration: const InputDecoration(
                  hintText: 'Enter a topic for flashcards…',
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.school_outlined),
                  contentPadding:
                      EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                ),
                onSubmitted: (_) => _sendMessage(),
              ),
            ),
          ),
          const SizedBox(width: 8),
          IconButton.filled(
            icon: const Icon(Icons.send_rounded),
            onPressed: _sendMessage,
          ),
        ],
      ),
    );
  }

  @override
  void dispose() {
    _textController.dispose();
    _scrollController.dispose();
    _genUiConversation.dispose();
    super.dispose();
  }
}

// ---------------------------------------------------------------------------
// Chat bubble (for text messages)
// ---------------------------------------------------------------------------

class _ChatBubble extends StatelessWidget {
  final String text;
  final bool isUser;

  const _ChatBubble({required this.text, required this.isUser});

  @override
  Widget build(BuildContext context) {
    return Align(
      alignment: isUser ? Alignment.centerRight : Alignment.centerLeft,
      child: Container(
        margin: const EdgeInsets.symmetric(vertical: 4, horizontal: 12),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        constraints:
            BoxConstraints(maxWidth: MediaQuery.of(context).size.width * 0.75),
        decoration: BoxDecoration(
          color: isUser
              ? Theme.of(context).colorScheme.primary
              : Colors.grey[200],
          borderRadius: BorderRadius.circular(18),
        ),
        child: Text(
          text,
          style: TextStyle(
            color: isUser ? Colors.white : Colors.black87,
            height: 1.4,
          ),
        ),
      ),
    );
  }
}
