# Dynamic Quiz — Build With AI 2026 Lightning Talk Demo

A Flutter app that generates interactive quiz questions on any topic in real time using **Gemini** and **GenUI** — built as a live demo for the [Build With AI 2026](https://buildwithai.dev) lightning talk.

---

## What it does

Type any topic (e.g. "Solar System", "Flutter Basics", "The Human Body") and the app:

1. Sends a prompt to **Gemini 2.5 Flash Lite** asking for 3 quiz questions.
2. Gemini responds with structured JSON that describes UI components.
3. **GenUI** parses that JSON and renders the questions as interactive Flutter widgets — no pre-written question bank required.

The AI picks from 6 different question formats, mixing them randomly each run:

| Format | Description |
|---|---|
| Multiple Choice | Pick the correct answer from 4 options |
| True / False | Classic two-choice card |
| Fill in the Blank | Type the missing word |
| Order the Steps | Drag items into the correct sequence |
| Word Bank | Tap words to fill in blanks |
| Slider | Drag to the correct numeric value |

---

## Key idea: AI-generated UI

The core concept being demonstrated is **generative UI** — the model doesn't just return text or data, it returns a description of a UI surface. GenUI handles the rendering, so the app can display arbitrarily structured question formats without knowing them ahead of time.

```
User types topic
      │
      ▼
Gemini 2.5 Flash Lite
      │  returns JSON UI description
      ▼
GenUI renders Flutter widgets
      │
      ▼
User answers → score tracked
```

---

## Tech stack

| | |
|---|---|
| Framework | Flutter (Dart) |
| AI model | Gemini 2.5 Flash Lite via `google_generative_ai` |
| GenUI | `genui ^0.9.0` — server-driven UI for Flutter |
| Env config | `flutter_dotenv` (API key via `.env`) |

---

## Running locally

**Prerequisites:** Flutter SDK, a Gemini API key.

1. Clone the repo.
2. Create a `.env` file in the project root:
   ```
   GEMINI_API_KEY=your_key_here
   ```
3. Install dependencies:
   ```
   flutter pub get
   ```
4. Run on your target device/emulator:
   ```
   flutter run
   ```

---

## Project structure

```
lib/
├── main.dart                  # App entry, Gemini + GenUI wiring
├── utils/
│   ├── api_key_helper.dart    # Loads API key from .env
│   └── logger.dart            # AI request/response logging
└── widgets/
    ├── quiz_catalog.dart      # Registers all question formats with GenUI
    ├── multiple_choice_card.dart
    ├── true_false_card.dart
    ├── fill_in_blank_card.dart
    ├── order_the_steps_card.dart
    ├── word_bank_card.dart
    └── slider_card.dart
```

---

> Questions and answers are AI-generated and may occasionally be inaccurate.
