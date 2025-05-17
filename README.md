# E-MOTION AI

A Flutter-based emotion tracking and mental wellness application with AI-powered insights.

## Features

- **Emotion Tracking**: Record and monitor your emotions with notes and timestamps
- **Calendar View**: Visualize your emotional patterns over time
- **Breathing Exercises**: Access guided breathing sessions for stress reduction
- **AI Therapist Chat**: "Talk it Through" with an AI-powered therapist using OpenAI
- **User Profiles**: Personalize your experience with custom profile information
- **Data Management**: Securely store data locally with option to delete all records

## Setup

### Prerequisites
- Flutter SDK (^3.7.2)
- Dart SDK (^3.7.2)
- OpenAI API Key

### Installation

1. Clone the repository
```
git clone https://github.com/yourusername/emotion-ai-app.git
cd emotion-ai-app
```

2. Install dependencies
```
flutter pub get
```

3. Set up environment variables
   - Create an `assets/.env` file in the project root
   - Add your OpenAI API key:
   ```
   OPENAI_API_KEY=your_api_key_here
   ```

4. Run the app
```
flutter run
```

## Usage

- **Home Screen**: Access all main features through the navigation menu
- **Record Emotions**: Log your current emotional state with context notes
- **Breathing Exercises**: Follow guided breathing patterns for relaxation
- **Talk it Through**: Chat with the AI therapist about your feelings
- **Calendar**: Review your emotional records by date
- **Profile**: Set up your personal information for more tailored AI therapy
- **Settings**: Manage app settings including data deletion

## Technologies

- Flutter & Dart
- Riverpod for state management
- SQLite for local storage
- OpenAI API for AI-powered therapy
- GoRouter for navigation
- flutter_dotenv for environment variables

## Security

- API keys are stored securely using environment variables
- All data is stored locally on your device
- Option to delete all local data is available
