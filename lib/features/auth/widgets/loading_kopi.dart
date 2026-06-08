import 'package:flutter/material.dart';

/// LoadingKopi — Widget animasi loading cangkir kopi.
///
/// Parameters:
/// - [fullScreen] : Tampilkan fullscreen dengan background krem (default: true)
/// - [pesan]      : Teks yang ditampilkan di bawah cangkir
/// - [gelapBg]    : Gunakan warna terang agar tampak di atas background gelap
class LoadingKopi extends StatefulWidget {
  final bool fullScreen;
  final String pesan;
  final bool gelapBg;

  const LoadingKopi({
    super.key,
    this.fullScreen = true,
    this.pesan = 'Menyeduh Data...',
    this.gelapBg = false,
  });

  @override
  State<LoadingKopi> createState() => _LoadingKopiState();
}

class _LoadingKopiState extends State<LoadingKopi>
    with TickerProviderStateMixin {
  // ── Steam (3 uap) ──
  late final List<AnimationController> _steamControllers;
  late final List<Animation<double>> _steamY;
  late final List<Animation<double>> _steamOpacity;
  late final List<Animation<double>> _steamScale;

  // ── Isi kopi ──
  late final AnimationController _fillController;
  late final Animation<double> _fillAnim;

  // ── Teks berkedip ──
  late final AnimationController _textController;
  late final Animation<double> _textOpacity;

  @override
  void initState() {
    super.initState();

    // --- Animasi uap (masing-masing dengan delay berbeda) ---
    _steamControllers = List.generate(
      3,
      (_) => AnimationController(
        vsync: this,
        duration: const Duration(milliseconds: 2000),
      ),
    );

    _steamY = _steamControllers
        .map((c) => Tween<double>(begin: 0, end: -20)
            .animate(CurvedAnimation(parent: c, curve: Curves.easeOut)))
        .toList();

    _steamOpacity = _steamControllers
        .map((c) => TweenSequence<double>([
              TweenSequenceItem(tween: Tween(begin: 0.0, end: 1.0), weight: 50),
              TweenSequenceItem(tween: Tween(begin: 1.0, end: 0.0), weight: 50),
            ]).animate(c))
        .toList();

    _steamScale = _steamControllers
        .map((c) => TweenSequence<double>([
              TweenSequenceItem(tween: Tween(begin: 1.0, end: 1.2), weight: 50),
              TweenSequenceItem(tween: Tween(begin: 1.2, end: 1.5), weight: 50),
            ]).animate(c))
        .toList();

    // Mulai uap dengan staggered delay (0ms, 400ms, 800ms)
    for (int i = 0; i < 3; i++) {
      Future.delayed(Duration(milliseconds: i * 400), () {
        if (mounted) _steamControllers[i].repeat();
      });
    }

    // --- Animasi pengisian kopi ---
    _fillController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2000),
    );
    _fillAnim =
        CurvedAnimation(parent: _fillController, curve: Curves.easeInOut);
    _fillController.repeat(reverse: true);

    // --- Animasi kedip teks ---
    _textController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500),
    );
    _textOpacity = TweenSequence<double>([
      TweenSequenceItem(tween: Tween(begin: 0.5, end: 1.0), weight: 50),
      TweenSequenceItem(tween: Tween(begin: 1.0, end: 0.5), weight: 50),
    ]).animate(_textController);
    _textController.repeat();
  }

  @override
  void dispose() {
    for (final c in _steamControllers) {
      c.dispose();
    }
    _fillController.dispose();
    _textController.dispose();
    super.dispose();
  }

  // ── Skema warna berdasarkan [gelapBg] ──
  Color get _steamColor => widget.gelapBg
      ? const Color(0xFFF3EDE6).withOpacity(0.40)
      : const Color(0xFF4B2E2B).withOpacity(0.20);

  Color get _strokeColor =>
      widget.gelapBg ? const Color(0xFFF3EDE6) : const Color(0xFF4B2E2B);

  Color get _fillColor =>
      widget.gelapBg ? const Color(0xFFC69C6D) : const Color(0xFF4B2E2B);

  Color get _textColor =>
      widget.gelapBg ? const Color(0xFFF3EDE6) : const Color(0xFF4B2E2B);

  Color get _bgColor =>
      widget.fullScreen && !widget.gelapBg
          ? const Color(0xFFF3EDE6)
          : Colors.transparent;

  Color get _cupBodyColor =>
      widget.gelapBg ? const Color(0xFF2A1A18) : Colors.white;

  @override
  Widget build(BuildContext context) {
    final content = Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        // ── Cangkir + Uap ──
        SizedBox(
          width: 96,
          // Tinggi: 96 (cangkir) + 32 (ruang uap di atas)
          height: 128,
          child: Stack(
            clipBehavior: Clip.none,
            alignment: Alignment.bottomCenter,
            children: [
              // Uap kopi (3 blob)
              Positioned(
                top: 0,
                left: 0,
                right: 0,
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: List.generate(3, (i) {
                    return AnimatedBuilder(
                      animation: _steamControllers[i],
                      builder: (_, __) {
                        return Transform.translate(
                          offset: Offset(0, _steamY[i].value),
                          child: Opacity(
                            opacity: _steamOpacity[i].value.clamp(0.0, 1.0),
                            child: Transform.scale(
                              scale: _steamScale[i].value,
                              child: Container(
                                width: 6,
                                height: 24,
                                margin: const EdgeInsets.symmetric(horizontal: 2),
                                decoration: BoxDecoration(
                                  color: _steamColor,
                                  borderRadius: BorderRadius.circular(3),
                                ),
                              ),
                            ),
                          ),
                        );
                      },
                    );
                  }),
                ),
              ),

              // Cangkir kopi (custom painted)
              Positioned(
                bottom: 0,
                child: AnimatedBuilder(
                  animation: _fillAnim,
                  builder: (_, __) {
                    return CustomPaint(
                      size: const Size(96, 96),
                      painter: _CoffeeCupPainter(
                        fillProgress: _fillAnim.value,
                        strokeColor: _strokeColor,
                        fillColor: _fillColor,
                        cupBodyColor: _cupBodyColor,
                      ),
                    );
                  },
                ),
              ),
            ],
          ),
        ),

        const SizedBox(height: 16),

        // ── Teks berkedip ──
        AnimatedBuilder(
          animation: _textOpacity,
          builder: (_, __) {
            return Opacity(
              opacity: _textOpacity.value.clamp(0.0, 1.0),
              child: Text(
                widget.pesan,
                style: TextStyle(
                  fontFamily: 'Poppins',
                  fontWeight: FontWeight.w500,
                  fontSize: 16,
                  color: _textColor,
                ),
              ),
            );
          },
        ),
      ],
    );

    // Mode fullscreen
    if (widget.fullScreen) {
      return Material(
        color: _bgColor,
        child: Center(child: content),
      );
    }

    // Mode embedded
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(40),
        child: content,
      ),
    );
  }
}

/// Custom painter cangkir kopi dengan animasi isi kopi dari bawah ke atas.
class _CoffeeCupPainter extends CustomPainter {
  final double fillProgress;
  final Color strokeColor;
  final Color fillColor;
  final Color cupBodyColor;

  const _CoffeeCupPainter({
    required this.fillProgress,
    required this.strokeColor,
    required this.fillColor,
    required this.cupBodyColor,
  });

  @override
  void paint(Canvas canvas, Size size) {
    // Scale dari koordinat SVG viewBox (100×100) ke ukuran widget sebenarnya
    canvas.save();
    canvas.scale(size.width / 100, size.height / 100);

    // ── Body cangkir ──
    // SVG: M20,40 Q20,80 50,80 Q80,80 80,40 Z
    final bodyPath = Path()
      ..moveTo(20, 40)
      ..quadraticBezierTo(20, 80, 50, 80)
      ..quadraticBezierTo(80, 80, 80, 40)
      ..close();

    canvas.drawPath(
      bodyPath,
      Paint()
        ..color = cupBodyColor
        ..style = PaintingStyle.fill,
    );
    canvas.drawPath(
      bodyPath,
      Paint()
        ..color = strokeColor
        ..style = PaintingStyle.stroke
        ..strokeWidth = 3,
    );

    // ── Gagang cangkir ──
    // SVG: M80,45 Q95,45 95,55 Q95,65 80,65
    final handlePath = Path()
      ..moveTo(80, 45)
      ..quadraticBezierTo(95, 45, 95, 55)
      ..quadraticBezierTo(95, 65, 80, 65);

    canvas.drawPath(
      handlePath,
      Paint()
        ..color = strokeColor
        ..style = PaintingStyle.stroke
        ..strokeWidth = 3
        ..strokeCap = StrokeCap.round
        ..strokeJoin = StrokeJoin.round,
    );

    // ── Piring bawah (ellipse) ──
    // SVG: <ellipse cx="50" cy="85" rx="35" ry="5" opacity="0.15"/>
    canvas.drawOval(
      Rect.fromCenter(
        center: const Offset(50, 85),
        width: 70, // rx*2
        height: 10, // ry*2
      ),
      Paint()
        ..color = strokeColor.withOpacity(0.15)
        ..style = PaintingStyle.fill,
    );

    // ── Isi kopi (animasi scaleY dari bawah) ──
    // SVG: M23,45 Q23,77 50,77 Q77,77 77,45 Z
    // originY = bawah fill = y:77
    final fillPath = Path()
      ..moveTo(23, 45)
      ..quadraticBezierTo(23, 77, 50, 77)
      ..quadraticBezierTo(77, 77, 77, 45)
      ..close();

    canvas.save();
    canvas.clipPath(bodyPath);      // potong sesuai batas cangkir
    canvas.translate(0, 77);        // pindah origin ke bawah fill
    canvas.scale(1.0, fillProgress); // scale Y (0→1)
    canvas.translate(0, -77);       // kembalikan origin
    canvas.drawPath(
      fillPath,
      Paint()
        ..color = fillColor
        ..style = PaintingStyle.fill,
    );
    canvas.restore();

    canvas.restore();
  }

  @override
  bool shouldRepaint(_CoffeeCupPainter old) =>
      old.fillProgress != fillProgress ||
      old.strokeColor != strokeColor ||
      old.fillColor != fillColor ||
      old.cupBodyColor != cupBodyColor;
}