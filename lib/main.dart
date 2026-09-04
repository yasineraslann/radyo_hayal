import 'dart:async';
import 'dart:convert';
import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:url_launcher/url_launcher.dart';
import 'package:audio_service/audio_service.dart';

import 'audio_handler.dart';

late RadioAudioHandler _audioHandler;

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  _audioHandler = await AudioService.init(
    builder: () => RadioAudioHandler(),
    config: const AudioServiceConfig(
      androidNotificationChannelId: 'com.radyohayal.app.audio',
      androidNotificationChannelName: 'RADYO HAYAL',
      androidNotificationChannelDescription:
          'RADYO HAYAL canlı radyo oynatıcı',
      androidNotificationIcon: 'mipmap/ic_launcher',
      androidNotificationClickStartsActivity: true,
      androidStopForegroundOnPause: false,
      androidShowNotificationBadge: true,
      notificationColor: Color(0xFF7C3AED),
    ),
  );

  runApp(const RadyoHayalApp());
}

class RadyoHayalApp extends StatelessWidget {
  const RadyoHayalApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'RADYO HAYAL',
      theme: ThemeData(
        brightness: Brightness.dark,
        scaffoldBackgroundColor: const Color(0xFF03030A),
        useMaterial3: true,
        fontFamily: 'Roboto',
      ),
      home: const RadyoHayalSplash(),
    );
  }
}

class RadyoHayalSplash extends StatefulWidget {
  const RadyoHayalSplash({super.key});

  @override
  State<RadyoHayalSplash> createState() => _RadyoHayalSplashState();
}

class _RadyoHayalSplashState extends State<RadyoHayalSplash>
    with SingleTickerProviderStateMixin {
  late AnimationController controller;

  @override
  void initState() {
    super.initState();

    controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1700),
    )..forward();

    Future.delayed(const Duration(milliseconds: 2300), () {
      if (!mounted) return;

      Navigator.of(context).pushReplacement(
        PageRouteBuilder(
          transitionDuration: const Duration(milliseconds: 500),
          pageBuilder: (_, animation, __) => const RadyoHayalHome(),
          transitionsBuilder: (_, animation, __, child) {
            return FadeTransition(
              opacity: CurvedAnimation(
                parent: animation,
                curve: Curves.easeOut,
              ),
              child: child,
            );
          },
        ),
      );
    });
  }

  @override
  void dispose() {
    controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF03030A),
      body: AnimatedBuilder(
        animation: controller,
        builder: (_, __) {
          final value = Curves.easeOutBack.transform(
            controller.value.clamp(0.0, 1.0),
          );

          final opacity = Curves.easeOut.transform(
            controller.value.clamp(0.0, 1.0),
          );

          return Stack(
            alignment: Alignment.center,
            children: [
              Container(
                decoration: const BoxDecoration(
                  gradient: RadialGradient(
                    center: Alignment.center,
                    radius: .9,
                    colors: [
                      Color(0xFF1A0D30),
                      Color(0xFF0B0813),
                      Color(0xFF03030A),
                    ],
                  ),
                ),
              ),
              Transform.scale(
                scale: .7 + value * .3,
                child: Container(
                  width: 260,
                  height: 260,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: const Color(0xFF7C3AED)
                        .withOpacity(.045 * opacity),
                    boxShadow: [
                      BoxShadow(
                        color: const Color(0xFF8B5CF6)
                            .withOpacity(.20 * opacity),
                        blurRadius: 100,
                        spreadRadius: 20,
                      ),
                    ],
                  ),
                ),
              ),
              Transform.scale(
                scale: .55 + value * .45,
                child: Opacity(
                  opacity: opacity,
                  child: Container(
                    width: 178,
                    height: 178,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      gradient: const SweepGradient(
                        colors: [
                          Color(0xFF7C3AED),
                          Color(0xFFEC4899),
                          Color(0xFF2563EB),
                          Color(0xFF7C3AED),
                        ],
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: const Color(0xFF8B5CF6)
                              .withOpacity(.42 * opacity),
                          blurRadius: 65,
                          spreadRadius: 7,
                        ),
                      ],
                    ),
                    child: Container(
                      margin: const EdgeInsets.all(7),
                      decoration: const BoxDecoration(
                        shape: BoxShape.circle,
                        color: Color(0xFF07070D),
                      ),
                      child: const Icon(
                        Icons.mic_rounded,
                        size: 76,
                        color: Colors.white,
                      ),
                    ),
                  ),
                ),
              ),
              Positioned(
                bottom: 108,
                child: Opacity(
                  opacity: opacity,
                  child: const Column(
                    children: [
                      Text(
                        'RADYO HAYAL',
                        style: TextStyle(
                          fontSize: 27,
                          fontWeight: FontWeight.w900,
                          letterSpacing: 3,
                        ),
                      ),
                      SizedBox(height: 9),
                      Text(
                        'HAYALLERİN ÖTESİNDE',
                        style: TextStyle(
                          color: Color(0xFFB794F4),
                          fontSize: 10,
                          fontWeight: FontWeight.w700,
                          letterSpacing: 3.2,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              Positioned(
                bottom: 57,
                child: Opacity(
                  opacity: opacity,
                  child: const Text(
                    'YAYINA HAZIRLANIYOR...',
                    style: TextStyle(
                      color: Color(0xFF625A6C),
                      fontSize: 8,
                      fontWeight: FontWeight.w700,
                      letterSpacing: 2,
                    ),
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}

class RadyoHayalHome extends StatefulWidget {
  const RadyoHayalHome({super.key});

  @override
  State<RadyoHayalHome> createState() => _RadyoHayalHomeState();
}

class _RadyoHayalHomeState extends State<RadyoHayalHome>
    with SingleTickerProviderStateMixin {
  static const String apiUrl =
      'https://radyoserver1.okeylisans.com/cp/get_info.php?p=8060';

  static const String whatsappUrl =
      'https://wa.me/905305267494?text=Merhaba%20Radyo%20Hayal%2C%20%C5%9Fark%C4%B1%20iste%C4%9Fim%20var.';

  Timer? _infoTimer;
  StreamSubscription<PlaybackState>? _playbackStateSubscription;

  bool isPlaying = false;
  bool isLoading = false;
  bool isMuted = false;

  double volume = 1.0;
  double previousVolume = 1.0;

  String songTitle = 'RADYO HAYAL';
  String artist = 'Hayallerin Ötesinde';
  String albumImage = '';
  String listeners = '0';

  String djName = 'AUTO DJ';

  final List<String> lastSongs = [];

  late AnimationController pulseController;

  @override
  void initState() {
    super.initState();

    pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1250),
    )..repeat(reverse: true);

    _playbackStateSubscription = _audioHandler.playbackState.listen((state) {
      if (!mounted) return;

      setState(() {
        isPlaying = state.playing;

        isLoading =
            state.processingState == AudioProcessingState.loading ||
            state.processingState == AudioProcessingState.buffering;
      });
    });

    _getRadioInfo();
    _loadVolume();

    _infoTimer = Timer.periodic(
      const Duration(seconds: 10),
      (_) => _getRadioInfo(),
    );
  }

  @override
  void dispose() {
    _infoTimer?.cancel();
    _playbackStateSubscription?.cancel();
    pulseController.dispose();
    super.dispose();
  }

  Future<void> _loadVolume() async {
    final currentVolume = _audioHandler.volume;

    if (!mounted) return;

    setState(() {
      volume = currentVolume;
      isMuted = currentVolume <= 0.001;

      if (currentVolume > 0.001) {
        previousVolume = currentVolume;
      }
    });
  }

  Future<void> _setVolume(double value) async {
    final safeValue = value.clamp(0.0, 1.0);

    await _audioHandler.setVolume(safeValue);

    if (!mounted) return;

    setState(() {
      volume = safeValue;
      isMuted = safeValue <= 0.001;

      if (safeValue > 0.001) {
        previousVolume = safeValue;
      }
    });
  }

  Future<void> _toggleMute() async {
    if (isMuted || volume <= 0.001) {
      final restoreVolume =
          previousVolume > 0.001 ? previousVolume : 1.0;

      await _setVolume(restoreVolume);
    } else {
      previousVolume = volume;
      await _setVolume(0.0);
    }
  }

  Future<void> _togglePlayer() async {
    if (isLoading) return;

    try {
      if (_audioHandler.playbackState.value.playing) {
        await _audioHandler.pause();

        if (mounted) {
          setState(() {
            isPlaying = false;
          });
        }

        return;
      }

      if (mounted) {
        setState(() {
          isLoading = true;
        });
      }

      await _audioHandler.play();

      if (mounted) {
        setState(() {
          isLoading = false;
          isPlaying = true;
        });
      }
    } catch (e) {
      debugPrint('RADYO OYNATMA HATASI: $e');

      if (!mounted) return;

      setState(() {
        isLoading = false;
        isPlaying = false;
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          backgroundColor: const Color(0xFF21101E),
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          content: Text(
            'Radyo bağlantı hatası:\n$e',
            style: const TextStyle(fontSize: 12),
          ),
        ),
      );
    }
  }

  Future<void> _getRadioInfo() async {
    try {
      final response = await http
          .get(
            Uri.parse(apiUrl),
            headers: {
              'Accept': 'application/json',
              'User-Agent': 'RadyoHayalApp/1.0',
            },
          )
          .timeout(
            const Duration(seconds: 8),
          );

      if (response.statusCode != 200) {
        debugPrint('API HTTP HATASI: ${response.statusCode}');
        return;
      }

      final data = jsonDecode(response.body);

      if (data is! Map) return;

      String newTitle = '';

      if (data['songtitle'] != null) {
        newTitle = data['songtitle'].toString().trim();
      }

      if (newTitle.isEmpty && data['title'] != null) {
        newTitle = data['title'].toString().trim();
      }

      String newImage = '';

      if (data['art'] != null) {
        newImage = data['art'].toString().trim();
      }

      if (newImage.isEmpty && data['album_image'] != null) {
        newImage = data['album_image'].toString().trim();
      }

      String newListeners = '';

      if (data['listeners'] != null) {
        newListeners = data['listeners'].toString();
      }

      if (newListeners.isEmpty && data['currentlisteners'] != null) {
        newListeners = data['currentlisteners'].toString();
      }

      // ========================================================
      // DJ DURUMU
      // ========================================================

      String newDjName = 'AUTO DJ';

      if (data['djusername'] != null) {
        final rawDj = data['djusername'].toString().trim();

        if (rawDj.isNotEmpty &&
            rawDj.toLowerCase() != 'no dj' &&
            rawDj.toLowerCase() != 'nodj' &&
            rawDj.toLowerCase() != 'none' &&
            rawDj.toLowerCase() != 'null') {
          newDjName = rawDj;
        }
      }

      String newArtist = 'RADYO HAYAL';

      if (newTitle.contains(' - ')) {
        final parts = newTitle.split(' - ');

        if (parts.length >= 2) {
          newArtist = parts.first.trim();
          newTitle = parts.sublist(1).join(' - ').trim();
        }
      }

      if (!mounted) return;

      setState(() {
        if (newTitle.isNotEmpty) {
          songTitle = newTitle;
        }

        artist = newArtist;
        djName = newDjName;

        if (newImage.isNotEmpty &&
            newImage != 'null' &&
            newImage.startsWith('http')) {
          albumImage = newImage;
        }

        if (newListeners.isNotEmpty) {
          listeners = newListeners;
        }
      });

      if (newTitle.isNotEmpty) {
        final fullSong = '$newArtist - $newTitle';

        if (lastSongs.isEmpty || lastSongs.first != fullSong) {
          setState(() {
            lastSongs.insert(0, fullSong);

            if (lastSongs.length > 5) {
              lastSongs.removeLast();
            }
          });
        }

        _audioHandler.updateSong(
          title: newTitle,
          artist: newArtist,
          imageUrl: newImage.isNotEmpty &&
                  newImage != 'null' &&
                  newImage.startsWith('http')
              ? newImage
              : null,
        );
      }
    } catch (e) {
      debugPrint('API HATASI: $e');
    }
  }

  Future<void> _openWhatsApp() async {
    final uri = Uri.parse(whatsappUrl);

    try {
      final launched = await launchUrl(
        uri,
        mode: LaunchMode.externalApplication,
      );

      if (!launched && mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('WhatsApp açılamadı.'),
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    } catch (e) {
      debugPrint('WHATSAPP HATASI: $e');

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('WhatsApp açılamadı.'),
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  Widget _glass({
    required Widget child,
    EdgeInsets padding = const EdgeInsets.all(18),
    double radius = 24,
  }) {
    return Container(
      padding: padding,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(radius),
        color: Colors.white.withOpacity(.045),
        border: Border.all(
          color: Colors.white.withOpacity(.075),
        ),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF8B5CF6).withOpacity(.055),
            blurRadius: 35,
            spreadRadius: 2,
          ),
        ],
      ),
      child: child,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF03030A),
      body: Stack(
        children: [
          _buildBackgroundGlow(),
          SafeArea(
            child: CustomScrollView(
              physics: const BouncingScrollPhysics(),
              slivers: [
                SliverToBoxAdapter(child: _buildHeader()),
                SliverToBoxAdapter(child: _buildLiveStatus()),
                SliverToBoxAdapter(child: _buildHero()),
                SliverToBoxAdapter(child: _buildNowPlaying()),
                SliverToBoxAdapter(child: _buildPlayer()),
                SliverToBoxAdapter(child: _buildLastSongs()),
                SliverToBoxAdapter(child: _buildRequest()),
                SliverToBoxAdapter(child: _buildFounder()),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBackgroundGlow() {
    return IgnorePointer(
      child: AnimatedBuilder(
        animation: pulseController,
        builder: (_, __) {
          final v = pulseController.value;

          return Stack(
            children: [
              Positioned(
                top: -170,
                left: -130,
                child: Container(
                  width: 390,
                  height: 390,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: const Color(0xFF7C3AED)
                        .withOpacity(.10 + v * .06),
                  ),
                ),
              ),
              Positioned(
                top: 230,
                right: -180,
                child: Container(
                  width: 400,
                  height: 400,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: const Color(0xFFEC4899)
                        .withOpacity(.07 + v * .04),
                  ),
                ),
              ),
              Positioned(
                bottom: -180,
                left: -100,
                child: Container(
                  width: 390,
                  height: 390,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: const Color(0xFF2563EB)
                        .withOpacity(.065 + v * .035),
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _buildHeader() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(22, 20, 22, 8),
      child: Row(
        children: [
          Container(
            width: 56,
            height: 56,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(18),
              gradient: const LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  Color(0xFF8B5CF6),
                  Color(0xFFEC4899),
                ],
              ),
              boxShadow: [
                BoxShadow(
                  color: const Color(0xFF8B5CF6).withOpacity(.32),
                  blurRadius: 30,
                  spreadRadius: 2,
                ),
              ],
            ),
            child: const Icon(
              Icons.graphic_eq_rounded,
              size: 31,
              color: Colors.white,
            ),
          ),
          const SizedBox(width: 14),
          const Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'RADYO HAYAL',
                  style: TextStyle(
                    fontSize: 21,
                    fontWeight: FontWeight.w900,
                    letterSpacing: 1.4,
                  ),
                ),
                SizedBox(height: 3),
                Text(
                  'HAYALLERİN ÖTESİNDE',
                  style: TextStyle(
                    color: Color(0xFF958BA3),
                    fontSize: 9,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 2.1,
                  ),
                ),
              ],
            ),
          ),
          _glass(
            padding: const EdgeInsets.all(11),
            radius: 15,
            child: const Icon(
              Icons.notifications_none_rounded,
              size: 21,
              color: Color(0xFFD9D2E2),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLiveStatus() {
    final isAutoDj = djName == 'AUTO DJ';

    return Padding(
      padding: const EdgeInsets.fromLTRB(24, 19, 24, 7),
      child: Row(
        children: [
          AnimatedBuilder(
            animation: pulseController,
            builder: (_, __) {
              final size = 8 + pulseController.value * 4;

              return Container(
                width: size,
                height: size,
                decoration: BoxDecoration(
                  color: isAutoDj
                      ? const Color(0xFF8B5CF6)
                      : const Color(0xFFFF3B81),
                  shape: BoxShape.circle,
                  boxShadow: [
                    BoxShadow(
                      color: (isAutoDj
                              ? const Color(0xFF8B5CF6)
                              : const Color(0xFFFF3B81))
                          .withOpacity(.65),
                      blurRadius: 12,
                      spreadRadius: 2,
                    ),
                  ],
                ),
              );
            },
          ),
          const SizedBox(width: 10),
          Text(
            isAutoDj ? 'AUTO DJ' : 'CANLI YAYIN',
            style: TextStyle(
              color: isAutoDj
                  ? const Color(0xFFB794F4)
                  : const Color(0xFFFF5798),
              fontSize: 10,
              fontWeight: FontWeight.w900,
              letterSpacing: 2,
            ),
          ),
          if (!isAutoDj) ...[
            const SizedBox(width: 7),
            Flexible(
              child: Text(
                '• $djName',
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  color: Color(0xFF8F8799),
                  fontSize: 9,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
          ],
          const Spacer(),
          Container(
            padding: const EdgeInsets.symmetric(
              horizontal: 11,
              vertical: 7,
            ),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(.035),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(
                color: Colors.white.withOpacity(.06),
              ),
            ),
            child: Row(
              children: [
                const Icon(
                  Icons.people_alt_outlined,
                  size: 15,
                  color: Color(0xFF817989),
                ),
                const SizedBox(width: 6),
                Text(
                  '$listeners DİNLEYİCİ',
                  style: const TextStyle(
                    color: Color(0xFF8F8799),
                    fontSize: 9,
                    fontWeight: FontWeight.w700,
                    letterSpacing: .7,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHero() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 18, 20, 22),
      child: AnimatedBuilder(
        animation: pulseController,
        builder: (_, __) {
          final pulse = pulseController.value;

          return Container(
            height: 365,
            width: double.infinity,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(36),
              gradient: const LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  Color(0xFF160D25),
                  Color(0xFF0C0A15),
                  Color(0xFF07070D),
                ],
              ),
              border: Border.all(
                color: Colors.white.withOpacity(.08),
              ),
              boxShadow: [
                BoxShadow(
                  color: const Color(0xFF7C3AED)
                      .withOpacity(.08 + pulse * .07),
                  blurRadius: 55 + pulse * 15,
                  spreadRadius: 5,
                ),
              ],
            ),
            child: Stack(
              alignment: Alignment.center,
              children: [
                Positioned(
                  top: -80,
                  right: -80,
                  child: Container(
                    width: 220,
                    height: 220,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      gradient: RadialGradient(
                        colors: [
                          const Color(0xFFEC4899)
                              .withOpacity(.20 + pulse * .06),
                          Colors.transparent,
                        ],
                      ),
                    ),
                  ),
                ),
                Positioned(
                  bottom: -100,
                  left: -90,
                  child: Container(
                    width: 250,
                    height: 250,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      gradient: RadialGradient(
                        colors: [
                          const Color(0xFF4F46E5)
                              .withOpacity(.16 + pulse * .05),
                          Colors.transparent,
                        ],
                      ),
                    ),
                  ),
                ),
                Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    _buildRadioArtwork(),
                    const SizedBox(height: 18),
                    const Text(
                      'RADYO HAYAL',
                      style: TextStyle(
                        fontSize: 25,
                        fontWeight: FontWeight.w900,
                        letterSpacing: 2.4,
                      ),
                    ),
                    const SizedBox(height: 5),
                    const Text(
                      'HAYALLERİN ÖTESİNDE',
                      style: TextStyle(
                        color: Color(0xFF9B91A8),
                        fontSize: 9,
                        fontWeight: FontWeight.w700,
                        letterSpacing: 3,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildRadioArtwork() {
    return AnimatedBuilder(
      animation: pulseController,
      builder: (_, __) {
        final p = pulseController.value;
        final t = p * math.pi * 2;

        final wave1 = .5 + .5 * math.sin(t);
        final wave2 = .5 + .5 * math.sin(t + 1.2);
        final wave3 = .5 + .5 * math.sin(t + 2.4);

        final micScale = 1.0 + wave1 * .09;
        final micY = math.sin(t) * 4.5;

        return SizedBox(
          width: 205,
          height: 205,
          child: Stack(
            alignment: Alignment.center,
            children: [
              Transform.scale(
                scale: 1.0 + wave1 * .10,
                child: Container(
                  width: 198,
                  height: 198,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: const Color(0xFF8B5CF6)
                          .withOpacity(.18 + wave1 * .25),
                      width: 2,
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: const Color(0xFF8B5CF6)
                            .withOpacity(.18 + wave1 * .18),
                        blurRadius: 28 + wave1 * 20,
                        spreadRadius: 3 + wave1 * 6,
                      ),
                    ],
                  ),
                ),
              ),
              Transform.scale(
                scale: 1.0 + wave2 * .13,
                child: Container(
                  width: 178,
                  height: 178,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: const Color(0xFFEC4899)
                          .withOpacity(.10 + wave2 * .20),
                      width: 1.5,
                    ),
                  ),
                ),
              ),
              Transform.scale(
                scale: .985 + wave3 * .025,
                child: Container(
                  width: 164,
                  height: 164,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: const SweepGradient(
                      colors: [
                        Color(0xFF7C3AED),
                        Color(0xFFEC4899),
                        Color(0xFF2563EB),
                        Color(0xFF7C3AED),
                      ],
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: const Color(0xFF8B5CF6)
                            .withOpacity(.30 + wave1 * .22),
                        blurRadius: 38 + wave1 * 20,
                        spreadRadius: 3 + wave1 * 5,
                      ),
                    ],
                  ),
                  child: Container(
                    margin: const EdgeInsets.all(7),
                    decoration: const BoxDecoration(
                      shape: BoxShape.circle,
                      color: Color(0xFF07070D),
                    ),
                    child: Stack(
                      alignment: Alignment.center,
                      children: [
                        Transform.scale(
                          scale: .96 + wave2 * .08,
                          child: Container(
                            width: 126,
                            height: 126,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              gradient: RadialGradient(
                                colors: [
                                  const Color(0xFF8B5CF6)
                                      .withOpacity(.22 + wave2 * .14),
                                  const Color(0xFF09090F),
                                ],
                              ),
                            ),
                          ),
                        ),
                        Transform.translate(
                          offset: Offset(0, micY),
                          child: Transform.scale(
                            scale: micScale,
                            child: Icon(
                              Icons.mic_rounded,
                              size: 70 + wave1 * 6,
                              color: Colors.white.withOpacity(
                                .88 + wave1 * .12,
                              ),
                            ),
                          ),
                        ),
                        Positioned(
                          top: 17,
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              _eqBar(7 + wave1 * 16),
                              _eqBar(10 + wave2 * 23),
                              _eqBar(8 + wave3 * 29),
                              _eqBar(14 + wave1 * 25),
                              _eqBar(9 + wave2 * 27),
                              _eqBar(13 + wave3 * 21),
                              _eqBar(7 + wave1 * 17),
                            ],
                          ),
                        ),
                        Positioned(
                          bottom: 18,
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              _eqBar(6 + wave3 * 12),
                              _eqBar(9 + wave1 * 18),
                              _eqBar(13 + wave2 * 21),
                              _eqBar(10 + wave3 * 18),
                              _eqBar(6 + wave1 * 13),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _eqBar(double height) {
    return Container(
      width: 3,
      height: height,
      margin: const EdgeInsets.symmetric(horizontal: 2.5),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(5),
        gradient: const LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            Color(0xFFEC4899),
            Color(0xFF8B5CF6),
          ],
        ),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFFEC4899).withOpacity(.45),
            blurRadius: 7,
          ),
        ],
      ),
    );
  }

  Widget _buildNowPlaying() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 28),
      child: _glass(
        padding: const EdgeInsets.all(16),
        radius: 28,
        child: Row(
          children: [
            Container(
              width: 82,
              height: 82,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(20),
                gradient: const LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [
                    Color(0xFF8B5CF6),
                    Color(0xFFEC4899),
                  ],
                ),
                boxShadow: [
                  BoxShadow(
                    color: const Color(0xFF8B5CF6).withOpacity(.28),
                    blurRadius: 22,
                    spreadRadius: 1,
                  ),
                ],
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(20),
                child: albumImage.isNotEmpty
                    ? Image.network(
                        albumImage,
                        fit: BoxFit.cover,
                        gaplessPlayback: true,
                        errorBuilder: (_, __, ___) {
                          return const Center(
                            child: Icon(
                              Icons.music_note_rounded,
                              size: 34,
                              color: Colors.white,
                            ),
                          );
                        },
                        loadingBuilder: (context, child, progress) {
                          if (progress == null) return child;

                          return const Center(
                            child: SizedBox(
                              width: 22,
                              height: 22,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                color: Colors.white,
                              ),
                            ),
                          );
                        },
                      )
                    : const Center(
                        child: Icon(
                          Icons.music_note_rounded,
                          size: 34,
                          color: Colors.white,
                        ),
                      ),
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Container(
                        width: 6,
                        height: 6,
                        decoration: const BoxDecoration(
                          color: Color(0xFFFF3B81),
                          shape: BoxShape.circle,
                        ),
                      ),
                      const SizedBox(width: 7),
                      const Text(
                        'ŞİMDİ ÇALIYOR',
                        style: TextStyle(
                          color: Color(0xFF91889D),
                          fontSize: 8,
                          fontWeight: FontWeight.w900,
                          letterSpacing: 1.8,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 9),
                  Text(
                    songTitle,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w900,
                      color: Colors.white,
                      height: 1.15,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    artist,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      color: Color(0xFFA49BAB),
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 9),
                  Row(
                    children: [
                      const Icon(
                        Icons.radio_rounded,
                        size: 12,
                        color: Color(0xFFB794F4),
                      ),
                      const SizedBox(width: 5),
                      const Text(
                        'RADYO HAYAL',
                        style: TextStyle(
                          color: Color(0xFF8C8299),
                          fontSize: 8,
                          fontWeight: FontWeight.w800,
                          letterSpacing: 1,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPlayer() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(22, 25, 22, 30),
      child: Column(
        children: [
          GestureDetector(
            onTap: _togglePlayer,
            child: AnimatedBuilder(
              animation: pulseController,
              builder: (_, __) {
                final glow = isPlaying
                    ? .28 + pulseController.value * .18
                    : .14;

                return Container(
                  width: 94,
                  height: 94,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: const LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: [
                        Color(0xFF8B5CF6),
                        Color(0xFFEC4899),
                      ],
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: const Color(0xFF8B5CF6)
                            .withOpacity(glow),
                        blurRadius: 35,
                        spreadRadius: 5,
                      ),
                    ],
                  ),
                  child: Center(
                    child: Container(
                      width: 82,
                      height: 82,
                      decoration: const BoxDecoration(
                        shape: BoxShape.circle,
                        color: Color(0xFF0A0810),
                      ),
                      child: Center(
                        child: isLoading
                            ? const SizedBox(
                                width: 29,
                                height: 29,
                                child: CircularProgressIndicator(
                                  strokeWidth: 3,
                                  color: Colors.white,
                                ),
                              )
                            : Icon(
                                isPlaying
                                    ? Icons.pause_rounded
                                    : Icons.play_arrow_rounded,
                                size: 45,
                                color: Colors.white,
                              ),
                      ),
                    ),
                  ),
                );
              },
            ),
          ),
          const SizedBox(height: 13),
          Text(
            isLoading
                ? 'YAYINA BAĞLANILIYOR...'
                : isPlaying
                    ? 'RADYO HAYAL ÇALIYOR'
                    : 'DİNLEMEK İÇİN DOKUN',
            style: TextStyle(
              color: isPlaying
                  ? const Color(0xFFB794F4)
                  : const Color(0xFF77717F),
              fontSize: 9,
              fontWeight: FontWeight.w800,
              letterSpacing: 1.3,
            ),
          ),
          const SizedBox(height: 18),

          // ======================================================
          // SES KONTROLÜ
          // ======================================================

          _glass(
            padding: const EdgeInsets.symmetric(
              horizontal: 14,
              vertical: 8,
            ),
            radius: 22,
            child: Row(
              children: [
                GestureDetector(
                  onTap: _toggleMute,
                  child: Container(
                    width: 38,
                    height: 38,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: Colors.white.withOpacity(.045),
                    ),
                    child: Icon(
                      isMuted || volume <= .001
                          ? Icons.volume_off_rounded
                          : volume < .5
                              ? Icons.volume_down_rounded
                              : Icons.volume_up_rounded,
                      size: 21,
                      color: isMuted || volume <= .001
                          ? const Color(0xFF77717F)
                          : const Color(0xFFB794F4),
                    ),
                  ),
                ),
                const SizedBox(width: 9),
                Expanded(
                  child: SliderTheme(
                    data: SliderTheme.of(context).copyWith(
                      trackHeight: 3,
                      thumbShape: const RoundSliderThumbShape(
                        enabledThumbRadius: 7,
                      ),
                      overlayShape: const RoundSliderOverlayShape(
                        overlayRadius: 15,
                      ),
                      activeTrackColor: const Color(0xFF8B5CF6),
                      inactiveTrackColor:
                          Colors.white.withOpacity(.08),
                      thumbColor: const Color(0xFFEC4899),
                      overlayColor:
                          const Color(0xFF8B5CF6).withOpacity(.15),
                    ),
                    child: Slider(
                      value: volume.clamp(0.0, 1.0),
                      min: 0,
                      max: 1,
                      onChanged: _setVolume,
                    ),
                  ),
                ),
                SizedBox(
                  width: 38,
                  child: Text(
                    '${(volume * 100).round()}%',
                    textAlign: TextAlign.right,
                    style: const TextStyle(
                      color: Color(0xFF8F8799),
                      fontSize: 9,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLastSongs() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(22, 0, 22, 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 4,
                height: 17,
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [
                      Color(0xFF8B5CF6),
                      Color(0xFFEC4899),
                    ],
                  ),
                  borderRadius: BorderRadius.circular(5),
                ),
              ),
              const SizedBox(width: 10),
              const Text(
                'SON ÇALANLAR',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w900,
                  letterSpacing: 1.5,
                ),
              ),
            ],
          ),
          const SizedBox(height: 13),
          _glass(
            padding: EdgeInsets.zero,
            radius: 24,
            child: lastSongs.isEmpty
                ? const Padding(
                    padding: EdgeInsets.all(24),
                    child: Center(
                      child: Text(
                        'Henüz şarkı bilgisi alınamadı.',
                        style: TextStyle(
                          color: Color(0xFF77717F),
                          fontSize: 12,
                        ),
                      ),
                    ),
                  )
                : Column(
                    children: List.generate(
                      lastSongs.length,
                      (index) {
                        final isFirst = index == 0;

                        return Container(
                          decoration: BoxDecoration(
                            border: index < lastSongs.length - 1
                                ? Border(
                                    bottom: BorderSide(
                                      color:
                                          Colors.white.withOpacity(.045),
                                    ),
                                  )
                                : null,
                          ),
                          padding: const EdgeInsets.symmetric(
                            horizontal: 15,
                            vertical: 12,
                          ),
                          child: Row(
                            children: [
                              SizedBox(
                                width: 25,
                                child: Text(
                                  '${index + 1}'.padLeft(2, '0'),
                                  style: TextStyle(
                                    color: isFirst
                                        ? const Color(0xFFB794F4)
                                        : const Color(0xFF696271),
                                    fontSize: 10,
                                    fontWeight: FontWeight.w900,
                                  ),
                                ),
                              ),
                              const SizedBox(width: 10),
                              Container(
                                width: 44,
                                height: 44,
                                decoration: BoxDecoration(
                                  borderRadius: BorderRadius.circular(13),
                                  gradient: LinearGradient(
                                    begin: Alignment.topLeft,
                                    end: Alignment.bottomRight,
                                    colors: isFirst
                                        ? const [
                                            Color(0xFF8B5CF6),
                                            Color(0xFFEC4899),
                                          ]
                                        : const [
                                            Color(0xFF211734),
                                            Color(0xFF171320),
                                          ],
                                  ),
                                ),
                                child: Icon(
                                  isFirst
                                      ? Icons.graphic_eq_rounded
                                      : Icons.music_note_rounded,
                                  size: 20,
                                  color: isFirst
                                      ? Colors.white
                                      : const Color(0xFF8C8299),
                                ),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Text(
                                  lastSongs[index],
                                  maxLines: 2,
                                  overflow: TextOverflow.ellipsis,
                                  style: TextStyle(
                                    fontSize: 12,
                                    fontWeight: isFirst
                                        ? FontWeight.w800
                                        : FontWeight.w600,
                                    color: isFirst
                                        ? Colors.white
                                        : const Color(0xFFC0B9C7),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        );
                      },
                    ),
                  ),
          ),
        ],
      ),
    );
  }

  Widget _buildRequest() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(22, 0, 22, 30),
      child: GestureDetector(
        onTap: _openWhatsApp,
        child: Container(
          padding: const EdgeInsets.all(18),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(24),
            gradient: const LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                Color(0xFF101C18),
                Color(0xFF100D18),
              ],
            ),
            border: Border.all(
              color: const Color(0xFF25D366).withOpacity(.20),
            ),
            boxShadow: [
              BoxShadow(
                color: const Color(0xFF25D366).withOpacity(.035),
                blurRadius: 30,
              ),
            ],
          ),
          child: Row(
            children: [
              Container(
                width: 51,
                height: 51,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: const Color(0xFF25D366).withOpacity(.12),
                  border: Border.all(
                    color: const Color(0xFF25D366).withOpacity(.15),
                  ),
                ),
                child: const Icon(
                  Icons.chat_rounded,
                  color: Color(0xFF25D366),
                  size: 25,
                ),
              ),
              const SizedBox(width: 14),
              const Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'ŞARKI İSTE',
                      style: TextStyle(
                        fontWeight: FontWeight.w900,
                        fontSize: 14,
                        letterSpacing: .3,
                      ),
                    ),
                    SizedBox(height: 5),
                    Text(
                      'WhatsApp üzerinden bize şarkı gönder',
                      style: TextStyle(
                        color: Color(0xFF918A99),
                        fontSize: 10,
                      ),
                    ),
                  ],
                ),
              ),
              Container(
                width: 34,
                height: 34,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: Colors.white.withOpacity(.045),
                ),
                child: const Icon(
                  Icons.arrow_forward_rounded,
                  size: 17,
                  color: Color(0xFFBDB5C5),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildFounder() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(22, 8, 22, 45),
      child: Column(
        children: [
          Row(
            children: [
              Expanded(
                child: Container(
                  height: 1,
                  decoration: const BoxDecoration(
                    gradient: LinearGradient(
                      colors: [
                        Colors.transparent,
                        Color(0xFF7C3AED),
                      ],
                    ),
                  ),
                ),
              ),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 15),
                child: Container(
                  width: 8,
                  height: 8,
                  decoration: const BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: LinearGradient(
                      colors: [
                        Color(0xFF8B5CF6),
                        Color(0xFFEC4899),
                      ],
                    ),
                  ),
                ),
              ),
              Expanded(
                child: Container(
                  height: 1,
                  decoration: const BoxDecoration(
                    gradient: LinearGradient(
                      colors: [
                        Color(0xFFEC4899),
                        Colors.transparent,
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          const Text(
            'KURUCU',
            style: TextStyle(
              fontSize: 8,
              fontWeight: FontWeight.w700,
              letterSpacing: 3.5,
              color: Color(0xFF6D6675),
            ),
          ),
          const SizedBox(height: 8),
          ShaderMask(
            shaderCallback: (bounds) {
              return const LinearGradient(
                colors: [
                  Color(0xFFB794F4),
                  Color(0xFFF472B6),
                ],
              ).createShader(bounds);
            },
            child: const Text(
              'YASİN ERASLAN',
              style: TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.w900,
                letterSpacing: 2.2,
                color: Colors.white,
              ),
            ),
          ),
          const SizedBox(height: 9),
          const Text(
            'RADYO HAYAL • HAYALLERİN ÖTESİNDE',
            textAlign: TextAlign.center,
            style: TextStyle(
              color: Color(0xFF514C58),
              fontSize: 8,
              letterSpacing: 1.3,
            ),
          ),
          const SizedBox(height: 5),
          const Text(
            '© 2009–2026 RADYO HAYAL',
            style: TextStyle(
              color: Color(0xFF3F3A45),
              fontSize: 7,
              letterSpacing: 1,
            ),
          ),
        ],
      ),
    );
  }
}