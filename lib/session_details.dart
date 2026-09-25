import 'package:flutter/material.dart';

const sessionKinds = {
  'training': 'Entrenamiento',
  'bullpen': 'Bullpen',
  'track': 'Pista',
  'therapy': 'Terapia',
};

class SessionDetails extends StatelessWidget {
  final Map<String, dynamic> session;
  const SessionDetails({super.key, required this.session});
  @override
  Widget build(BuildContext context) => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Chip(label: Text(sessionKinds[session['kind']] ?? 'Entrenamiento')),
      Text(
        'Lugar: ${(session['location'] as String? ?? '').isEmpty ? 'Por confirmar' : session['location']}',
      ),
      Text(
        'Hora: ${session['start_time'] == null ? 'Por confirmar' : (session['start_time'] as String).substring(0, 5)}',
      ),
      if ((session['throwing_plan'] as String? ?? '').isNotEmpty) ...[
        const SizedBox(height: 8),
        const Text(
          'Plan de tiros',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        Text(session['throwing_plan']),
      ],
    ],
  );
}

class TherapyNotice extends StatelessWidget {
  final List<Map<String, dynamic>> sessions;
  final Set<String> completed;
  const TherapyNotice({
    super.key,
    required this.sessions,
    required this.completed,
  });
  @override
  Widget build(BuildContext context) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final upcoming = sessions
        .where(
          (s) =>
              s['kind'] == 'therapy' &&
              !completed.contains(s['id']) &&
              !DateTime.parse(s['day']).isBefore(today),
        )
        .toList();
    if (upcoming.isEmpty) return const SizedBox.shrink();
    return Card(
      color: const Color(0xff3b2d18),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Row(
              children: [
                Icon(Icons.event_note),
                SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'Terapia agendada',
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                ),
              ],
            ),
            ...upcoming.map(
              (s) => Text(
                '${s['day']} · ${s['start_time'] == null ? 'Hora por confirmar' : (s['start_time'] as String).substring(0, 5)} · ${s['title']}',
              ),
            ),
            const Text('Revisa el lugar y las indicaciones de tu cita.'),
          ],
        ),
      ),
    );
  }
}
