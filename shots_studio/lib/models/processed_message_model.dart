class ProcessedMessage {
  final String messageId;
  final DateTime processedAt;
  final bool hasTransaction;
  final String? transactionId;

  ProcessedMessage({
    required this.messageId,
    required this.processedAt,
    required this.hasTransaction,
    this.transactionId,
  });

  Map<String, dynamic> toJson() {
    return {
      'messageId': messageId,
      'processedAt': processedAt.toIso8601String(),
      'hasTransaction': hasTransaction,
      'transactionId': transactionId,
    };
  }

  factory ProcessedMessage.fromJson(Map<String, dynamic> json) {
    return ProcessedMessage(
      messageId: json['messageId'] as String,
      processedAt: DateTime.parse(json['processedAt'] as String),
      hasTransaction: json['hasTransaction'] as bool,
      transactionId: json['transactionId'] as String?,
    );
  }
}
