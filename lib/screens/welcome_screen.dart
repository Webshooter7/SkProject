import 'package:flutter/material.dart';
import 'login_screen.dart';

class WelcomeScreen extends StatelessWidget {
  const WelcomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Welcome to Gold & Silver Portal"),
      ),
      body: LayoutBuilder(
        builder: (context, constraints) {
          bool useHorizontalLayout = constraints.maxWidth > 800;

          return Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [Colors.blue.shade200, Colors.blue.shade100],
              ),
            ),
            child: Center(
              child: SingleChildScrollView(
                child: Padding(
                  padding: const EdgeInsets.all(24.0),
                  child: Column(
                    children: [
                      const SizedBox(height: 20),
                      SingleChildScrollView(
                        scrollDirection: Axis.horizontal,
                        child: Flex(
                          direction: useHorizontalLayout
                              ? Axis.horizontal
                              : Axis.vertical,
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            _buildRoleCard(
                              context,
                              role: "Admin",
                              imagePath: "images/admin_image.png",
                              onPressed: () {
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (context) => const LoginScreen(role: "admin"),
                                  ),
                                );
                              },
                            ),
                            SizedBox(
                              width: useHorizontalLayout ? 300 : 0,
                              height: useHorizontalLayout ? 0 : 24,
                            ),
                            _buildRoleCard(
                              context,
                              role: "Staff",
                              imagePath: "images/staff_image.png",
                              onPressed: () {
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (context) => const LoginScreen(role: "staff"),
                                  ),
                                );
                              },
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            )
          );
        },
      ),
    );
  }

  Widget _buildRoleCard(
      BuildContext context, {
        required String role,
        required String imagePath,
        required VoidCallback onPressed,
      }) {
    return Card(
      color: Colors.blue.shade50,
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      child: Container(
        padding: const EdgeInsets.all(20),
        width: 350,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              height: 350,
              width: 350,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
              ),
              child: ClipOval(
                child: Image.asset(
                  imagePath,
                  fit: BoxFit.cover,
                ),
              ),
            ),
            const SizedBox(height: 16),
            Text(
              role,
              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: 8),
            ElevatedButton(
              onPressed: onPressed,
              child: Text("Login"),
            ),
          ],
        ),
      ),
    );
  }
}
