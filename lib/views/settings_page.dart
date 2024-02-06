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
        title: const Text('Settings',
            style: TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.bold,
            )),
        backgroundColor: const Color(0xFF7B86E2),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () {
            Navigator.of(context).pushReplacementNamed('/');
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
                if (context.mounted) {
                  Navigator.of(context).pushReplacementNamed('/accountSettings',
                      arguments: {'source': 'settings'});
                }
              },
            ),
            _buildSettingsItem(
              'Notifications',
              Icons.notifications,
              () {
                if (context.mounted) {
                  Navigator.of(context).pushReplacementNamed('/notification');
                }
              },
            ),
            _buildSettingsItem(
              'Blocks',
              Icons.block,
              () {
                if (context.mounted) {
                  Navigator.of(context).pushReplacementNamed('/blockPage');
                }
              },
            ),
            _buildSettingsItem(
              'About',
              Icons.info,
              () {
                if (context.mounted) {
                  Navigator.of(context).pushReplacementNamed('/about',
                      arguments: {'source': 'settings'});
                }
              },
            ),
            _buildSettingsItem(
              'Rate the App',
              Icons.star,
              () async {
                const url =
                    'https://play.google.com/store/apps/details?id=com.orhava.appointments';
                final Uri uri = Uri.parse(url);
                if (await canLaunchUrl(uri)) {
                  await launchUrl(uri);
                } else {
                  throw 'Could not launch $url';
                }
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
                    Navigator.of(context).pushReplacementNamed('/signIn');
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
