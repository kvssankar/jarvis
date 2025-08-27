import 'package:flutter/material.dart';
import 'package:shots_studio/l10n/app_localizations.dart';
import 'package:shots_studio/screens/transaction_analysis_screen.dart';
import 'package:shots_studio/services/message_service.dart';
import 'package:shots_studio/services/snackbar_service.dart';

class LandingScreen extends StatefulWidget {
  const LandingScreen({super.key});

  @override
  State<LandingScreen> createState() => _LandingScreenState();
}

class _LandingScreenState extends State<LandingScreen> {
  final MessageService _messageService = MessageService();
  bool _hasPermission = false;
  bool _isCheckingPermission = true;

  @override
  void initState() {
    super.initState();
    _checkPermissions();
  }

  Future<void> _checkPermissions() async {
    final hasPermission = await _messageService.hasSmsPermission();
    setState(() {
      _hasPermission = hasPermission;
      _isCheckingPermission = false;
    });
  }

  Future<void> _requestPermissions() async {
    final granted = await _messageService.requestSmsPermission();
    setState(() {
      _hasPermission = granted;
    });

    if (granted) {
      _navigateToTransactionAnalysis();
    } else {
      SnackbarService().showError(
        context,
        'SMS permission is required to analyze transaction messages',
      );
    }
  }

  void _navigateToTransactionAnalysis() {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => const TransactionAnalysisScreen(),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final localizations = AppLocalizations.of(context)!;
    final theme = Theme.of(context);

    if (_isCheckingPermission) {
      return Scaffold(body: const Center(child: CircularProgressIndicator()));
    }

    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              // App Icon/Logo
              Container(
                width: 120,
                height: 120,
                decoration: BoxDecoration(
                  color: theme.colorScheme.primaryContainer,
                  borderRadius: BorderRadius.circular(24),
                ),
                child: Icon(
                  Icons.account_balance_wallet,
                  size: 64,
                  color: theme.colorScheme.onPrimaryContainer,
                ),
              ),
              const SizedBox(height: 32),

              // App Title
              Text(
                'Transaction Analyzer',
                style: theme.textTheme.headlineMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: theme.colorScheme.onSurface,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 16),

              // App Description
              Text(
                'Analyze your SMS messages to extract and organize transaction information automatically using AI.',
                style: theme.textTheme.bodyLarge?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 48),

              // Features List
              _buildFeatureItem(
                icon: Icons.sms,
                title: 'SMS Analysis',
                description:
                    'Automatically reads and processes transaction SMS',
              ),
              const SizedBox(height: 16),
              _buildFeatureItem(
                icon: Icons.smart_toy,
                title: 'AI-Powered',
                description: 'Uses advanced AI to extract transaction details',
              ),
              const SizedBox(height: 16),
              _buildFeatureItem(
                icon: Icons.security,
                title: 'Privacy First',
                description: 'All processing happens locally on your device',
              ),
              const SizedBox(height: 48),

              // Main Action Button
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed:
                      _hasPermission
                          ? _navigateToTransactionAnalysis
                          : _requestPermissions,
                  icon: Icon(_hasPermission ? Icons.analytics : Icons.security),
                  label: Text(
                    _hasPermission
                        ? 'Analyze Transactions'
                        : 'Grant SMS Permission',
                  ),
                  style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    textStyle: const TextStyle(fontSize: 16),
                  ),
                ),
              ),
              const SizedBox(height: 16),

              // Permission Info
              if (!_hasPermission)
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: theme.colorScheme.surfaceContainerHighest,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Row(
                    children: [
                      Icon(
                        Icons.info_outline,
                        color: theme.colorScheme.primary,
                        size: 20,
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          'SMS permission is required to read and analyze your transaction messages.',
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: theme.colorScheme.onSurfaceVariant,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildFeatureItem({
    required IconData icon,
    required String title,
    required String description,
  }) {
    final theme = Theme.of(context);

    return Row(
      children: [
        Container(
          width: 48,
          height: 48,
          decoration: BoxDecoration(
            color: theme.colorScheme.secondaryContainer,
            borderRadius: BorderRadius.circular(12),
          ),
          child: Icon(
            icon,
            color: theme.colorScheme.onSecondaryContainer,
            size: 24,
          ),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: theme.textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                description,
                style: theme.textTheme.bodySmall?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
