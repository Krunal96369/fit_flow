import 'dart:io';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';

import '../../services/error/error_service.dart';

enum ExportFormat { csv, pdf, json }

enum ExportDataType { workouts, nutrition, health, all }

final exportServiceProvider = Provider<ExportService>((ref) {
  return ExportServiceImpl(ref.watch(errorServiceProvider));
});

abstract class ExportService {
  Future<void> exportData({
    required ExportDataType dataType,
    required ExportFormat format,
    required DateTime startDate,
    required DateTime endDate,
  });
}

class ExportServiceImpl implements ExportService {
  final ErrorService _errorService;

  ExportServiceImpl(this._errorService);

  @override
  Future<void> exportData({
    required ExportDataType dataType,
    required ExportFormat format,
    required DateTime startDate,
    required DateTime endDate,
  }) async {
    try {
      // This is a placeholder implementation. In a real app,
      // you would fetch data from repositories and generate
      // the appropriate format.

      // Create a demo file
      final directory = await getApplicationDocumentsDirectory();
      final timestamp = DateTime.now().millisecondsSinceEpoch;
      final filename = 'fitflow_${dataType.name}_$timestamp.${format.name}';
      final file = File('${directory.path}/$filename');

      // Write some placeholder content
      await file.writeAsString(
        'FitFlow Export\n'
        'Data type: ${dataType.name}\n'
        'Format: ${format.name}\n'
        'Date range: ${startDate.toString()} to ${endDate.toString()}\n'
        'This is a placeholder file for demonstration purposes.',
      );

      // Share the file
      await Share.shareXFiles([
        XFile(file.path),
      ], subject: 'FitFlow ${dataType.name} Export');
    } catch (e) {
      _errorService.logError(
        ErrorType.unknown,
        'Failed to export data',
        exception: e,
      );
      rethrow;
    }
  }
}
