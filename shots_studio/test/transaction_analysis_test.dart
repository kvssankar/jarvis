import 'package:flutter_test/flutter_test.dart';
import 'package:shots_studio/models/transaction_model.dart';
import 'package:shots_studio/services/message_service.dart';

void main() {
  group('Transaction Model Tests', () {
    test('Transaction model should serialize and deserialize correctly', () {
      final transaction = Transaction(
        id: 'test-id',
        fromAccount: 'HDFC Bank',
        toAccount: 'Amazon',
        transactionType: 'DEBIT',
        amount: 1299.50,
        category: 'shopping',
        transactionDate: DateTime(2024, 1, 15, 10, 30),
        paymentMode: 'UPI',
        originalMessage: 'Test transaction message',
        description: 'Online purchase',
        currency: 'INR',
      );

      final json = transaction.toJson();
      final deserializedTransaction = Transaction.fromJson(json);

      expect(deserializedTransaction.id, equals(transaction.id));
      expect(
        deserializedTransaction.fromAccount,
        equals(transaction.fromAccount),
      );
      expect(deserializedTransaction.toAccount, equals(transaction.toAccount));
      expect(
        deserializedTransaction.transactionType,
        equals(transaction.transactionType),
      );
      expect(deserializedTransaction.amount, equals(transaction.amount));
      expect(deserializedTransaction.category, equals(transaction.category));
      expect(
        deserializedTransaction.transactionDate,
        equals(transaction.transactionDate),
      );
      expect(
        deserializedTransaction.paymentMode,
        equals(transaction.paymentMode),
      );
      expect(
        deserializedTransaction.originalMessage,
        equals(transaction.originalMessage),
      );
      expect(
        deserializedTransaction.description,
        equals(transaction.description),
      );
      expect(deserializedTransaction.currency, equals(transaction.currency));
    });

    test('TransactionSummary should group transactions correctly', () {
      final transactions = [
        Transaction(
          id: '1',
          fromAccount: 'HDFC Bank',
          toAccount: 'Amazon',
          transactionType: 'DEBIT',
          amount: 1000.0,
          category: 'shopping',
          transactionDate: DateTime(2024, 1, 15),
          paymentMode: 'UPI',
          originalMessage: 'Test message 1',
        ),
        Transaction(
          id: '2',
          fromAccount: 'HDFC Bank',
          toAccount: 'Flipkart',
          transactionType: 'DEBIT',
          amount: 500.0,
          category: 'shopping',
          transactionDate: DateTime(2024, 1, 16),
          paymentMode: 'CARD',
          originalMessage: 'Test message 2',
        ),
      ];

      final summary = TransactionSummary(
        accountName: 'HDFC Bank',
        totalAmount: 1500.0,
        transactionCount: 2,
        transactions: transactions,
        firstTransaction: DateTime(2024, 1, 15),
        lastTransaction: DateTime(2024, 1, 16),
      );

      expect(summary.accountName, equals('HDFC Bank'));
      expect(summary.totalAmount, equals(1500.0));
      expect(summary.transactionCount, equals(2));
      expect(summary.transactions.length, equals(2));
    });
  });

  group('SMS Message Tests', () {
    test('SmsMessage model should serialize and deserialize correctly', () {
      final message = SmsMessage(
        id: 'msg-1',
        address: '+1234567890',
        body: 'Test SMS message',
        date: DateTime(2024, 1, 15, 10, 30),
        type: 1,
        isRead: true,
      );

      final json = message.toJson();
      final deserializedMessage = SmsMessage.fromJson(json);

      expect(deserializedMessage.id, equals(message.id));
      expect(deserializedMessage.address, equals(message.address));
      expect(deserializedMessage.body, equals(message.body));
      expect(deserializedMessage.date, equals(message.date));
      expect(deserializedMessage.type, equals(message.type));
      expect(deserializedMessage.isRead, equals(message.isRead));
    });

    test('SmsMessage should correctly identify received and sent messages', () {
      final receivedMessage = SmsMessage(
        id: 'msg-1',
        address: '+1234567890',
        body: 'Received message',
        date: DateTime.now(),
        type: 1,
        isRead: true,
      );

      final sentMessage = SmsMessage(
        id: 'msg-2',
        address: '+1234567890',
        body: 'Sent message',
        date: DateTime.now(),
        type: 2,
        isRead: true,
      );

      expect(receivedMessage.isReceived, isTrue);
      expect(receivedMessage.isSent, isFalse);
      expect(sentMessage.isReceived, isFalse);
      expect(sentMessage.isSent, isTrue);
    });
  });
}
