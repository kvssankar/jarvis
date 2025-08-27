import 'package:sqflite/sqflite.dart' hide Transaction;
import 'package:shots_studio/database/database_helper.dart';
import 'package:shots_studio/models/transaction_model.dart' as model;
import 'package:crypto/crypto.dart';
import 'dart:convert';

class TransactionRepository {
  final DatabaseHelper _databaseHelper = DatabaseHelper();

  /// Insert a new transaction
  Future<int> insertTransaction(model.Transaction transaction) async {
    final db = await _databaseHelper.database;
    final now = DateTime.now().millisecondsSinceEpoch;

    final transactionMap = transaction.toJson();
    transactionMap['message_hash'] = _generateMessageHash(
      transaction.originalMessage,
    );
    transactionMap['created_at'] = now;
    transactionMap['updated_at'] = now;
    transactionMap['transaction_date'] =
        transaction.transactionDate.millisecondsSinceEpoch;

    return await db.insert(
      'transactions',
      transactionMap,
      conflictAlgorithm:
          ConflictAlgorithm.ignore, // Ignore duplicates based on message_hash
    );
  }

  /// Insert multiple transactions
  Future<List<int>> insertTransactions(
    List<model.Transaction> transactions,
  ) async {
    final db = await _databaseHelper.database;
    final batch = db.batch();
    final now = DateTime.now().millisecondsSinceEpoch;

    for (final transaction in transactions) {
      final transactionMap = transaction.toJson();
      transactionMap['message_hash'] = _generateMessageHash(
        transaction.originalMessage,
      );
      transactionMap['created_at'] = now;
      transactionMap['updated_at'] = now;
      transactionMap['transaction_date'] =
          transaction.transactionDate.millisecondsSinceEpoch;

      batch.insert(
        'transactions',
        transactionMap,
        conflictAlgorithm: ConflictAlgorithm.ignore,
      );
    }

    final batchResults = await batch.commit();
    return batchResults.cast<int>();
  }

  /// Get all transactions
  Future<List<model.Transaction>> getAllTransactions() async {
    final db = await _databaseHelper.database;
    final List<Map<String, dynamic>> maps = await db.query(
      'transactions',
      orderBy: 'transaction_date DESC',
    );

    return maps.map((map) => _transactionFromMap(map)).toList();
  }

  /// Get transactions within date range
  Future<List<model.Transaction>> getTransactionsByDateRange(
    DateTime startDate,
    DateTime endDate,
  ) async {
    final db = await _databaseHelper.database;
    final List<Map<String, dynamic>> maps = await db.query(
      'transactions',
      where: 'transaction_date >= ? AND transaction_date <= ?',
      whereArgs: [
        startDate.millisecondsSinceEpoch,
        endDate.millisecondsSinceEpoch,
      ],
      orderBy: 'transaction_date DESC',
    );

    return maps.map((map) => _transactionFromMap(map)).toList();
  }

  /// Get transactions by type (DEBIT/CREDIT)
  Future<List<model.Transaction>> getTransactionsByType(String type) async {
    final db = await _databaseHelper.database;
    final List<Map<String, dynamic>> maps = await db.query(
      'transactions',
      where: 'transaction_type = ?',
      whereArgs: [type],
      orderBy: 'transaction_date DESC',
    );

    return maps.map((map) => _transactionFromMap(map)).toList();
  }

  /// Get transactions by category
  Future<List<model.Transaction>> getTransactionsByCategory(
    String category,
  ) async {
    final db = await _databaseHelper.database;
    final List<Map<String, dynamic>> maps = await db.query(
      'transactions',
      where: 'category = ?',
      whereArgs: [category],
      orderBy: 'transaction_date DESC',
    );

    return maps.map((map) => _transactionFromMap(map)).toList();
  }

  /// Search transactions
  Future<List<model.Transaction>> searchTransactions(String query) async {
    final db = await _databaseHelper.database;
    final searchQuery = '%${query.toLowerCase()}%';

    final List<Map<String, dynamic>> maps = await db.query(
      'transactions',
      where: '''
        LOWER(payee_name) LIKE ? OR 
        LOWER(requestor_name) LIKE ? OR 
        LOWER(category) LIKE ? OR 
        LOWER(description) LIKE ?
      ''',
      whereArgs: [searchQuery, searchQuery, searchQuery, searchQuery],
      orderBy: 'transaction_date DESC',
    );

    return maps.map((map) => _transactionFromMap(map)).toList();
  }

  /// Delete transaction by ID
  Future<int> deleteTransaction(int id) async {
    final db = await _databaseHelper.database;
    return await db.delete('transactions', where: 'id = ?', whereArgs: [id]);
  }

  /// Delete all transactions
  Future<int> deleteAllTransactions() async {
    final db = await _databaseHelper.database;
    return await db.delete('transactions');
  }

  /// Get transaction count
  Future<int> getTransactionCount() async {
    final db = await _databaseHelper.database;
    final result = await db.rawQuery(
      'SELECT COUNT(*) as count FROM transactions',
    );
    return Sqflite.firstIntValue(result) ?? 0;
  }

  /// Check if message has already been processed
  Future<bool> isMessageProcessed(String originalMessage) async {
    final db = await _databaseHelper.database;
    final messageHash = _generateMessageHash(originalMessage);

    final result = await db.query(
      'transactions',
      where: 'message_hash = ?',
      whereArgs: [messageHash],
      limit: 1,
    );

    return result.isNotEmpty;
  }

  /// Get analysis metadata
  Future<Map<String, dynamic>?> getAnalysisMetadata() async {
    final db = await _databaseHelper.database;
    final result = await db.query(
      'analysis_metadata',
      orderBy: 'id DESC',
      limit: 1,
    );

    return result.isNotEmpty ? result.first : null;
  }

  /// Update analysis metadata
  Future<void> updateAnalysisMetadata({
    DateTime? lastAnalyzedMessageDate,
    required int totalMessagesAnalyzed,
    required int totalTransactionsFound,
  }) async {
    final db = await _databaseHelper.database;
    final now = DateTime.now().millisecondsSinceEpoch;

    final metadata = {
      'last_analyzed_message_date':
          lastAnalyzedMessageDate?.millisecondsSinceEpoch,
      'last_analysis_date': now,
      'total_messages_analyzed': totalMessagesAnalyzed,
      'total_transactions_found': totalTransactionsFound,
    };

    // Delete existing metadata and insert new one
    await db.delete('analysis_metadata');
    await db.insert('analysis_metadata', metadata);
  }

  /// Generate hash for message to detect duplicates
  String _generateMessageHash(String message) {
    final bytes = utf8.encode(message.trim());
    final digest = sha256.convert(bytes);
    return digest.toString();
  }

  /// Convert database map to Transaction object
  model.Transaction _transactionFromMap(Map<String, dynamic> map) {
    return model.Transaction(
      id: map['id']?.toString() ?? '',
      fromAccount: map['requestor_name'] as String,
      toAccount: map['payee_name'] as String,
      amount: (map['amount'] as num).toDouble(),
      transactionDate: DateTime.fromMillisecondsSinceEpoch(
        map['transaction_date'] as int,
      ),
      description: map['description'] as String?,
      category: map['category'] as String,
      transactionType: map['transaction_type'] as String,
      currency: map['currency'] as String? ?? 'INR',
      paymentMode: map['payment_mode'] as String,
      originalMessage: map['original_message'] as String,
    );
  }
}
