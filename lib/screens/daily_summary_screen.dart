import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

class DailySummaryScreen extends StatefulWidget {
  const DailySummaryScreen({super.key});

  @override
  State<DailySummaryScreen> createState() => _DailySummaryScreenState();
}

class _DailySummaryScreenState extends State<DailySummaryScreen> {
  DateTime selectedDate = DateTime.now();
  Map<String, dynamic> summaryData = {};
  bool isLoading = false;

  @override
  void initState() {
    super.initState();
    fetchSummary();
  }

  Future<void> fetchSummary() async {
    setState(() {
      isLoading = true;
      summaryData.clear();
    });

    DateTime startOfDay = DateTime(selectedDate.year, selectedDate.month, selectedDate.day);
    DateTime endOfDay = startOfDay.add(const Duration(days: 1));

    QuerySnapshot snapshot = await FirebaseFirestore.instance
        .collection('transactions')
        .where('dateTime', isGreaterThanOrEqualTo: startOfDay)
        .where('dateTime', isLessThan: endOfDay)
        .get();

    Map<String, Map<String, double>> totals = {
      'gold': {'buyWeight': 0, 'buyAmount': 0, 'sellWeight': 0, 'sellAmount': 0},
      'silver': {'buyWeight': 0, 'buyAmount': 0, 'sellWeight': 0, 'sellAmount': 0},
      'other': {'buyAmount': 0, 'sellAmount': 0},
    };

    for (var doc in snapshot.docs) {
      final data = doc.data() as Map<String, dynamic>;
      String item = (data['item'] ?? 'other').toLowerCase();
      String type = (data['type'] ?? 'buy').toLowerCase();
      double weight = (data['weight'] ?? 0).toDouble();
      double amount = (data['totalAmount'] ?? 0).toDouble();

      if (!totals.containsKey(item)) continue;

      if (item == 'other') {
        totals[item]!['${type}Amount'] = (totals[item]!['${type}Amount'] ?? 0) + amount;
      } else {
        totals[item]!['${type}Weight'] = (totals[item]!['${type}Weight'] ?? 0) + weight;
        totals[item]!['${type}Amount'] = (totals[item]!['${type}Amount'] ?? 0) + amount;
      }
    }

    setState(() {
      summaryData = totals;
      isLoading = false;
    });
  }

  Future<void> _selectDate() async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: selectedDate,
      firstDate: DateTime.now().subtract(const Duration(days: 180)),
      lastDate: DateTime.now(),
    );
    if (picked != null && picked != selectedDate) {
      setState(() {
        selectedDate = picked;
      });
      fetchSummary();
    }
  }

  Widget _buildSummaryCard(String item, Map<String, double> data) {
    return Card(
      elevation: 3,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      margin: const EdgeInsets.symmetric(vertical: 10),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              item.toUpperCase(),
              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 10),
            if (item != 'other') ...[
              Text('Buy Weight: ${data['buyWeight']?.toStringAsFixed(3)}g'),
              Text('Buy Amount: ₹${data['buyAmount']?.toStringAsFixed(2)}'),
              Text('Sell Weight: ${data['sellWeight']?.toStringAsFixed(3)}g'),
              Text('Sell Amount: ₹${data['sellAmount']?.toStringAsFixed(2)}'),
            ] else ...[
              Text('Buy Amount: ₹${data['buyAmount']?.toStringAsFixed(2)}'),
              Text('Sell Amount: ₹${data['sellAmount']?.toStringAsFixed(2)}'),
            ],
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Daily Summary'),
        backgroundColor: const Color(0xFF29B6F6),
      ),
      body: Container(
        width: double.infinity,
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [Colors.blue.shade100, Colors.blue.shade50],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
        ),
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Date: ${DateFormat('dd MMM yyyy').format(selectedDate)}',
                  style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
                ),
                ElevatedButton.icon(
                  onPressed: _selectDate,
                  icon: const Icon(Icons.calendar_today,color: Colors.white,),
                  label: const Text('Change Date'),
                ),
              ],
            ),
            const SizedBox(height: 20),
            if (isLoading)
              const Center(child: CircularProgressIndicator())
            else
              Expanded(
                child: ListView(
                  children: summaryData.entries
                      .map((e) => _buildSummaryCard(e.key, e.value.cast<String, double>()))
                      .toList(),
                ),
              ),
          ],
        ),
      ),
    );
  }
}
