import 'dart:async';
import 'package:flutter/material.dart';
import 'sign_in_screen.dart';

class GetStartedScreen extends StatefulWidget {
  const GetStartedScreen({super.key});

  @override
  State<GetStartedScreen> createState() => _GetStartedScreenState();
}

class _GetStartedScreenState extends State<GetStartedScreen> {
  final PageController _pageController = PageController();
  int _currentPage = 0;
  late Timer _timer;
  bool _isUserInteracting = false;

  // Data konten halaman onboarding
  final List<Map<String, dynamic>> _pages = [
    {
      'image': 'assets/bg1.png',
      'title': 'Discover New Destinations',
      'subtitle': 'Explore hidden gems and popular locations around the world',
    },
    {
      'image': 'assets/bg2.png',
      'title': 'Plan Perfect Trips',
      'subtitle': 'Create personalized itineraries tailored to your preferences',
    },
    {
      'image': 'assets/bg3.png',
      'title': 'Unforgettable Experiences',
      'subtitle': 'Make memories that last a lifetime with unique adventures',
    },
  ];

  @override
  void initState() {
    super.initState();
    _startAutoSlide();
  }

  void _startAutoSlide() {
    _timer = Timer.periodic(const Duration(seconds: 5), (Timer timer) {
      if (!_isUserInteracting && _pageController.hasClients) {
        int nextPage = (_currentPage + 1) % _pages.length;
        _pageController.animateToPage(
          nextPage,
          duration: const Duration(milliseconds: 800),
          curve: Curves.easeOutQuint,
        );
      }
    });
  }

  @override
  void dispose() {
    _timer.cancel();
    _pageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;
    final theme = Theme.of(context);

    return Scaffold(
      body: NotificationListener<ScrollNotification>(
        onNotification: (ScrollNotification notification) {
          // Deteksi interaksi pengguna dengan PageView
          if (notification is ScrollStartNotification) {
            setState(() {
              _isUserInteracting = true;
            });
          } else if (notification is ScrollEndNotification) {
            setState(() {
              _isUserInteracting = false;
            });
            // Restart timer setelah pengguna selesai berinteraksi
            _timer.cancel();
            _startAutoSlide();
          }
          return true;
        },
        child: Stack(
          children: [
            // Background slider dengan gestur
            PageView.builder(
              controller: _pageController,
              itemCount: _pages.length,
              onPageChanged: (index) {
                setState(() {
                  _currentPage = index;
                });
              },
              itemBuilder: (context, index) {
                return Stack(
                  fit: StackFit.expand,
                  children: [
                    // Background image dengan efek filter
                    ShaderMask(
                      shaderCallback: (rect) {
                        return LinearGradient(
                          begin: Alignment.topCenter,
                          end: Alignment.bottomCenter,
                          colors: [
                            Colors.black,
                            Colors.transparent,
                          ],
                          stops: const [0.4, 0.95],
                        ).createShader(rect);
                      },
                      blendMode: BlendMode.dstIn,
                      child: Image.asset(
                        _pages[index]['image'],
                        fit: BoxFit.cover,
                      ),
                    ),

                    // Overlay gradient
                    Container(
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: [
                            Colors.black.withOpacity(0.1),
                            Colors.black.withOpacity(0.5),
                            Colors.black.withOpacity(0.7),
                          ],
                          begin: Alignment.topCenter,
                          end: Alignment.bottomCenter,
                          stops: const [0.3, 0.65, 0.9],
                        ),
                      ),
                    ),

                    // Content overlay with animation
                    Positioned(
                      left: 0,
                      right: 0,
                      bottom: size.height * 0.35,
                      child: Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 24),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            AnimatedOpacity(
                              opacity: 1.0,
                              duration: const Duration(milliseconds: 500),
                              child: Text(
                                _pages[index]['title'],
                                style: const TextStyle(
                                  fontSize: 28,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.white,
                                  letterSpacing: 0.5,
                                  shadows: [
                                    Shadow(
                                      blurRadius: 10,
                                      color: Colors.black45,
                                      offset: Offset(0, 2),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                            const SizedBox(height: 12),
                            AnimatedOpacity(
                              opacity: 1.0,
                              duration: const Duration(milliseconds: 600),
                              child: Text(
                                _pages[index]['subtitle'],
                                style: TextStyle(
                                  fontSize: 16,
                                  color: Colors.white.withOpacity(0.9),
                                  height: 1.4,
                                  shadows: const [
                                    Shadow(
                                      blurRadius: 8,
                                      color: Colors.black45,
                                      offset: Offset(0, 2),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                );
              },
            ),

            // Modern elegant page indicator
            Positioned(
              bottom: size.height * 0.28,
              left: 0,
              right: 0,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: List.generate(_pages.length, (index) {
                  return AnimatedContainer(
                    duration: const Duration(milliseconds: 300),
                    margin: const EdgeInsets.symmetric(horizontal: 6),
                    height: 6,
                    width: _currentPage == index ? 30 : 10,
                    decoration: BoxDecoration(
                      color: _currentPage == index
                          ? Colors.white
                          : Colors.white.withOpacity(0.5),
                      borderRadius: BorderRadius.circular(12),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.2),
                          blurRadius: 4,
                          offset: const Offset(0, 1),
                        ),
                      ],
                    ),
                  );
                }),
              ),
            ),

            // Bottom card with action button
            Align(
              alignment: Alignment.bottomCenter,
              child: Container(
                width: double.infinity,
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: const BorderRadius.only(
                    topLeft: Radius.circular(32),
                    topRight: Radius.circular(32),
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.15),
                      blurRadius: 12,
                      offset: const Offset(0, -3),
                    ),
                  ],
                ),
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(24, 32, 24, 36),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        'Ready to explore beyond boundaries?',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.w700,
                          color: Colors.grey.shade800,
                          letterSpacing: 0.3,
                          height: 1.2,
                        ),
                      ),


                      const SizedBox(height: 32),
                      // Primary action button
                      Container(
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(18),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.teal.shade700.withOpacity(0.4),
                              blurRadius: 12,
                              offset: const Offset(0, 4),
                              spreadRadius: 0,
                            ),
                          ],
                        ),
                        width: double.infinity,
                        child: ElevatedButton.icon(
                          onPressed: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(builder: (context) => const SignInScreen()),
                            );
                          },
                          icon: const Icon(Icons.flight_takeoff_rounded, color: Colors.white),
                          label: const Text(
                            'Start Your Journey',
                            style: TextStyle(
                              fontSize: 17,
                              fontWeight: FontWeight.bold,
                              letterSpacing: 0.3,
                              color: Colors.white,
                            ),
                          ),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.teal.shade700,
                            padding: const EdgeInsets.symmetric(vertical: 18),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(18),
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(height: 20),
                      // Secondary action button (skip)

                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}