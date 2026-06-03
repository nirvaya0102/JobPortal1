# Flutter Mobile App Unit Testing Guide

This directory contains comprehensive unit tests for the Khojgar Kendra mobile app.

## Test Structure

```
test/
├── core/
│   └── storage/
│       └── token_storage_test.dart       # TokenStorage mock tests
├── features/
│   ├── auth/
│   │   └── services/
│   ├── jobs/
│   │   ├── models/
│   │   │   ├── job_model_test.dart       # JobModel parsing tests
│   │   │   └── application_model_test.dart
│   │   └── services/
│   └── notifications/
│       └── models/
│           └── notification_model_test.dart
├── shared/
│   └── widgets/
│       └── app_button_test.dart          # Widget tests
└── helpers/
    ├── mock_token_storage.dart           # Mock implementations
    └── test_helpers.dart                 # Test data & utilities
```

## Running Tests

### Run all tests
```bash
flutter test
```

### Run tests for a specific file
```bash
flutter test test/features/jobs/models/job_model_test.dart
```

### Run tests with verbose output
```bash
flutter test --verbose
```

### Run tests with coverage
```bash
flutter test --coverage
```

### Generate coverage report
```bash
flutter test --coverage
# Install lcov (macOS: brew install lcov, Linux: sudo apt-get install lcov)
genhtml coverage/lcov.info -o coverage/html
open coverage/html/index.html
```

### Watch mode (run tests on file changes)
```bash
flutter test --watch
```

## Test Coverage

### Models (100% Coverage)
- ✅ **JobModel**: JSON parsing, defaults, type conversion
- ✅ **ApplicationModel & CandidateModel**: Nested object parsing, null safety
- ✅ **NotificationModel**: Enum parsing, date handling

### Services (Mocked)
- ✅ **TokenStorage**: Save, retrieve, clear tokens
- Authentication flow
- Job operations
- Applications

### Widgets
- ✅ **AppButton**: States, interactions, loading, icons

## Test Categories

### Unit Tests
- **Model Tests**: JSON deserialization, null handling, defaults
- **Storage Tests**: Token persistence, retrieval, clearing
- **Widget Tests**: Rendering, user interactions, state changes

### What Each Test File Contains

#### job_model_test.dart (18 tests)
- Complete JSON parsing ✓
- Company object parsing ✓
- Missing optional fields ✓
- Applicants count in multiple formats ✓
- _count structure ✓
- Default values ✓

#### application_model_test.dart (13 tests)
- Complete JSON parsing ✓
- Nested candidate data ✓
- Nullable fields ✓
- Missing required fields defaults ✓

#### notification_model_test.dart (19 tests)
- Type enum parsing ✓
- All notification types ✓
- Unknown type fallback ✓
- Date parsing ✓
- Nullable actionUrl ✓

#### token_storage_test.dart (16 tests)
- Save/retrieve tokens ✓
- Token overwriting ✓
- Clearing tokens ✓
- Call count tracking ✓
- Complete lifecycle ✓

#### app_button_test.dart (12 tests)
- Button rendering ✓
- Click handling ✓
- Loading state ✓
- Icon display ✓
- Width expansion ✓

## Key Testing Patterns Used

### 1. Arrange-Act-Assert (AAA)
```dart
test('example', () {
  // Arrange
  final json = {'id': '1', 'title': 'Job'};
  
  // Act
  final job = JobModel.fromJson(json);
  
  // Assert
  expect(job.id, '1');
});
```

### 2. Group Organization
```dart
group('Feature', () {
  group('SubFeature', () {
    test('specific behavior', () {});
  });
});
```

### 3. Mock Objects
```dart
MockTokenStorage.reset();
await MockTokenStorage.saveTokens(...);
expect(MockTokenStorage.saveCallCount, 1);
```

### 4. Widget Testing
```dart
testWidgets('widget behavior', (WidgetTester tester) async {
  await tester.pumpWidget(widget);
  await tester.tap(find.byType(Button));
  expect(find.text('text'), findsOneWidget);
});
```

## Test Helpers

### TestHelpers Class
Provides mock data for common scenarios:
- `getMockLoginResponse()` - Login data
- `getMockJobsList()` - Multiple jobs
- `getMockApplicationsList()` - Applications
- `getMockNotificationsList()` - Notifications

### MockTokenStorage
Mock implementation for testing token operations without dependencies.

## Writing New Tests

### 1. Test Models
```dart
group('MyModel', () {
  group('fromJson', () {
    test('creates valid instance', () {
      final json = {...};
      final model = MyModel.fromJson(json);
      expect(model.property, expectedValue);
    });
  });
});
```

### 2. Test Widgets
```dart
testWidgets('MyWidget renders correctly', (WidgetTester tester) async {
  await tester.pumpWidget(
    MaterialApp(home: MyWidget(...))
  );
  expect(find.byType(MyWidget), findsOneWidget);
});
```

### 3. Test Services (with mocks)
```dart
test('service method works', () async {
  MockTokenStorage.reset();
  // Use mock instead of real implementation
  final result = await ServiceUnderTest.method();
  expect(result, expectedValue);
});
```

## Common Test Assertions

```dart
expect(actual, matcher);

// Common matchers
expect(value, equals(expected));
expect(value, isNull);
expect(value, isNotNull);
expect(value, isEmpty);
expect(value, isNotEmpty);
expect(list, contains(item));
expect(value, isA<Type>());
expect(callback, throwsException);
```

## Best Practices

1. **Test naming**: Use descriptive names that explain what is tested
   - ❌ `test('works')`
   - ✅ `test('saves access token and refresh token')`

2. **Setup/Teardown**: Use setUp and tearDown
   ```dart
   setUp(() {
     MockTokenStorage.reset();
   });
   ```

3. **Test isolation**: Each test should be independent
   - Don't rely on test execution order
   - Clean up state after each test

4. **Single responsibility**: One assertion per concept
   - Test one thing per test case
   - Use multiple tests for multiple scenarios

5. **Avoid flakiness**: 
   - Use `pumpAndSettle()` for async operations
   - Don't use `sleep()` or delays
   - Mock external dependencies

## Continuous Integration

These tests can be run in CI/CD:

```yaml
# Example GitHub Actions
- name: Run tests
  run: flutter test --coverage

- name: Upload coverage
  uses: codecov/codecov-action@v3
```

## Future Test Additions

- [ ] Service layer tests (with http mocking)
- [ ] Provider/State management tests
- [ ] Integration tests
- [ ] Performance tests
- [ ] Golden file tests for UI consistency

## Troubleshooting

### Tests not found
```bash
# Ensure test files end with _test.dart
flutter test --verbose
```

### Timeout errors
```bash
# Increase timeout for slow operations
flutter test --timeout=60s
```

### Dependencies issues
```bash
# Get all packages
flutter pub get
# Then run tests
flutter test
```

## Resources

- [Flutter Testing Documentation](https://flutter.dev/docs/testing)
- [Dart Testing Guide](https://dart.dev/guides/testing)
- [Flutter Widget Testing](https://flutter.dev/docs/testing/unit-and-widget-tests)
- [Effective Dart: Testing](https://dart.dev/guides/language/effective-dart/testing)
