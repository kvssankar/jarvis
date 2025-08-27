import 'package:shots_studio/repositories/transaction_repository.dart';
import 'package:shots_studio/models/transaction_model.dart';

/// Simple test utility to verify database functionality
class DatabaseTest {
  static Future<void> testDatabase() async {
    final repository = TransactionRepository();

    try {
      // Test creating a sample transaction
      final testTransaction = Transaction(
        id: 'test-123',
        fromAccount: 'Test Bank',
        toAccount: 'Test Merchant',
        transactionType: 'DEBIT',
        amount: 100.0,
        category: 'shopping',
        transactionDate: DateTime.now(),
        paymentMode: 'UPI',
        originalMessage: 'Test message for database verification',
        description: 'Test transaction',
        currency: 'INR',
      );

      // Insert transaction
      final insertResult = await repository.insertTransaction(testTransaction);
      assert(insertResult > 0, 'Transaction should be inserted');

      // Get all transactions
      final transactions = await repository.getAllTransactions();
      assert(transactions.isNotEmpty, 'Should have at least one transaction');

      // Test search
      final searchResults = await repository.searchTransactions('test');
      assert(searchResults.isNotEmpty, 'Should find test transaction');

      // Test metadata
      await repository.updateAnalysisMetadata(
        totalMessagesAnalyzed: 1,
        totalTransactionsFound: 1,
      );

      final metadata = await repository.getAnalysisMetadata();
      assert(metadata != null, 'Metadata should exist');

      // Test completed successfully - all assertions passed
    } catch (e) {
      throw Exception('Database test failed: $e');
    }
  }
}
