import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

class BalanceEntryScreen extends StatefulWidget {
  const BalanceEntryScreen({super.key});

  @override
  State<BalanceEntryScreen> createState() => _BalanceEntryScreenState();
}

class _BalanceEntryScreenState extends State<BalanceEntryScreen> {
  final TextEditingController _openingGoldController = TextEditingController();
  final TextEditingController _openingSilverController = TextEditingController();
  final TextEditingController _openingCashController = TextEditingController();

  final TextEditingController _closingGoldController = TextEditingController();
  final TextEditingController _closingSilverController = TextEditingController();
  final TextEditingController _closingCashController = TextEditingController();

  bool _isLoading = false;

  DateTime today = DateTime.now();

  @override
  void initState() {
    super.initState();
    _loadPreviousClosingAsOpening();
    _loadExistingBalanceIfExists();
  }

  Future<void> _loadPreviousClosingAsOpening() async {
    final yesterday = DateTime(today.year, today.month, today.day - 1);

    final snapshot = await FirebaseFirestore.instance
        .collection('daily_balances')
        .where('date', isEqualTo: Timestamp.fromDate(yesterday))
        .limit(1)
        .get();

    if (snapshot.docs.isNotEmpty) {
      final data = snapshot.docs.first.data();
      _openingGoldController.text = (data['closingGold'] ?? 0).toStringAsFixed(3);
      _openingSilverController.text = (data['closingSilver'] ?? 0).toStringAsFixed(3);
      _openingCashController.text = (data['closingCash'] ?? 0).toStringAsFixed(2);
    }
  }

  Future<void> _loadExistingBalanceIfExists() async {
    final todayDate = DateTime(today.year, today.month, today.day);
    final snapshot = await FirebaseFirestore.instance
        .collection('daily_balances')
        .where('date', isEqualTo: Timestamp.fromDate(todayDate))
        .limit(1)
        .get();

    if (snapshot.docs.isNotEmpty) {
      final data = snapshot.docs.first.data();
      _openingGoldController.text = (data['openingGold'] ?? 0).toStringAsFixed(3);
      _openingSilverController.text = (data['openingSilver'] ?? 0).toStringAsFixed(3);
      _openingCashController.text = (data['openingCash'] ?? 0).toStringAsFixed(2);

      _closingGoldController.text = (data['closingGold'] ?? 0).toStringAsFixed(3);
      _closingSilverController.text = (data['closingSilver'] ?? 0).toStringAsFixed(3);
      _closingCashController.text = (data['closingCash'] ?? 0).toStringAsFixed(2);
    }
  }

  Future<Map<String, double>> _calculateTransactionImpact() async {
    final startOfDay = DateTime(today.year, today.month, today.day);
    final endOfDay = startOfDay.add(const Duration(days: 1));

    final snapshot = await FirebaseFirestore.instance
        .collection('transactions')
        .where('dateTime', isGreaterThanOrEqualTo: startOfDay)
        .where('dateTime', isLessThan: endOfDay)
        .get();

    double netGold = 0;
    double netSilver = 0;
    double netCash = 0;

    for (var doc in snapshot.docs) {
      final data = doc.data();
      final String type = data['type'] ?? 'buy';
      final String item = data['item']?.toLowerCase() ?? 'other';
      final double weight = (data['weight'] ?? 0).toDouble();
      final double amount = (data['totalAmount'] ?? 0).toDouble();

      final factor = type == 'buy' ? 1 : -1;

      if (item == 'gold') netGold += factor * weight;
      if (item == 'silver') netSilver += factor * weight;
      netCash += type == 'buy' ? -amount : amount;
    }

    return {
      'netGold': netGold,
      'netSilver': netSilver,
      'netCash': netCash,
    };
  }

  Future<void> _saveBalance() async {
    setState(() => _isLoading = true);

    final openingGold = double.tryParse(_openingGoldController.text) ?? 0;
    final openingSilver = double.tryParse(_openingSilverController.text) ?? 0;
    final openingCash = double.tryParse(_openingCashController.text) ?? 0;

    final closingGoldManual = double.tryParse(_closingGoldController.text);
    final closingSilverManual = double.tryParse(_closingSilverController.text);
    final closingCashManual = double.tryParse(_closingCashController.text);

    final net = await _calculateTransactionImpact();

    final closingGold = closingGoldManual ?? (openingGold + net['netGold']!);
    final closingSilver = closingSilverManual ?? (openingSilver + net['netSilver']!);
    final closingCash = closingCashManual ?? (openingCash + net['netCash']!);

    await FirebaseFirestore.instance.collection('daily_balances').doc(DateFormat('yyyy-MM-dd').format(today)).set({
      'date': Timestamp.fromDate(DateTime(today.year, today.month, today.day)),
      'openingGold': double.parse(openingGold.toStringAsFixed(3)),
      'openingSilver': double.parse(openingSilver.toStringAsFixed(3)),
      'openingCash': double.parse(openingCash.toStringAsFixed(2)),
      'closingGold': double.parse(closingGold.toStringAsFixed(3)),
      'closingSilver': double.parse(closingSilver.toStringAsFixed(3)),
      'closingCash': double.parse(closingCash.toStringAsFixed(2)),
    });

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Balance saved successfully')),
      );
    }

    setState(() => _isLoading = false);
  }

  Widget _buildTextField(String label, TextEditingController controller) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: TextField(
        controller: controller,
        keyboardType: TextInputType.numberWithOptions(decimal: true),
        decoration: InputDecoration(
          labelText: label,
          border: const OutlineInputBorder(),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Daily Balance Entry'),
        backgroundColor: const Color(0xFF29B6F6),
      ),
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [Colors.blue.shade200, Colors.blue.shade100],
          ),
        ),
        child: SingleChildScrollView(
          child: ConstrainedBox(
            constraints: BoxConstraints(
              minHeight: MediaQuery.of(context).size.height -
                  MediaQuery.of(context).padding.top -
                  kToolbarHeight,
            ),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                children: [
                  const Text("Opening Balance", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                  _buildTextField("Gold (g)", _openingGoldController),
                  _buildTextField("Silver (g)", _openingSilverController),
                  _buildTextField("Cash (₹)", _openingCashController),
                  const SizedBox(height: 16),
                  const Text("Closing Balance (Optional Manual Entry)", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                  _buildTextField("Gold (g)", _closingGoldController),
                  _buildTextField("Silver (g)", _closingSilverController),
                  _buildTextField("Cash (₹)", _closingCashController),
                  const SizedBox(height: 24),
                  ElevatedButton.icon(
                    onPressed: _isLoading ? null : _saveBalance,
                    icon: const Icon(Icons.save, color: Colors.white,),
                    label: const Text("Save Balance"),
                    style: ElevatedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
                    ),
                  ),
                  if (_isLoading)
                    const Padding(
                      padding: EdgeInsets.only(top: 16),
                      child: CircularProgressIndicator(),
                    )
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}