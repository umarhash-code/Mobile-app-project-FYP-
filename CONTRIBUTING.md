# Contributing to Everyday Chronicles

Thank you for considering contributing to the Everyday Chronicles project! This document outlines the guidelines and processes for contributing.

## 🤝 How to Contribute

### Reporting Issues

1. **Check existing issues** - Search through existing issues to avoid duplicates
2. **Use issue templates** - Follow the provided templates for bug reports and feature requests
3. **Provide detailed information** - Include steps to reproduce, expected behavior, and system details
4. **Add relevant labels** - Help categorize the issue appropriately

### Submitting Changes

1. **Fork the repository**
   ```bash
   git clone https://github.com/umarhash-code/Mobile-app-project-FYP-.git
   ```

2. **Create a feature branch**
   ```bash
   git checkout -b feature/your-feature-name
   ```

3. **Make your changes**
   - Follow the coding standards outlined below
   - Add tests for new functionality
   - Update documentation as needed

4. **Commit your changes**
   ```bash
   git commit -m "feat: add new emotion detection algorithm"
   ```

5. **Push to your fork**
   ```bash
   git push origin feature/your-feature-name
   ```

6. **Submit a Pull Request**
   - Use the pull request template
   - Provide a clear description of changes
   - Link related issues
   - Request review from maintainers

## 📝 Coding Standards

### Dart/Flutter Guidelines

- **Follow Flutter best practices** and [Effective Dart](https://dart.dev/guides/language/effective-dart)
- **Use meaningful variable names** that describe their purpose
- **Add documentation** for public APIs and complex logic
- **Maintain consistent formatting** using `flutter format`
- **Follow Material 3 guidelines** for UI components

### Code Structure

```dart
// Good: Descriptive function with documentation
/// Analyzes text for emotional content using AI detection
/// 
/// Returns [EmotionResult] containing detected emotion and confidence
Future<EmotionResult> analyzeEmotion(String text) async {
  // Implementation
}

// Bad: Unclear naming and no documentation
Future<dynamic> doStuff(String s) async {
  // Implementation
}
```

### Commit Message Convention

We follow [Conventional Commits](https://www.conventionalcommits.org/) specification:

- `feat:` - New features
- `fix:` - Bug fixes
- `docs:` - Documentation changes
- `style:` - Code style changes (formatting, etc.)
- `refactor:` - Code refactoring
- `test:` - Adding or updating tests
- `chore:` - Maintenance tasks

Examples:
```
feat: add voice-to-text journal entry functionality
fix: resolve emotion detection accuracy for casual language
docs: update installation instructions for Firebase setup
refactor: optimize AI emotion processing algorithm
```

## 🧪 Testing

### Running Tests
```bash
# Run all tests
flutter test

# Run tests with coverage
flutter test --coverage
```

### Adding Tests
- Write unit tests for new functions and classes
- Add widget tests for UI components
- Include integration tests for key user flows
- Ensure test coverage remains above 80%

## 📱 Platform-Specific Considerations

### Android
- Test on various screen sizes and Android versions
- Ensure Material Design compliance
- Verify proper permissions handling

### iOS
- Follow Apple Human Interface Guidelines
- Test on different iOS versions
- Ensure proper App Store compliance

### Web/Desktop
- Ensure responsive design works across platforms
- Test keyboard navigation and accessibility

## 🔍 Code Review Process

1. **Automated Checks** - All PRs must pass CI/CD checks
2. **Manual Review** - At least one maintainer review required
3. **Testing** - Verify changes work on multiple platforms
4. **Documentation** - Ensure proper documentation updates

### Review Checklist
- [ ] Code follows project conventions
- [ ] Tests are included and passing
- [ ] Documentation is updated
- [ ] Breaking changes are documented
- [ ] Performance impact is considered

## 🏗️ Development Setup

### Prerequisites
- Flutter SDK 3.0+
- Dart SDK 3.0+
- Android Studio / Xcode (for mobile development)
- Firebase account for backend services

### Local Development
1. Clone the repository
2. Run `flutter pub get`
3. Set up Firebase configuration
4. Run `flutter run` to start development

### Building for Release
```bash
# Android
flutter build apk --release
flutter build appbundle --release

# iOS
flutter build ipa --release

# Web
flutter build web --release
```

## 🎯 Areas for Contribution

### High Priority
- **Emotion Detection Accuracy** - Improve AI algorithms
- **Performance Optimization** - Reduce app startup time
- **Accessibility** - Add screen reader support
- **Internationalization** - Multi-language support

### Medium Priority
- **Voice Features** - Voice-to-text functionality
- **Social Features** - Sharing and community aspects
- **Advanced Analytics** - Better mood insights
- **Wearable Integration** - Smartwatch compatibility

### Low Priority
- **Themes** - Additional color schemes
- **Export Options** - More data export formats
- **Gamification** - Achievement system
- **Widgets** - Home screen widgets

## 📞 Getting Help

- **Documentation** - Check the README and project wiki
- **Discussions** - Use GitHub Discussions for questions
- **Issues** - Report bugs through GitHub Issues
- **Email** - Contact maintainers for sensitive matters

## 🏆 Recognition

Contributors will be recognized in:
- README.md contributors section
- Release notes for significant contributions
- Hall of fame for major features

## 📄 License

By contributing to Everyday Chronicles, you agree that your contributions will be licensed under the MIT License.

---

Thank you for making Everyday Chronicles better! 🙏