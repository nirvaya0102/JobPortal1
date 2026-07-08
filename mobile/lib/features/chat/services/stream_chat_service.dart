import 'package:stream_chat/stream_chat.dart';

import '../../../core/api/api_client.dart';

class StreamTokenData {
  final String apiKey;
  final String token;
  final String userId;
  final String name;
  final String role;

  const StreamTokenData({
    required this.apiKey,
    required this.token,
    required this.userId,
    required this.name,
    required this.role,
  });

  factory StreamTokenData.fromJson(Map<String, dynamic> json) {
    final user = json['user'] is Map
        ? Map<String, dynamic>.from(json['user'])
        : <String, dynamic>{};

    return StreamTokenData(
      apiKey: json['apiKey']?.toString() ?? '',
      token: json['token']?.toString() ?? '',
      userId: user['id']?.toString() ?? '',
      name: user['name']?.toString() ?? 'User',
      role: user['role']?.toString() ?? '',
    );
  }
}

class StreamChannelData {
  final String channelId;
  final String channelType;

  const StreamChannelData({required this.channelId, required this.channelType});

  factory StreamChannelData.fromJson(Map<String, dynamic> json) {
    return StreamChannelData(
      channelId: json['channelId']?.toString() ?? '',
      channelType: json['channelType']?.toString() ?? 'messaging',
    );
  }
}

class JobPortalStreamChatService {
  JobPortalStreamChatService._();

  static final JobPortalStreamChatService instance =
      JobPortalStreamChatService._();

  StreamChatClient? _client;
  StreamTokenData? _tokenData;

  StreamChatClient? get clientOrNull => _client;

  StreamChatClient get client {
    final value = _client;
    if (value == null) {
      throw StateError('Stream Chat is not connected.');
    }
    return value;
  }

  String? get currentUserId => _tokenData?.userId;

  Future<StreamChatClient> connect() async {
    final tokenData = await _fetchToken();

    final existingClient = _client;
    if (existingClient != null &&
        _tokenData?.userId == tokenData.userId &&
        _tokenData?.apiKey == tokenData.apiKey) {
      return existingClient;
    }

    if (existingClient != null) {
      await existingClient.disconnectUser();
    }

    final nextClient = StreamChatClient(
      tokenData.apiKey,
      logLevel: Level.WARNING,
    );

    await nextClient.connectUser(
      User(id: tokenData.userId, name: tokenData.name, role: tokenData.role),
      tokenData.token,
    );

    _client = nextClient;
    _tokenData = tokenData;
    return nextClient;
  }

  Future<StreamChannelData> createOneToOneChannel({
    required String targetUserId,
    String? jobId,
  }) async {
    try {
      final response = await ApiClient.dio.post(
        'stream/channel',
        data: {
          'targetUserId': targetUserId,
          if (jobId != null && jobId.trim().isNotEmpty) 'jobId': jobId.trim(),
        },
      );

      final data = response.data['data'] is Map
          ? Map<String, dynamic>.from(response.data['data'])
          : <String, dynamic>{};
      final channelData = StreamChannelData.fromJson(data);
      if (channelData.channelId.isEmpty || channelData.channelType.isEmpty) {
        throw Exception('Invalid Stream channel response.');
      }
      return channelData;
    } on DioException catch (e) {
      throw Exception(_readableError(e, 'Failed to create chat.'));
    } catch (_) {
      throw Exception('Something went wrong. Please try again.');
    }
  }

  Future<Channel> watchChannel({
    required String channelId,
    String channelType = 'messaging',
  }) async {
    final chatClient = await connect();
    final channel = chatClient.channel(channelType, id: channelId);
    await channel.watch();
    return channel;
  }

  Future<void> disconnect() async {
    final existingClient = _client;
    _client = null;
    _tokenData = null;

    if (existingClient != null) {
      await existingClient.disconnectUser();
    }
  }

  Future<StreamTokenData> _fetchToken() async {
    try {
      final response = await ApiClient.dio.get('stream/token');
      final data = response.data['data'] is Map
          ? Map<String, dynamic>.from(response.data['data'])
          : <String, dynamic>{};
      final tokenData = StreamTokenData.fromJson(data);

      if (tokenData.apiKey.isEmpty ||
          tokenData.token.isEmpty ||
          tokenData.userId.isEmpty) {
        throw Exception('Invalid Stream token response.');
      }

      return tokenData;
    } on DioException catch (e) {
      throw Exception(_readableError(e, 'Failed to connect chat.'));
    }
  }

  String _readableError(DioException error, String fallback) {
    if (error.type == DioExceptionType.connectionError) {
      return 'No internet connection.';
    }
    if (error.response?.statusCode == 401) {
      return 'Session expired. Please login again.';
    }
    if ((error.response?.statusCode ?? 0) >= 500) {
      return 'Server error. Please try again later.';
    }

    final data = error.response?.data;
    if (data is Map && data['message'] != null) {
      final message = data['message'].toString().trim();
      if (message.isNotEmpty) return message;
    }

    final message = error.message?.trim();
    return message == null || message.isEmpty ? fallback : message;
  }
}
