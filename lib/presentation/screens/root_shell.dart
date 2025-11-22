// lib/presentation/screens/root_shell.dart
import 'package:flutter/material.dart';
import 'home_screen.dart';
import 'settings_screen.dart';

class RootShell extends StatefulWidget {
  const RootShell({super.key});

  @override
  State<RootShell> createState() => _RootShellState();
}

class _RootShellState extends State<RootShell> with SingleTickerProviderStateMixin {
  final _pages = const [HomeScreen(), SettingsScreen()];
  int _index = 0;

  late final AnimationController _c;
  late Animation<double> _pos; // 0.25 (sol) ↔ 0.75 (sağ)

  // 2 sekme için duraklar
  static const _leftPos = 0.25;
  static const _rightPos = 0.75;

  // Boyut ayarları (düzgün hizalanmış, ince görünüm)
  static const _barHeight = 70.0;     // yeşil bar
  static const _buttonSize = 50.0;    // seçili beyaz buton
  static const _waveDepth = 30.0;     // oyuğun derinliği
  static const _radius = 16.0;        // köşeler

  // Stack yüksekliği: bar + butonun yukarı çıkan yarısı + güvenli pay
  static const _outerHeight = _barHeight + (_buttonSize / 2) + 8;

  @override
  void initState() {
    super.initState();
    _c = AnimationController(vsync: this, duration: const Duration(milliseconds: 260));
    _pos = Tween<double>(begin: _leftPos, end: _leftPos).animate(
      CurvedAnimation(parent: _c, curve: Curves.easeOutCubic),
    );
  }

  void _switchTab(int i) {
    if (i == _index) return;
    setState(() => _index = i);
    final target = i == 0 ? _leftPos : _rightPos;
    _pos = Tween<double>(begin: _pos.value, end: target).animate(
      CurvedAnimation(parent: _c, curve: Curves.easeOutCubic),
    );
    _c
      ..reset()
      ..forward();
  }

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final green = const Color(0xFF00A885);

    return Scaffold(
      extendBody: true,
      body: IndexedStack(index: _index, children: _pages),

      bottomNavigationBar: SafeArea(
        minimum: const EdgeInsets.fromLTRB(14, 0, 14, 10),
        child: AnimatedBuilder(
          animation: _c,
          builder: (_, __) {
            final p = _pos.value; // 0..1 dalga merkezi
            return SizedBox(
              height: _outerHeight,
              child: Stack(
                alignment: Alignment.bottomCenter,
                children: [
                  // Dalgalı yeşil arka plan (tam genişlik)
                  LayoutBuilder(
                    builder: (context, cons) => CustomPaint(
                      size: Size(cons.maxWidth, _barHeight),
                      painter: _WavyBarPainter(
                        color: green,
                        pos: p,
                        waveDepth: _waveDepth,
                        radius: _radius,
                      ),
                    ),
                  ),

                  // Tıklama bölgeleri (pasif ikonlar)
                  Positioned.fill(
                    child: Row(
                      children: [
                        Expanded(
                          child: _TabTapRegion(
                            onTap: () => _switchTab(0),
                            selected: _index == 0,
                            icon: Icons.home_rounded,
                            barHeight: _barHeight,
                          ),
                        ),
                        Expanded(
                          child: _TabTapRegion(
                            onTap: () => _switchTab(1),
                            selected: _index == 1,
                            icon: Icons.settings_rounded,
                            barHeight: _barHeight,
                          ),
                        ),
                      ],
                    ),
                  ),

                  // Seçili beyaz buton (oyukla tam hizalı)
                  Positioned(
                    bottom: _barHeight - (_buttonSize / 2) - (_waveDepth - 20),
                    left: 0,
                    right: 0,
                    child: Align(
                      alignment: Alignment(p * 2 - 1, 0), // 0.25→-0.5, 0.75→+0.5
                      child: _RaisedSelectedButton(
                        icon: _index == 0 ? Icons.home_rounded : Icons.settings_rounded,
                        color: green,
                        size: _buttonSize,
                      ),
                    ),
                  ),
                ],
              ),
            );
          },
        ),
      ),
    );
  }
}

/// Dalgalı bar: üst kenarda seçili sekmenin altında konkav oyuk
class _WavyBarPainter extends CustomPainter {
  final Color color;
  final double pos;       // 0..1 (oyuk merkezi)
  final double waveDepth; // oyuğun derinliği
  final double radius;    // köşeler

  _WavyBarPainter({
    required this.color,
    required this.pos,
    required this.waveDepth,
    required this.radius,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width;
    final h = size.height;
    final r = radius;

    final centerX = w * pos;
    const notchHalf = 40.0; // oyuğun yatay yayılımı

    final leftEdge = (centerX - notchHalf).clamp(r, w - r);
    final rightEdge = (centerX + notchHalf).clamp(r, w - r);

    final path = Path()
      ..moveTo(0, h)
      ..lineTo(0, r)
      ..quadraticBezierTo(0, 0, r, 0)
      ..lineTo(leftEdge, 0)
      // konkav oyuk (yumuşak S eğrisi)
      ..cubicTo(
        leftEdge + notchHalf * 0.20, 0,
        centerX - notchHalf * 0.36, waveDepth * 0.92,
        centerX, waveDepth,
      )
      ..cubicTo(
        centerX + notchHalf * 0.36, waveDepth * 0.92,
        rightEdge - notchHalf * 0.20, 0,
        rightEdge, 0,
      )
      ..lineTo(w - r, 0)
      ..quadraticBezierTo(w, 0, w, r)
      ..lineTo(w, h - r)
      ..quadraticBezierTo(w, h, w - r, h)
      ..lineTo(r, h)
      ..quadraticBezierTo(0, h, 0, h - r)
      ..close();

    final paint = Paint()..color = color;
    canvas.drawShadow(path, Colors.black.withOpacity(.22), 10, false);
    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(covariant _WavyBarPainter old) {
    return old.pos != pos || old.color != color || old.waveDepth != waveDepth || old.radius != radius;
  }
}

/// Alt barda pasif ikon (beyaz). Seçili olan için opaklığı düşürüyoruz.
class _TabTapRegion extends StatelessWidget {
  final VoidCallback onTap;
  final bool selected;
  final IconData icon;
  final double barHeight;

  const _TabTapRegion({
    super.key,
    required this.onTap,
    required this.selected,
    required this.icon,
    required this.barHeight,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      customBorder: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      splashColor: Colors.white24,
      child: SizedBox(
        height: barHeight,
        child: Icon(
          icon,
          color: Colors.white.withOpacity(selected ? 0 : 1), // seçiliyse gizle
          size: 26,
        ),
      ),
    );
  }
}

/// Seçili buton: yükselmiş beyaz daire + yeşil ikon
class _RaisedSelectedButton extends StatelessWidget {
  final IconData icon;
  final Color color;
  final double size;

  const _RaisedSelectedButton({
    required this.icon,
    required this.color,
    required this.size,
  });

  @override
  Widget build(BuildContext context) {
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0.0, end: 1.0),
      duration: const Duration(milliseconds: 210),
      curve: Curves.easeOutBack,
      builder: (_, t, child) => Transform.translate(
        offset: Offset(0, -4 * t),
        child: Transform.scale(scale: 0.96 + 0.04 * t, child: child),
      ),
      child: Container(
        width: size,
        height: size,
        decoration: const BoxDecoration(
          color: Colors.white,
          shape: BoxShape.circle,
          boxShadow: [BoxShadow(color: Color(0x33000000), blurRadius: 12, offset: Offset(0, 6))],
        ),
        child: Icon(icon, color: color, size: 26),
      ),
    );
  }
}
