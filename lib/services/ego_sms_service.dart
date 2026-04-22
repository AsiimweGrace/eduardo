import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'offline_storage_service.dart';

class SmsResult {
  final bool success;
  final String message;
  final String? error;

  SmsResult({required this.success, required this.message, this.error});
}

class EgoSmsService {
  static EgoSmsService? _instance;
  static const String _baseUrl = 'https://comms.egosms.co/api/v1/json/';
  
  static const String _usernameKey = 'egosms_username';
  static const String _apiKeyKey = 'egosms_api_key';
  static const String _senderIdKey = 'egosms_sender_id';

  final OfflineStorageService _offlineStorage = OfflineStorageService.instance;

  EgoSmsService._();

  static EgoSmsService get instance {
    _instance ??= EgoSmsService._();
    return _instance!;
  }

  Future<void> configure({
    required String username,
    required String apiKey,
    required String senderId,
  }) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_usernameKey, username);
    await prefs.setString(_apiKeyKey, apiKey);
    await prefs.setString(_senderIdKey, senderId);
  }

  Future<void> configureWithDefaults() async {
    await configure(
      username: 'BBMI',
      apiKey: 'asimblack256',
      senderId: 'BBMI',
    );
  }

  Future<Map<String, String>> _getCredentials() async {
    final prefs = await SharedPreferences.getInstance();
    return {
      'username': prefs.getString(_usernameKey) ?? '',
      'apiKey': prefs.getString(_apiKeyKey) ?? '',
      'senderId': prefs.getString(_senderIdKey) ?? 'BananaAI',
    };
  }

  Future<bool> _hasValidCredentials() async {
    final creds = await _getCredentials();
    return creds['username']!.isNotEmpty && creds['apiKey']!.isNotEmpty;
  }

  Future<SmsResult> sendSms({
    required String number,
    required String message,
    String? senderId,
    int priority = 0,
  }) async {
    if (!await _hasValidCredentials()) {
      return SmsResult(
        success: false,
        message: 'SMS service not configured',
        error: 'Please configure EgoSMS credentials in settings',
      );
    }

    final creds = await _getCredentials();
    final isOnline = await _offlineStorage.isOnline();

    if (!isOnline) {
      return SmsResult(
        success: false,
        message: 'No internet connection',
        error: 'Message queued for sending when online',
      );
    }

    try {
      final response = await http.post(
        Uri.parse(_baseUrl),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'method': 'SendSms',
          'userdata': {
            'username': creds['username'],
            'password': creds['apiKey'],
          },
          'msgdata': [
            {
              'number': _formatPhoneNumber(number),
              'message': message,
              'senderid': senderId ?? creds['senderId'],
              'priority': priority.toString(),
            },
          ],
        }),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if (data['response'] != null && data['response']['success'] == true) {
          return SmsResult(success: true, message: 'SMS sent successfully');
        } else {
          final errorMsg = data['response']?['error'] ?? 'Unknown error';
          return SmsResult(success: false, message: 'Failed to send SMS', error: errorMsg);
        }
      } else {
        return SmsResult(
          success: false,
          message: 'Server error',
          error: response.reasonPhrase,
        );
      }
    } catch (e) {
      return SmsResult(
        success: false,
        message: 'Connection error',
        error: e.toString(),
      );
    }
  }

  Future<SmsResult> sendBulkSms({
    required List<Map<String, String>> messages,
    String? senderId,
  }) async {
    if (!await _hasValidCredentials()) {
      return SmsResult(
        success: false,
        message: 'SMS service not configured',
        error: 'Please configure EgoSMS credentials in settings',
      );
    }

    final creds = await _getCredentials();
    final isOnline = await _offlineStorage.isOnline();

    if (!isOnline) {
      return SmsResult(
        success: false,
        message: 'No internet connection',
        error: 'Messages queued for sending when online',
      );
    }

    try {
      final msgData = messages.map((m) => {
        'number': _formatPhoneNumber(m['number']!),
        'message': m['message']!,
        'senderid': senderId ?? creds['senderId'],
        'priority': '0',
      }).toList();

      final response = await http.post(
        Uri.parse(_baseUrl),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'method': 'SendSms',
          'userdata': {
            'username': creds['username'],
            'password': creds['apiKey'],
          },
          'msgdata': msgData,
        }),
      );

      if (response.statusCode == 200) {
        return SmsResult(success: true, message: 'Bulk SMS sent successfully');
      } else {
        return SmsResult(
          success: false,
          message: 'Server error',
          error: response.reasonPhrase,
        );
      }
    } catch (e) {
      return SmsResult(
        success: false,
        message: 'Connection error',
        error: e.toString(),
      );
    }
  }

  String _formatPhoneNumber(String number) {
    String cleaned = number.replaceAll(RegExp(r'[^\d]'), '');
    
    if (cleaned.startsWith('0')) {
      cleaned = '256${cleaned.substring(1)}';
    } else if (!cleaned.startsWith('256')) {
      cleaned = '256$cleaned';
    }
    
    return cleaned;
  }

  Future<SmsResult> sendAdvisorySms({
    required String phoneNumber,
    required String disease,
    required String recommendation,
  }) async {
    final message = 'Banana Health AI Alert:\n'
        'Disease: $disease\n'
        'Recommendation: $recommendation\n'
        'From Banana Health AI';
    
    return sendSms(number: phoneNumber, message: message);
  }

  Future<void> syncPendingMessages() async {
    final isOnline = await _offlineStorage.isOnline();
    if (!isOnline) return;

    final prefs = await SharedPreferences.getInstance();
    final pendingMessages = prefs.getStringList('pending_sms') ?? [];
    
    if (pendingMessages.isEmpty) return;

    final creds = await _getCredentials();
    if (!await _hasValidCredentials()) return;

    try {
      final msgData = pendingMessages.map((m) {
        final parts = m.split('|');
        return {
          'number': _formatPhoneNumber(parts[0]),
          'message': parts[1],
          'senderid': creds['senderId'],
          'priority': '0',
        };
      }).toList();

      final response = await http.post(
        Uri.parse(_baseUrl),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'method': 'SendSms',
          'userdata': {
            'username': creds['username'],
            'password': creds['apiKey'],
          },
          'msgdata': msgData,
        }),
      );

      if (response.statusCode == 200) {
        await prefs.remove('pending_sms');
      }
    } catch (e) {
      print('Failed to sync pending SMS: $e');
    }
  }

  Future<void> queueMessageForLater(String number, String message) async {
    final prefs = await SharedPreferences.getInstance();
    final pending = prefs.getStringList('pending_sms') ?? [];
    pending.add('$number|$message');
    await prefs.setStringList('pending_sms', pending);
  }

  Future<bool> hasSmsConfiguration() async {
    return await _hasValidCredentials();
  }
}
