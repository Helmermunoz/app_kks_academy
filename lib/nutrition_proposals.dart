import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

abstract class ProposalStore {
  Future<List<Map<String, dynamic>>> proposals(String athlete);
  Future<List<Map<String, dynamic>>> jobs(String athlete);
  Future<bool> qualifiedReviewer();
  Future<void> generate(String job);
  Future<void> review(String proposal, bool approve, String notes);
}

class SupabaseProposalStore implements ProposalStore {
  final SupabaseClient client;
  SupabaseProposalStore(this.client);
  @override
  Future<List<Map<String, dynamic>>> proposals(String athlete) => client
      .from('nutrition_proposals')
      .select()
      .eq('athlete_id', athlete)
      .order('generated_at', ascending: false)
      .limit(50);
  @override
  Future<List<Map<String, dynamic>>> jobs(String athlete) => client
      .from('nutrition_jobs')
      .select()
      .eq('athlete_id', athlete)
      .order('created_at', ascending: false)
      .limit(50);
  @override
  Future<bool> qualifiedReviewer() async =>
      (await client
          .from('nutrition_reviewers')
          .select('profile_id')
          .eq('profile_id', client.auth.currentUser!.id)
          .maybeSingle()) !=
      null;
  @override
  Future<void> generate(String job) async {
    await client.functions.invoke('nutrition-assistant', body: {'job_id': job});
  }

  @override
  Future<void> review(String proposal, bool approve, String notes) async {
    await client.rpc(
      'review_nutrition_proposal',
      params: {'target': proposal, 'approved': approve, 'notes': notes},
    );
  }
}

class NutritionProposalsPage extends StatefulWidget {
  final ProposalStore store;
  final String athlete;
  final bool staff;
  const NutritionProposalsPage({
    super.key,
    required this.store,
    required this.athlete,
    required this.staff,
  });
  @override
  State<NutritionProposalsPage> createState() => _NutritionProposalsPageState();
}

class _NutritionProposalsPageState extends State<NutritionProposalsPage> {
  List<Map<String, dynamic>> proposals = [], jobs = [];
  bool loading = true, busy = false, reviewer = false;
  String? error;
  @override
  void initState() {
    super.initState();
    load();
  }

  Future<void> load() async {
    setState(() {
      loading = true;
      error = null;
      proposals = [];
      jobs = [];
    });
    try {
      final p = await widget.store.proposals(widget.athlete);
      final j = widget.staff
          ? await widget.store.jobs(widget.athlete)
          : <Map<String, dynamic>>[];
      final r = widget.staff && await widget.store.qualifiedReviewer();
      if (mounted) {
        setState(() {
          proposals = p;
          jobs = j;
          reviewer = r;
        });
      }
    } catch (_) {
      if (mounted) {
        setState(
          () => error = 'No se pudieron cargar las propuestas. Revisa la conexión y la configuración con administración.',
        );
      }
    } finally {
      if (mounted) setState(() => loading = false);
    }
  }

  Future<void> perform(Future<void> Function() action) async {
    if (busy) return;
    setState(() => busy = true);
    try {
      await action();
      if (mounted) await load();
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(
              'No se pudo completar. Revisa permisos, estado y límites; espera antes de reintentar.',
            ),
          ),
        );
      }
    } finally {
      if (mounted) setState(() => busy = false);
    }
  }

  Future<void> review(Map<String, dynamic> p, bool approve) async {
    var notes = '';
    final result = await showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(
          approve ? 'Aprobar propuesta revisada' : 'Rechazar propuesta',
        ),
        content: TextField(
          onChanged: (value) => notes = value,
          maxLength: 2000,
          maxLines: 4,
          decoration: const InputDecoration(
            labelText: 'Notas de revisión profesional',
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancelar'),
          ),
          FilledButton(
            onPressed: () {
              if (notes.trim().isNotEmpty) {
                Navigator.pop(context, notes.trim());
              }
            },
            child: const Text('Confirmar revisión'),
          ),
        ],
      ),
    );
    if (result != null && mounted) {
      await perform(() => widget.store.review(p['id'], approve, result));
    }
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(
      title: const Text('Propuestas de alimentación'),
      actions: [
        IconButton(
          tooltip: 'Actualizar',
          onPressed: busy || loading ? null : load,
          icon: const Icon(Icons.refresh),
        ),
      ],
    ),
    body: loading
        ? const Center(child: CircularProgressIndicator())
        : SingleChildScrollView(
            padding: const EdgeInsets.all(20),
            child: Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 700),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    const Text(
                      'Ideas generales de comidas. Requieren revisión de un profesional acreditado; no sustituyen atención clínica.',
                    ),
                    if (widget.staff)
                      const Text(
                        'Las sesiones publicadas con horario, duración e intensidad generan un trabajo pendiente para adultos con consentimiento registrado. Procesar un trabajo puede usar la API si administración habilitó el modo real.',
                      ),
                    if (error != null) ...[
                      Text(error!),
                      TextButton(
                        onPressed: load,
                        child: const Text('Reintentar'),
                      ),
                    ],
                    for (final j in jobs.where(
                      (j) => [
                        'pending',
                        'failed',
                        'running',
                      ].contains(j['status']),
                    ))
                      Card(
                        child: ListTile(
                          title: Text(
                            'Trabajo · ${j['status']} · versión ${j['workout_version']}',
                          ),
                          subtitle: Text('Intentos: ${j['attempts']}/3'),
                          trailing: IconButton(
                            tooltip: 'Procesar trabajo pendiente',
                            icon: const Icon(Icons.play_arrow),
                            onPressed: busy || j['attempts'] >= 3
                                ? null
                                : () => perform(
                                    () => widget.store.generate(j['id']),
                                  ),
                          ),
                        ),
                      ),
                    if (proposals.isEmpty && error == null)
                      Padding(
                        padding: const EdgeInsets.all(20),
                        child: Text(
                          widget.staff
                              ? 'Todavía no hay borradores.'
                              : 'Todavía no hay propuestas aprobadas vigentes.',
                        ),
                      ),
                    for (final p in proposals)
                      Card(
                        child: Padding(
                          padding: const EdgeInsets.all(16),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                '${p['status']} · ${p['generation_mode'] == 'mock' ? 'EJEMPLO DE PRUEBA' : 'Revisión profesional'}',
                                style: const TextStyle(
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              Text(
                                'Sesión versión ${p['source_workout_version']} · ${p['generated_at']}',
                              ),
                              for (final meal
                                  in (p['content']['meals'] as List))
                                Padding(
                                  padding: const EdgeInsets.symmetric(
                                    vertical: 8,
                                  ),
                                  child: Text(
                                    '${meal['suggestion']}\n${meal['timing']}',
                                  ),
                                ),
                              Text('Hidratación: ${p['content']['hydration']}'),
                              Text('Recuperación: ${p['content']['recovery']}'),
                              Text(p['content']['review_warning']),
                              if (p['review_notes'] != null)
                                Text('Revisión: ${p['review_notes']}'),
                              if (reviewer && p['status'] == 'draft')
                                Wrap(
                                  spacing: 8,
                                  children: [
                                    FilledButton(
                                      onPressed:
                                          busy || p['generation_mode'] == 'mock'
                                          ? null
                                          : () => review(p, true),
                                      child: const Text('Aprobar'),
                                    ),
                                    OutlinedButton(
                                      onPressed: busy
                                          ? null
                                          : () => review(p, false),
                                      child: const Text('Rechazar'),
                                    ),
                                  ],
                                ),
                            ],
                          ),
                        ),
                      ),
                  ],
                ),
              ),
            ),
          ),
  );
}
