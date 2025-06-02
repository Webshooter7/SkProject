import 'dart:convert';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:csv/csv.dart';
import 'package:universal_html/html.dart' as html;

class ExportScreen extends StatefulWidget {
  const ExportScreen({Key? key}) : super(key: key);

  @override
  State<ExportScreen> createState() => _ExportScreenState();
}

class _ExportScreenState extends State<ExportScreen> {
  DateTime? _startDate;
  DateTime? _endDate;

  Future<void> _pickDateRange(BuildContext context) async {
    final now = DateTime.now();
    final sixMonthsAgo = now.subtract(const Duration(days: 180));

    final initialDateRange = DateTimeRange(
      start: now.subtract(const Duration(days: 7)),
      end: now,
    );

    final picked = await showDateRangePicker(
      context: context,
      firstDate: sixMonthsAgo,
      lastDate: now,
      initialDateRange: _startDate != null && _endDate != null
          ? DateTimeRange(start: _startDate!, end: _endDate!)
          : initialDateRange,
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            dialogTheme: DialogTheme(
              backgroundColor: Colors.transparent,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
            ),
            colorScheme: Theme.of(context).colorScheme.copyWith(
              primary: const Color(0xFF29B6F6),
              onPrimary: Colors.white,
              surface: Colors.transparent,
              onSurface: Colors.black87,
            ),
            datePickerTheme: DatePickerThemeData(
              backgroundColor: Colors.transparent,
              headerBackgroundColor: const Color(0xFF29B6F6),
              headerForegroundColor: Colors.white,
              rangeSelectionBackgroundColor: const Color(0xFF29B6F6).withOpacity(0.3),
              rangePickerBackgroundColor: Colors.transparent,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
            ),
          ),
          child: Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [Colors.blue.shade100, Colors.blue.shade50],
              ),
              borderRadius: BorderRadius.circular(16),
            ),
            child: child,
          ),
        );
      },
    );

    if (picked != null) {
      setState(() {
        _startDate = picked.start;
        _endDate = picked.end;
      });
    }
  }

  String _generateFileName() {
    if (_startDate == null || _endDate == null) return 'transactions.csv';

    final startFormatted = DateFormat('dd-MM-yyyy').format(_startDate!);
    final endFormatted = DateFormat('dd-MM-yyyy').format(_endDate!);

    return 'transactions_${startFormatted}_to_${endFormatted}.csv';
  }

  Future<void> _exportFilteredCSV() async {
    if (_startDate == null || _endDate == null) return;

    final snapshot = await FirebaseFirestore.instance
        .collection('transactions')
        .where('dateTime', isGreaterThanOrEqualTo: Timestamp.fromDate(_startDate!))
        .where('dateTime', isLessThanOrEqualTo: Timestamp.fromDate(_endDate!))
        .orderBy('dateTime', descending: true)
        .get();

    final transactions = snapshot.docs;

    List<List<String>> csvData = [
      [
        'Date & Time',
        'Type',
        'Item',
        'Weight (g)',
        'Rate (Rs.)',
        'Total (Rs.)',
        'Customer',
        'Phone Number',
        'Purity',
        'Comments'
      ]
    ];

    for (var doc in transactions) {
      final data = doc.data();
      final dateTime = (data['dateTime'] as Timestamp).toDate();

      // Fixed AM/PM format - using 'h:mm a' for 12-hour format with AM/PM
      final formattedDate = '"${DateFormat('dd/MM/yyyy h:mm a').format(dateTime)}"';

      // Properly format numbers and handle null values for better alignment
      final weight = data['weight']?.toString() ?? '0';
      final rate = data['pricePerGram']?.toString() ?? '0';
      final total = data['totalAmount']?.toString() ?? '0';
      final customerName = data['customerName']?.toString() ?? '';
      final phone = '"${data['phone']?.toString() ?? ''}"';
      final purity = data['purity']?.toString() ?? '';
      final comments = data['comments']?.toString() ?? '';
      final type = data['type']?.toString() ?? '';
      final item = data['item']?.toString() ?? '';

      csvData.add([
        formattedDate,
        type,
        item,
        weight,
        rate,
        total,
        customerName,
        phone,
        purity,
        comments,
      ]);
    }

    // Convert to CSV with proper formatting
    final csv = const ListToCsvConverter().convert(csvData);
    final bytes = utf8.encode(csv);
    final blob = html.Blob([bytes]);
    final url = html.Url.createObjectUrlFromBlob(blob);

    // Generate filename with date range
    final fileName = _generateFileName();

    final anchor = html.AnchorElement(href: url)
      ..setAttribute('download', fileName)
      ..click();
    html.Url.revokeObjectUrl(url);

    // Show success message
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('CSV exported successfully as: $fileName'),
          backgroundColor: Colors.green,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Export Transactions'),
        backgroundColor: const Color(0xFF29B6F6),
        foregroundColor: Colors.white,
      ),
      body: Container(
        width: double.infinity,
        height: double.infinity,
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [Colors.blue.shade100, Colors.blue.shade50],
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.center,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Card(
              elevation: 4,
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    const Text(
                      'Select Date Range for Export',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 16),

                    if (_startDate != null && _endDate != null)
                      Padding(
                        padding: const EdgeInsets.only(bottom: 12),
                        child: Text(
                          'Exporting records from ${DateFormat('dd MMM yyyy').format(_startDate!)} to ${DateFormat('dd MMM yyyy').format(_endDate!)}',
                          style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w500),
                        ),
                      ),

                    ElevatedButton.icon(
                      onPressed: () => _pickDateRange(context),
                      icon: const Icon(Icons.date_range, color: Colors.white),
                      label: const Text(
                        'Select Date Range',
                        style: TextStyle(color: Colors.white),
                      ),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF29B6F6),
                        padding: const EdgeInsets.symmetric(
                          horizontal: 20,
                          vertical: 12,
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),
                    if (_startDate != null && _endDate != null) ...[
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: Colors.blue.shade50,
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(color: Colors.blue.shade200),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Selected Range:',
                              style: TextStyle(
                                fontSize: 14,
                                color: Colors.blue.shade700,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              '${DateFormat('dd MMM yyyy').format(_startDate!)} - ${DateFormat('dd MMM yyyy').format(_endDate!)}',
                              style: const TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const SizedBox(height: 8),
                            Text(
                              'File will be saved as: ${_generateFileName()}',
                              style: TextStyle(
                                fontSize: 12,
                                color: Colors.grey.shade600,
                                fontStyle: FontStyle.italic,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ),
            const SizedBox(height: 24),
            ElevatedButton.icon(
              onPressed: (_startDate != null && _endDate != null)
                  ? _exportFilteredCSV
                  : null,
              icon: const Icon(Icons.download, color: Colors.white),
              label: const Text(
                'Export CSV',
                style: TextStyle(color: Colors.white),
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.green,
                disabledBackgroundColor: Colors.grey.shade400,
                padding: const EdgeInsets.symmetric(
                  horizontal: 24,
                  vertical: 12,
                ),
                textStyle: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}