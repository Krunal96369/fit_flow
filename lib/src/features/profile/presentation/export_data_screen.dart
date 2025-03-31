import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../common_widgets/accessible_button.dart';
import '../../../common_widgets/error_dialog.dart';
import '../../../services/error/error_service.dart';
import '../../../services/export/export_service.dart';

class ExportDataScreen extends ConsumerStatefulWidget {
  const ExportDataScreen({super.key});

  @override
  ConsumerState<ExportDataScreen> createState() => _ExportDataScreenState();
}

class _ExportDataScreenState extends ConsumerState<ExportDataScreen> {
  ExportDataType _selectedDataType = ExportDataType.all;
  ExportFormat _selectedFormat = ExportFormat.pdf;
  DateTimeRange _dateRange = DateTimeRange(
    start: DateTime.now().subtract(const Duration(days: 30)),
    end: DateTime.now(),
  );
  bool _isExporting = false;

  Future<void> _exportData() async {
    setState(() {
      _isExporting = true;
    });

    try {
      await ref
          .read(exportServiceProvider)
          .exportData(
            dataType: _selectedDataType,
            format: _selectedFormat,
            startDate: _dateRange.start,
            endDate: _dateRange.end,
          );

      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text('Export successful!')));
      }
    } catch (e) {
      if (mounted) {
        showDialog(
          context: context,
          builder:
              (context) => ErrorDialog(
                errorType: ErrorType.unknown,
                technicalMessage: 'Failed to export data: $e',
                onRetry: _exportData,
              ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isExporting = false;
        });
      }
    }
  }

  Future<void> _selectDateRange() async {
    final newRange = await showDateRangePicker(
      context: context,
      firstDate: DateTime(2020),
      lastDate: DateTime.now(),
      initialDateRange: _dateRange,
    );

    if (newRange != null) {
      setState(() {
        _dateRange = newRange;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Export Data')),
      body: ListView(
        padding: const EdgeInsets.all(16.0),
        children: [
          // Data type selection
          Padding(
            padding: const EdgeInsets.only(bottom: 8.0),
            child: Text(
              'Select Data to Export',
              style: Theme.of(
                context,
              ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
            ),
          ),
          const SizedBox(height: 8),
          ...ExportDataType.values.map(
            (type) => RadioListTile<ExportDataType>(
              title: Text(_getDataTypeTitle(type)),
              subtitle: Text(_getDataTypeDescription(type)),
              value: type,
              groupValue: _selectedDataType,
              onChanged: (value) {
                setState(() {
                  _selectedDataType = value!;
                });
              },
            ),
          ),

          const Divider(),

          // Format selection
          Padding(
            padding: const EdgeInsets.only(bottom: 8.0),
            child: Text(
              'Select Export Format',
              style: Theme.of(
                context,
              ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
            ),
          ),
          const SizedBox(height: 8),
          ...ExportFormat.values.map(
            (format) => RadioListTile<ExportFormat>(
              title: Text(format.name.toUpperCase()),
              subtitle: Text(_getFormatDescription(format)),
              value: format,
              groupValue: _selectedFormat,
              onChanged: (value) {
                setState(() {
                  _selectedFormat = value!;
                });
              },
            ),
          ),

          const Divider(),

          // Date range selection
          Padding(
            padding: const EdgeInsets.only(bottom: 8.0),
            child: Text(
              'Date Range',
              style: Theme.of(
                context,
              ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
            ),
          ),
          const SizedBox(height: 8),
          ListTile(
            title: const Text('Select Date Range'),
            subtitle: Text(
              '${_dateRange.start.toLocal().toString().split(' ')[0]} to '
              '${_dateRange.end.toLocal().toString().split(' ')[0]}',
            ),
            trailing: const Icon(Icons.calendar_today),
            onTap: _selectDateRange,
          ),

          const SizedBox(height: 24),

          // Privacy notice
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.surface,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: Theme.of(context).colorScheme.outline),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Privacy Notice',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 8),
                const Text(
                  'Exported data will include your personal information '
                  'from the selected data type within the chosen date range. '
                  'Please be careful when sharing this data with others.',
                ),
              ],
            ),
          ),

          const SizedBox(height: 24),

          // Export button
          AccessibleButton(
            onPressed: _isExporting ? () {} : _exportData,
            semanticLabel: 'Export your data',
            child:
                _isExporting
                    ? const SizedBox(
                      height: 20,
                      width: 20,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                    : const Text('EXPORT DATA'),
          ),
        ],
      ),
    );
  }

  String _getDataTypeTitle(ExportDataType type) {
    switch (type) {
      case ExportDataType.workouts:
        return 'Workout Data';
      case ExportDataType.nutrition:
        return 'Nutrition Data';
      case ExportDataType.health:
        return 'Health Data';
      case ExportDataType.all:
        return 'All Data';
    }
  }

  String _getDataTypeDescription(ExportDataType type) {
    switch (type) {
      case ExportDataType.workouts:
        return 'Your logged workouts, exercises, and sets';
      case ExportDataType.nutrition:
        return 'Your logged meals and nutritional information';
      case ExportDataType.health:
        return 'Your steps, heart rate, and other health metrics';
      case ExportDataType.all:
        return 'All workout, nutrition, and health data';
    }
  }

  String _getFormatDescription(ExportFormat format) {
    switch (format) {
      case ExportFormat.csv:
        return 'Spreadsheet format for Excel, Google Sheets, etc.';
      case ExportFormat.pdf:
        return 'Document format with formatting and charts';
      case ExportFormat.json:
        return 'Technical format for data processing';
    }
  }
}
