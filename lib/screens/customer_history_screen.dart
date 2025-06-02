import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

class CustomerHistoryScreen extends StatefulWidget {
  const CustomerHistoryScreen({Key? key}) : super(key: key);

  @override
  State<CustomerHistoryScreen> createState() => _CustomerHistoryScreenState();
}

class _CustomerHistoryScreenState extends State<CustomerHistoryScreen> {
  final TextEditingController _searchController = TextEditingController();
  List<DocumentSnapshot> _filteredTransactions = [];
  bool _isLoading = false;
  String _searchQuery = '';
  String _customerNameDisplay = '';

  Future<void> _searchTransactions() async {
    final query = _searchController.text.trim().toLowerCase();
    if (query.isEmpty) return;

    setState(() {
      _isLoading = true;
      _searchQuery = query;
      _customerNameDisplay = '';
    });

    final sixMonthsAgo = DateTime.now().subtract(const Duration(days: 180));

    final snapshot = await FirebaseFirestore.instance
        .collection('transactions')
        .orderBy('dateTime', descending: true)
        .get();

    _filteredTransactions = snapshot.docs.where((doc) {
      final data = doc.data();
      final name = (data['customerName'] ?? '').toString().toLowerCase();
      final phone = (data['phone'] ?? '').toString().toLowerCase();
      final date = (data['dateTime'] as Timestamp).toDate();
      return (name.contains(query) || phone.contains(query)) && date.isAfter(sixMonthsAgo);
    }).toList();

    if (_filteredTransactions.isNotEmpty) {
      final firstData = _filteredTransactions.first.data() as Map<String, dynamic>;
      _customerNameDisplay = firstData['customerName'] ?? '';
    }

    setState(() {
      _isLoading = false;
    });
  }

  Widget _buildTransactionTable() {
    if (_filteredTransactions.isEmpty) {
      return const Padding(
        padding: EdgeInsets.all(32),
        child: Center(
          child: Text(
            'No transactions found for this customer.',
            style: TextStyle(fontSize: 16),
          ),
        ),
      );
    }

    return Column(
      children: [
        Padding(padding: EdgeInsets.symmetric(vertical: 8),
          child: Text('Customer: $_customerNameDisplay', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),),
        ),
        Expanded(
          child: SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: SingleChildScrollView(
              scrollDirection: Axis.vertical,
              child: DataTable(
                headingRowColor: MaterialStateProperty.all(Color(0xFF29B6f6)),
                columns: const [
                  DataColumn(label: Text('Date', style: TextStyle(color: Colors.white),)),
                  DataColumn(label: Text('Type', style: TextStyle(color: Colors.white),)),
                  DataColumn(label: Text('Item', style: TextStyle(color: Colors.white),)),
                  DataColumn(label: Text('Weight', style: TextStyle(color: Colors.white),)),
                  DataColumn(label: Text('Rate', style: TextStyle(color: Colors.white),)),
                  DataColumn(label: Text('Total', style: TextStyle(color: Colors.white),)),
                  DataColumn(label: Text('Purity', style: TextStyle(color: Colors.white),)),
                  DataColumn(label: Text('Comments', style: TextStyle(color: Colors.white),)),
                ],
                rows: _filteredTransactions.map((doc) {
                  final data = doc.data() as Map<String, dynamic>;
                  return DataRow(
                    cells: [
                      DataCell(Text(DateFormat('dd/MM/yyyy – hh:mm a').format((data['dateTime'] as Timestamp).toDate()))),
                      DataCell(Text(data['type'] ?? '')),
                      DataCell(Text(data['item'] ?? '')),
                      DataCell(Text('${data['weight'] ?? 0}g')),
                      DataCell(Text('₹${(data['pricePerGram'] ?? 0).toStringAsFixed(3)}')),
                      DataCell(Text('₹${(data['totalAmount'] ?? 0).toStringAsFixed(2)}')),
                      DataCell(Text(data['purity'] ?? '')),
                      DataCell(Text(data['comments'] ?? '-')),
                    ],
                  );
                }).toList(),
              ),
            ),
          ),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Customer Transaction History'),
        backgroundColor: const Color(0xFF29B6F6),
      ),
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
          child: Column(
            children: [
              TextField(
                controller: _searchController,
                decoration: InputDecoration(
                  labelText: 'Enter Customer Name or Phone',
                  border: const OutlineInputBorder(),
                  suffixIcon: IconButton(
                    icon: const Icon(Icons.search),
                    onPressed: _searchTransactions,
                  ),
                ),
                onSubmitted: (_) => _searchTransactions(),
              ),
              const SizedBox(height: 20),
              Expanded(
                child: _isLoading
                    ? const Center(child: CircularProgressIndicator())
                    : _buildTransactionTable(),
              ),
            ],
          ),
        ),
      ),
    );
  }
}