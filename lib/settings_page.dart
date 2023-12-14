import 'package:appointments/sign_in_screen.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:url_launcher/url_launcher.dart';

class SettingsPage extends StatelessWidget {
  const SettingsPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF161229),
      appBar: AppBar(
        title: const Text('Settings'),
        backgroundColor: const Color(0xFF7B86E2),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () {
            Navigator.pop(context);
          },
        ),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildSettingsItem(
              'Account Settings',
              Icons.account_circle,
              () {
                // Navigate to account settings page
              },
            ),
            _buildSettingsItem(
              'Notifications',
              Icons.notifications,
              () {
                // Navigate to notifications page
              },
            ),
            _buildSettingsItem(
              'About',
              Icons.info,
              () {
                // Navigate to about page
              },
            ),
            _buildSettingsItem(
              'Rate the App',
              Icons.star,
              () {
                // Navigate to rate the app page
              },
            ),
            _buildSettingsItem(
              'More Apps',
              Icons.apps,
              () async {
                const url =
                    'https://play.google.com/store/apps/dev?id=7010355545573406247&pli=1';
                final Uri uri = Uri.parse(url);
                if (await canLaunchUrl(uri)) {
                  await launchUrl(uri);
                } else {
                  throw 'Could not launch $url';
                }
              },
            ),
            _buildSettingsItem(
              'Logout',
              Icons.exit_to_app,
              () async {
                try {
                  await FirebaseAuth.instance.signOut();
                  await GoogleSignIn().signOut();

                  if (context.mounted) {
                    Navigator.pushReplacement(
                      context,
                      MaterialPageRoute(
                        builder: (context) => const SignInScreen(),
                      ),
                    );
                  }
                } catch (e) {
                  // ignore: avoid_print
                  print("Error during sign out: $e");
                }
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSettingsItem(String title, IconData icon, Function() onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.only(bottom: 16.0),
        padding: const EdgeInsets.all(16.0),
        decoration: BoxDecoration(
          color: const Color(0xFF7B86E2),
          borderRadius: BorderRadius.circular(8.0),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Row(
              children: [
                Icon(
                  icon,
                  color: Colors.white,
                ),
                const SizedBox(width: 16.0),
                Text(
                  title,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 16.0,
                  ),
                ),
              ],
            ),
            const Icon(
              Icons.arrow_forward_ios,
              color: Colors.white,
            ),
          ],
        ),
      ),
    );
  }
}
