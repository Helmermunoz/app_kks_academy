import 'package:flutter/material.dart';

class AcademyBackground extends StatelessWidget {
  final Widget child;
  const AcademyBackground({super.key, required this.child});
  @override
  Widget build(BuildContext context) => DecoratedBox(
    decoration: const BoxDecoration(
      gradient: LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: [
          Color(0xffb9eee5),
          Color(0xffe5f1ff),
          Color(0xffdcebd2),
          Color(0xffffe7d5),
        ],
        stops: [0, .4, .75, 1],
      ),
    ),
    child: Stack(
      children: [
        const Positioned(
          top: -95,
          right: -90,
          child: _Orb(color: Color(0x22007889), size: 330),
        ),
        const Positioned(
          bottom: -110,
          left: -100,
          child: _Orb(color: Color(0x2269ad35), size: 370),
        ),
        Positioned.fill(child: CustomPaint(painter: _FieldLines())),
        child,
      ],
    ),
  );
}

class _Orb extends StatelessWidget {
  final Color color;
  final double size;
  const _Orb({required this.color, required this.size});
  @override
  Widget build(BuildContext context) => Container(
    width: size,
    height: size,
    decoration: BoxDecoration(shape: BoxShape.circle, color: color),
  );
}

class _FieldLines extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = const Color(0x12003558)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2;
    final center = Offset(size.width * .85, size.height * .45);
    for (final radius in [120.0, 190.0, 260.0]) {
      canvas.drawCircle(center, radius, paint);
    }
    final diamond = Path()
      ..moveTo(center.dx, center.dy - 100)
      ..lineTo(center.dx + 100, center.dy)
      ..lineTo(center.dx, center.dy + 100)
      ..lineTo(center.dx - 100, center.dy)
      ..close();
    canvas.drawPath(diamond, paint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

class AcademyPlayers extends StatelessWidget {
  const AcademyPlayers({super.key});
  @override
  Widget build(BuildContext context) => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Container(
        width: double.infinity,
        padding: const EdgeInsets.all(28),
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            colors: [Color(0xff071e3b), Color(0xff005d69), Color(0xff008c82)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(24),
          boxShadow: const [
            BoxShadow(
              color: Color(0x22002740),
              blurRadius: 24,
              offset: Offset(0, 10),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Wrap(
              spacing: 10,
              crossAxisAlignment: WrapCrossAlignment.center,
              children: [
                Icon(Icons.sports_baseball, color: Color(0xffbcf074), size: 30),
                Text(
                  'KKs ACADEMY / BÉISBOL',
                  style: TextStyle(
                    color: Color(0xffbcf074),
                    fontWeight: FontWeight.w800,
                    letterSpacing: 2,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),
            Text(
              'Andrés Muñoz',
              style: TextStyle(
                fontSize: MediaQuery.sizeOf(context).width < 500 ? 34 : 48,
                color: Colors.white,
                fontWeight: FontWeight.w900,
                height: 1.1,
              ),
            ),
            const SizedBox(height: 10),
            const Text(
              'Marineros de Seattle',
              style: TextStyle(color: Color(0xffb6ede4), fontSize: 19),
            ),
            const SizedBox(height: 24),
            const Text(
              'Tu talento. Tu posición. Tu programa.',
              style: TextStyle(
                color: Colors.white,
                fontSize: 22,
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 8),
            const Text(
              'Entrenamiento, recuperación y seguimiento en un mismo lugar. Para jugadores de todas las posiciones.',
              style: TextStyle(
                color: Color(0xffd9efef),
                fontSize: 16,
                height: 1.5,
              ),
            ),
          ],
        ),
      ),
      const SizedBox(height: 20),
      const Text(
        'Más pitchers en la academia',
        style: TextStyle(
          fontSize: 20,
          fontWeight: FontWeight.w800,
          color: Color(0xff092b47),
        ),
      ),
      const SizedBox(height: 12),
      LayoutBuilder(
        builder: (context, constraints) {
          final width = constraints.maxWidth < 650
              ? constraints.maxWidth
              : (constraints.maxWidth - 24) / 3;
          return Wrap(
            spacing: 12,
            runSpacing: 12,
            children: [
              _player(
                width,
                'BO',
                'Brayan Orrantia',
                'Orioles',
                const Color(0xffb84b10),
              ),
              _player(
                width,
                'LG',
                'Luis Enrique Gastelum',
                'Cardinals',
                const Color(0xffad243d),
              ),
              _player(
                width,
                'AU',
                'Alejandro Urias',
                'Mets · Cañeros',
                const Color(0xff1755a0),
              ),
            ],
          );
        },
      ),
      const SizedBox(height: 24),
    ],
  );
  Widget _player(
    double width,
    String initials,
    String name,
    String team,
    Color color,
  ) => Container(
    width: width,
    padding: const EdgeInsets.all(18),
    decoration: BoxDecoration(
      color: Colors.white,
      borderRadius: BorderRadius.circular(18),
      border: Border(top: BorderSide(color: color, width: 5)),
    ),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        CircleAvatar(
          backgroundColor: color,
          foregroundColor: Colors.white,
          child: Text(initials),
        ),
        const SizedBox(height: 12),
        Text(
          name,
          style: const TextStyle(
            fontSize: 17,
            fontWeight: FontWeight.w800,
            color: Color(0xff092b47),
          ),
        ),
        const SizedBox(height: 6),
        Text(
          team,
          style: TextStyle(color: color, fontWeight: FontWeight.w600),
        ),
      ],
    ),
  );
}
