import 'package:aia/pages/talk_mode_page.dart';
import 'package:flutter/material.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen>
    with TickerProviderStateMixin {
  late AnimationController _silhouetteController;
  late AnimationController _buttonController;
  late Animation<Offset> _buttonPositionAnimation;
  late Animation<double> _buttonWidthAnimation;
  late Animation<double> _buttonHeightAnimation;
  late Animation<double> _buttonOpacityAnimation;

  @override
  void initState() {
    super.initState();

    _silhouetteController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2),
    );

    _buttonController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1000),
    );

    _buttonPositionAnimation = Tween<Offset>(
      begin: Offset.zero,
      end: const Offset(0, 2.0),
    ).animate(
      CurvedAnimation(parent: _buttonController, curve: Curves.easeInOut),
    );

    _buttonWidthAnimation = Tween<double>(begin: 200, end: 0).animate(
      CurvedAnimation(
        parent: _buttonController,
        curve: const Interval(0.0, 0.5, curve: Curves.easeIn),
      ),
    );

    _buttonHeightAnimation = Tween<double>(begin: 50, end: 0).animate(
      CurvedAnimation(
        parent: _buttonController,
        curve: const Interval(0.0, 0.5, curve: Curves.easeIn),
      ),
    );

    _buttonOpacityAnimation = Tween<double>(begin: 1.0, end: 0.0).animate(
      CurvedAnimation(
        parent: _buttonController,
        curve: const Interval(0.5, 1.0, curve: Curves.easeOut),
      ),
    );

    Future.delayed(const Duration(seconds: 1), () {
      _silhouetteController.forward();
    });
  }

  void _navigateToChat() {
    _buttonController.forward().then((_) {
      Navigator.of(context).pushReplacement(
        PageRouteBuilder(
          pageBuilder:
              (context, animation, secondaryAnimation) => const TalkModePage(),
          transitionsBuilder: (context, animation, secondaryAnimation, child) {
            return FadeTransition(opacity: animation, child: child);
          },
          transitionDuration: const Duration(milliseconds: 500),
        ),
      );
    });
  }

  @override
  void dispose() {
    _silhouetteController.dispose();
    _buttonController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;

    return Scaffold(
      backgroundColor: Colors.black,
      body: Stack(
        alignment: Alignment.center,
        children: [
          // Silhouette
          Center(
            child: FadeTransition(
              opacity: _silhouetteController,
              child: Opacity(
                opacity: 1,
                child: Image.asset(
                  'assets/female_ai_silhouette_with_txt.png',
                  height: size.height,
                  fit: BoxFit.cover,
                ),
              ),
            ),
          ),

          // Start Button
          Positioned(
            bottom: 100,

            child: SlideTransition(
              position: _buttonPositionAnimation,
              child: FadeTransition(
                opacity: _buttonOpacityAnimation,
                child: AnimatedBuilder(
                  animation: _buttonController,
                  builder: (context, child) {
                    return SizedBox(
                      width: _buttonWidthAnimation.value,
                      height: _buttonHeightAnimation.value,
                      child: OutlinedButton(
                        onPressed: _navigateToChat,
                        style: OutlinedButton.styleFrom(
                          backgroundColor: Color.fromRGBO(30, 230, 254, 1),
                          foregroundColor: Color.fromRGBO(0, 36, 57, 1),
                          textStyle: TextStyle(fontWeight: FontWeight.bold),
                          // side: const BorderSide(color: Colors.white),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(30),
                          ),
                        ),
                        child:
                            _buttonController.value < 0.5
                                ? const Text("Start The Journey")
                                : const SizedBox(),
                      ),
                    );
                  },
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
