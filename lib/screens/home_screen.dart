import 'dart:async';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:skproject/auth_sevice/auth_service.dart';
import 'package:skproject/screens/add_transaction_screen.dart';
import 'package:skproject/screens/admin_dashboard_screen.dart';
import 'package:skproject/screens/balance_entry_screen.dart';
import 'package:skproject/screens/create_staff_screen.dart';
import 'package:skproject/screens/customer_history_screen.dart';
import 'package:skproject/screens/daily_summary_screen.dart';
import 'package:skproject/screens/export_screen.dart';
import 'package:skproject/screens/manage_staff_accounts.dart';
import 'package:skproject/screens/monthly_summary_screen.dart';
import 'package:skproject/screens/transactions_history.dart';
import 'package:skproject/screens/welcome_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  bool _isLoading = false;
  String _currentTime = '';
  String _todayLabel = '';
  String _userRole = '';

  Timer? _clock;
  StreamSubscription<DocumentSnapshot<Map<String, dynamic>>>? _balanceSubscription;

  double _opGold = 0;
  double _opSilver = 0;
  double _opCash = 0;

  double _clGold = 0;
  double _clSilver = 0;
  double _clCash = 0;

  /// Returns today's Firestore document key, e.g. "2025-06-02"
  String get todayKey => DateFormat('yyyy-MM-dd').format(DateTime.now());

  @override
  void initState() {
    super.initState();
    _startClock();
    _loadUserRoleAndListenBalances();
  }

  @override
  void dispose() {
    _clock?.cancel();
    _balanceSubscription?.cancel();
    super.dispose();
  }

  void _startClock() {
    _updateDateTime();
    _clock = Timer.periodic(const Duration(seconds: 1), (_) => _updateDateTime());
  }

  void _updateDateTime() {
    if (!mounted) return;
    setState(() {
      _currentTime = DateFormat('hh:mm:ss a').format(DateTime.now());
      _todayLabel = DateFormat('dd MMMM yyyy').format(DateTime.now());
    });
  }

  Future<void> _loadUserRoleAndListenBalances() async {
    // 1) Load userRole from SharedPreferences
    final prefs = await SharedPreferences.getInstance();
    _userRole = prefs.getString('userRole') ?? '';

    // 2) Ensure today's daily_balances document exists (if not, create it from yesterday)
    final todayDocRef = FirebaseFirestore.instance.collection('daily_balances').doc(todayKey);
    final todaySnapshot = await todayDocRef.get();
    if (!todaySnapshot.exists) {
      // Fetch yesterday's closing balances
      final yesterdayKey = DateFormat('yyyy-MM-dd').format(DateTime.now().subtract(const Duration(days: 1)));
      final yesterdayDoc = await FirebaseFirestore.instance.collection('daily_balances').doc(yesterdayKey).get();
      final yData = yesterdayDoc.data() ?? {};

      // Build the initial structure for today
      final initialData = {
        'date': Timestamp.now(),
        'openingGold': (yData['closingGold'] ?? 0.0).toDouble(),
        'openingSilver': (yData['closingSilver'] ?? 0.0).toDouble(),
        'openingCash': (yData['closingCash'] ?? 0.0).toDouble(),
        'closingGold': (yData['closingGold'] ?? 0.0).toDouble(),
        'closingSilver': (yData['closingSilver'] ?? 0.0).toDouble(),
        'closingCash': (yData['closingCash'] ?? 0.0).toDouble(),
      };
      await todayDocRef.set(initialData);
    }

    // 3) Subscribe to real-time updates on today's daily_balances doc
    _balanceSubscription = FirebaseFirestore.instance
        .collection('daily_balances')
        .doc(todayKey)
        .snapshots()
        .listen((snapshot) {
      if (snapshot.exists && mounted) {
        final data = snapshot.data()!;
        setState(() {
          _opGold = (data['openingGold'] ?? 0.0).toDouble();
          _opSilver = (data['openingSilver'] ?? 0.0).toDouble();
          _opCash = (data['openingCash'] ?? 0.0).toDouble();

          _clGold = (data['closingGold'] ?? 0.0).toDouble();
          _clSilver = (data['closingSilver'] ?? 0.0).toDouble();
          _clCash = (data['closingCash'] ?? 0.0).toDouble();
        });
      }
    });
  }

  Future<void> _logout() async {
    setState(() => _isLoading = true);
    try {
      await AuthService.logout();
      if (!mounted) return;
      Navigator.of(context).pushAndRemoveUntil(
        MaterialPageRoute(builder: (_) => const WelcomeScreen()),
            (_) => false,
      );
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Widget _balanceLine(String label, double amount, {String unit = 'g', bool isCash = false}) {
    final formatted = isCash
        ? '₹${amount.toStringAsFixed(2)}'
        : '${amount.toStringAsFixed(2)} $unit';
    return Text(
      '$label: $formatted',
      style: TextStyle(fontSize: 14, color: Colors.grey[800]),
    );
  }

  @override
  Widget build(BuildContext context) {
    final adminCards = [
      {
        'title': 'Admin Dashboard',
        'icon': Icons.dashboard,
        'onTap': () => Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => const AdminDashboard()),
        ),
      },
      {
        'title': 'Add Transaction',
        'icon': Icons.add_box,
        'onTap': () => Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => const AddTransactionScreen()),
        ),
      },
      {
        'title': 'Monthly Summary',
        'icon': Icons.summarize,
        'onTap': () => Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => const MonthlyReportScreen()),
        ),
      },
      {
        'title': 'Daily Summary',
        'icon': Icons.assessment,
        'onTap': () => Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => const DailySummaryScreen()),
        ),
      },
      {
        'title': 'Daily Transactions History',
        'icon': Icons.history,
        'onTap': () => Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => const ViewTransactionsScreen()),
        ),
      },
      {
        'title': 'Customer History',
        'icon': Icons.person_search,
        'onTap': () => Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => const CustomerHistoryScreen()),
        ),
      },
      {
        'title': 'Export History',
        'icon': Icons.download,
        'onTap': () => Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => const ExportScreen()),
        ),
      },
      {
        'title': 'Balance Entry',
        'icon': Icons.account_balance_wallet,
        'onTap': () => Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => const BalanceEntryScreen()),
        ),
      },
      {
        'title': 'Create Staff Accounts',
        'icon': Icons.account_box,
        'onTap': () => Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => const CreateStaffScreen()),
        ),
      },
      {
        'title': 'Manage Staff Accounts',
        'icon': Icons.manage_accounts,
        'onTap': () => Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => const ManageStaffScreen()),
        ),
      },
    ];

    final staffCards = [
      {
        'title': 'Add Transaction',
        'icon': Icons.add_box,
        'onTap': () => Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => const AddTransactionScreen()),
        ),
      }
    ];

    final cardsToShow = _userRole == 'admin' ? adminCards : staffCards;

    return Scaffold(
      appBar: AppBar(
        title: const Text("Gold & Silver Dashboard"),
        actions: [
          _isLoading
              ? const Padding(
            padding: EdgeInsets.all(10.0),
            child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2),
          )
              : IconButton(
            icon: const Icon(Icons.logout),
            onPressed: _logout,
            tooltip: 'Logout',
          ),
        ],
      ),
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [Colors.blue.shade200, Colors.blue.shade100],
          ),
        ),
        child: LayoutBuilder(
          builder: (context, constraints) {
            final availableHeight = constraints.maxHeight;
            return SingleChildScrollView(
              child: ConstrainedBox(
                constraints: BoxConstraints(minHeight: availableHeight),
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    children: [
                      LayoutBuilder(
                        builder: (context, innerConstraints) {
                          // Narrow screen: stacked
                          if (innerConstraints.maxWidth < 600) {
                            return Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                // Date & Time
                                Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      "Today: $_todayLabel",
                                      style: const TextStyle(
                                          fontSize: 18, fontWeight: FontWeight.w500),
                                    ),
                                    const SizedBox(height: 4),
                                    Text(
                                      "Time: $_currentTime",
                                      style:
                                      TextStyle(fontSize: 16, color: Colors.grey[700]),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 16),
                                // Balances
                                Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    const Text(
                                      "Opening Balance",
                                      style: TextStyle(
                                          fontSize: 16, fontWeight: FontWeight.w500),
                                    ),
                                    const SizedBox(height: 4),
                                    _balanceLine("Gold", _opGold),
                                    _balanceLine("Silver", _opSilver),
                                    _balanceLine("Cash", _opCash, isCash: true),
                                    const SizedBox(height: 12),
                                    const Text(
                                      "Closing Balance",
                                      style: TextStyle(
                                          fontSize: 16, fontWeight: FontWeight.w500),
                                    ),
                                    const SizedBox(height: 4),
                                    _balanceLine("Gold", _clGold),
                                    _balanceLine("Silver", _clSilver),
                                    _balanceLine("Cash", _clCash, isCash: true),
                                  ],
                                ),
                              ],
                            );
                          } else {
                            // Wide screen: side‐by‐side
                            return Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                // Left: Date & Time
                                Expanded(
                                  flex: 1,
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        "Today: $_todayLabel",
                                        style: const TextStyle(
                                            fontSize: 18, fontWeight: FontWeight.w500),
                                      ),
                                      const SizedBox(height: 4),
                                      Text(
                                        "Time: $_currentTime",
                                        style: TextStyle(
                                            fontSize: 16, color: Colors.grey[700]),
                                      ),
                                    ],
                                  ),
                                ),
                                const SizedBox(width: 16),
                                // Right: Balances
                                Expanded(
                                  flex: 1,
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.end,
                                    children: [
                                      const Text(
                                        "Opening Balance",
                                        style: TextStyle(
                                            fontSize: 16, fontWeight: FontWeight.w500),
                                      ),
                                      const SizedBox(height: 4),
                                      Text(
                                        "Gold: ${_opGold.toStringAsFixed(3)} g | Silver: ${_opSilver.toStringAsFixed(3)} g | Cash: ₹${_opCash.toStringAsFixed(2)}",
                                        style: TextStyle(
                                            fontSize: 14, color: Colors.grey[800]),
                                        textAlign: TextAlign.end,
                                      ),
                                      const SizedBox(height: 12),
                                      const Text(
                                        "Closing Balance",
                                        style: TextStyle(
                                            fontSize: 16, fontWeight: FontWeight.w500),
                                      ),
                                      const SizedBox(height: 4),
                                      Text(
                                        "Gold: ${_clGold.toStringAsFixed(3)} g | Silver: ${_clSilver.toStringAsFixed(3)} g | Cash: ₹${_clCash.toStringAsFixed(2)}",
                                        style: TextStyle(
                                            fontSize: 14, color: Colors.grey[800]),
                                        textAlign: TextAlign.end,
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            );
                          }
                        },
                      ),
                      const SizedBox(height: 150),
                      // ───────────────── Dashboard Grid ─────────────────
                      LayoutBuilder(
                        builder: (context, gridConstraints) {
                          int crossAxisCount = gridConstraints.maxWidth >= 1200
                              ? 4
                              : gridConstraints.maxWidth >= 800
                              ? 3
                              : 2;
                          double maxCardWidth = 240.0;

                          return Center(
                            child: Container(
                              constraints: BoxConstraints(
                                maxWidth: maxCardWidth * crossAxisCount +
                                    (crossAxisCount - 1) * 16.0,
                              ),
                              child: GridView.count(
                                crossAxisCount: crossAxisCount,
                                crossAxisSpacing: 16,
                                mainAxisSpacing: 16,
                                childAspectRatio: 1.2,
                                shrinkWrap: true,
                                physics: const NeverScrollableScrollPhysics(),
                                children: cardsToShow
                                    .map((card) => _buildDashboardCard(
                                  context,
                                  title: card['title'] as String,
                                  icon: card['icon'] as IconData,
                                  onTap: card['onTap'] as VoidCallback,
                                ))
                                    .toList(),
                              ),
                            ),
                          );
                        },
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

  Widget _buildDashboardCard(
      BuildContext context, {
        required String title,
        required IconData icon,
        required VoidCallback onTap,
      }) {
    return InkWell(
      onTap: onTap,
      child: Card(
        elevation: 10,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        child: Center(
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(icon, size: 48, color: Theme.of(context).primaryColor),
                const SizedBox(height: 16),
                Text(
                  title,
                  style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w500),
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}