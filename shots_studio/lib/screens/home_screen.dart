import 'package:flutter/material.dart';
import 'package:shots_studio/models/transaction_model.dart';
import 'package:shots_studio/services/transaction_analysis_service.dart';
import 'package:shots_studio/services/ai_service.dart';
import 'package:shots_studio/services/snackbar_service.dart';
import 'package:shots_studio/screens/app_drawer_screen.dart';
import 'package:shots_studio/screens/transaction_analysis_screen.dart';

import 'package:intl/intl.dart';

class HomeScreen extends StatefulWidget {
  final String? apiKey;
  final String modelName;
  final int maxParallel;
  final bool devMode;
  final bool autoProcessEnabled;
  final bool analyticsEnabled;
  final bool betaTestingEnabled;
  final bool amoledModeEnabled;
  final String selectedTheme;
  final Function(String) onApiKeyChanged;
  final Function(String) onModelChanged;
  final Function(int) onMaxParallelChanged;
  final Function(bool) onDevModeChanged;
  final Function(bool) onAutoProcessEnabledChanged;
  final Function(bool) onAnalyticsEnabledChanged;
  final Function(bool) onBetaTestingEnabledChanged;
  final Function(bool)? onAmoledModeChanged;
  final Function(String)? onThemeChanged;
  final Function(Locale)? onLocaleChanged;

  const HomeScreen({
    super.key,
    required this.apiKey,
    required this.modelName,
    required this.maxParallel,
    required this.devMode,
    required this.autoProcessEnabled,
    required this.analyticsEnabled,
    required this.betaTestingEnabled,
    required this.amoledModeEnabled,
    required this.selectedTheme,
    required this.onApiKeyChanged,
    required this.onModelChanged,
    required this.onMaxParallelChanged,
    required this.onDevModeChanged,
    required this.onAutoProcessEnabledChanged,
    required this.onAnalyticsEnabledChanged,
    required this.onBetaTestingEnabledChanged,
    this.onAmoledModeChanged,
    this.onThemeChanged,
    this.onLocaleChanged,
  });

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  TransactionAnalysisService? _analysisService;
  List<Transaction> _transactions = [];
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _initializeAnalysisService();
    _loadTransactions();
  }

  Future<void> _initializeAnalysisService() async {
    final config = AIConfig(
      apiKey: widget.apiKey ?? '',
      modelName: widget.modelName,
      maxParallel: widget.maxParallel,
      timeoutSeconds: 120,
      showMessage: ({
        required String message,
        Color? backgroundColor,
        Duration? duration,
      }) {
        if (mounted) {
          SnackbarService().showInfo(context, message);
        }
      },
    );

    _analysisService = TransactionAnalysisService(config);
  }

  Future<void> _loadTransactions() async {
    if (_analysisService == null) return;

    setState(() {
      _isLoading = true;
    });

    try {
      final transactions = await _analysisService!.getAllTransactions();
      setState(() {
        _transactions = transactions;
      });
    } catch (e) {
      // Handle error silently, will show empty state
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> _analyzeMessages() async {
    // Navigate to transaction analysis screen for detailed analysis
    Navigator.of(context)
        .push(
          MaterialPageRoute(
            builder: (context) => const TransactionAnalysisScreen(),
          ),
        )
        .then((_) {
          // Reload transactions when coming back
          _loadTransactions();
        });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Transaction Analyzer'),
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _analyzeMessages,
            tooltip: 'Analyze Messages',
          ),
        ],
      ),
      drawer: AppDrawer(
        currentApiKey: widget.apiKey,
        currentModelName: widget.modelName,
        onApiKeyChanged: widget.onApiKeyChanged,
        onModelChanged: widget.onModelChanged,
        currentLimit: 100,
        onLimitChanged: (int limit) {},
        currentMaxParallel: widget.maxParallel,
        onMaxParallelChanged: widget.onMaxParallelChanged,
        currentDevMode: widget.devMode,
        onDevModeChanged: widget.onDevModeChanged,
        currentAutoProcessEnabled: widget.autoProcessEnabled,
        onAutoProcessEnabledChanged: widget.onAutoProcessEnabledChanged,
        currentAnalyticsEnabled: widget.analyticsEnabled,
        onAnalyticsEnabledChanged: widget.onAnalyticsEnabledChanged,
        currentBetaTestingEnabled: widget.betaTestingEnabled,
        onBetaTestingEnabledChanged: widget.onBetaTestingEnabledChanged,
        currentAmoledModeEnabled: widget.amoledModeEnabled,
        onAmoledModeChanged: widget.onAmoledModeChanged,
        currentSelectedTheme: widget.selectedTheme,
        onThemeChanged: widget.onThemeChanged,
        onLocaleChanged: widget.onLocaleChanged,
        allScreenshots: [],
        onClearCorruptFiles: () {},
        onResetAiProcessing: () {},
      ),
      body: _buildBody(),
    );
  }

  Widget _buildBody() {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_transactions.isEmpty) {
      return _buildEmptyState();
    }

    return _buildTransactionsList();
  }

  Widget _buildEmptyState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.receipt_long,
              size: 80,
              color: Theme.of(context).colorScheme.primary.withOpacity(0.5),
            ),
            const SizedBox(height: 24),
            Text(
              'No Transactions Found',
              style: Theme.of(
                context,
              ).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.bold),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 12),
            Text(
              'Start analyzing your SMS messages to find transaction information.',
              style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                color: Theme.of(context).colorScheme.onSurfaceVariant,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 32),
            ElevatedButton.icon(
              onPressed: _analyzeMessages,
              icon: const Icon(Icons.analytics),
              label: const Text('Analyze SMS Messages'),
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.symmetric(
                  horizontal: 24,
                  vertical: 12,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTransactionsList() {
    // Group transactions by date
    final groupedTransactions = <String, List<Transaction>>{};
    for (final transaction in _transactions) {
      final dateKey = DateFormat(
        'MMM dd, yyyy',
      ).format(transaction.transactionDate);
      groupedTransactions.putIfAbsent(dateKey, () => []).add(transaction);
    }

    // Sort groups by date (newest first)
    final sortedKeys =
        groupedTransactions.keys.toList()..sort((a, b) {
          final dateA = DateFormat('MMM dd, yyyy').parse(a);
          final dateB = DateFormat('MMM dd, yyyy').parse(b);
          return dateB.compareTo(dateA);
        });

    return Column(
      children: [
        // Summary card
        _buildSummaryCard(),
        // Transactions list
        Expanded(
          child: ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: sortedKeys.length,
            itemBuilder: (context, index) {
              final dateKey = sortedKeys[index];
              final dayTransactions = groupedTransactions[dateKey]!;

              // Sort transactions within the day by time (newest first)
              dayTransactions.sort(
                (a, b) => b.transactionDate.compareTo(a.transactionDate),
              );

              return Card(
                margin: const EdgeInsets.only(bottom: 16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Padding(
                      padding: const EdgeInsets.all(16),
                      child: Text(
                        dateKey,
                        style: Theme.of(context).textTheme.titleMedium
                            ?.copyWith(fontWeight: FontWeight.bold),
                      ),
                    ),
                    ...dayTransactions.map(
                      (transaction) => _buildTransactionTile(transaction),
                    ),
                  ],
                ),
              );
            },
          ),
        ),
      ],
    );
  }

  Widget _buildSummaryCard() {
    final totalDebit = _transactions
        .where((t) => t.transactionType == 'DEBIT')
        .fold(0.0, (sum, t) => sum + t.amount);
    final totalCredit = _transactions
        .where((t) => t.transactionType == 'CREDIT')
        .fold(0.0, (sum, t) => sum + t.amount);

    return Container(
      margin: const EdgeInsets.all(16),
      child: Card(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              Expanded(
                child: _buildSummaryItem(
                  'Total Transactions',
                  _transactions.length.toString(),
                  Icons.receipt,
                  Theme.of(context).colorScheme.primary,
                ),
              ),
              Expanded(
                child: _buildSummaryItem(
                  'Total Debit',
                  '₹${totalDebit.toStringAsFixed(0)}',
                  Icons.arrow_upward,
                  Colors.red,
                ),
              ),
              Expanded(
                child: _buildSummaryItem(
                  'Total Credit',
                  '₹${totalCredit.toStringAsFixed(0)}',
                  Icons.arrow_downward,
                  Colors.green,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSummaryItem(
    String label,
    String value,
    IconData icon,
    Color color,
  ) {
    return Column(
      children: [
        Icon(icon, color: color, size: 24),
        const SizedBox(height: 8),
        Text(
          value,
          style: Theme.of(context).textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.bold,
            color: color,
          ),
        ),
        Text(
          label,
          style: Theme.of(context).textTheme.bodySmall,
          textAlign: TextAlign.center,
        ),
      ],
    );
  }

  Widget _buildTransactionTile(Transaction transaction) {
    final isDebit = transaction.transactionType == 'DEBIT';
    final color = isDebit ? Colors.red : Colors.green;
    final icon = isDebit ? Icons.arrow_upward : Icons.arrow_downward;

    return ListTile(
      leading: CircleAvatar(
        backgroundColor: color.withOpacity(0.1),
        child: Icon(icon, color: color, size: 20),
      ),
      title: Text(
        transaction.toAccount,
        style: const TextStyle(fontWeight: FontWeight.w500),
      ),
      subtitle: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(transaction.category),
          Text(
            DateFormat('HH:mm').format(transaction.transactionDate),
            style: Theme.of(context).textTheme.bodySmall,
          ),
        ],
      ),
      trailing: Text(
        '${isDebit ? '-' : '+'}₹${transaction.amount.toStringAsFixed(2)}',
        style: TextStyle(
          fontWeight: FontWeight.bold,
          color: color,
          fontSize: 16,
        ),
      ),
      onTap: () => _showTransactionDetails(transaction),
    );
  }

  void _showTransactionDetails(Transaction transaction) {
    showDialog(
      context: context,
      builder:
          (context) => AlertDialog(
            title: Text(transaction.toAccount),
            content: SingleChildScrollView(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  _buildDetailRow(
                    'Amount',
                    '₹${transaction.amount.toStringAsFixed(2)}',
                  ),
                  _buildDetailRow(
                    'Date',
                    DateFormat(
                      'MMM dd, yyyy • HH:mm',
                    ).format(transaction.transactionDate),
                  ),
                  _buildDetailRow('Type', transaction.transactionType),
                  _buildDetailRow('From Account', transaction.fromAccount),
                  _buildDetailRow('Category', transaction.category),
                  if (transaction.description != null)
                    _buildDetailRow('Description', transaction.description!),
                  const SizedBox(height: 16),
                  const Text(
                    'Original Message:',
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 8),
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color:
                          Theme.of(context).colorScheme.surfaceContainerHighest,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      transaction.originalMessage,
                      style: Theme.of(context).textTheme.bodySmall,
                    ),
                  ),
                ],
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(context).pop(),
                child: const Text('Close'),
              ),
            ],
          ),
    );
  }

  Widget _buildDetailRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 80,
            child: Text(
              '$label:',
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
          ),
          Expanded(child: Text(value)),
        ],
      ),
    );
  }
}
