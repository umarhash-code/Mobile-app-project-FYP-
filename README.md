# 📱 Everyday Chronicles - FYP Mobile Application

A comprehensive Flutter-based mobile application for daily journaling, mood tracking, and personal wellness with advanced AI emotion detection.

![Flutter](https://img.shields.io/badge/Flutter-%2302569B.svg?style=for-the-badge&logo=Flutter&logoColor=white)
![Dart](https://img.shields.io/badge/dart-%230175C2.svg?style=for-the-badge&logo=dart&logoColor=white)
![Firebase](https://img.shields.io/badge/firebase-%23039BE5.svg?style=for-the-badge&logo=firebase)

## 🌟 Features

### 📔 Smart Journaling
- **AI-Powered Emotion Detection**: Advanced emotion analysis using pure Dart implementation
- **Daily Entry Management**: Create, edit, and organize journal entries
- **Mood Insights**: Track emotional patterns over time
- **Smart Keywords**: Enhanced detection with daily-use language and expressions

### 🧘 Wellness & Mindfulness
- **Mindfulness Exercises**: Guided meditation and breathing exercises
- **Prayer Times**: Islamic prayer schedule with location-based calculations
- **Step Counter**: Integrated health tracking
- **Weather Integration**: Local weather updates for mood correlation

### 📊 Analytics & Insights
- **Emotion Analytics**: Comprehensive mood pattern analysis
- **App Usage Tracking**: Digital wellness monitoring
- **Personal Statistics**: Detailed insights into journaling habits

### 🎨 User Experience
- **Material 3 Design**: Modern, clean interface
- **Dark/Light Themes**: Customizable appearance
- **Offline Support**: Works without internet connection
- **Cross-Platform**: Android, iOS, Web, Windows, macOS, Linux support

## 🚀 Technologies Used

- **Frontend**: Flutter 3.x with Dart
- **Backend**: Firebase Authentication & Storage
- **AI/ML**: Custom Pure Dart Emotion Detection Engine
- **State Management**: Provider Pattern
- **Local Storage**: Shared Preferences
- **Fonts**: Google Fonts (Poppins)
- **Architecture**: Clean Architecture with Service Layer

## 📱 Screenshots

*Screenshots will be added as the project progresses*

## 🛠️ Installation & Setup

### Prerequisites
- Flutter SDK (3.0+)
- Dart SDK (3.0+)
- Android Studio / VS Code
- Firebase Account

### Clone Repository
```bash
git clone https://github.com/umarhash-code/Mobile-app-project-FYP-.git
cd Mobile-app-project-FYP-
```

### Install Dependencies
```bash
flutter pub get
```

### Firebase Setup
1. Create a new Firebase project
2. Add your `google-services.json` (Android) and `GoogleService-Info.plist` (iOS)
3. Configure Firebase Authentication and Firestore

### Run Application
```bash
# Run on mobile device/emulator
flutter run

# Run on specific platform
flutter run -d android
flutter run -d ios
flutter run -d windows
flutter run -d chrome
```

## 🏗️ Project Structure

```
lib/
├── ai/                    # AI Emotion Detection Engine
│   ├── emotion_weights.json
│   └── pure_dart_emotion_ai.dart
├── models/               # Data Models
├── screens/              # UI Screens
│   ├── auth/            # Authentication
│   ├── dashboard/       # Main Dashboard
│   ├── journal/         # Journal Management
│   ├── mindfulness/     # Wellness Features
│   └── settings/        # App Configuration
├── services/            # Business Logic
├── widgets/             # Reusable Components
└── utils/               # Utilities & Helpers
```

## 🧠 AI Emotion Detection

### Core Features
- **7 Emotion Categories**: Happy, Sad, Angry, Fear, Love, Surprise, Neutral
- **Daily Language Processing**: Optimized for casual, everyday expressions
- **Context Awareness**: School, work, and relationship context detection
- **Learning Capability**: Adapts to user's writing patterns
- **Offline Processing**: No external API dependencies

### Emotion Keywords Examples
```dart
// Happy emotions
"yay", "feeling awesome", "on top of the world", "super excited"

// Sad emotions  
"feeling down", "so sad", "worst day ever", "broken inside"

// Angry emotions
"so angry", "pissed off", "driving me crazy", "can't stand"

// And 2000+ more keywords across all categories...
```

## 📝 Key Screens

1. **Authentication**: Sign up, Sign in, Password recovery
2. **Dashboard**: Main hub with quick actions
3. **Journal Entry**: Create and manage daily entries
4. **Mood Analytics**: Emotion patterns and insights
5. **Mindfulness**: Guided exercises and wellness tools
6. **Settings**: App customization and preferences

## 🔮 Future Enhancements

- [ ] Voice-to-text journal entries
- [ ] Collaborative journaling with friends/family
- [ ] Advanced ML models for better emotion detection
- [ ] Wearable device integration
- [ ] Social features and community support
- [ ] Export data in multiple formats
- [ ] Habit tracking integration

## 🤝 Contributing

We welcome contributions! Please follow these steps:

1. Fork the repository
2. Create a feature branch (`git checkout -b feature/AmazingFeature`)
3. Commit changes (`git commit -m 'Add AmazingFeature'`)
4. Push to branch (`git push origin feature/AmazingFeature`)
5. Open a Pull Request

## 📄 License

This project is licensed under the MIT License - see the [LICENSE](LICENSE) file for details.

## 👨‍💻 Author

**Umar Hash**
- GitHub: [@umarhash-code](https://github.com/umarhash-code)
- Project: Final Year Project (FYP) - Mobile Application Development

## 🙏 Acknowledgments

- Flutter team for the amazing framework
- Firebase for backend services
- Material Design for UI/UX inspiration
- Open source community for continuous learning

---

*Built with ❤️ using Flutter for Final Year Project*
