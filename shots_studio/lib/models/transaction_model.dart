class Transaction {
  final String id;
  final String fromAccount; // Source Account/Entity
  final String toAccount; // Destination Account/Entity
  final String transactionType; // DEBIT/CREDIT
  final double amount; // Transaction Amount
  final String category; // Expense/Income Category
  final DateTime transactionDate; // Date of Transaction
  final String paymentMode; // UPI/CARD/NETBANKING/CASH/etc.
  final String originalMessage;
  final String? description;
  final String? currency;

  Transaction({
    required this.id,
    required this.fromAccount,
    required this.toAccount,
    required this.transactionType,
    required this.amount,
    required this.category,
    required this.transactionDate,
    required this.paymentMode,
    required this.originalMessage,
    this.description,
    this.currency = 'INR',
  });

  // Method to convert a Transaction instance to a Map (JSON)
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'fromAccount': fromAccount,
      'toAccount': toAccount,
      'transactionType': transactionType,
      'amount': amount,
      'category': category,
      'transactionDate': transactionDate.toIso8601String(),
      'paymentMode': paymentMode,
      'originalMessage': originalMessage,
      'description': description,
      'currency': currency,
    };
  }

  // Factory constructor to create a Transaction instance from a Map (JSON)
  factory Transaction.fromJson(Map<String, dynamic> json) {
    return Transaction(
      id: json['id'] as String,
      fromAccount: json['fromAccount'] as String,
      toAccount: json['toAccount'] as String,
      transactionType: json['transactionType'] as String,
      amount: (json['amount'] as num).toDouble(),
      category: json['category'] as String,
      transactionDate: DateTime.parse(json['transactionDate'] as String),
      paymentMode: json['paymentMode'] as String,
      originalMessage: json['originalMessage'] as String,
      description: json['description'] as String?,
      currency: json['currency'] as String? ?? 'INR',
    );
  }

  Transaction copyWith({
    String? id,
    String? fromAccount,
    String? toAccount,
    String? transactionType,
    double? amount,
    String? category,
    DateTime? transactionDate,
    String? paymentMode,
    String? originalMessage,
    String? description,
    String? currency,
  }) {
    return Transaction(
      id: id ?? this.id,
      fromAccount: fromAccount ?? this.fromAccount,
      toAccount: toAccount ?? this.toAccount,
      transactionType: transactionType ?? this.transactionType,
      amount: amount ?? this.amount,
      category: category ?? this.category,
      transactionDate: transactionDate ?? this.transactionDate,
      paymentMode: paymentMode ?? this.paymentMode,
      originalMessage: originalMessage ?? this.originalMessage,
      description: description ?? this.description,
      currency: currency ?? this.currency,
    );
  }

  // Helper getter for backward compatibility
  bool get isDebit => transactionType == 'DEBIT';
  bool get isCredit => transactionType == 'CREDIT';
}

class TransactionSummary {
  final String accountName;
  final double totalAmount;
  final int transactionCount;
  final List<Transaction> transactions;
  final DateTime firstTransaction;
  final DateTime lastTransaction;

  TransactionSummary({
    required this.accountName,
    required this.totalAmount,
    required this.transactionCount,
    required this.transactions,
    required this.firstTransaction,
    required this.lastTransaction,
  });

  Map<String, dynamic> toJson() {
    return {
      'accountName': accountName,
      'totalAmount': totalAmount,
      'transactionCount': transactionCount,
      'transactions': transactions.map((t) => t.toJson()).toList(),
      'firstTransaction': firstTransaction.toIso8601String(),
      'lastTransaction': lastTransaction.toIso8601String(),
    };
  }

  factory TransactionSummary.fromJson(Map<String, dynamic> json) {
    return TransactionSummary(
      accountName: json['accountName'] as String,
      totalAmount: (json['totalAmount'] as num).toDouble(),
      transactionCount: json['transactionCount'] as int,
      transactions:
          (json['transactions'] as List)
              .map((t) => Transaction.fromJson(t as Map<String, dynamic>))
              .toList(),
      firstTransaction: DateTime.parse(json['firstTransaction'] as String),
      lastTransaction: DateTime.parse(json['lastTransaction'] as String),
    );
  }
}
