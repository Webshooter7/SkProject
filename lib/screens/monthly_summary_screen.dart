import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';
import 'package:excel/excel.dart';
import 'dart:html' as html;
import 'dart:typed_data';

class MonthlyReportScreen extends StatefulWidget {
  const MonthlyReportScreen({super.key});

  @override
  State<MonthlyReportScreen> createState() => _MonthlyReportScreenState();
}

class _MonthlyReportScreenState extends State<MonthlyReportScreen> {
  List<Map<String, dynamic>> _monthlyReports = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _fetchMonthlyReport();
  }

  Future<void> _fetchMonthlyReport() async {
    final now = DateTime.now();
    final reports = <Map<String, dynamic>>[];

    for (int i = 0; i < 6; i++) {
      final month = DateTime(now.year, now.month - i, 1);
      final start = Timestamp.fromDate(month);
      final end = Timestamp.fromDate(DateTime(month.year, month.month + 1, 0, 23, 59, 59));

      final transactionsSnap = await FirebaseFirestore.instance
          .collection('transactions')
          .where('dateTime', isGreaterThanOrEqualTo: start, isLessThanOrEqualTo: end)
          .get();

      double totalBuy = 0;
      double totalSell = 0;
      int transactionCount = transactionsSnap.docs.length;

      for (var doc in transactionsSnap.docs) {
        final data = doc.data();
        final amount = (data['totalAmount'] ?? 0).toDouble();
        if ((data['type'] ?? '') == 'buy') {
          totalBuy += amount;
        } else {
          totalSell += amount;
        }
      }

      final balanceSnap = await FirebaseFirestore.instance
          .collection('daily_balances')
          .doc(DateFormat('yyyy-MM-dd').format(DateTime(month.year, month.month, 1)))
          .get();

      final balanceEndSnap = await FirebaseFirestore.instance
          .collection('daily_balances')
          .doc(DateFormat('yyyy-MM-dd').format(DateTime(month.year, month.month + 1, 0)))
          .get();

      reports.add({
        'month': DateFormat('MMMM yyyy').format(month),
        'totalBuy': totalBuy,
        'totalSell': totalSell,
        'profit': totalSell - totalBuy,
        'transactions': transactionCount,
        'openingGold': balanceSnap.data()?['openingGold'] ?? 0,
        'openingSilver': balanceSnap.data()?['openingSilver'] ?? 0,
        'openingCash': balanceSnap.data()?['openingCash'] ?? 0,
        'closingGold': balanceEndSnap.data()?['closingGold'] ?? 0,
        'closingSilver': balanceEndSnap.data()?['closingSilver'] ?? 0,
        'closingCash': balanceEndSnap.data()?['closingCash'] ?? 0,
      });
    }

    setState(() {
      _monthlyReports = reports;
      _isLoading = false;
    });
  }

  void _downloadExcel() {
    final excel = Excel.createExcel();
    final sheet = excel['Monthly Report'];
    excel.setDefaultSheet('Monthly Report');
    sheet.appendRow([
      TextCellValue('Month'),
      TextCellValue('Opening Gold'),
      TextCellValue('Opening Silver'),
      TextCellValue('Opening Cash'),
      TextCellValue('Closing Gold'),
      TextCellValue('Closing Silver'),
      TextCellValue('Closing Cash'),
      TextCellValue('Total Buys (₹)'),
      TextCellValue('Total Sells (₹)'),
      TextCellValue('Net Profit (₹)'),
      TextCellValue('Transactions'),
    ]);

    for (var report in _monthlyReports) {
      sheet.appendRow([
        TextCellValue(report['month']),
        TextCellValue(report['openingGold'].toString()),
        TextCellValue(report['openingSilver'].toString()),
        TextCellValue(report['openingCash'].toString()),
        TextCellValue(report['closingGold'].toString()),
        TextCellValue(report['closingSilver'].toString()),
        TextCellValue(report['closingCash'].toString()),
        TextCellValue(report['totalBuy'].toStringAsFixed(2)),
        TextCellValue(report['totalSell'].toStringAsFixed(2)),
        TextCellValue(report['profit'].toStringAsFixed(2)),
        TextCellValue(report['transactions'].toString()),
      ]);
    }

    final fileBytes = excel.encode();
    final blob = html.Blob([Uint8List.fromList(fileBytes!)]);
    final url = html.Url.createObjectUrlFromBlob(blob);
    final anchor = html.AnchorElement(href: url)
      ..setAttribute('download', 'Monthly_Report.xlsx')
      ..click();
    html.Url.revokeObjectUrl(url);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Monthly Report (Last 6 Months)'),
        backgroundColor: const Color(0xFF29B6F6),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            ElevatedButton.icon(
              onPressed: _downloadExcel,
              icon: const Icon(Icons.download, color: Colors.white,),
              label: const Text('Download Excel'),
            ),
            const SizedBox(height: 20),
            Expanded(
              child: SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: DataTable(
                  columns: const [
                    DataColumn(label: Text('Month')),
                    DataColumn(label: Text('Opening Gold')),
                    DataColumn(label: Text('Opening Silver')),
                    DataColumn(label: Text('Opening Cash')),
                    DataColumn(label: Text('Closing Gold')),
                    DataColumn(label: Text('Closing Silver')),
                    DataColumn(label: Text('Closing Cash')),
                    DataColumn(label: Text('Total Buys')),
                    DataColumn(label: Text('Total Sells')),
                    DataColumn(label: Text('Net Profit')),
                    DataColumn(label: Text('Transactions')),
                  ],
                  rows: _monthlyReports.map((report) {
                    return DataRow(cells: [
                      DataCell(Text(report['month'])),
                      DataCell(Text('${report['openingGold']}g')),
                      DataCell(Text('${report['openingSilver']}g')),
                      DataCell(Text('₹${report['openingCash']}')),
                      DataCell(Text('${report['closingGold']}g')),
                      DataCell(Text('${report['closingSilver']}g')),
                      DataCell(Text('₹${report['closingCash']}')),
                      DataCell(Text('₹${report['totalBuy'].toStringAsFixed(2)}')),
                      DataCell(Text('₹${report['totalSell'].toStringAsFixed(2)}')),
                      DataCell(Text('₹${report['profit'].toStringAsFixed(2)}')),
                      DataCell(Text(report['transactions'].toString())),
                    ]);
                  }).toList(),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}