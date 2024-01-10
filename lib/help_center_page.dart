import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

class HelpCenterPage extends StatelessWidget {
  // Define your questions and corresponding YouTube video links here
  final List<Map<String, String>> faqs = [
    {
      'question': 'How to open a business page?',
      'videoLink': 'https://www.youtube.com/watch?v=Gwz0tQ8Lvwo',
    },
    {
      'question': 'How to make a appointment?',
      'videoLink': 'https://www.youtube.com/shorts/IBH-TQGNP30',
    },
    // Add more questions and links as needed
  ];

  HelpCenterPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF161229),
      appBar: AppBar(
        title: const Text('Help Center',
            style: TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.bold,
            )),
        backgroundColor: const Color(0xFF7B86E2),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () {
            Navigator.pop(context);
          },
        ),
      ),
      body: ListView.builder(
        itemCount: faqs.length,
        itemBuilder: (context, index) {
          return ListTile(
            title: Text(faqs[index]['question']!,
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                )),
            onTap: () {
              _launchYouTubeVideo(faqs[index]['videoLink']!);
            },
          );
        },
      ),
    );
  }

  Future<void> _launchYouTubeVideo(String url) async {
    final Uri uri = Uri.parse(url);
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri);
    } else {
      throw 'Could not launch $url';
    }
  }
}
