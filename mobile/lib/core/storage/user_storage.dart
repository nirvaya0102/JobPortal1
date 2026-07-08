import 'package:flutter_secure_storage/flutter_secure_storage.dart';

class UserStorage {
  static const FlutterSecureStorage _storage = FlutterSecureStorage();

  static const String _nameKey = 'user_name';
  static const String _idKey = 'user_id';
  static const String _roleKey = 'user_role';
  static const String _locationKey = 'user_location';
  static const String _emailKey = 'user_email';
  static const String _phoneKey = 'user_phone';
  static const String _rememberMeEmailKey = 'remember_me_email'; // AUTH-006

  static Future<void> saveUser({
    String? id,
    required String name,
    required String role,
    String? location,
    String? email,
    String? phone,
  }) async {
    if (id != null && id.trim().isNotEmpty) {
      await _storage.write(key: _idKey, value: id.trim());
    }
    await _storage.write(key: _nameKey, value: name);
    await _storage.write(key: _roleKey, value: role);
    if (location != null && location.trim().isNotEmpty) {
      await _storage.write(key: _locationKey, value: location.trim());
    }
    if (email != null && email.trim().isNotEmpty) {
      await _storage.write(key: _emailKey, value: email.trim());
    }
    if (phone != null && phone.trim().isNotEmpty) {
      await _storage.write(key: _phoneKey, value: phone.trim());
    }
  }

  static Future<String?> getId() => _storage.read(key: _idKey);
  static Future<String?> getName() => _storage.read(key: _nameKey);
  static Future<String?> getRole() => _storage.read(key: _roleKey);
  static Future<String?> getLocation() => _storage.read(key: _locationKey);
  static Future<String?> getEmail() => _storage.read(key: _emailKey);
  static Future<String?> getPhone() => _storage.read(key: _phoneKey);

  static Future<void> savePhone(String phone) =>
      _storage.write(key: _phoneKey, value: phone.trim());

  // AUTH-006: Remember me functionality
  static Future<void> saveRememberMeEmail(String email) =>
      _storage.write(key: _rememberMeEmailKey, value: email);

  static Future<String?> getRememberMeEmail() =>
      _storage.read(key: _rememberMeEmailKey);

  static Future<void> clearRememberMeEmail() =>
      _storage.delete(key: _rememberMeEmailKey);

  static Future<void> clear() async {
    await _storage.delete(key: _idKey);
    await _storage.delete(key: _nameKey);
    await _storage.delete(key: _roleKey);
    await _storage.delete(key: _locationKey);
    await _storage.delete(key: _emailKey);
    await _storage.delete(key: _phoneKey);
  }
}
