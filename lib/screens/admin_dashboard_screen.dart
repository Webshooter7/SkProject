import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:skproject/auth_sevice/auth_service.dart';

class AdminDashboard extends StatefulWidget {
  const AdminDashboard({Key? key}) : super(key: key);

  @override
  State<AdminDashboard> createState() => _AdminDashboardState();
}

class _AdminDashboardState extends State<AdminDashboard> {
  int totalTransactions = 0;
  double soldGold = 0.0;
  double soldSilver = 0.0;
  double totalRevenue = 0.0;
  double totalProfit = 0;
  double goldBought = 0;
  double silverBought = 0;
  double totalCost = 0.0;

  @override
  void initState() {
    super.initState();
    _loadSummaryData();
  }

  Future<void> _loadSummaryData() async {
    final now = DateTime.now();
    final sixMonthsAgo = DateTime(now.year, now.month - 6, now.day);

    final snapshot = await FirebaseFirestore.instance
        .collection('transactions')
        .where('dateTime', isGreaterThanOrEqualTo: Timestamp.fromDate(sixMonthsAgo))
        .get();

    double gold = 0;
    double silver = 0;
    double revenue = 0;
    double cost = 0;

    for (var doc in snapshot.docs) {
      final data = doc.data();
      final item = (data['item'] ?? '').toString().toLowerCase();
      final amount = (data['totalAmount'] ?? 0).toDouble();
      final weight = (data['weight'] ?? 0).toDouble();
      final type = (data['type'] ?? '').toString().toLowerCase();

      if (type == 'sell') {
        revenue += amount;
        if (item == 'gold') gold += weight;
        if (item == 'silver') silver += weight;
      } else if (type == 'buy') {
        cost += amount;
        if (item == 'gold') goldBought += weight;
        if (item == 'silver') silverBought += weight;
      }
    }

    setState(() {
      totalTransactions = snapshot.docs.length;
      soldGold = gold;
      soldSilver = silver;
      totalRevenue = revenue;
      totalProfit = revenue - cost;
      totalCost = cost;
      goldBought = goldBought;
      silverBought = silverBought;
    });
  }


  Widget _buildSummaryCard(String label, String value, IconData icon, Color color) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Container(
        padding: const EdgeInsets.all(16),
        width: 250,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(icon, color: color, size: 32),
            const SizedBox(height: 12),
            Text(label, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w500)),
            const SizedBox(height: 4),
            Text(value, style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<String?>(
      future: AuthService.getSavedUserRole(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }

        if (snapshot.data != 'admin') {
          return const Scaffold(
            body: Center(
              child: Text(
                'Access Denied. Admins only.',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.w500),
              ),
            ),
          );
        }

        return Scaffold(
          appBar: AppBar(
            title: const Text('Admin Dashboard'),
            backgroundColor: const Color(0xFF29B6F6),
            elevation: 0,
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
            child: Center(
              child: SingleChildScrollView(
                child: Center(
                  child: Wrap(
                    alignment: WrapAlignment.center,
                    spacing: 20,
                    runSpacing: 20,
                    children: [
                      _buildSummaryCard('Total Transactions', '$totalTransactions', Icons.receipt_long, Colors.teal),
                      _buildSummaryCard('Gold Sold (g)', soldGold.toStringAsFixed(3), Icons.star, Colors.amber.shade700),
                      _buildSummaryCard('Silver Sold (g)', soldSilver.toStringAsFixed(3), Icons.circle, Colors.grey),
                      _buildSummaryCard('Gold Bought (g)', goldBought.toStringAsFixed(3), Icons.star_border, Colors.amber.shade400),
                      _buildSummaryCard('Silver Bought (g)', silverBought.toStringAsFixed(3), Icons.circle_outlined, Colors.grey.shade400),
                      _buildSummaryCard('Total Cost', '₹${totalCost.toStringAsFixed(2)}', Icons.money_off, Colors.red),
                      _buildSummaryCard('Net Loss', totalCost > totalRevenue ? '₹${(totalCost - totalRevenue).toStringAsFixed(2)}' : '₹0.00', Icons.trending_down, Colors.deepOrange),
                      _buildSummaryCard('Total Revenue', '₹${totalRevenue.toStringAsFixed(2)}', Icons.attach_money, Colors.green),
                      _buildSummaryCard('Net Profit', '₹${totalProfit.toStringAsFixed(2)}', Icons.trending_up, Colors.deepPurple),
                    ],
                  ),
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}
