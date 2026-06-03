/// Test helper functions and constants
class TestHelpers {
  // Sample JSON data for tests
  static const String validToken = 'valid_token_xyz123';
  static const String validRefreshToken = 'refresh_token_xyz456';
  static const String testEmail = 'test@example.com';
  static const String testPassword = 'TestPassword123';
  static const String testName = 'Test User';

  // Auth test data
  static Map<String, dynamic> getMockLoginResponse() {
    return {
      'data': {
        'token': validToken,
        'refreshToken': validRefreshToken,
        'user': {
          'id': '1',
          'name': testName,
          'email': testEmail,
          'role': 'CANDIDATE',
        },
      },
    };
  }

  static Map<String, dynamic> getMockRegisterResponse() {
    return {
      'data': {
        'message': 'User registered successfully',
      },
    };
  }

  // Job test data
  static Map<String, dynamic> getMockJobResponse() {
    return {
      'id': '1',
      'title': 'Flutter Developer',
      'companyName': 'Tech Corp',
      'companyLogo': 'https://example.com/logo.png',
      'location': 'Kathmandu',
      'salary': '50000-80000',
      'type': 'Full-time',
      'description': 'Join our team',
      'status': 'active',
      'applicantsCount': 5,
    };
  }

  static List<Map<String, dynamic>> getMockJobsList() {
    return [
      getMockJobResponse(),
      {
        'id': '2',
        'title': 'Backend Developer',
        'company': {'name': 'StartUp Inc', 'logo': 'https://example.com/startup.png'},
        'location': 'Pokhara',
        'status': 'active',
        'applicantsCount': '10',
      },
      {
        'id': '3',
        'title': 'UI Designer',
        'status': 'active',
        'applicantsCount': 0,
      },
    ];
  }

  // Application test data
  static Map<String, dynamic> getMockApplicationResponse() {
    return {
      'id': 'app1',
      'jobId': 'job1',
      'candidateId': 'cand1',
      'coverLetter': 'I am interested in this role',
      'status': 'ACCEPTED',
      'appliedAt': '2025-06-01T10:30:00Z',
      'resumeFileName': 'resume.pdf',
      'candidate': {
        'id': 'cand1',
        'name': 'John Doe',
        'email': 'john@example.com',
      },
    };
  }

  static List<Map<String, dynamic>> getMockApplicationsList() {
    return [
      getMockApplicationResponse(),
      {
        'id': 'app2',
        'jobId': 'job2',
        'candidateId': 'cand2',
        'status': 'PENDING',
        'appliedAt': '2025-06-01T10:30:00Z',
        'candidate': {
          'id': 'cand2',
          'name': 'Jane Smith',
          'email': 'jane@example.com',
        },
      },
    ];
  }

  // Notification test data
  static Map<String, dynamic> getMockNotificationResponse() {
    return {
      'id': 'notif1',
      'title': 'New Job Alert',
      'message': 'Flutter Developer job posted',
      'type': 'JOB_ALERT',
      'read': false,
      'actionUrl': '/job/123',
      'createdAt': '2025-06-01T10:30:00Z',
    };
  }

  static List<Map<String, dynamic>> getMockNotificationsList() {
    return [
      getMockNotificationResponse(),
      {
        'id': 'notif2',
        'title': 'Application Viewed',
        'message': 'Your application was viewed',
        'type': 'APPLICATION_VIEWED',
        'read': true,
        'createdAt': '2025-06-01T10:30:00Z',
      },
    ];
  }

  // Error test data
  static Map<String, dynamic> getMockErrorResponse(String message) {
    return {
      'error': true,
      'message': message,
    };
  }

  static Map<String, dynamic> getInvalidCredentialsError() {
    return getMockErrorResponse('Invalid email or password');
  }

  static Map<String, dynamic> getNetworkError() {
    return getMockErrorResponse('Network error');
  }

  static Map<String, dynamic> getUnauthorizedError() {
    return getMockErrorResponse('Unauthorized');
  }
}
