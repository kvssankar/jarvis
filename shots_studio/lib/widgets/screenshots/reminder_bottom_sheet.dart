import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

class ReminderBottomSheet extends StatefulWidget {
  final DateTime? initialReminderTime;
  final String? initialReminderText;

  const ReminderBottomSheet({
    super.key,
    this.initialReminderTime,
    this.initialReminderText,
  });

  @override
  State<ReminderBottomSheet> createState() => _ReminderBottomSheetState();
}

class _ReminderBottomSheetState extends State<ReminderBottomSheet> {
  late TextEditingController _reminderTextController;
  DateTime? _selectedDateTime;
  final _formKey = GlobalKey<FormState>();

  @override
  void initState() {
    super.initState();
    _reminderTextController = TextEditingController(
      text: widget.initialReminderText ?? 'Hey check me out!',
    );

    if (widget.initialReminderTime != null &&
        widget.initialReminderTime!.isBefore(DateTime.now())) {
      _selectedDateTime = null;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        Navigator.of(
          context,
        ).pop({'reminderTime': null, 'reminderText': null, 'expired': true});
      });
    } else {
      _selectedDateTime = widget.initialReminderTime;
    }
  }

  @override
  void dispose() {
    _reminderTextController.dispose();
    super.dispose();
  }

  Future<void> _selectDateTime() async {
    final DateTime? pickedDate = await showDatePicker(
      context: context,
      initialDate:
          _selectedDateTime ?? DateTime.now().add(const Duration(hours: 1)),
      firstDate: DateTime.now(),
      lastDate: DateTime(2101),
      helpText: 'Select reminder date',
    );

    if (pickedDate != null) {
      if (!mounted) return;

      final TimeOfDay? pickedTime = await showTimePicker(
        context: context,
        initialTime: TimeOfDay.fromDateTime(
          _selectedDateTime ?? DateTime.now().add(const Duration(hours: 1)),
        ),
        helpText: 'Select reminder time',
      );

      if (pickedTime != null) {
        setState(() {
          _selectedDateTime = DateTime(
            pickedDate.year,
            pickedDate.month,
            pickedDate.day,
            pickedTime.hour,
            pickedTime.minute,
          );
        });
      }
    }
  }

  void _setReminder() {
    if (_formKey.currentState!.validate() && _selectedDateTime != null) {
      Navigator.of(context).pop({
        'reminderTime': _selectedDateTime,
        'reminderText': _reminderTextController.text.trim(),
      });
    }
  }

  void _clearReminder() {
    Navigator.of(context).pop({'reminderTime': null, 'reminderText': null});
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final isReminderAlreadySet = widget.initialReminderTime != null;

    return Container(
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).viewInsets.bottom,
      ),
      child: DraggableScrollableSheet(
        initialChildSize: isReminderAlreadySet ? 0.5 : 0.7,
        minChildSize: 0.4,
        maxChildSize: isReminderAlreadySet ? 0.7 : 0.9,
        expand: false,
        builder: (context, scrollController) {
          return Container(
            decoration: BoxDecoration(
              color: colorScheme.surface,
              borderRadius: const BorderRadius.vertical(
                top: Radius.circular(20),
              ),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Handle bar
                Container(
                  margin: const EdgeInsets.only(top: 12),
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: colorScheme.onSurfaceVariant.withOpacity(0.4),
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),

                // Header
                Padding(
                  padding: const EdgeInsets.all(20),
                  child: Row(
                    children: [
                      Icon(
                        isReminderAlreadySet ? Icons.alarm : Icons.alarm_add,
                        color: colorScheme.primary,
                        size: 28,
                      ),
                      const SizedBox(width: 12),
                      Text(
                        isReminderAlreadySet
                            ? 'Active Reminder'
                            : 'Set Reminder',
                        style: theme.textTheme.headlineSmall?.copyWith(
                          fontWeight: FontWeight.bold,
                          color: colorScheme.onSecondaryContainer,
                        ),
                      ),
                    ],
                  ),
                ),

                Expanded(
                  child: SingleChildScrollView(
                    controller: scrollController,
                    padding: const EdgeInsets.symmetric(horizontal: 20),
                    child:
                        widget.initialReminderTime != null
                            ? _buildReminderViewMode(theme, colorScheme)
                            : Form(
                              key: _formKey,
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  // Reminder text input
                                  Text(
                                    'Reminder message',
                                    style: theme.textTheme.titleMedium
                                        ?.copyWith(
                                          fontWeight: FontWeight.w600,
                                          color:
                                              colorScheme.onSecondaryContainer,
                                        ),
                                  ),
                                  const SizedBox(height: 8),
                                  TextFormField(
                                    controller: _reminderTextController,
                                    style: TextStyle(
                                      color: colorScheme.onSecondaryContainer,
                                    ),
                                    decoration: InputDecoration(
                                      hintText:
                                          'What should I remind you about?',
                                      filled: true,
                                      fillColor: colorScheme.secondaryContainer,
                                      border: OutlineInputBorder(
                                        borderRadius: BorderRadius.circular(12),
                                        borderSide: BorderSide.none,
                                      ),
                                      prefixIcon: Icon(
                                        Icons.message_outlined,
                                        color: colorScheme.onSecondaryContainer,
                                      ),
                                    ),
                                    maxLines: 3,
                                    validator: (value) {
                                      if (value == null ||
                                          value.trim().isEmpty) {
                                        return 'Please enter a reminder message';
                                      }
                                      return null;
                                    },
                                  ),

                                  const SizedBox(height: 24),

                                  // Date and time selection
                                  Text(
                                    'When to remind',
                                    style: theme.textTheme.titleMedium
                                        ?.copyWith(
                                          fontWeight: FontWeight.w600,
                                          color: colorScheme.onSurface,
                                        ),
                                  ),
                                  const SizedBox(height: 8),

                                  Card(
                                    elevation: 0,
                                    color: colorScheme.surfaceContainer,
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                    child: InkWell(
                                      onTap: _selectDateTime,
                                      borderRadius: BorderRadius.circular(12),
                                      child: Padding(
                                        padding: const EdgeInsets.all(16),
                                        child: Row(
                                          children: [
                                            Icon(
                                              Icons.schedule,
                                              color: colorScheme.primary,
                                            ),
                                            const SizedBox(width: 12),
                                            Expanded(
                                              child: Column(
                                                crossAxisAlignment:
                                                    CrossAxisAlignment.start,
                                                children: [
                                                  Text(
                                                    _selectedDateTime != null
                                                        ? DateFormat(
                                                          'EEEE, MMM d, yyyy',
                                                        ).format(
                                                          _selectedDateTime!,
                                                        )
                                                        : 'Select date',
                                                    style: theme
                                                        .textTheme
                                                        .bodyLarge
                                                        ?.copyWith(
                                                          fontWeight:
                                                              FontWeight.w500,
                                                          color:
                                                              _selectedDateTime !=
                                                                      null
                                                                  ? colorScheme
                                                                      .onSurface
                                                                  : colorScheme
                                                                      .onSurfaceVariant,
                                                        ),
                                                  ),
                                                  Text(
                                                    _selectedDateTime != null
                                                        ? DateFormat(
                                                          'h:mm a',
                                                        ).format(
                                                          _selectedDateTime!,
                                                        )
                                                        : 'Select time',
                                                    style: theme
                                                        .textTheme
                                                        .bodyMedium
                                                        ?.copyWith(
                                                          color:
                                                              _selectedDateTime !=
                                                                      null
                                                                  ? colorScheme
                                                                      .onSurfaceVariant
                                                                  : colorScheme
                                                                      .onSurfaceVariant
                                                                      .withOpacity(
                                                                        0.7,
                                                                      ),
                                                        ),
                                                  ),
                                                ],
                                              ),
                                            ),
                                            Icon(
                                              Icons.chevron_right,
                                              color:
                                                  colorScheme.onSurfaceVariant,
                                            ),
                                          ],
                                        ),
                                      ),
                                    ),
                                  ),

                                  if (_selectedDateTime != null) ...[
                                    const SizedBox(height: 16),
                                    Container(
                                      padding: const EdgeInsets.all(12),
                                      decoration: BoxDecoration(
                                        color: colorScheme.primaryContainer
                                            .withOpacity(0.3),
                                        borderRadius: BorderRadius.circular(8),
                                        border: Border.all(
                                          color: colorScheme.primary
                                              .withOpacity(0.3),
                                        ),
                                      ),
                                      child: Row(
                                        children: [
                                          Icon(
                                            Icons.info_outline,
                                            color: colorScheme.primary,
                                            size: 16,
                                          ),
                                          const SizedBox(width: 8),
                                          Expanded(
                                            child: Text(
                                              'Reminder set for ${DateFormat('MMM d, yyyy, h:mm a').format(_selectedDateTime!)}',
                                              style: theme.textTheme.bodySmall
                                                  ?.copyWith(
                                                    color: colorScheme.primary,
                                                  ),
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ],

                                  const SizedBox(height: 32),

                                  // Quick time options
                                  Text(
                                    'Quick options',
                                    style: theme.textTheme.titleMedium
                                        ?.copyWith(
                                          fontWeight: FontWeight.w600,
                                          color: colorScheme.onSurface,
                                        ),
                                  ),
                                  const SizedBox(height: 8),

                                  Wrap(
                                    spacing: 8,
                                    runSpacing: 8,
                                    children: [
                                      _buildQuickTimeChip(
                                        'In 1 hour',
                                        DateTime.now().add(
                                          const Duration(hours: 1),
                                        ),
                                      ),
                                      _buildQuickTimeChip(
                                        'In 3 hours',
                                        DateTime.now().add(
                                          const Duration(hours: 3),
                                        ),
                                      ),
                                      _buildQuickTimeChip(
                                        'Tomorrow 9 AM',
                                        DateTime.now()
                                            .add(const Duration(days: 1))
                                            .copyWith(hour: 9, minute: 0),
                                      ),
                                      _buildQuickTimeChip(
                                        'Next week',
                                        DateTime.now().add(
                                          const Duration(days: 7),
                                        ),
                                      ),
                                    ],
                                  ),

                                  const SizedBox(height: 40),
                                ],
                              ),
                            ),
                  ),
                ),

                // Action buttons
                Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: colorScheme.surface,
                    border: Border(
                      top: BorderSide(
                        color: colorScheme.outlineVariant,
                        width: 1,
                      ),
                    ),
                  ),
                  child: Row(
                    children: [
                      if (widget.initialReminderTime != null)
                        Expanded(
                          child: OutlinedButton.icon(
                            onPressed: _clearReminder,
                            icon: const Icon(Icons.delete_outline),
                            label: const Text('Clear Reminder'),
                            style: OutlinedButton.styleFrom(
                              foregroundColor: colorScheme.secondary,
                              side: BorderSide(color: colorScheme.secondary),
                              padding: const EdgeInsets.symmetric(vertical: 12),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(8),
                              ),
                            ),
                          ),
                        )
                      else
                        Expanded(
                          child: FilledButton.icon(
                            onPressed:
                                _selectedDateTime != null ? _setReminder : null,
                            icon: const Icon(Icons.alarm_add),
                            label: const Text('Set Reminder'),
                            style: FilledButton.styleFrom(
                              padding: const EdgeInsets.symmetric(vertical: 12),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(8),
                              ),
                            ),
                          ),
                        ),
                    ],
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildQuickTimeChip(String label, DateTime dateTime) {
    final colorScheme = Theme.of(context).colorScheme;
    final isSelected =
        _selectedDateTime != null &&
        _selectedDateTime!.difference(dateTime).abs() <
            const Duration(minutes: 1);

    return FilterChip(
      label: Text(label),
      selected: isSelected,
      onSelected: (_) {
        setState(() {
          _selectedDateTime = dateTime;
        });
      },
      backgroundColor: colorScheme.surfaceContainer,
      selectedColor: colorScheme.primaryContainer,
      checkmarkColor: colorScheme.primary,
      labelStyle: TextStyle(
        color: isSelected ? colorScheme.primary : colorScheme.onSurfaceVariant,
      ),
    );
  }

  Widget _buildReminderViewMode(ThemeData theme, ColorScheme colorScheme) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: colorScheme.primaryContainer.withOpacity(0.3),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: colorScheme.primary.withOpacity(0.3)),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Icon(Icons.event, color: colorScheme.primary, size: 20),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      DateFormat(
                        'EEEE, MMMM d, yyyy',
                      ).format(widget.initialReminderTime!),
                      style: theme.textTheme.titleMedium?.copyWith(
                        color: colorScheme.onSecondaryContainer,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              // Time
              Row(
                children: [
                  Icon(Icons.access_time, color: colorScheme.primary, size: 20),
                  const SizedBox(width: 12),
                  Text(
                    DateFormat('h:mm a').format(widget.initialReminderTime!),
                    style: theme.textTheme.titleMedium?.copyWith(
                      color: colorScheme.onSecondaryContainer,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              // Message
              if (widget.initialReminderText != null &&
                  widget.initialReminderText!.isNotEmpty) ...[
                Divider(color: colorScheme.outlineVariant),
                const SizedBox(height: 12),
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Icon(
                      Icons.message_outlined,
                      color: colorScheme.primary,
                      size: 20,
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        widget.initialReminderText!,
                        style: theme.textTheme.bodyLarge?.copyWith(
                          color: colorScheme.onSurfaceVariant,
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ],
          ),
        ),
        const SizedBox(height: 24),

        // Note about existing reminder
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: colorScheme.surfaceContainer,
            borderRadius: BorderRadius.circular(8),
          ),
          child: Row(
            children: [
              Icon(Icons.info_outline, color: colorScheme.primary, size: 18),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  'You already have a reminder set for this screenshot. You can clear it and set a new one if needed.',
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: colorScheme.onSurfaceVariant,
                  ),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 24),
      ],
    );
  }
}
