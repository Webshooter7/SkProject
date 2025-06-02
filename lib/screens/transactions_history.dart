import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

class ViewTransactionsScreen extends StatelessWidget {
  const ViewTransactionsScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('All Transactions'),
        backgroundColor: const Color(0xFF29B6F6),
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.white),
        titleTextStyle: const TextStyle(
          color: Colors.white,
          fontSize: 20,
          fontWeight: FontWeight.w500,
        ),
      ),
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [Colors.blue.shade100, Colors.blue.shade50],
          ),
        ),
        child: StreamBuilder<QuerySnapshot>(
          stream: FirebaseFirestore.instance
              .collection('transactions')
              .where('dateTime', isGreaterThanOrEqualTo: Timestamp.fromDate(DateTime.now().subtract(const Duration(days: 180)),),)
              .orderBy('dateTime', descending: true)
              .snapshots(),
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Center(
                child: CircularProgressIndicator(
                  valueColor: AlwaysStoppedAnimation<Color>(Color(0xFF29B6F6)),
                ),
              );
            }

            if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
              return Center(
                child: Card(
                  margin: const EdgeInsets.all(16),
                  elevation: 2,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Padding(
                    padding: EdgeInsets.all(24),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          Icons.receipt_long,
                          size: 64,
                          color: Color(0xFF757575),
                        ),
                        SizedBox(height: 16),
                        Text(
                          'No transactions found',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.w600,
                            color: Color(0xFF424242),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              );
            }

            final transactions = snapshot.data!.docs;

            return Center(
              child: Container(
                constraints: const BoxConstraints(maxWidth: 1200), // Maximum width for the table
                margin: const EdgeInsets.all(16),
                child: Card(
                  elevation: 2,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(16),
                        decoration: const BoxDecoration(
                          color: Color(0xFF29B6F6),
                          borderRadius: BorderRadius.only(
                            topLeft: Radius.circular(8),
                            topRight: Radius.circular(8),
                          ),
                        ),
                        child: Text(
                          'Transaction History (${transactions.length} records)',
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                      Flexible(
                        child: LayoutBuilder(builder: (context, constraints) {
                          final containerWidth = constraints.maxWidth;
                          return SingleChildScrollView(
                            scrollDirection: Axis.horizontal,
                            child: ConstrainedBox(
                              constraints: BoxConstraints(minWidth: containerWidth),
                              child: DataTable(
                                headingRowColor: MaterialStateProperty.all(
                                  const Color(0xFF4FC3F7).withOpacity(0.1),
                                ),
                                headingTextStyle: const TextStyle(
                                  fontWeight: FontWeight.w600,
                                  color: Color(0xFF424242),
                                ),
                                dataTextStyle: const TextStyle(
                                  color: Color(0xFF424242),
                                ),
                                columnSpacing: 24,
                                columns: const [
                                  DataColumn(
                                    label: Text('S.No'),
                                    numeric: true,
                                  ),
                                  DataColumn(
                                    label: Text('Date & Time'),
                                    tooltip: 'Transaction date and time',
                                  ),
                                  DataColumn(
                                    label: Text('Type'),
                                    tooltip: 'Transaction type',
                                  ),
                                  DataColumn(
                                    label: Text('Item'),
                                    tooltip: 'Item name',
                                  ),
                                  DataColumn(
                                    label: Text('Weight'),
                                    tooltip: 'Weight in grams',
                                  ),
                                  DataColumn(
                                    label: Text('Rate'),
                                    tooltip: 'Price per gram',
                                  ),
                                  DataColumn(
                                    label: Text('Total'),
                                    tooltip: 'Total amount',
                                  ),
                                  DataColumn(
                                    label: Text('Customer'),
                                    tooltip: 'Customer name',
                                  ),
                                  DataColumn(
                                    label: Text('Phone'),
                                    tooltip: 'Customer phone number',
                                  ),
                                  DataColumn(
                                    label: Text('Purity'),
                                    tooltip: 'Gold purity',
                                  ),
                                  DataColumn(
                                    label: Text('Comments'),
                                  ),
                                ],
                                rows: transactions.asMap().entries.map((entry) {
                                  final index = entry.key;
                                  final doc = entry.value;
                                  final data = doc.data() as Map<String, dynamic>;

                                  return DataRow(
                                    cells: [
                                      DataCell(Text('${index + 1}')),
                                      DataCell(
                                        Text(
                                          DateFormat('dd/MM/yyyy\nhh:mm a').format(
                                            (data['dateTime'] as Timestamp).toDate(),
                                          ),
                                        ),
                                      ),
                                      DataCell(
                                        Container(
                                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                          decoration: BoxDecoration(
                                            color: (data['type'] ?? '').toLowerCase() == 'sell'
                                                ? Colors.green.withOpacity(0.1)
                                                : Colors.red.withOpacity(0.1),
                                            borderRadius: BorderRadius.circular(4),
                                          ),
                                          child: Text(
                                            data['type'] ?? '',
                                            style: TextStyle(
                                              color: (data['type'] ?? '').toLowerCase() == 'sell'
                                                  ? Colors.green.shade700
                                                  : Colors.red.shade700,
                                              fontWeight: FontWeight.w500,
                                            ),
                                          ),
                                        ),
                                      ),
                                      DataCell(Text(data['item'] ?? '')),
                                      DataCell(Text('${data['weight'] ?? 0}g', style: const TextStyle(fontWeight: FontWeight.w500))),
                                      DataCell(Text('₹${data['pricePerGram'] ?? 0}', style: const TextStyle(fontWeight: FontWeight.w500))),
                                      DataCell(Text('₹${(data['totalAmount'] ?? 0).toStringAsFixed(2)}',
                                        style: const TextStyle(fontWeight: FontWeight.w600, color: Color(0xFF29B6F6)),
                                      )),
                                      DataCell(Text(data['customerName'] ?? '')),
                                      DataCell(Text(data['phone'] ?? '')),
                                      DataCell(
                                        Container(
                                          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                          decoration: BoxDecoration(
                                            color: const Color(0xFF29B6F6).withOpacity(0.1),
                                            borderRadius: BorderRadius.circular(4),
                                          ),
                                          child: Text(
                                            data['purity'] ?? '',
                                            style: const TextStyle(
                                              color: Color(0xFF29B6F6),
                                              fontWeight: FontWeight.w500,
                                              fontSize: 12,
                                            ),
                                          ),
                                        ),
                                      ),
                                      DataCell(Text(data['comments'] ?? '-------')),
                                    ],
                                  );
                                }).toList(),
                              ),
                            ),
                          );
                        }),
                      ),
                    ],
                  ),
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}