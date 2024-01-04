import 'package:flutter/material.dart';
import 'package:flutter_sequence_animation/flutter_sequence_animation.dart';

class AboutPage extends StatelessWidget {
  const AboutPage({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: const Color(0xFF7B86E2),
        title: const Text('About us'),
      ),
      backgroundColor: const Color(0xFF161229),
      body: const SingleChildScrollView(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // Improved Animated Logo Container
            PixarStyleIntro(),
            // App Description
            Padding(
              padding: EdgeInsets.all(16.0),
              child: Text(
                'Welcome to our Appointment App! Easily manage your appointments and stay organized on the go.',
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 18.0, color: Colors.white),
              ),
            ),

            Padding(
              padding: EdgeInsets.all(16.0),
              child: Text(
                'Version 1',
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 18.0, color: Colors.white),
              ),
            ),

            // Additional Information
            Padding(
              padding: EdgeInsets.all(16.0),
              child: Text(
                'Our mission is to simplify your life by providing a seamless and intuitive appointment management experience. Join us in making your daily schedule more manageable!',
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 16.0, color: Color(0xFF878493)),
              ),
            ),

            // Contact Information
            Padding(
              padding: EdgeInsets.all(16.0),
              child: Text(
                'Contact us at: or6562@gmail.com',
                style: TextStyle(fontSize: 16.0, color: Color(0xFF878493)),
              ),
            ),
            CoolAnimatedLogo(),
          ],
        ),
      ),
    );
  }
}

class CoolAnimatedLogo extends StatefulWidget {
  const CoolAnimatedLogo({super.key, Key? keys});

  @override
  CoolAnimatedLogoState createState() => CoolAnimatedLogoState();
}

class CoolAnimatedLogoState extends State<CoolAnimatedLogo>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _positionAnimation;
  late Animation<double> _rotationAnimation;

  bool _isPaused = false;

  @override
  void initState() {
    super.initState();

    _controller = AnimationController(
      duration: const Duration(seconds: 4),
      vsync: this,
    );

    _positionAnimation = Tween<double>(begin: -100, end: 100).animate(
      CurvedAnimation(
        parent: _controller,
        curve: const Interval(0, 0.5, curve: Curves.easeInOut),
      ),
    );

    _rotationAnimation = Tween<double>(begin: 0, end: 2 * 3.141).animate(
      CurvedAnimation(
        parent: _controller,
        curve: const Interval(0.5, 1, curve: Curves.easeInOut),
      ),
    );

    _controller.repeat(reverse: true);
  }

  void _toggleAnimation() {
    if (_controller.isAnimating) {
      _controller.stop();
    } else {
      _controller.repeat(reverse: !_controller.isDismissed);
    }

    setState(() {
      _isPaused = !_isPaused;
    });
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: _toggleAnimation,
      child: AnimatedBuilder(
        animation: _controller,
        builder: (context, child) {
          return Transform.translate(
            offset: Offset(_positionAnimation.value, 0),
            child: Transform.rotate(
              angle: _rotationAnimation.value,
              child: Image.asset(
                'images/icon_app_cute_bigger.png',
              ),
            ),
          );
        },
      ),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }
}

class PixarStyleIntro extends StatefulWidget {
  const PixarStyleIntro({super.key});

  @override
  PixarStyleIntroState createState() => PixarStyleIntroState();
}

class PixarStyleIntroState extends State<PixarStyleIntro>
    with SingleTickerProviderStateMixin {
  late AnimationController controller;
  late SequenceAnimation sequenceAnimation;

  @override
  void initState() {
    super.initState();

    controller = AnimationController(vsync: this);
    sequenceAnimation = SequenceAnimationBuilder()
        .addAnimatable(
          animatable: Tween<double>(begin: 0.0, end: 1.0),
          from: Duration.zero,
          to: const Duration(milliseconds: 500),
          tag: "opacity",
        )
        .addAnimatable(
          animatable: Tween<double>(begin: 20.0, end: 50.0),
          from: const Duration(milliseconds: 500),
          to: const Duration(milliseconds: 1000),
          curve: Curves.easeInOutExpo,
          tag: "fontSize",
        )
        .animate(controller);

    controller.forward();
  }

  @override
  Widget build(BuildContext context) {
    final listenables = [
      sequenceAnimation["opacity"],
      sequenceAnimation["fontSize"],
    ];

    return AnimatedBuilder(
      animation: Listenable.merge(listenables),
      builder: (context, child) {
        return Opacity(
          opacity: sequenceAnimation["opacity"].value,
          child: Text(
            'Appointment',
            style: TextStyle(
              fontSize: sequenceAnimation["fontSize"].value,
              color: const Color(0xFF7B86E2),
              fontWeight: FontWeight.bold,
            ),
          ),
        );
      },
    );
  }

  @override
  void dispose() {
    controller.dispose();
    super.dispose();
  }
}
