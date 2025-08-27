import 'dart:async';
import 'dart:convert';
import 'package:flutter/services.dart';
import 'package:permission_handler/permission_handler.dart';

class MessageService {
  static const MethodChannel _channel = MethodChannel('message_service');

  static MessageService? _instance;
  MessageService._internal();

  factory MessageService() {
    return _instance ??= MessageService._internal();
  }

  /// Request SMS permission from the user
  Future<bool> requestSmsPermission() async {
    try {
      final status = await Permission.sms.request();
      return status == PermissionStatus.granted;
    } catch (e) {
      print('Error requesting SMS permission: $e');
      return false;
    }
  }

  /// Check if SMS permission is granted
  Future<bool> hasSmsPermission() async {
    try {
      final status = await Permission.sms.status;
      return status == PermissionStatus.granted;
    } catch (e) {
      print('Error checking SMS permission: $e');
      return false;
    }
  }

  /// Read all SMS messages from the device
  Future<List<SmsMessage>> readAllMessages() async {
    try {
      // Check permission first
      if (!await hasSmsPermission()) {
        throw Exception('SMS permission not granted');
      }

      final result = await _channel.invokeMethod('readAllMessages');
      final List<dynamic> messagesJson = jsonDecode(result);

      return messagesJson
          .map((json) => SmsMessage.fromJson(json as Map<String, dynamic>))
          .toList();
    } on PlatformException catch (e) {
      print('Platform exception reading messages: ${e.message}');
      throw Exception('Failed to read messages: ${e.message}');
    } catch (e) {
      print('Error reading messages: $e');
      throw Exception('Failed to read messages: $e');
    }
  }

  /// Read SMS messages from a specific date range
  Future<List<SmsMessage>> readMessagesFromDateRange({
    required DateTime startDate,
    required DateTime endDate,
  }) async {
    try {
      if (!await hasSmsPermission()) {
        throw Exception('SMS permission not granted');
      }

      final result = await _channel.invokeMethod('readMessagesFromDateRange', {
        'startDate': startDate.millisecondsSinceEpoch,
        'endDate': endDate.millisecondsSinceEpoch,
      });

      final List<dynamic> messagesJson = jsonDecode(result);

      return messagesJson
          .map((json) => SmsMessage.fromJson(json as Map<String, dynamic>))
          .toList();
    } on PlatformException catch (e) {
      print(
        'Platform exception reading messages from date range: ${e.message}',
      );
      throw Exception('Failed to read messages: ${e.message}');
    } catch (e) {
      print('Error reading messages from date range: $e');
      throw Exception('Failed to read messages: $e');
    }
  }

  /// Read recent SMS messages (last N days)
  Future<List<SmsMessage>> readRecentMessages({int days = 30}) async {
    final endDate = DateTime.now();
    final startDate = endDate.subtract(Duration(days: days));

    return readMessagesFromDateRange(startDate: startDate, endDate: endDate);
  }

  /// Read SMS messages since a specific date (for incremental analysis)
  Future<List<SmsMessage>> readMessagesSince(DateTime sinceDate) async {
    final endDate = DateTime.now();
    return readMessagesFromDateRange(startDate: sinceDate, endDate: endDate);
  }
}

class SmsMessage {
  final String id;
  final String address; // Phone number or sender
  final String body;
  final DateTime date;
  final int type; // 1 = received, 2 = sent
  final bool isRead;

  SmsMessage({
    required this.id,
    required this.address,
    required this.body,
    required this.date,
    required this.type,
    required this.isRead,
  });

  bool get isReceived => type == 1;
  bool get isSent => type == 2;

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'address': address,
      'body': body,
      'date': date.toIso8601String(),
      'type': type,
      'isRead': isRead,
    };
  }

  factory SmsMessage.fromJson(Map<String, dynamic> json) {
    return SmsMessage(
      id: json['id'] as String,
      address: json['address'] as String,
      body: json['body'] as String,
      date: DateTime.fromMillisecondsSinceEpoch(json['date'] as int),
      type: json['type'] as int,
      isRead: json['isRead'] as bool,
    );
  }
}
