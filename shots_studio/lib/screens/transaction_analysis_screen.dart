import 'package:flutter/material.dart';
import 'package:shots_studio/models/transaction_model.dart';
import 'package:shots_studio/services/message_service.dart';
import 'package:shots_studio/services/transaction_analysis_service.dart';
import 'package:shots_studio/services/ai_service.dart';
import 'package:shots_studio/services/snackbar_service.dart';
import 'package:shots_studio/l10n/app_localizations.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:intl/intl.dart';

class TransactionAnalysisScreen extends StatefulWidget {
  const TransactionAnalysisScreen({super.key});

  @override
  State<TransactionAnalysisScreen> createState() =>
      _TransactionAnalysisScreenState();
}

class _TransactionAnalysisScreenState extends State<TransactionAnalysisScreen> {
  final MessageService _messageService = MessageService();
  TransactionAnalysisService? _analysisService;

  // Data
  List<Transaction> _allTransactions = [];
  List<Transaction> _filteredTransactions = [];
  bool _isLoading = false;
  bool _hasPermission = false;
  int _processedCount = 0;
  int _totalCount = 0;
  String _currentStatus = '';

  // Filtering and search
  final TextEditingController _searchController = TextEditingController();
  DateTime? _startDate;
  DateTime? _endDate;
  String _groupBy = 'none'; // none, source, destination, category
  String _searchQuery = '';

  // Table sorting
  int _sortColumnIndex = 6; // Default sort by date
  bool _sortAscending = false;

  @override
  void initState() {
    super.initState();
    _checkPermissions();
    _initializeAnalysisService();
    _searchController.addListener(_onSearchChanged);
    _loadExistingTransactions();
  }

  @override
  void dispose() {
    _searchController.removeListener(_onSearchChanged);
    _searchController.dispose();
    super.dispose();
  }

  void _onSearchChanged() {
    setState(() {
      _searchQuery = _searchController.text.toLowerCase();
      _applyFilters();
    });
  }

  Future<void> _initializeAnalysisService() async {
    final prefs = await SharedPreferences.getInstance();
    final apiKey = prefs.getString('apiKey') ?? '';
    final modelName = prefs.getString('modelName') ?? 'gemini-2.0-flash';
    final maxParallel = prefs.getInt('maxParallel') ?? 4;

    final config = AIConfig(
      apiKey: apiKey,
      modelName: modelName,
      maxParallel: maxParallel,
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

  Future<void> _loadExistingTransactions() async {
    if (_analysisService == null) return;

    try {
      final transactions = await _analysisService!.getAllTransactions();
      if (transactions.isNotEmpty) {
        setState(() {
          _allTransactions = transactions;
          _filteredTransactions = List.from(transactions);
          _applyFilters();
        });
      }
    } catch (e) {
      // Error loading existing transactions, will show empty state
    }
  }

  Future<void> _checkPermissions() async {
    final hasPermission = await _messageService.hasSmsPermission();
    setState(() {
      _hasPermission = hasPermission;
    });
  }

  Future<void> _requestPermissions() async {
    final granted = await _messageService.requestSmsPermission();
    setState(() {
      _hasPermission = granted;
    });

    if (!granted && mounted) {
      SnackbarService().showError(
        context,
        'SMS permission is required to analyze transaction messages',
      );
    }
  }

  Future<void> _analyzeTransactions() async {
    if (!_hasPermission) {
      await _requestPermissions();
      return;
    }

    if (_analysisService == null) {
      SnackbarService().showError(context, 'Analysis service not initialized');
      return;
    }

    setState(() {
      _isLoading = true;
      _processedCount = 0;
      _totalCount = 0;
      _currentStatus = 'Reading messages...';
    });

    try {
      // Get analysis metadata to determine incremental analysis
      final metadata = await _analysisService!.getAnalysisMetadata();
      final lastAnalyzedDate =
          metadata?['last_analyzed_message_date'] != null
              ? DateTime.fromMillisecondsSinceEpoch(
                metadata!['last_analyzed_message_date'] as int,
              )
              : null;

      // Read messages (incremental if we have previous analysis)
      final List<SmsMessage> messages;
      if (lastAnalyzedDate != null) {
        messages = await _messageService.readMessagesSince(lastAnalyzedDate);
        setState(() {
          _currentStatus =
              'Found ${messages.length} new messages since last analysis...';
        });
      } else {
        messages = await _messageService.readRecentMessages(days: 90);
        setState(() {
          _currentStatus = 'Analyzing ${messages.length} messages...';
        });
      }

      // Analyze messages for transactions (with incremental support)
      final result = await _analysisService!.analyzeMessagesForTransactions(
        messages: messages,
        incremental: true,
        onProgress: (processed, total) {
          setState(() {
            _processedCount = processed;
            _totalCount = total;
            _currentStatus =
                total > 0
                    ? 'Processing batch $processed of $total...'
                    : 'Loading existing transactions...';
          });
        },
      );

      if (result.success && result.data != null) {
        final transactions = result.data!;

        setState(() {
          _allTransactions = transactions;
          _filteredTransactions = List.from(transactions);
          _currentStatus = 'Analysis complete';
          _applyFilters();
        });

        if (mounted) {
          final newTransactionsCount =
              messages.isNotEmpty
                  ? transactions.length - _allTransactions.length
                  : 0;
          final message =
              newTransactionsCount > 0
                  ? 'Found $newTransactionsCount new transactions (${transactions.length} total)'
                  : 'Analysis complete - ${transactions.length} transactions total';

          SnackbarService().showSuccess(context, message);
        }
      } else {
        if (mounted) {
          SnackbarService().showError(
            context,
            result.error ?? 'Failed to analyze transactions',
          );
        }
      }
    } catch (e) {
      if (mounted) {
        SnackbarService().showError(
          context,
          'Error analyzing transactions: $e',
        );
      }
    } finally {
      setState(() {
        _isLoading = false;
        _processedCount = 0;
        _totalCount = 0;
        _currentStatus = '';
      });
    }
  }

  void _applyFilters() {
    List<Transaction> filtered = List.from(_allTransactions);

    // Apply search filter
    if (_searchQuery.isNotEmpty) {
      filtered =
          filtered.where((transaction) {
            return transaction.toAccount.toLowerCase().contains(_searchQuery) ||
                transaction.fromAccount.toLowerCase().contains(_searchQuery) ||
                transaction.category.toLowerCase().contains(_searchQuery);
          }).toList();
    }

    // Apply date range filter
    if (_startDate != null) {
      filtered =
          filtered.where((transaction) {
            return transaction.transactionDate.isAfter(_startDate!) ||
                transaction.transactionDate.isAtSameMomentAs(_startDate!);
          }).toList();
    }

    if (_endDate != null) {
      filtered =
          filtered.where((transaction) {
            return transaction.transactionDate.isBefore(
              _endDate!.add(const Duration(days: 1)),
            );
          }).toList();
    }

    // Apply sorting
    filtered.sort((a, b) {
      int result = 0;
      switch (_sortColumnIndex) {
        case 0: // Source
          result = a.fromAccount.compareTo(b.fromAccount);
          break;
        case 1: // Destination
          result = a.toAccount.compareTo(b.toAccount);
          break;
        case 2: // Type
          result = a.transactionType.compareTo(b.transactionType);
          break;
        case 3: // Amount
          result = a.amount.compareTo(b.amount);
          break;
        case 4: // Category
          result = a.category.compareTo(b.category);
          break;
        case 5: // Payment Mode
          result = a.paymentMode.compareTo(b.paymentMode);
          break;
        case 6: // Date
          result = a.transactionDate.compareTo(b.transactionDate);
          break;
      }
      return _sortAscending ? result : -result;
    });

    setState(() {
      _filteredTransactions = filtered;
    });
  }

  void _selectDateRange() async {
    final DateTimeRange? picked = await showDateRangePicker(
      context: context,
      firstDate: DateTime(2020),
      lastDate: DateTime.now(),
      initialDateRange:
          _startDate != null && _endDate != null
              ? DateTimeRange(start: _startDate!, end: _endDate!)
              : null,
    );

    if (picked != null) {
      setState(() {
        _startDate = picked.start;
        _endDate = picked.end;
        _applyFilters();
      });
    }
  }

  void _clearDateRange() {
    setState(() {
      _startDate = null;
      _endDate = null;
      _applyFilters();
    });
  }

  Map<String, List<Transaction>> _groupTransactions() {
    if (_groupBy == 'none') {
      return {'All Transactions': _filteredTransactions};
    }

    Map<String, List<Transaction>> grouped = {};
    for (var transaction in _filteredTransactions) {
      String key;
      switch (_groupBy) {
        case 'source':
          key = transaction.fromAccount;
          break;
        case 'destination':
          key = transaction.toAccount;
          break;
        case 'category':
          key = transaction.category;
          break;
        default:
          key = 'All';
      }
      grouped.putIfAbsent(key, () => []).add(transaction);
    }
    return grouped;
  }

  @override
  Widget build(BuildContext context) {
    final localizations = AppLocalizations.of(context)!;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Transaction Analysis'),
        actions: [
          if (_hasPermission && !_isLoading) ...[
            IconButton(
              icon: const Icon(Icons.refresh),
              onPressed: _analyzeTransactions,
              tooltip: 'Analyze New Messages',
            ),
            PopupMenuButton<String>(
              onSelected: (value) {
                switch (value) {
                  case 'clear_all':
                    _showClearDataDialog();
                    break;
                  case 'full_analysis':
                    _performFullAnalysis();
                    break;
                }
              },
              itemBuilder:
                  (context) => [
                    const PopupMenuItem(
                      value: 'full_analysis',
                      child: ListTile(
                        leading: Icon(Icons.analytics),
                        title: Text('Full Re-analysis'),
                        subtitle: Text('Analyze all messages again'),
                      ),
                    ),
                    const PopupMenuItem(
                      value: 'clear_all',
                      child: ListTile(
                        leading: Icon(Icons.delete_forever),
                        title: Text('Clear All Data'),
                        subtitle: Text('Delete all transactions'),
                      ),
                    ),
                  ],
            ),
          ],
        ],
      ),
      body: _buildBody(localizations),
    );
  }

  Widget _buildBody(AppLocalizations localizations) {
    if (!_hasPermission) {
      return _buildPermissionRequest(localizations);
    }

    if (_isLoading) {
      return _buildLoadingView();
    }

    if (_allTransactions.isEmpty) {
      return _buildEmptyState(localizations);
    }

    return _buildTransactionTable();
  }

  Widget _buildPermissionRequest(AppLocalizations localizations) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.sms, size: 64, color: Colors.grey),
            const SizedBox(height: 16),
            Text(
              'SMS Permission Required',
              style: Theme.of(context).textTheme.headlineSmall,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            Text(
              'To analyze your transaction messages, we need permission to read SMS messages. This data is processed locally and never shared.',
              style: Theme.of(context).textTheme.bodyMedium,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),
            ElevatedButton.icon(
              onPressed: _requestPermissions,
              icon: const Icon(Icons.security),
              label: const Text('Grant Permission'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildLoadingView() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const CircularProgressIndicator(),
            const SizedBox(height: 16),
            Text(
              _currentStatus,
              style: Theme.of(context).textTheme.bodyLarge,
              textAlign: TextAlign.center,
            ),
            if (_totalCount > 0) ...[
              const SizedBox(height: 8),
              LinearProgressIndicator(value: _processedCount / _totalCount),
              const SizedBox(height: 8),
              Text(
                '$_processedCount / $_totalCount',
                style: Theme.of(context).textTheme.bodySmall,
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyState(AppLocalizations localizations) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.receipt_long, size: 64, color: Colors.grey),
            const SizedBox(height: 16),
            Text(
              'No Transactions Found',
              style: Theme.of(context).textTheme.headlineSmall,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            Text(
              'Start analyzing your SMS messages to find transaction information.',
              style: Theme.of(context).textTheme.bodyMedium,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),
            ElevatedButton.icon(
              onPressed: _analyzeTransactions,
              icon: const Icon(Icons.analytics),
              label: const Text('Analyze Messages'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTransactionTable() {
    final groupedTransactions = _groupTransactions();

    return Column(
      children: [
        // Filters and controls
        _buildFiltersSection(),
        // Summary stats
        _buildSummarySection(),
        // Table
        Expanded(
          child:
              _groupBy == 'none'
                  ? _buildDataTable(_filteredTransactions)
                  : _buildGroupedTable(groupedTransactions),
        ),
      ],
    );
  }

  Widget _buildFiltersSection() {
    return Container(
      padding: const EdgeInsets.all(16),
      color: Theme.of(context).colorScheme.surfaceContainerHighest,
      child: Column(
        children: [
          // Search and date range row
          Row(
            children: [
              // Search field
              Expanded(
                flex: 2,
                child: TextField(
                  controller: _searchController,
                  decoration: const InputDecoration(
                    hintText: 'Search source, destination, or category...',
                    prefixIcon: Icon(Icons.search),
                    border: OutlineInputBorder(),
                    isDense: true,
                  ),
                ),
              ),
              const SizedBox(width: 8),
              // Date range button
              ElevatedButton.icon(
                onPressed: _selectDateRange,
                icon: const Icon(Icons.date_range),
                label: Text(
                  _startDate != null && _endDate != null
                      ? '${DateFormat('MMM dd').format(_startDate!)} - ${DateFormat('MMM dd').format(_endDate!)}'
                      : 'Date Range',
                ),
              ),
              if (_startDate != null || _endDate != null) ...[
                const SizedBox(width: 8),
                IconButton(
                  onPressed: _clearDateRange,
                  icon: const Icon(Icons.clear),
                  tooltip: 'Clear date filter',
                ),
              ],
            ],
          ),
          const SizedBox(height: 12),
          // Group by dropdown
          Row(
            children: [
              const Text('Group by: '),
              const SizedBox(width: 8),
              DropdownButton<String>(
                value: _groupBy,
                onChanged: (String? newValue) {
                  setState(() {
                    _groupBy = newValue ?? 'none';
                  });
                },
                items: const [
                  DropdownMenuItem(value: 'none', child: Text('None')),
                  DropdownMenuItem(value: 'source', child: Text('Source')),
                  DropdownMenuItem(
                    value: 'destination',
                    child: Text('Destination'),
                  ),
                  DropdownMenuItem(value: 'category', child: Text('Category')),
                ],
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildSummarySection() {
    final totalAmount = _filteredTransactions
        .where((t) => t.transactionType == 'DEBIT')
        .fold(0.0, (sum, t) => sum + t.amount);
    final creditAmount = _filteredTransactions
        .where((t) => t.transactionType == 'CREDIT')
        .fold(0.0, (sum, t) => sum + t.amount);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          _buildSummaryItem(
            'Transactions',
            _filteredTransactions.length.toString(),
            Icons.receipt,
          ),
          _buildSummaryItem(
            'Total Debit',
            '₹${totalAmount.toStringAsFixed(2)}',
            Icons.arrow_upward,
            color: Colors.red,
          ),
          _buildSummaryItem(
            'Total Credit',
            '₹${creditAmount.toStringAsFixed(2)}',
            Icons.arrow_downward,
            color: Colors.green,
          ),
        ],
      ),
    );
  }

  Widget _buildSummaryItem(
    String label,
    String value,
    IconData icon, {
    Color? color,
  }) {
    return Column(
      children: [
        Icon(icon, color: color ?? Theme.of(context).colorScheme.primary),
        const SizedBox(height: 4),
        Text(
          value,
          style: Theme.of(
            context,
          ).textTheme.titleSmall?.copyWith(fontWeight: FontWeight.bold),
        ),
        Text(label, style: Theme.of(context).textTheme.bodySmall),
      ],
    );
  }

  Widget _buildDataTable(List<Transaction> transactions) {
    return SingleChildScrollView(
      child: PaginatedDataTable(
        header: Text('Transactions (${transactions.length})'),
        rowsPerPage: 10,
        sortColumnIndex: _sortColumnIndex,
        sortAscending: _sortAscending,
        columns: [
          DataColumn(
            label: const Text('From Account'),
            onSort: (columnIndex, ascending) => _sort(columnIndex, ascending),
          ),
          DataColumn(
            label: const Text('To Account'),
            onSort: (columnIndex, ascending) => _sort(columnIndex, ascending),
          ),
          DataColumn(
            label: const Text('Type'),
            onSort: (columnIndex, ascending) => _sort(columnIndex, ascending),
          ),
          DataColumn(
            label: const Text('Amount'),
            numeric: true,
            onSort: (columnIndex, ascending) => _sort(columnIndex, ascending),
          ),
          DataColumn(
            label: const Text('Category'),
            onSort: (columnIndex, ascending) => _sort(columnIndex, ascending),
          ),
          DataColumn(
            label: const Text('Payment Mode'),
            onSort: (columnIndex, ascending) => _sort(columnIndex, ascending),
          ),
          DataColumn(
            label: const Text('Date'),
            onSort: (columnIndex, ascending) => _sort(columnIndex, ascending),
          ),
        ],
        source: _TransactionDataSource(transactions, _showTransactionDetails),
      ),
    );
  }

  Widget _buildGroupedTable(
    Map<String, List<Transaction>> groupedTransactions,
  ) {
    return ListView.builder(
      itemCount: groupedTransactions.length,
      itemBuilder: (context, index) {
        final entry = groupedTransactions.entries.elementAt(index);
        final groupName = entry.key;
        final transactions = entry.value;

        return Card(
          margin: const EdgeInsets.all(8),
          child: ExpansionTile(
            title: Text(
              groupName,
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
            subtitle: Text('${transactions.length} transactions'),
            children: [
              SizedBox(height: 400, child: _buildDataTable(transactions)),
            ],
          ),
        );
      },
    );
  }

  void _sort(int columnIndex, bool ascending) {
    setState(() {
      _sortColumnIndex = columnIndex;
      _sortAscending = ascending;
      _applyFilters();
    });
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

  Future<void> _performFullAnalysis() async {
    if (!_hasPermission) {
      await _requestPermissions();
      return;
    }

    if (_analysisService == null) {
      SnackbarService().showError(context, 'Analysis service not initialized');
      return;
    }

    // Clear existing data first
    await _analysisService!.clearAllData();

    setState(() {
      _allTransactions = [];
      _filteredTransactions = [];
    });

    // Perform full analysis
    await _analyzeTransactions();
  }

  void _showClearDataDialog() {
    showDialog(
      context: context,
      builder:
          (context) => AlertDialog(
            title: const Text('Clear All Data'),
            content: const Text(
              'This will permanently delete all stored transaction data. This action cannot be undone.\n\nAre you sure you want to continue?',
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(context).pop(),
                child: const Text('Cancel'),
              ),
              TextButton(
                onPressed: () async {
                  Navigator.of(context).pop();
                  await _clearAllData();
                },
                style: TextButton.styleFrom(foregroundColor: Colors.red),
                child: const Text('Delete All'),
              ),
            ],
          ),
    );
  }

  Future<void> _clearAllData() async {
    if (_analysisService == null) return;

    try {
      await _analysisService!.clearAllData();
      setState(() {
        _allTransactions = [];
        _filteredTransactions = [];
      });

      if (mounted) {
        SnackbarService().showSuccess(
          context,
          'All transaction data has been cleared',
        );
      }
    } catch (e) {
      if (mounted) {
        SnackbarService().showError(context, 'Failed to clear data: $e');
      }
    }
  }
}

class _TransactionDataSource extends DataTableSource {
  final List<Transaction> transactions;
  final Function(Transaction) onTap;

  _TransactionDataSource(this.transactions, this.onTap);

  @override
  DataRow? getRow(int index) {
    if (index >= transactions.length) return null;

    final transaction = transactions[index];

    return DataRow(
      onSelectChanged: (_) => onTap(transaction),
      cells: [
        DataCell(
          SizedBox(
            width: 120,
            child: Text(
              transaction.fromAccount,
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ),
        DataCell(
          SizedBox(
            width: 120,
            child: Text(transaction.toAccount, overflow: TextOverflow.ellipsis),
          ),
        ),
        DataCell(
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              color:
                  transaction.transactionType == 'DEBIT'
                      ? Colors.red.shade100
                      : Colors.green.shade100,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Text(
              transaction.transactionType,
              style: TextStyle(
                color:
                    transaction.transactionType == 'DEBIT'
                        ? Colors.red.shade800
                        : Colors.green.shade800,
                fontWeight: FontWeight.bold,
                fontSize: 12,
              ),
            ),
          ),
        ),
        DataCell(
          Text(
            '${transaction.transactionType == 'DEBIT' ? '-' : '+'}₹${transaction.amount.toStringAsFixed(2)}',
            style: TextStyle(
              fontWeight: FontWeight.bold,
              color:
                  transaction.transactionType == 'DEBIT'
                      ? Colors.red
                      : Colors.green,
            ),
          ),
        ),
        DataCell(
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
            decoration: BoxDecoration(
              color: Colors.blue.shade100,
              borderRadius: BorderRadius.circular(8),
            ),
            child: Text(
              transaction.category,
              style: TextStyle(fontSize: 11, color: Colors.blue.shade800),
            ),
          ),
        ),
        DataCell(
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
            decoration: BoxDecoration(
              color: Colors.purple.shade100,
              borderRadius: BorderRadius.circular(8),
            ),
            child: Text(
              transaction.paymentMode,
              style: TextStyle(fontSize: 11, color: Colors.purple.shade800),
            ),
          ),
        ),
        DataCell(
          Text(
            DateFormat('MMM dd, yy\nHH:mm').format(transaction.transactionDate),
            style: const TextStyle(fontSize: 12),
          ),
        ),
      ],
    );
  }

  @override
  bool get isRowCountApproximate => false;

  @override
  int get rowCount => transactions.length;

  @override
  int get selectedRowCount => 0;
}
