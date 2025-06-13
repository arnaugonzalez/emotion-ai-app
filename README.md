# E-motion AI

<div align="center">

![E-motion AI](assets/logo.png)

*Your personal emotional wellness companion*

</div>

## 🚀 Quick Start

1. **Clone & Install**
   ```bash
   git clone https://github.com/yourusername/emotion-ai-app.git
   cd emotion-ai-app
   flutter pub get
   ```

2. **Environment Setup**
   - Create a `.env` file in the `assets` directory
   - Add required configuration:
   ```env
   # OpenAI API Configuration
   OPENAI_API_KEY=your_api_key_here

   # Admin Configuration (Required)
   ADMIN_PIN=your_secure_pin_here
   ```

3. **Run the App**
   ```bash
   flutter run
   ```

## 🛡️ Security Requirements

- **Admin PIN**: Must be configured in `.env` file
- **Environment File**: Never commit `.env` to version control
- **Secure Storage**: Sensitive data is stored using Flutter Secure Storage

## 🌟 Key Features

- 🎨 **Emotion Tracking**
  - Custom emotion colors
  - Detailed emotion logging
  - Historical tracking

- 🧘 **Wellness Tools**
  - Guided breathing exercises
  - Meditation timers
  - Relaxation techniques

- 📊 **Analytics & Insights**
  - Emotional patterns
  - Progress tracking
  - Custom reports

- 🤖 **AI Integration**
  - Personalized suggestions
  - Pattern recognition
  - Adaptive responses

## 💻 Technical Stack

- **Frontend**: Flutter & Dart
- **State Management**: Riverpod
- **Navigation**: Go Router
- **Storage**: SQLite & Secure Storage
- **AI**: OpenAI API Integration

## 📱 Supported Platforms

- iOS 11.0+
- Android 5.0+
- Web (Beta)

## 🔄 Sync & Backup

- Automatic data synchronization
- Offline support
- Secure cloud backup

## 🤝 Contributing

1. Fork the repository
2. Create your feature branch
3. Commit your changes
4. Push to the branch
5. Open a Pull Request

## 📄 License

This project is licensed under the MIT License - see the [LICENSE](LICENSE) file for details.

## 🙏 Acknowledgments

- OpenAI for API support
- Flutter team for the framework
- All contributors and testers

---
<div align="center">
Made with ❤️ for emotional wellness
</div>
