import '../../../core/api/api_client.dart';
import '../../../core/storage/user_storage.dart';

class CandidateProfileService {
  Future<CandidateProfileData> fetchProfile() async {
    final meResponse = await ApiClient.dio.get('auth/me');
    final meData = _asMap(meResponse.data['data'] ?? meResponse.data);
    final user = _asMap(meData['user']);

    final applicationsResponse = await ApiClient.dio.get(
      'jobs/my-applications?page=1&limit=1',
    );
    final applicationsData = _asMap(applicationsResponse.data['data']);
    final pagination = _asMap(applicationsData['pagination']);
    final applicationsCount = _asInt(pagination['total']);

    final profile = _asMap(user['candidateProfile']);
    final skillsText = (profile['skills'] ?? '').toString().trim();
    final skills = skillsText.isEmpty
        ? <String>[]
        : skillsText
              .split(RegExp(r'[,\n]'))
              .map((skill) => skill.trim())
              .where((skill) => skill.isNotEmpty)
              .toList();

    final filledFields =
        [
              user['name'],
              user['email'],
              user['location'],
              profile['headline'],
              profile['bio'],
              profile['resumeUrl'],
              if (skills.isNotEmpty) skills.join(','),
            ]
            .where(
              (value) => value != null && value.toString().trim().isNotEmpty,
            )
            .length;

    final profileCompletion = ((filledFields / 7) * 100).round().clamp(0, 100);

    return CandidateProfileData(
      name: await _display(user['name'], UserStorage.getName, 'Your Name'),
      role: await _display(user['role'], UserStorage.getRole, 'Candidate'),
      location: await _display(
        user['location'] ?? user['companyLocation'],
        UserStorage.getLocation,
        'Your location',
      ),
      email: await _display(
        user['email'],
        UserStorage.getEmail,
        'your@email.com',
      ),
      headline: await _display(
        profile['headline'],
        () async => null,
        'Your professional headline',
      ),
      bio: await _display(
        profile['bio'],
        () async => null,
        'Add a short bio to showcase your strengths.',
      ),
      skills: skills,
      resumeFileName: await _display(
        profile['resumeFileName'],
        () async => null,
        '',
      ),
      hasResume: (profile['resumeUrl'] ?? '').toString().trim().isNotEmpty,
      applicationsCount: applicationsCount,
      profileCompletion: profileCompletion,
    );
  }

  Future<String> _display(
    dynamic value,
    Future<String?> Function() fallbackLoader,
    String fallback,
  ) async {
    final text = value?.toString().trim() ?? '';
    if (text.isNotEmpty) return text;

    final fallbackValue = (await fallbackLoader())?.trim() ?? '';
    return fallbackValue.isEmpty ? fallback : fallbackValue;
  }

  // PROFILE-004: Update skills
  Future<void> updateSkills(List<String> skills) async {
    try {
      await ApiClient.dio.patch(
        'auth/profile/skills',
        data: {
          'skills': skills.join(', '),
        },
      );
    } catch (e) {
      throw Exception('Failed to update skills: ${e.toString()}');
    }
  }

  int _asInt(dynamic value) {
    if (value is int) return value;
    return int.tryParse(value?.toString() ?? '') ?? 0;
  }

  Map<String, dynamic> _asMap(dynamic value) {
    if (value is Map<String, dynamic>) return value;
    if (value is Map) {
      return value.map((key, dynamic value) => MapEntry(key.toString(), value));
    }
    return <String, dynamic>{};
  }
}

class CandidateProfileData {
  final String name;
  final String role;
  final String location;
  final String email;
  final String headline;
  final String bio;
  final List<String> skills;
  final String resumeFileName;
  final bool hasResume;
  final int applicationsCount;
  final int profileCompletion;

  const CandidateProfileData({
    required this.name,
    required this.role,
    required this.location,
    required this.email,
    required this.headline,
    required this.bio,
    required this.skills,
    required this.resumeFileName,
    required this.hasResume,
    required this.applicationsCount,
    required this.profileCompletion,
  });
}
