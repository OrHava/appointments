import 'package:appointments/auth_views/sign_in_screen.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_web_browser/flutter_web_browser.dart';

class AccountSettingsPage extends StatelessWidget {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final TextEditingController _feedbackController = TextEditingController();

  AccountSettingsPage({Key? key, required this.source}) : super(key: key);
  final String source;
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: const Color(0xFF7B86E2),
        title: const Text('Account Settings',
            style: TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.bold,
            )),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () {
            if (source == 'businessHome') {
              Navigator.of(context).pushReplacementNamed('/businessHome');
            } else {
              Navigator.of(context).pushReplacementNamed('/settings');
            }
          },
        ),
      ),
      backgroundColor: const Color(0xFF161229),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildSettingsItem('Change Password', Icons.lock, () async {
                await _changePassword(context);
              }),
              _buildSettingsItem('Delete Account', Icons.delete, () async {
                bool confirm = await _showDeleteConfirmationDialog(context);
                if (confirm && context.mounted) {
                  await _deleteAccount(context);
                }
              }),
              _buildSettingsItem('Send Feedback & Support', Icons.feedback, () {
                _showFeedbackForm(context);
              }),
              const SizedBox(height: 16),
              _buildTermsAndPrivacyButtons(context),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _changePassword(BuildContext context) async {
    try {
      await _auth.sendPasswordResetEmail(email: _auth.currentUser!.email!);
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Password reset email sent. Check your email.'),
          ),
        );
      }
    } catch (error) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error: $error'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<bool> _showDeleteConfirmationDialog(BuildContext context) async {
    return await showDialog<bool>(
          context: context,
          builder: (BuildContext context) {
            return AlertDialog(
              title: const Text('Are you sure?'),
              content: const Text('This action cannot be undone.'),
              actions: [
                TextButton(
                  onPressed: () {
                    Navigator.of(context).pop(false);
                  },
                  child: const Text('Cancel'),
                ),
                TextButton(
                  onPressed: () {
                    Navigator.of(context).pop(true);
                  },
                  child: const Text('Delete'),
                ),
              ],
            );
          },
        ) ??
        false;
  }

  Future<void> _deleteAccount(BuildContext context) async {
    try {
      await _auth.currentUser!.delete();
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Account deleted successfully.'),
          ),
        );
      }

      // Navigate back to login screen or another screen after deletion
      if (context.mounted) {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(
            builder: (context) => const SignInScreen(),
          ),
        );
      }
    } catch (error) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error: $error'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Widget _buildTermsAndPrivacyButtons(BuildContext context) {
    return Center(
      child: Column(
        children: [
          _buildLinkButton('Terms of Service', () {
            _launchURL(
                'https://www.termsofservicegenerator.net/live.php?token=rcoONtPSNt6cCxP3PgH3Zdtk7Go3pmI2');
          }),
          const SizedBox(height: 8),
          _buildLinkButton('Privacy Policy', () {
            _launchURL(
                'https://www.termsfeed.com/live/6e06beb2-019b-4053-8e80-8d08fe5644b5');
          }),
        ],
      ),
    );
  }

  Widget _buildLinkButton(String label, VoidCallback onPressed) {
    return ElevatedButton(
      style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF7B86E2)),
      onPressed: onPressed,
      child: Text(label),
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

  void _showFeedbackForm(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) {
        return ClipRect(
          child: Align(
            alignment: Alignment.topCenter,
            child: AlertDialog(
              content: SingleChildScrollView(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    const Text(
                      'Provide Feedback & Support',
                      style:
                          TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 16),
                    TextField(
                      controller: _feedbackController,
                      maxLines: 5,
                      decoration: const InputDecoration(
                        labelText: 'Your Feedback',
                        border: OutlineInputBorder(),
                      ),
                    ),
                    const SizedBox(height: 16),
                    ElevatedButton(
                      style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF7B86E2)),
                      onPressed: () {
                        _sendFeedback(context);
                      },
                      child: const Text('Send Feedback'),
                    ),
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  void _sendFeedback(BuildContext context) {
    String feedbackText = _feedbackController.text.trim();

    // Get the current user's ID
    String currentUserUid = _auth.currentUser!.uid;

    // Reference to the feedback node in the database
    DatabaseReference feedbackRef =
        FirebaseDatabase.instance.ref().child('feedback');

    // Generate a unique key for each feedback entry
    String feedbackKey = feedbackRef.push().key!;

    // Create a map to represent the feedback entry
    Map<String, dynamic> feedbackData = {
      'userId': currentUserUid,
      'text': feedbackText,
      'timestamp':
          ServerValue.timestamp, // Use server timestamp for accurate timing
    };

    // Update the database with the feedback
    feedbackRef.child(feedbackKey).set(feedbackData);

    // Close the feedback form
    Navigator.pop(context);
  }

  void _launchURL(String url) async {
    await FlutterWebBrowser.openWebPage(url: url);
  }
}
