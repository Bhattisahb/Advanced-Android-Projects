import 'dart:io';
import 'package:csv/csv.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:path_provider/path_provider.dart';
import 'package:intl/intl.dart';
import '../models/task.dart';

class ExportService {
  static Future<String> exportToCsv(List<Task> tasks) async {
    List<List<dynamic>> rows = [];
    
    // Add header row
    rows.add(['Title', 'Description', 'Due Date', 'Status', 'Repeating', 'Repeat Days', 'Progress']);
    
    // Add task data
    for (var task in tasks) {
      rows.add([
        task.title,
        task.description,
        DateFormat('yyyy-MM-dd HH:mm').format(task.dueDate),
        task.isCompleted ? 'Completed' : 'Pending',
        task.isRepeating ? 'Yes' : 'No',
        task.repeatDays?.join(', ') ?? '',
        '${(task.progress * 100).toStringAsFixed(0)}%',
      ]);
    }

    String csv = const ListToCsvConverter().convert(rows);
    
    final directory = await getApplicationDocumentsDirectory();
    final file = File('${directory.path}/tasks_${DateTime.now().millisecondsSinceEpoch}.csv');
    await file.writeAsString(csv);
    
    return file.path;
  }

  static Future<String> exportToPdf(List<Task> tasks, {String? outputDir, String? outputFilePath}) async {
    final pdf = pw.Document();

    pdf.addPage(
      pw.MultiPage(
        build: (context) => [
          pw.Header(
            level: 0,
            child: pw.Text('Tasks Report', style: pw.TextStyle(fontSize: 24)),
          ),
          pw.Table.fromTextArray(
            context: context,
            border: pw.TableBorder.all(),
            headerStyle: pw.TextStyle(fontWeight: pw.FontWeight.bold),
            headerDecoration: pw.BoxDecoration(
              color: PdfColors.grey300,
            ),
            data: <List<String>>[
              // Header row
              ['Title', 'Description', 'Due Date', 'Status', 'Progress'],
              // Data rows
              ...tasks.map((task) => [
                    task.title,
                    task.description,
                    DateFormat('yyyy-MM-dd HH:mm').format(task.dueDate),
                    task.isCompleted ? 'Completed' : 'Pending',
                    '${(task.progress * 100).toStringAsFixed(0)}%',
                  ]),
            ],
          ),
        ],
      ),
    );

    File file;
    if (outputFilePath != null && outputFilePath.isNotEmpty) {
      file = File(outputFilePath);
      final dir = file.parent;
      if (!dir.existsSync()) dir.createSync(recursive: true);
    } else {
      final directory = outputDir != null ? Directory(outputDir) : await getApplicationDocumentsDirectory();
      if (!directory.existsSync()) {
        directory.createSync(recursive: true);
      }
      file = File('${directory.path}/tasks_${DateTime.now().millisecondsSinceEpoch}.pdf');
    }
    await file.writeAsBytes(await pdf.save());

    // Try to copy to the public Downloads directory on Android so users can access it
    try {
      if (Platform.isAndroid) {
        final downloads = Directory('/storage/emulated/0/Download');
        if (downloads.existsSync()) {
          final filename = file.path.split(Platform.pathSeparator).last;
          final publicFile = File('${downloads.path}/$filename');
          await publicFile.writeAsBytes(await file.readAsBytes());
          return publicFile.path;
        }
      }
    } catch (e) {
      // ignore and fall back to app directory
    }

    return file.path;
  }
}