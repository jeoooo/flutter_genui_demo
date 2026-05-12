# BWAI – Generative UI Talk: Slide Content
# Target: 20 minutes (~18 slides)

---

## Slide 1 — Title

**Creating a Generative UI Mobile App Using Flutter, Gemini, and the `genui` Package**

**Subtitle:** *(event name / date)*
**Location:** *(venue)*

---

## Slide 2 — Speaker Intro

**Hi! I'm Jeo**

- From **Davao** · Software Developer
- Svelte · React · Firebase · TypeScript
- I love Mobile Apps — Flutter, Android, React Native
- Tech Volunteer @ GDG Davao

> **Disclaimer:** Developer's POV. Focus is on *how it works*, not pixel-perfect design.

`[IMG PLACEHOLDER: Speaker headshot]`

---

## Slide 3 — Agenda

**In This Talk...**

1. Traditional UI with AI vs Generative UI
2. What `genui` is — and how it works
3. Building a dynamic quiz app, step by step

---

## Slide 4 — Chapter Divider

**Chapter One**

# Traditional vs Generative

---

## Slide 5 — The Problem with Traditional AI UIs

**In Traditional UIs…**

- UIs come **pre-built** — the AI has no say in how responses are presented
- Output is always text inside a fixed widget
- Even if the AI is flexible, **the experience isn't**

`[IMG PLACEHOLDER: Classic chat UI — AI response as plain text inside a Card]`

---

## Slide 6 — What is Generative UI?

**Generative UI** — AI generates not just *content*, but the **entire UX**

| Traditional UIs | Generative UIs |
|---|---|
| Developer pre-designs every screen | AI selects the right UI for the context |
| AI output wrapped in a **fixed widget** | AI output **is** the widget |
| UI is a **container** for AI output | UI is **part of** the AI output |

`[IMG PLACEHOLDER: Side-by-side — text response vs interactive quiz card rendered by genui]`

---

## Slide 7 — What We're Building

**Dynamic Quiz App**

- User types any topic — Gemini generates questions **on the fly**
- Questions render as **interactive widgets** — not text
- 6 formats: Multiple Choice · True/False · Fill in the Blank · Order the Steps · Word Bank · Slider
- Immediate feedback + explanations on reveal

`[IMG PLACEHOLDER: App screenshot — mix of card types generated for "Flutter Basics"]`

---

## Slide 8 — Chapter Divider

**Chapter Two**

# Let's Build It

---

## Slide 9 — Step 1: Setup

**Dependencies**

```yaml
# pubspec.yaml
dependencies:
  genui: ^0.9.0
  google_generative_ai: ^0.4.0
  json_schema_builder: ^0.1.3
  flutter_dotenv: ^5.0.2
```

**API key in `.env`** (add to `.gitignore`, declare as asset):

```
GEMINI_API_KEY=your_key_here
```

```dart
void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await loadEnv();
  runApp(const QuizApp());
}
```

`[IMG PLACEHOLDER: Google AI Studio "Get API key" page]`

---

## Slide 10 — Step 2: The Core Concept — `CatalogItem`

**A `CatalogItem` = one schema + one widget**

```dart
CatalogItem(
  name: 'MultipleChoiceCard',   // Gemini uses this name
  dataSchema: S.object( ... ),  // tells Gemini what JSON to produce
  widgetBuilder: (context) {    // turns that JSON into a Flutter widget
    final data = context.data as Map<String, Object?>;
    return MultipleChoiceCard( ... );
  },
)
```

> genui injects the schema into the system prompt automatically — no manual prompt engineering.

---

## Slide 11 — Step 3: Define Your Schemas

**Each card type gets its own schema**

```dart
// Multiple choice
dataSchema: S.object(properties: {
  'question':       S.string(),
  'choices':        S.list(items: S.object(properties: {
    'id': S.string(), 'text': S.string(),
  })),
  'correctChoiceId': S.string(),
  'explanation':     S.string(),
}, required: ['question', 'choices', 'correctChoiceId']),

// True / False
dataSchema: S.object(properties: {
  'statement':   S.string(),
  'isTrue':      S.boolean(),
  'explanation': S.string(),
}, required: ['statement', 'isTrue']),

// Fill in the blank
dataSchema: S.object(properties: {
  'statement':     S.string(),
  'correctAnswer': S.string(),
  'hint':          S.string(),
}, required: ['statement', 'correctAnswer']),
```

---

## Slide 12 — Step 4: Assemble the Catalog

**Register all card types in one place**

```dart
// lib/widgets/quiz_catalog.dart
Catalog buildQuizCatalog({
  required void Function(bool isCorrect) onAnswered,
}) {
  return BasicCatalogItems.asCatalog().copyWith(newItems: [
    multipleChoiceCardItem(onAnswered),
    trueFalseCardItem(onAnswered),
    fillInBlankCardItem(onAnswered),
    orderTheStepsCardItem(onAnswered),
    wordBankCardItem(onAnswered),
    sliderCardItem(onAnswered),
  ]);
}
```

- `BasicCatalogItems` — genui's built-in text/markdown widgets
- `.copyWith(newItems: [...])` — add your custom types on top
- To add a new format: create its file, add one line here

---

## Slide 13 — Step 5: Wire Everything Together

```dart
void _startQuiz(String topic) {
  final catalog = buildQuizCatalog(
    onAnswered: (isCorrect) => setState(() {
      _answered++;
      if (isCorrect) _correct++;
    }),
  );

  // genui reads your schemas and builds the system prompt
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
      final response = model.generateContentStream(
        [Content.text(message.text)],
      );
      await for (final chunk in response) {
        transport.addChunk(chunk.text ?? '');
      }
    },
  );

  _conversation = Conversation(
    controller: _surfaceController!,
    transport: transport,
  );
}
```

```dart
String _systemFragments(String topic) =>
    'You are a quiz generator for "$topic". '
    'Output all 5 questions at once without waiting. '
    'Keep explanations short (1 sentence). Mix difficulty.';
```

---

## Slide 14 — Step 6: Listen & Render

**Listen for surfaces → render one at a time with `Surface`**

```dart
// Listen for Gemini emitting a new component
_conversation!.events.listen((event) {
  if (event is ConversationSurfaceAdded(:final surfaceId)) {
    setState(() => _surfaceIds.add(surfaceId));
  }
});

// Kick off the quiz
_conversation!.sendRequest(
  ChatMessage.user('Give me quiz questions about: $topic. Mix the formats.'),
);
```

```dart
// Show one card at a time — genui picks the right widget automatically
Surface(
  key: ValueKey(_surfaceIds[_currentIndex]),
  surfaceContext: _surfaceController!.contextFor(_surfaceIds[_currentIndex]),
)

// After answering, a button advances to the next card
FilledButton.icon(
  onPressed: _nextQuestion,
  label: Text(_currentIndex >= _surfaceIds.length - 1
      ? 'See Results'
      : 'Next Question'),
)
```

`[IMG PLACEHOLDER: App screenshot — single card shown with Next Question button]`

---

## Slide 15 — Architecture in One Diagram

```
User types topic
      ↓
Conversation.sendRequest()
      ↓
A2uiTransportAdapter → Gemini 2.0 Flash
      ↓  (streams JSON component objects)
genui parses stream → ConversationSurfaceAdded
      ↓
SurfaceController matches CatalogItem
      ↓
Surface widget → your widgetBuilder → Flutter card
```

`[IMG PLACEHOLDER: Clean visual diagram of the above flow]`

---

## Slide 16 — Live Demo

**Let's try it**

Topics to try:
- "Flutter Basics"
- "World War II"
- "The Human Body"

> Ask the audience for a topic!

`[IMG PLACEHOLDER: QR code to GitHub repo]`

---

## Slide 17 — Key Takeaways

1. **Traditional AI UIs are still static** — the AI fills content, but the experience is fixed
2. **Generative UI flips that** — the AI decides *what* to render, not just *what to say*
3. **A2UI is the protocol; `genui` is the Flutter implementation** — backend-agnostic by design
4. **A `CatalogItem` is the unit of Generative UI** — one schema tells Gemini what to produce, one widget builder renders it
5. **You write normal Flutter widgets** — `genui` handles the bridge between LLM output and your UI
6. **In ~200 lines of Dart**, we got 4 interactive question formats, real-time streaming, and zero manual JSON parsing

---

## Slide 18 — Thank You + Resources

**Thanks!**

- `genui` — `pub.dev/packages/genui`
- Google AI Studio — `aistudio.google.com`
- Source code — `[IMG PLACEHOLDER: QR code]`

Questions?

**Jeo** · GitHub: `jeoooo` · GDG Davao

`[IMG PLACEHOLDER: GDG Davao logo]`
