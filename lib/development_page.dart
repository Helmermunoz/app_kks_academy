import 'package:flutter/material.dart';

import 'development_store.dart';
import 'session_details.dart';
import 'video_store.dart';
import 'video_platform_stub.dart'
    if (dart.library.js_interop) 'video_platform_web.dart';

String dayString(DateTime day) => day.toIso8601String().substring(0, 10);
List<DevelopmentRow> sessionClips(DevelopmentRow row) =>
    List<DevelopmentRow>.from(row['session_videos'] ?? []);
bool completedSession(DevelopmentRow row) =>
    singleRelated(row['workout_completions']) != null;
bool pendingReview(DevelopmentRow row) =>
    sessionClips(row).any((v) => singleRelated(v['video_reviews']) == null);

class DevelopmentPage extends StatefulWidget {
  final DevelopmentStore store;
  final VideoStore? videos;
  final bool staff;
  final Map<String, String> athletes;
  final String? initialAthlete;
  const DevelopmentPage({
    super.key,
    required this.store,
    required this.staff,
    required this.athletes,
    this.videos,
    this.initialAthlete,
  });
  @override
  State<DevelopmentPage> createState() => _DevelopmentPageState();
}

class _DevelopmentPageState extends State<DevelopmentPage> {
  List<DevelopmentRow> rows = [];
  bool loading = true;
  String? error;
  late String? athlete = widget.staff ? null : widget.initialAthlete;
  String filter = 'all';
  late DateTimeRange range = DateTimeRange(
    start: DateTime.now().subtract(const Duration(days: 30)),
    end: DateTime.now().add(const Duration(days: 7)),
  );
  @override
  void initState() {
    super.initState();
    load();
  }

  Future<void> load() async {
    setState(() {
      loading = true;
      error = null;
    });
    try {
      final data = await widget.store.sessions(
        dayString(range.start),
        dayString(range.end),
      );
      if (mounted) setState(() => rows = data);
    } catch (e) {
      if (mounted) setState(() => error = developmentError(e));
    } finally {
      if (mounted) setState(() => loading = false);
    }
  }

  Future<void> report(DevelopmentRow row) async {
    final saved = await showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (_) => SessionReportDialog(session: row, store: widget.store),
    );
    if (saved == true && mounted) await load();
  }

  Future<void> review(DevelopmentRow row, DevelopmentRow clip) async {
    final saved = await showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (_) => VideoReviewDialog(
        clip: clip,
        store: widget.store,
        videos: widget.videos,
        canEdit: widget.staff,
      ),
    );
    if (saved == true && mounted) await load();
  }

  @override
  Widget build(BuildContext context) {
    final selected = rows
        .where((r) => athlete == null || r['athlete_id'] == athlete)
        .toList();
    final visible = selected
        .where(
          (r) => switch (filter) {
            'pending' => !completedSession(r),
            'discomfort' =>
              singleRelated(r['session_reports'])?['discomfort'] == true,
            'videos' => pendingReview(r),
            _ => true,
          },
        )
        .toList();
    final reports = selected
        .map((r) => singleRelated(r['session_reports']))
        .whereType<DevelopmentRow>();
    final pitches = reports.fold<int>(
      0,
      (sum, r) => sum + ((r['actual_pitches'] as num?)?.toInt() ?? 0),
    );
    // Only include sessions with BOTH counts in the percentage denominator.
    final counted = reports.where(
      (r) => r['actual_pitches'] != null && r['strikes'] != null,
    );
    final countedPitches = counted.fold<num>(
      0,
      (sum, r) => sum + r['actual_pitches'],
    );
    final strikes = counted.fold<num>(0, (sum, r) => sum + r['strikes']);
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.staff ? 'Panel del entrenador' : 'Mi seguimiento'),
        actions: [
          IconButton(
            onPressed: loading ? null : load,
            tooltip: 'Actualizar',
            icon: const Icon(Icons.refresh),
          ),
        ],
      ),
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 1000),
          child: ListView(
            padding: const EdgeInsets.all(20),
            children: [
              const Text(
                'Plan, resultados y revisión en un solo lugar.',
                style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 12),
              if (widget.staff)
                DropdownButtonFormField<String>(
                  initialValue: athlete ?? '',
                  isExpanded: true,
                  decoration: const InputDecoration(labelText: 'Atleta'),
                  items: [
                    const DropdownMenuItem(
                      value: '',
                      child: Text('Todos mis atletas'),
                    ),
                    ...widget.athletes.entries.map(
                      (e) =>
                          DropdownMenuItem(value: e.key, child: Text(e.value)),
                    ),
                  ],
                  onChanged: loading
                      ? null
                      : (v) => setState(() => athlete = v == '' ? null : v),
                ),
              OutlinedButton.icon(
                icon: const Icon(Icons.date_range),
                label: Text(
                  '${dayString(range.start)} — ${dayString(range.end)}',
                ),
                onPressed: loading
                    ? null
                    : () async {
                        final value = await showDateRangePicker(
                          context: context,
                          initialDateRange: range,
                          firstDate: DateTime(2000),
                          lastDate: DateTime(2100),
                        );
                        if (value != null && mounted) {
                          setState(() => range = value);
                          await load();
                        }
                      },
              ),
              if (loading)
                const LinearProgressIndicator()
              else if (error != null) ...[
                Text(
                  error!,
                  style: TextStyle(color: Theme.of(context).colorScheme.error),
                ),
                TextButton(onPressed: load, child: const Text('Reintentar')),
              ] else ...[
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    Chip(
                      label: Text(
                        '${selected.where(completedSession).length}/${selected.length} sesiones completadas',
                      ),
                    ),
                    Chip(label: Text('$pitches lanzamientos registrados')),
                    Chip(
                      label: Text(
                        countedPitches == 0
                            ? 'Strikes: sin datos'
                            : '${(100 * strikes / countedPitches).toStringAsFixed(1)}% strikes',
                      ),
                    ),
                    Chip(
                      label: Text(
                        '${selected.where((r) => singleRelated(r['session_reports'])?['discomfort'] == true).length} reportes con molestias',
                      ),
                    ),
                    Chip(
                      label: Text(
                        '${selected.expand(sessionClips).where((v) => singleRelated(v['video_reviews']) == null).length} videos sin revisar',
                      ),
                    ),
                  ],
                ),
                const Text(
                  'El porcentaje usa solo sesiones con lanzamientos y strikes registrados. Guardar resultados no marca la sesión como completada.',
                ),
                const SizedBox(height: 12),
                Wrap(
                  spacing: 8,
                  children:
                      {
                            'all': 'Todas',
                            'pending': 'Sin completar',
                            'discomfort': 'Con molestias',
                            'videos': 'Videos por revisar',
                          }.entries
                          .map(
                            (e) => ChoiceChip(
                              label: Text(e.value),
                              selected: filter == e.key,
                              onSelected: (_) => setState(() => filter = e.key),
                            ),
                          )
                          .toList(),
                ),
                if (visible.isEmpty)
                  const Padding(
                    padding: EdgeInsets.all(24),
                    child: Text('No hay sesiones para estos filtros.'),
                  ),
                ...visible.map((row) {
                  final result = singleRelated(row['session_reports']);
                  return Card(
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          Text(
                            '${widget.athletes[row['athlete_id']] ?? 'Atleta'} · ${row['day']}',
                            style: const TextStyle(fontWeight: FontWeight.bold),
                          ),
                          Text(
                            row['title'],
                            style: const TextStyle(fontSize: 20),
                          ),
                          SessionDetails(session: row),
                          Text(
                            completedSession(row)
                                ? 'Completado por el atleta'
                                : 'Sin completar',
                          ),
                          if (result != null) ...[
                            Text('Esfuerzo: ${result['effort']}/10'),
                            if (result['actual_pitches'] != null)
                              Text(
                                'Lanzamientos: ${result['actual_pitches']} · Planeados: ${result['planned_pitches'] ?? 'sin registrar'} · Strikes: ${result['strikes'] ?? 'sin registrar'}',
                              ),
                            if (result['velocity_mph'] != null)
                              Text(
                                'Velocidad registrada con radar: ${result['velocity_mph']} mph',
                              ),
                            if ((result['pitch_types'] ?? '') != '')
                              Text('Tipos: ${result['pitch_types']}'),
                            if (result['discomfort'] == true)
                              const Text(
                                'Molestias reportadas: requiere revisión del equipo.',
                                style: TextStyle(color: Color(0xffffa4ad)),
                              ),
                            if ((result['notes'] ?? '') != '')
                              Text(result['notes']),
                            Text(
                              'Última edición: ${result['updated_at'] ?? ''}',
                              style: Theme.of(context).textTheme.bodySmall,
                            ),
                          ],
                          OutlinedButton.icon(
                            onPressed: () => report(row),
                            icon: const Icon(Icons.assignment),
                            label: Text(
                              result == null
                                  ? 'Registrar resultados'
                                  : 'Editar resultados',
                            ),
                          ),
                          ...sessionClips(row).map((v) {
                            final status = singleRelated(
                              v['video_reviews'],
                            )?['status'];
                            return ListTile(
                              contentPadding: EdgeInsets.zero,
                              title: Text(v['title']),
                              subtitle: Text(reviewLabel(status)),
                              trailing: const Icon(Icons.rate_review),
                              onTap: () => review(row, v),
                            );
                          }),
                          if (sessionClips(row).isEmpty)
                            const Text('Sin videos en esta sesión.'),
                        ],
                      ),
                    ),
                  );
                }),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

String reviewLabel(String? status) => switch (status) {
  'reviewed' => 'Revisado',
  'work_on' => 'Trabajar esta corrección',
  _ => 'Pendiente de revisar',
};

class SessionReportDialog extends StatefulWidget {
  final DevelopmentRow session;
  final DevelopmentStore store;
  const SessionReportDialog({
    super.key,
    required this.session,
    required this.store,
  });
  @override
  State<SessionReportDialog> createState() => _SessionReportDialogState();
}

class _SessionReportDialogState extends State<SessionReportDialog> {
  final form = GlobalKey<FormState>();
  late final existing = singleRelated(widget.session['session_reports']);
  late final fields = {
    for (final key in [
      'planned_pitches',
      'actual_pitches',
      'strikes',
      'velocity_mph',
      'pitch_types',
      'effort',
      'notes',
    ])
      key: TextEditingController(text: existing?[key]?.toString() ?? ''),
  };
  late bool discomfort = existing?['discomfort'] == true;
  bool busy = false;
  String? error;
  bool get throwing => ['bullpen', 'training'].contains(widget.session['kind']);
  @override
  void dispose() {
    for (final c in fields.values) {
      c.dispose();
    }
    super.dispose();
  }

  Widget number(
    String key,
    String label, {
    bool required = false,
    double min = 0,
    double max = 500,
    bool decimal = false,
  }) => Padding(
    padding: const EdgeInsets.only(bottom: 12),
    child: TextFormField(
      controller: fields[key],
      enabled: !busy,
      keyboardType: TextInputType.numberWithOptions(decimal: decimal),
      decoration: InputDecoration(labelText: label),
      validator: (raw) {
        final text = (raw ?? '').trim().replaceAll(',', '.');
        if (text.isEmpty) return required ? 'Completa este dato' : null;
        final value = decimal ? double.tryParse(text) : int.tryParse(text);
        if (value == null || !value.isFinite || value < min || value > max) {
          return 'Usa un valor entre $min y $max';
        }
        if (key == 'strikes') {
          final total = int.tryParse(fields['actual_pitches']!.text.trim());
          if (total == null || value > total) {
            return 'Los strikes no pueden superar los lanzamientos';
          }
        }
        return null;
      },
    ),
  );

  Future<void> save() async {
    if (!form.currentState!.validate()) return;
    setState(() {
      busy = true;
      error = null;
    });
    try {
      await widget.store.saveReport(widget.session['id'], {
        for (final key in ['planned_pitches', 'actual_pitches', 'strikes'])
          key: throwing ? int.tryParse(fields[key]!.text.trim()) : null,
        'velocity_mph': throwing
            ? double.tryParse(
                fields['velocity_mph']!.text.trim().replaceAll(',', '.'),
              )
            : null,
        'pitch_types': throwing ? fields['pitch_types']!.text.trim() : '',
        'effort': int.parse(fields['effort']!.text.trim()),
        'discomfort': discomfort,
        'notes': fields['notes']!.text.trim(),
      }, existing != null);
      if (mounted) Navigator.pop(context, true);
    } catch (e) {
      if (mounted) setState(() => error = developmentError(e));
    } finally {
      if (mounted) setState(() => busy = false);
    }
  }

  @override
  Widget build(BuildContext context) => PopScope(
    canPop: !busy,
    child: AlertDialog(
      title: const Text('Resultados de la sesión'),
      content: SizedBox(
        width: 520,
        child: SingleChildScrollView(
          child: Form(
            key: form,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text('${widget.session['title']} · ${widget.session['day']}'),
                if ((widget.session['throwing_plan'] ?? '') != '')
                  Text(
                    'Plan del entrenador: ${widget.session['throwing_plan']}',
                  ),
                const SizedBox(height: 16),
                if (throwing) ...[
                  number(
                    'planned_pitches',
                    'Lanzamientos planeados (opcional)',
                  ),
                  number(
                    'actual_pitches',
                    'Lanzamientos realizados (opcional)',
                  ),
                  number('strikes', 'Strikes (opcional)'),
                  number(
                    'velocity_mph',
                    'Velocidad con radar, mph (opcional)',
                    decimal: true,
                    min: 0.1,
                    max: 120,
                  ),
                  TextFormField(
                    controller: fields['pitch_types'],
                    enabled: !busy,
                    maxLength: 500,
                    decoration: const InputDecoration(
                      labelText: 'Tipos y cantidades',
                      hintText: '20 rectas, 10 cambios…',
                    ),
                  ),
                ],
                number(
                  'effort',
                  'Esfuerzo percibido, 1 a 10',
                  required: true,
                  min: 1,
                  max: 10,
                ),
                SwitchListTile(
                  contentPadding: EdgeInsets.zero,
                  title: const Text('Hubo molestias'),
                  value: discomfort,
                  onChanged: busy
                      ? null
                      : (v) => setState(() => discomfort = v),
                ),
                if (discomfort)
                  const Text(
                    'Este reporte se mostrará al equipo para su revisión.',
                  ),
                TextFormField(
                  controller: fields['notes'],
                  enabled: !busy,
                  maxLength: 2000,
                  minLines: 2,
                  maxLines: 5,
                  decoration: const InputDecoration(
                    labelText: 'Comentarios / descripción de molestias',
                  ),
                  validator: (v) => discomfort && (v ?? '').trim().isEmpty
                      ? 'Describe las molestias para el equipo'
                      : null,
                ),
                if (error != null)
                  Text(
                    error!,
                    style: TextStyle(
                      color: Theme.of(context).colorScheme.error,
                    ),
                  ),
              ],
            ),
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: busy ? null : () => Navigator.pop(context),
          child: const Text('Cancelar'),
        ),
        FilledButton(
          onPressed: busy ? null : save,
          child: Text(busy ? 'Guardando…' : 'Guardar resultados'),
        ),
      ],
    ),
  );
}

class VideoReviewDialog extends StatefulWidget {
  final DevelopmentRow clip;
  final DevelopmentStore store;
  final VideoStore? videos;
  final bool canEdit;
  const VideoReviewDialog({
    super.key,
    required this.clip,
    required this.store,
    required this.canEdit,
    this.videos,
  });
  @override
  State<VideoReviewDialog> createState() => _VideoReviewDialogState();
}

class _VideoReviewDialogState extends State<VideoReviewDialog> {
  final form = GlobalKey<FormState>();
  late final existing = singleRelated(widget.clip['video_reviews']);
  late final notes = TextEditingController(text: existing?['notes'] ?? '');
  late final seconds = TextEditingController(
    text: existing?['at_seconds']?.toString() ?? '',
  );
  late String status = existing?['status'] ?? 'reviewed';
  String? url, error;
  bool busy = false, loading = true;
  @override
  void initState() {
    super.initState();
    playback();
  }

  Future<void> playback() async {
    setState(() {
      loading = true;
      error = null;
    });
    try {
      final value = await widget.videos?.playback(widget.clip['object_path']);
      if (mounted) setState(() => url = value);
    } catch (_) {
      if (mounted) {
        setState(
          () =>
              error = 'No se pudo abrir el video. Intenta cargarlo nuevamente.',
        );
      }
    } finally {
      if (mounted) setState(() => loading = false);
    }
  }

  @override
  void dispose() {
    notes.dispose();
    seconds.dispose();
    super.dispose();
  }

  Future<void> save() async {
    if (!form.currentState!.validate()) return;
    setState(() {
      busy = true;
      error = null;
    });
    try {
      await widget.store.saveReview(widget.clip['id'], {
        'status': status,
        'notes': notes.text.trim(),
        'at_seconds': int.tryParse(seconds.text.trim()),
      }, existing != null);
      if (mounted) Navigator.pop(context, true);
    } catch (e) {
      if (mounted) setState(() => error = developmentError(e));
    } finally {
      if (mounted) setState(() => busy = false);
    }
  }

  @override
  Widget build(BuildContext context) => PopScope(
    canPop: !busy,
    child: AlertDialog(
      title: Text(widget.clip['title']),
      content: SizedBox(
        width: 700,
        child: SingleChildScrollView(
          child: Form(
            key: form,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const Text(
                  'Revisión privada para el atleta y su equipo de entrenamiento.',
                ),
                if (loading) const LinearProgressIndicator(),
                if (url != null) videoPlayer(url!),
                TextButton(
                  onPressed: busy || loading ? null : playback,
                  child: const Text('Recargar video'),
                ),
                if (widget.canEdit) ...[
                  DropdownButtonFormField<String>(
                    initialValue: status,
                    isExpanded: true,
                    decoration: const InputDecoration(
                      labelText: 'Estado de revisión',
                    ),
                    items: ['reviewed', 'work_on']
                        .map(
                          (s) => DropdownMenuItem(
                            value: s,
                            child: Text(reviewLabel(s)),
                          ),
                        )
                        .toList(),
                    onChanged: busy ? null : (s) => setState(() => status = s!),
                  ),
                  const SizedBox(height: 16),
                  TextFormField(
                    controller: seconds,
                    enabled: !busy,
                    keyboardType: TextInputType.number,
                    decoration: const InputDecoration(
                      labelText: 'Segundo del video (opcional)',
                      hintText: '12',
                    ),
                    validator: (v) {
                      if ((v ?? '').trim().isEmpty) return null;
                      final n = int.tryParse(v!.trim());
                      return n == null || n < 0 || n > 86400
                          ? 'Escribe un segundo válido'
                          : null;
                    },
                  ),
                  TextFormField(
                    controller: notes,
                    enabled: !busy,
                    maxLength: 2000,
                    minLines: 3,
                    maxLines: 6,
                    decoration: const InputDecoration(
                      labelText: 'Observación del entrenador',
                    ),
                    validator: (v) =>
                        status == 'work_on' && (v ?? '').trim().isEmpty
                        ? 'Describe la corrección'
                        : null,
                  ),
                ] else ...[
                  Text(
                    reviewLabel(existing?['status']),
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                  if (existing?['at_seconds'] != null)
                    Text('Segundo ${existing!['at_seconds']} del video'),
                  Text(
                    existing?['notes'] ??
                        'Tu entrenador todavía no ha revisado este video.',
                  ),
                ],
                if (existing != null)
                  Text(
                    'Última revisión: ${existing!['reviewed_at']}',
                    style: Theme.of(context).textTheme.bodySmall,
                  ),
                if (error != null)
                  Text(
                    error!,
                    style: TextStyle(
                      color: Theme.of(context).colorScheme.error,
                    ),
                  ),
              ],
            ),
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: busy ? null : () => Navigator.pop(context),
          child: const Text('Cerrar'),
        ),
        if (widget.canEdit)
          FilledButton(
            onPressed: busy ? null : save,
            child: Text(busy ? 'Guardando…' : 'Guardar revisión'),
          ),
      ],
    ),
  );
}
