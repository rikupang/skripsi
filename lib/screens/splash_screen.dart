import 'dart:async';
import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'get_started_screen.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  SplashScreenState createState() => SplashScreenState();
}

// Widget untuk efek gelombang
class WaveClipper extends CustomClipper<Path> {
  final double animation;
  final double waveHeight;

  WaveClipper(this.animation, this.waveHeight);

  @override
  Path getClip(Size size) {
    final path = Path();
    final baseHeight = size.height - waveHeight;

    path.lineTo(0.0, baseHeight);

    // Buat gelombang menggunakan kurva bezier
    for (var i = 0.0; i < size.width; i++) {
      final x = i;
      final waveHeight = this.waveHeight * math.sin((i / size.width * 2 * math.pi) + (animation * 2 * math.pi));
      final y = baseHeight + waveHeight;
      path.lineTo(x, y);
    }

    path.lineTo(size.width, baseHeight);
    path.lineTo(size.width, 0.0);
    path.close();
    return path;
  }

  @override
  bool shouldReclip(WaveClipper oldClipper) => true;
}

class SplashScreenState extends State<SplashScreen> with TickerProviderStateMixin {
  late AnimationController _logoController;
  late AnimationController _waveController;
  late AnimationController _colorController;
  late AnimationController _textFadeController;
  late AnimationController _lineController;
  late Animation<double> _lineAnimation;
  late Animation<double> _logoScaleAnimation;

  late List<AnimationController> _letterControllers;
  late List<Animation<Offset>> _letterAnimations;

  bool showText = false;
  bool showLine = false;

  @override
  void initState() {
    super.initState();

    _logoController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2500),
    )..forward();

    _logoScaleAnimation = Tween<double>(
      begin: 0.8,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _logoController,
      curve: Curves.elasticOut,
    ));

    _waveController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 4000),
    );

    _colorController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 4500),
    );

    _textFadeController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    );

    _lineController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500),
    );

    _lineAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(CurvedAnimation(
      parent: _lineController,
      curve: Curves.easeInOut,
    ));

    // Animasi tiap huruf "KuyMelali"
    _letterControllers = List.generate(9, (index) {
      return AnimationController(
        vsync: this,
        duration: const Duration(milliseconds: 800),
      );
    });

    _letterAnimations = _letterControllers.map((controller) {
      return Tween<Offset>(
        begin: const Offset(0, 0.5),
        end: const Offset(0, 0),
      ).animate(CurvedAnimation(parent: controller, curve: Curves.easeOutBack));
    }).toList();

    // Urutan animasi - diperlambat
    Timer(const Duration(seconds: 2), () {
      if (mounted) {
        _waveController.forward();
        _waveController.repeat(reverse: true);
        _colorController.forward();
      }
    });

    // Menampilkan teks saat warna sudah setengah layar (nilai 0.5)
    _colorController.addListener(() {
      if (_colorController.value >= 0.5 && !showText && mounted) {
        setState(() => showText = true);
        _textFadeController.forward();
        for (int i = 0; i < _letterControllers.length; i++) {
          Future.delayed(Duration(milliseconds: i * 120), () {
            if (mounted) _letterControllers[i].forward();
          });
        }
      }
    });

    Timer(const Duration(seconds: 5), () {
      if (mounted) {
        setState(() => showLine = true);
        _lineController.forward();
      }
    });

    Timer(const Duration(seconds: 9), () {
      if (mounted) {
        Navigator.pushReplacement(
          context,
          PageRouteBuilder(
            transitionDuration: const Duration(milliseconds: 800),
            pageBuilder: (context, animation, secondaryAnimation) => const GetStartedScreen(),
            transitionsBuilder: (context, animation, secondaryAnimation, child) {
              return FadeTransition(
                opacity: animation,
                child: child,
              );
            },
          ),
        );
      }
    });
  }

  @override
  void dispose() {
    _logoController.dispose();
    _waveController.dispose();
    _colorController.dispose();
    _textFadeController.dispose();
    _lineController.dispose();
    for (var controller in _letterControllers) {
      controller.dispose();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;
    const text = 'KuyMelali';

    return Scaffold(
      body: Stack(
        children: [
          // Background putih
          Container(color: Colors.white),

          // Animasi gelombang teal
          AnimatedBuilder(
            animation: Listenable.merge([_waveController, _colorController]),
            builder: (context, child) {
              final fillPercent = Curves.easeInOut.transform(_colorController.value);

              return Stack(
                children: [
                  // Gelombang utama
                  ClipPath(
                    clipper: WaveClipper(
                      _waveController.value,
                      30.0, // Tinggi gelombang
                    ),
                    child: Container(
                      height: size.height * fillPercent,
                      width: size.width,
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          begin: Alignment.topCenter,
                          end: Alignment.bottomCenter,
                          colors: [
                            Colors.teal.shade300,
                            Colors.teal,
                          ],
                        ),
                      ),
                    ),
                  ),

                  // Gelombang overlay dengan offset berbeda
                  Opacity(
                    opacity: 0.4,
                    child: ClipPath(
                      clipper: WaveClipper(
                        (_waveController.value + 0.5) % 1.0,
                        18.0, // Tinggi gelombang kedua
                      ),
                      child: Container(
                        height: size.height * fillPercent * 0.95,
                        width: size.width,
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                            colors: [
                              Colors.teal.shade100,
                              Colors.teal.shade400,
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              );
            },
          ),

          // Logo Welcome Bali dengan animasi scale dan menghilang saat warna setengah layar
          Center(
            child: AnimatedBuilder(
              animation: Listenable.merge([_logoController, _colorController]),
              builder: (context, child) {
                // Hilangkan logo ketika warna mencapai 0.5 (separuh layar)
                double opacity = _colorController.value <= 0.45
                    ? 1.0
                    : _colorController.value >= 0.55
                    ? 0.0
                    : 1.0 - ((_colorController.value - 0.45) * 10); // Transisi cepat di antara 0.45-0.55

                return Opacity(
                  opacity: opacity,
                  child: Transform.scale(
                    scale: _logoScaleAnimation.value,
                    child: Image.asset('assets/welcome_bali.png', width: 250),
                  ),
                );
              },
            ),
          ),

          // Text KuyMelali + ikon pesawat
          if (showText)
            FadeTransition(
              opacity: _textFadeController,
              child: Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        for (int i = 0; i < text.length; i++)
                          SlideTransition(
                            position: _letterAnimations[i],
                            child: Text(
                              text[i],
                              style: const TextStyle(
                                fontSize: 32,
                                fontWeight: FontWeight.bold,
                                color: Colors.white,
                                shadows: [
                                  Shadow(
                                    color: Colors.black26,
                                    offset: Offset(1, 1),
                                    blurRadius: 3,
                                  ),
                                ],
                              ),
                            ),
                          ),
                        const SizedBox(width: 8),
                        const Hero(
                          tag: 'planeIcon',
                          child: Icon(
                            Icons.airplanemode_active,
                            color: Colors.white,
                            size: 32,
                            shadows: [
                              Shadow(
                                color: Colors.black26,
                                offset: Offset(1, 1),
                                blurRadius: 3,
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 10),
                    if (showLine)
                      AnimatedBuilder(
                        animation: _lineAnimation,
                        builder: (context, child) {
                          return Container(
                            height: 4,
                            width: 160 * _lineAnimation.value,
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(2),
                              boxShadow: const [
                                BoxShadow(
                                  color: Colors.black12,
                                  blurRadius: 2,
                                  offset: Offset(0, 1),
                                ),
                              ],
                            ),
                          );
                        },
                      ),
                  ],
                ),
              ),
            ),
        ],
      ),
    );
  }
}