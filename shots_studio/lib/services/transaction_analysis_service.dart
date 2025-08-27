import 'dart:async';
import 'dart:convert';
import 'package:shots_studio/models/transaction_model.dart';
import 'package:shots_studio/services/ai_service.dart';
import 'package:shots_studio/services/message_service.dart';
import 'package:shots_studio/repositories/transaction_repository.dart';
import 'package:uuid/uuid.dart';

class TransactionAnalysisService extends AIService {
  final TransactionRepository _repository = TransactionRepository();

  TransactionAnalysisService(super.config);

  /// Analyze messages and extract transactions using LLM with incremental support
  Future<AIResult<List<Transaction>>> analyzeMessagesForTransactions({
    required List<SmsMessage> messages,
    required Function(int processed, int total) onProgress,
    bool incremental = true,
  }) async {
    if (isCancelled) {
      return AIResult.cancelled();
    }

    try {
      // Filter out already processed messages if incremental
      List<SmsMessage> messagesToProcess = messages;
      if (incremental) {
        messagesToProcess = await _filterUnprocessedMessages(messages);
      }

      // Filter messages that might contain transaction information
      final potentialTransactionMessages = _filterTransactionMessages(
        messagesToProcess,
      );

      if (potentialTransactionMessages.isEmpty) {
        // Still return existing transactions from database
        final existingTransactions = await _repository.getAllTransactions();
        return AIResult.success(existingTransactions);
      }

      onProgress(0, potentialTransactionMessages.length);

      // Process messages in batches to avoid overwhelming the LLM
      const batchSize = 10;
      final List<Transaction> newTransactions = [];

      for (int i = 0; i < potentialTransactionMessages.length; i += batchSize) {
        if (isCancelled) {
          return AIResult.cancelled();
        }

        final batch =
            potentialTransactionMessages.skip(i).take(batchSize).toList();

        final batchResult = await _processBatch(batch);
        if (batchResult.success && batchResult.data != null) {
          newTransactions.addAll(batchResult.data!);
        }

        onProgress(i + batch.length, potentialTransactionMessages.length);
      }

      // Save new transactions to database
      if (newTransactions.isNotEmpty) {
        await _repository.insertTransactions(
          newTransactions.cast<Transaction>(),
        );
      }

      // Update analysis metadata
      final lastMessageDate =
          potentialTransactionMessages.isNotEmpty
              ? potentialTransactionMessages
                  .map((m) => m.date)
                  .reduce((a, b) => a.isAfter(b) ? a : b)
              : null;

      await _repository.updateAnalysisMetadata(
        lastAnalyzedMessageDate: lastMessageDate,
        totalMessagesAnalyzed: potentialTransactionMessages.length,
        totalTransactionsFound: newTransactions.length,
      );

      // Return all transactions (existing + new)
      final allTransactions = await _repository.getAllTransactions();
      return AIResult.success(allTransactions);
    } catch (e) {
      return AIResult.error('Failed to analyze messages: $e');
    }
  }

  /// Filter out messages that have already been processed
  Future<List<SmsMessage>> _filterUnprocessedMessages(
    List<SmsMessage> messages,
  ) async {
    final List<SmsMessage> unprocessedMessages = [];

    for (final message in messages) {
      final isProcessed = await _repository.isMessageProcessed(message.body);
      if (!isProcessed) {
        unprocessedMessages.add(message);
      }
    }

    return unprocessedMessages;
  }

  /// Get all stored transactions
  Future<List<Transaction>> getAllTransactions() async {
    final transactions = await _repository.getAllTransactions();
    return transactions.cast<Transaction>();
  }

  /// Get transactions within date range
  Future<List<Transaction>> getTransactionsByDateRange(
    DateTime startDate,
    DateTime endDate,
  ) async {
    final transactions = await _repository.getTransactionsByDateRange(
      startDate,
      endDate,
    );
    return transactions.cast<Transaction>();
  }

  /// Search transactions
  Future<List<Transaction>> searchTransactions(String query) async {
    final transactions = await _repository.searchTransactions(query);
    return transactions.cast<Transaction>();
  }

  /// Get analysis metadata
  Future<Map<String, dynamic>?> getAnalysisMetadata() async {
    return await _repository.getAnalysisMetadata();
  }

  /// Clear all transaction data
  Future<void> clearAllData() async {
    await _repository.deleteAllTransactions();
  }

  /// Filter messages that likely contain transaction information
  List<SmsMessage> _filterTransactionMessages(List<SmsMessage> messages) {
    final transactionKeywords = [
      'debited',
      'credited',
      'paid',
      'received',
      'transferred',
      'sent',
      'upi',
      'imps',
      'neft',
      'rtgs',
      'paytm',
      'phonepe',
      'googlepay',
      'amazon pay',
      'bhim',
      'mobikwik',
      'freecharge',
      'airtel money',
      'jio money',
      'ola money',
      'rupay',
      'visa',
      'mastercard',
      'transaction',
      'payment',
      'refund',
      'cashback',
      'reward',
      'balance',
      'account',
      'bank',
      'atm',
      'pos',
      'online',
      'rs.',
      'rs ',
      'inr',
      '₹',
      'amount',
      'total',
      'bill',
      'purchase',
      'order',
      'booking',
      'subscription',
      'recharge',
    ];

    return messages.where((message) {
      final body = message.body.toLowerCase();
      return transactionKeywords.any((keyword) => body.contains(keyword)) &&
          _containsAmount(body);
    }).toList();
  }

  /// Check if message contains amount information
  bool _containsAmount(String text) {
    // Look for patterns like: Rs. 100, ₹100, INR 100, 100.00, etc.
    final amountPatterns = [
      RegExp(r'rs\.?\s*\d+', caseSensitive: false),
      RegExp(r'₹\s*\d+'),
      RegExp(r'inr\s*\d+', caseSensitive: false),
      RegExp(r'\d+\.\d{2}'),
      RegExp(r'\d{1,3}(?:,\d{3})*(?:\.\d{2})?'),
    ];

    return amountPatterns.any((pattern) => pattern.hasMatch(text));
  }

  /// Process a batch of messages using LLM
  Future<AIResult<List<Transaction>>> _processBatch(
    List<SmsMessage> messages,
  ) async {
    try {
      final prompt = _buildTransactionAnalysisPrompt(messages);

      final requestData = prepareCategorizationRequest(
        prompt: prompt,
        screenshotMetadata: [], // Not needed for message analysis
      );

      if (requestData == null) {
        return AIResult.error('Failed to prepare request');
      }

      final response = await makeAPIRequest(requestData);

      if (response['error'] != null) {
        return AIResult.error(response['error'] as String);
      }

      final responseText = response['data'] as String?;
      if (responseText == null) {
        return AIResult.error('No response from AI');
      }

      final transactions = _parseTransactionResponse(responseText, messages);
      return AIResult.success(transactions);
    } catch (e) {
      return AIResult.error('Failed to process batch: $e');
    }
  }

  /// Build prompt for transaction analysis
  String _buildTransactionAnalysisPrompt(List<SmsMessage> messages) {
    final messagesText = messages
        .map(
          (msg) =>
              'Message from ${msg.address} on ${msg.date.toIso8601String()}:\n${msg.body}',
        )
        .join('\n\n');

    return '''
Analyze the following SMS messages and extract transaction information. For each transaction found, provide the details in JSON format.

Instructions:
1. Identify messages that contain financial transactions (payments, transfers, purchases, etc.)
2. Extract the following information for each transaction:
   - fromAccount: The source account/entity (bank/service that sent the message)
   - toAccount: The destination account/entity (recipient/merchant name)
   - transactionType: Either "DEBIT" or "CREDIT"
   - amount: The transaction amount (as a number)
   - category: Transaction category (food, transport, shopping, utilities, etc.)
   - transactionDate: The transaction date (ISO format)
   - paymentMode: Payment method (UPI, CARD, NETBANKING, CASH, etc.)
   - description: Brief description of the transaction
   - currency: Currency code (default INR)

3. Return ONLY a JSON array of transactions, no other text.
4. If no transactions are found, return an empty array [].

Example output format:
[
  {
    "fromAccount": "HDFC Bank",
    "toAccount": "Amazon",
    "transactionType": "DEBIT",
    "amount": 1299.00,
    "category": "shopping",
    "transactionDate": "2024-01-15T10:30:00.000Z",
    "paymentMode": "UPI",
    "description": "Online purchase",
    "currency": "INR"
  }
]

Messages to analyze:
$messagesText
''';
  }

  /// Parse LLM response and create Transaction objects
  List<Transaction> _parseTransactionResponse(
    String responseText,
    List<SmsMessage> originalMessages,
  ) {
    try {
      // Clean the response text to extract JSON
      String cleanedResponse = responseText.trim();

      // Remove any markdown formatting
      if (cleanedResponse.startsWith('```json')) {
        cleanedResponse = cleanedResponse.substring(7);
      }
      if (cleanedResponse.endsWith('```')) {
        cleanedResponse = cleanedResponse.substring(
          0,
          cleanedResponse.length - 3,
        );
      }

      cleanedResponse = cleanedResponse.trim();

      final List<dynamic> transactionData = jsonDecode(cleanedResponse);
      final List<Transaction> transactions = [];

      for (
        int i = 0;
        i < transactionData.length && i < originalMessages.length;
        i++
      ) {
        try {
          final data = transactionData[i] as Map<String, dynamic>;
          final originalMessage = originalMessages[i];

          final transaction = Transaction(
            id: const Uuid().v4(),
            fromAccount:
                data['fromAccount'] as String? ?? originalMessage.address,
            toAccount: data['toAccount'] as String? ?? 'Unknown',
            transactionType: data['transactionType'] as String? ?? 'DEBIT',
            amount: (data['amount'] as num?)?.toDouble() ?? 0.0,
            category: data['category'] as String? ?? 'Other',
            transactionDate:
                data['transactionDate'] != null
                    ? DateTime.parse(data['transactionDate'] as String)
                    : originalMessage.date,
            paymentMode: data['paymentMode'] as String? ?? 'Unknown',
            originalMessage: originalMessage.body,
            description: data['description'] as String?,
            currency: data['currency'] as String? ?? 'INR',
          );

          // Only add valid transactions (with amount > 0)
          if (transaction.amount > 0) {
            transactions.add(transaction);
          }
        } catch (e) {
          // Log error parsing individual transaction
          continue;
        }
      }

      return transactions;
    } catch (e) {
      // Error parsing transaction response, using fallback
      return _fallbackTransactionExtraction(originalMessages);
    }
  }

  /// Fallback method to extract basic transaction info using regex
  List<Transaction> _fallbackTransactionExtraction(List<SmsMessage> messages) {
    final List<Transaction> transactions = [];

    for (final message in messages) {
      try {
        final amount = _extractAmount(message.body);
        if (amount > 0) {
          final transaction = Transaction(
            id: const Uuid().v4(),
            fromAccount: message.address,
            toAccount: _extractPayeeName(message.body),
            transactionType:
                _isDebitTransaction(message.body) ? 'DEBIT' : 'CREDIT',
            amount: amount,
            category: 'Other',
            transactionDate: message.date,
            paymentMode: _extractPaymentMode(message.body),
            originalMessage: message.body,
            description: _extractDescription(message.body),
            currency: 'INR',
          );
          transactions.add(transaction);
        }
      } catch (e) {
        // Error in fallback extraction for message
        continue;
      }
    }

    return transactions;
  }

  /// Extract amount from message text using regex
  double _extractAmount(String text) {
    final patterns = [
      RegExp(r'rs\.?\s*(\d+(?:,\d{3})*(?:\.\d{2})?)', caseSensitive: false),
      RegExp(r'₹\s*(\d+(?:,\d{3})*(?:\.\d{2})?)'),
      RegExp(r'inr\s*(\d+(?:,\d{3})*(?:\.\d{2})?)', caseSensitive: false),
      RegExp(
        r'amount\s*:?\s*(\d+(?:,\d{3})*(?:\.\d{2})?)',
        caseSensitive: false,
      ),
    ];

    for (final pattern in patterns) {
      final match = pattern.firstMatch(text);
      if (match != null) {
        final amountStr = match.group(1)?.replaceAll(',', '') ?? '0';
        return double.tryParse(amountStr) ?? 0.0;
      }
    }

    return 0.0;
  }

  /// Extract payee name from message text
  String _extractPayeeName(String text) {
    // Look for common patterns like "paid to", "sent to", "at", etc.
    final patterns = [
      RegExp(
        r'(?:paid to|sent to|transferred to)\s+([A-Za-z\s]+)',
        caseSensitive: false,
      ),
      RegExp(r'at\s+([A-Za-z\s]+)', caseSensitive: false),
      RegExp(r'to\s+([A-Z][A-Za-z\s]+)', caseSensitive: false),
    ];

    for (final pattern in patterns) {
      final match = pattern.firstMatch(text);
      if (match != null) {
        return match.group(1)?.trim() ?? 'Unknown';
      }
    }

    return 'Unknown';
  }

  /// Extract description from message text
  String _extractDescription(String text) {
    // Take first 50 characters as description
    return text.length > 50 ? '${text.substring(0, 50)}...' : text;
  }

  /// Determine if transaction is debit or credit
  bool _isDebitTransaction(String text) {
    final debitKeywords = [
      'debited',
      'paid',
      'sent',
      'transferred',
      'purchase',
      'spent',
    ];
    final creditKeywords = [
      'credited',
      'received',
      'refund',
      'cashback',
      'reward',
    ];

    final lowerText = text.toLowerCase();

    if (debitKeywords.any((keyword) => lowerText.contains(keyword))) {
      return true;
    }
    if (creditKeywords.any((keyword) => lowerText.contains(keyword))) {
      return false;
    }

    // Default to debit if unclear
    return true;
  }

  /// Extract payment mode from message text
  String _extractPaymentMode(String text) {
    final lowerText = text.toLowerCase();

    if (lowerText.contains('upi')) return 'UPI';
    if (lowerText.contains('card') ||
        lowerText.contains('debit') ||
        lowerText.contains('credit')) {
      return 'CARD';
    }
    if (lowerText.contains('netbanking') || lowerText.contains('net banking')) {
      return 'NETBANKING';
    }
    if (lowerText.contains('imps')) return 'IMPS';
    if (lowerText.contains('neft')) return 'NEFT';
    if (lowerText.contains('rtgs')) return 'RTGS';
    if (lowerText.contains('atm')) return 'ATM';
    if (lowerText.contains('pos')) return 'POS';
    if (lowerText.contains('cash')) return 'CASH';

    return 'Unknown';
  }

  /// Group transactions by account and calculate summaries
  List<TransactionSummary> groupTransactionsByAccount(
    List<Transaction> transactions,
  ) {
    final Map<String, List<Transaction>> grouped = {};

    for (final transaction in transactions) {
      final key = transaction.fromAccount;
      grouped.putIfAbsent(key, () => []).add(transaction);
    }

    return grouped.entries.map((entry) {
        final accountTransactions = entry.value;
        accountTransactions.sort(
          (a, b) => a.transactionDate.compareTo(b.transactionDate),
        );

        final totalAmount = accountTransactions
            .where((t) => t.isDebit)
            .fold(0.0, (sum, t) => sum + t.amount);

        return TransactionSummary(
          accountName: entry.key,
          totalAmount: totalAmount,
          transactionCount: accountTransactions.length,
          transactions: accountTransactions,
          firstTransaction: accountTransactions.first.transactionDate,
          lastTransaction: accountTransactions.last.transactionDate,
        );
      }).toList()
      ..sort((a, b) => b.totalAmount.compareTo(a.totalAmount));
  }
}
