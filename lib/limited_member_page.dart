import 'package:flutter/material.dart';

import 'academy_repository.dart';
import 'academy_portal.dart';
import 'nutrition_page.dart';
import 'session_details.dart';

class LimitedMemberPage extends StatefulWidget {
  final AcademyRepository repository;
  final Record profile;
  final List<Record> people;
  const LimitedMemberPage({
    super.key,
    required this.repository,
    required this.profile,
    required this.people,
  });
  @override
  State<LimitedMemberPage> createState() => _LimitedMemberPageState();
}

class _LimitedMemberPageState extends State<LimitedMemberPage> {
  String? selected;
  @override
  Widget build(BuildContext context) {
    final nutrition = widget.profile['role'] == 'nutrition';
    final athletes = widget.people
        .where((p) => p['role'] == 'athlete')
        .toList();
    selected ??= athletes.isEmpty ? null : athletes.first['id'] as String;
    final athlete = athletes.where((p) => p['id'] == selected).firstOrNull;
    return PortalFrame(
      title: 'KKs ACADEMY',
      actions: [
        IconButton(
          tooltip: 'Cerrar sesión',
          icon: const Icon(Icons.logout),
          onPressed: widget.repository.signOut,
        ),
      ],
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            'Hola, ${widget.profile['name']}',
            style: const TextStyle(fontSize: 28),
          ),
          Text(nutrition ? 'Nutrición' : 'Administrador · solo consulta'),
          if (athletes.isEmpty)
            const Text('Todavía no hay atletas registrados.'),
          if (athletes.isNotEmpty)
            DropdownButtonFormField<String>(
              initialValue: selected,
              decoration: const InputDecoration(labelText: 'Atleta'),
              items: athletes
                  .map(
                    (p) => DropdownMenuItem<String>(
                      value: p['id'],
                      child: Text(p['name']),
                    ),
                  )
                  .toList(),
              onChanged: (value) => setState(() => selected = value),
            ),
          if (athlete != null && widget.repository.nutritionStore != null)
            OutlinedButton.icon(
              icon: const Icon(Icons.restaurant),
              label: const Text('Alimentación / InBody'),
              onPressed: () => Navigator.push<void>(
                context,
                MaterialPageRoute(
                  builder: (_) => NutritionPage(
                    store: widget.repository.nutritionStore!,
                    athlete: selected!,
                    athleteName: athlete['name'],
                    readOnly: !nutrition,
                  ),
                ),
              ),
            ),
          if (!nutrition && selected != null)
            FutureBuilder<List<Record>>(
              key: ValueKey(selected),
              future: widget.repository.workouts(selected!),
              builder: (context, snapshot) {
                if (snapshot.hasError) {
                  return const Text(
                    'No se pudieron cargar los entrenamientos.',
                  );
                }
                if (!snapshot.hasData) return const LinearProgressIndicator();
                if (snapshot.data!.isEmpty) {
                  return const Text('Sin entrenamientos registrados.');
                }
                return Column(
                  children: snapshot.data!
                      .map(
                        (w) => Card(
                          child: Padding(
                            padding: const EdgeInsets.all(16),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text('${w['day']} · ${w['title']}'),
                                Text(w['instructions']),
                                SessionDetails(session: w),
                              ],
                            ),
                          ),
                        ),
                      )
                      .toList(),
                );
              },
            ),
        ],
      ),
    );
  }
}
