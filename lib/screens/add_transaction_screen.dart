import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';

class AddTransactionScreen extends StatefulWidget {
  const AddTransactionScreen({super.key});

  @override
  State<AddTransactionScreen> createState() => _AddTransactionScreenState();
}

class _AddTransactionScreenState extends State<AddTransactionScreen> {
  final _formKey = GlobalKey<FormState>();
  final TextEditingController _weightController = TextEditingController();
  final TextEditingController _priceController = TextEditingController();
  final TextEditingController _customerNameController = TextEditingController();
  final TextEditingController _phoneController = TextEditingController();
  final TextEditingController _purityController = TextEditingController();
  final TextEditingController _commentsController = TextEditingController();

  String _transactionType = 'buy';
  String _itemType = 'gold';

  double get _totalAmount {
    final weight = double.tryParse(_weightController.text) ?? 0;
    final price = double.tryParse(_priceController.text) ?? 0;
    return weight * price;
  }

  String get todayDateKey => DateFormat('yyyy-MM-dd').format(DateTime.now());

  Future<void> _submitTransaction() async {
    if (_formKey.currentState!.validate()) {
      try {
        final weight = double.parse(_weightController.text);
        final price = double.parse(_priceController.text);
        final total = _totalAmount;

        final docRef = FirebaseFirestore.instance.collection('transactions').doc();
        final balanceRef = FirebaseFirestore.instance.collection('daily_balances').doc(todayDateKey);

        await FirebaseFirestore.instance.runTransaction((txn) async {
          final balanceSnap = await txn.get(balanceRef);
          Map<String, dynamic> currentBalance;

          if (balanceSnap.exists) {
            currentBalance = balanceSnap.data()!;
          } else {
            final yesterdayKey = DateFormat('yyyy-MM-dd')
                .format(DateTime.now().subtract(const Duration(days: 1)));
            final ySnap = await FirebaseFirestore.instance
                .collection('daily_balances')
                .doc(yesterdayKey)
                .get();

            currentBalance = {
              'openingGold': ySnap.data()?['closingGold'] ?? 0.0,
              'openingSilver': ySnap.data()?['closingSilver'] ?? 0.0,
              'openingCash': ySnap.data()?['closingCash'] ?? 0.0,
              'closingGold': ySnap.data()?['closingGold'] ?? 0.0,
              'closingSilver': ySnap.data()?['closingSilver'] ?? 0.0,
              'closingCash': ySnap.data()?['closingCash'] ?? 0.0,
            };
          }

          double deltaWeight = _transactionType == 'buy' ? weight : -weight;
          double deltaCash = _transactionType == 'buy' ? -total : total;

          if (_itemType == 'gold') {
            currentBalance['closingGold'] = (currentBalance['closingGold'] ?? 0.0) + deltaWeight;
          } else if (_itemType == 'silver') {
            currentBalance['closingSilver'] = (currentBalance['closingSilver'] ?? 0.0) + deltaWeight;
          }

          currentBalance['closingCash'] = (currentBalance['closingCash'] ?? 0.0) + deltaCash;

          txn.set(balanceRef, currentBalance);

          txn.set(docRef, {
            'type': _transactionType,
            'item': _itemType,
            'weight': weight,
            'pricePerGram': price,
            'totalAmount': total,
            'customerName': _customerNameController.text.trim(),
            'phone': _phoneController.text.trim(),
            'purity': _purityController.text.trim(),
            'comments': _itemType == 'other' ? _commentsController.text.trim() : '',
            'dateTime': Timestamp.now(),
          });
        });

        _formKey.currentState!.reset();
        _weightController.clear();
        _priceController.clear();
        _customerNameController.clear();
        _phoneController.clear();
        _purityController.clear();
        _commentsController.clear();

        _showTransactionDialog(weight, price, total);
      } catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e')),
        );
      }
    }
  }

  void _showTransactionDialog(double weight, double price, double total) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) {
        return AlertDialog(
          title: const Text('Transaction Summary'),
          content: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildSummaryRow('Transaction Type:', _transactionType.toUpperCase()),
                _buildSummaryRow('Item Type:', _itemType.toUpperCase()),
                _buildSummaryRow('Weight (gm):', weight.toStringAsFixed(3)),
                _buildSummaryRow('Price per Gram (₹):', price.toStringAsFixed(2)),
                _buildSummaryRow('Total Amount (₹):', total.toStringAsFixed(2)),
                if (_customerNameController.text.trim().isNotEmpty)
                  _buildSummaryRow('Customer Name:', _customerNameController.text.trim()),
                if (_phoneController.text.trim().isNotEmpty)
                  _buildSummaryRow('Phone Number:', _phoneController.text.trim()),
                if (_purityController.text.trim().isNotEmpty)
                  _buildSummaryRow('Purity:', _purityController.text.trim()),
                if (_itemType == 'other' && _commentsController.text.trim().isNotEmpty)
                  _buildSummaryRow('Comments:', _commentsController.text.trim()),
                const SizedBox(height: 10),
                const Divider(),
                const SizedBox(height: 10),
                const Text(
                  'Please review the above details carefully.',
                  style: TextStyle(fontStyle: FontStyle.italic),
                ),
              ],
            ),
          ),
          actions: [
            Center(
              child: ElevatedButton(
                onPressed: () => Navigator.pop(context),
                style: ElevatedButton.styleFrom(
                  minimumSize: const Size(100, 45),
                ),
                child: const Text('Close'),
              ),
            ),
          ],
        );
      },
    );
  }

  Widget _buildSummaryRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            flex: 3,
            child: Text(
              label,
              style: const TextStyle(fontWeight: FontWeight.w600),
            ),
          ),
          Expanded(
            flex: 4,
            child: Text(value),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Add Transaction')),
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [Colors.blue.shade100, Colors.blue.shade50],
          ),
        ),
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Form(
            key: _formKey,
            child: ListView(
              children: [
                DropdownButtonFormField<String>(
                  value: _transactionType,
                  items: ['buy', 'sell'].map((type) {
                    return DropdownMenuItem(
                      value: type,
                      child: Text(type.toUpperCase()),
                    );
                  }).toList(),
                  onChanged: (value) => setState(() => _transactionType = value!),
                  decoration: const InputDecoration(labelText: 'Transaction Type'),
                ),
                const SizedBox(height: 16),
                DropdownButtonFormField<String>(
                  value: _itemType,
                  items: ['gold', 'silver', 'other'].map((item) {
                    return DropdownMenuItem(
                      value: item,
                      child: Text(item.toUpperCase()),
                    );
                  }).toList(),
                  onChanged: (value) => setState(() => _itemType = value!),
                  decoration: const InputDecoration(labelText: 'Item Type'),
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: _weightController,
                  keyboardType: const TextInputType.numberWithOptions(decimal: true),
                  inputFormatters: [
                    FilteringTextInputFormatter.allow(RegExp(r'^\d*\.?\d{0,3}'))
                  ],
                  decoration: const InputDecoration(labelText: 'Weight (gm)'),
                  validator: (value) =>
                  value == null || value.isEmpty ? 'Enter weight' : null,
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: _priceController,
                  keyboardType: const TextInputType.numberWithOptions(decimal: true),
                  inputFormatters: [
                    FilteringTextInputFormatter.allow(RegExp(r'^\d*\.?\d{0,2}'))
                  ],
                  decoration: const InputDecoration(labelText: 'Price per gram (₹)'),
                  validator: (value) =>
                  value == null || value.isEmpty ? 'Enter price' : null,
                ),
                const SizedBox(height: 16),
                Text(
                  'Total Amount: ₹ ${_totalAmount.toStringAsFixed(2)}',
                  style: const TextStyle(fontSize: 16),
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: _customerNameController,
                  decoration: const InputDecoration(labelText: 'Customer Name'),
                ),
                const SizedBox(height: 16),
                if (_itemType == 'gold' || _itemType == 'silver' || _itemType == 'other')
                  TextFormField(
                    controller: _purityController,
                    decoration:
                    const InputDecoration(labelText: 'Purity (e.g., 99.9%)'),
                    validator: (value) {
                      if ((_itemType == 'gold' || _itemType == 'silver' || _itemType == 'other') &&
                          (value == null || value.trim().isEmpty)) {
                        return 'Purity is required';
                      }
                      return null;
                    },
                  ),
                if (_itemType == 'other') ...[
                  const SizedBox(height: 16),
                  TextFormField(
                    controller: _commentsController,
                    decoration: const InputDecoration(
                      labelText: 'Comments / Additional Description',
                      hintText: 'e.g., 22K gold coin, processed',
                    ),
                    validator: (value) {
                      if (_itemType == 'other' && (value == null || value.trim().isEmpty)) {
                        return 'Comments are required for "Other"';
                      }
                      return null;
                    },
                  ),
                ],
                const SizedBox(height: 16),
                TextFormField(
                  controller: _phoneController,
                  keyboardType: TextInputType.phone,
                  decoration:
                  const InputDecoration(labelText: 'Phone Number (optional)'),
                ),
                const SizedBox(height: 24),
                ElevatedButton(
                  style: ElevatedButton.styleFrom(minimumSize: const Size(250, 50)),
                  onPressed: _submitTransaction,
                  child: const Text('Submit', style: TextStyle(fontSize: 20)),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}