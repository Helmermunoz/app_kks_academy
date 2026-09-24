import 'package:flutter/material.dart';

import 'nutrition_store.dart';

const measurementFields = {
  'height_cm': 'Estatura (cm)',
  'weight_kg': 'Peso (kg)',
  'body_fat_percent': 'Grasa corporal (%)',
  'fat_mass_kg': 'Masa grasa (kg)',
  'skeletal_muscle_kg': 'Masa muscular esquelética (kg)',
  'basal_kcal': 'Metabolismo basal (kcal/día)',
};
double? parseMeasurement(String text) =>
    double.tryParse(text.trim().replaceAll(',', '.'));
String? validateMeasurement(String key, String text, {double? weight}) {
  if (text.trim().isEmpty) {
    return key == 'weight_kg' ? 'Ingresa el peso del reporte' : null;
  }
  final n = parseMeasurement(text);
  final max = switch (key) {
    'height_cm' => 300.0,
    'body_fat_percent' => 100.0,
    'basal_kcal' => 10000.0,
    _ => 500.0,
  };
  final zeroAllowed = [
    'body_fat_percent',
    'fat_mass_kg',
    'skeletal_muscle_kg',
  ].contains(key);
  if (n == null || !n.isFinite || n > max || (zeroAllowed ? n < 0 : n <= 0)) {
    return 'Revisa el valor y la unidad del reporte';
  }
  if (['fat_mass_kg', 'skeletal_muscle_kg'].contains(key) &&
      weight != null &&
      n > weight) {
    return 'No puede superar el peso total';
  }
  return null;
}

class NutritionPage extends StatefulWidget {
  final NutritionStore store;
  final String athlete, athleteName;
  const NutritionPage({
    super.key,
    required this.store,
    required this.athlete,
    required this.athleteName,
  });
  @override
  State<NutritionPage> createState() => _NutritionPageState();
}

class _NutritionPageState extends State<NutritionPage> {
  NutritionRecord? profile;
  List<NutritionRecord> rows = [];
  bool loading = true;
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
      rows = [];
    });
    try {
      final p = await widget.store.profile(widget.athlete);
      final records = await widget.store.measurements(widget.athlete);
      if (mounted) {
        setState(() {
          profile = p;
          rows = records;
        });
      }
    } catch (_) {
      if (mounted) {
        setState(
          () => error = 'No se pudo cargar alimentación. Revisa tu conexión o contacta al administrador para habilitar este apartado.',
        );
      }
    } finally {
      if (mounted) setState(() => loading = false);
    }
  }

  Future<void> edit(bool measurement) async {
    final saved = await showDialog<bool>(
      context: context,
      builder: (_) => NutritionForm(
        measurement: measurement,
        initial: measurement ? null : profile,
        save: (values) => measurement
            ? widget.store.addMeasurement(widget.athlete, values)
            : widget.store.saveProfile(
                widget.athlete,
                values,
                exists: profile != null,
              ),
      ),
    );
    if (saved == true && mounted) await load();
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(
      title: const Text('Mi alimentación / InBody'),
      actions: [
        IconButton(
          onPressed: loading ? null : load,
          tooltip: 'Actualizar',
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
                constraints: const BoxConstraints(maxWidth: 900),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Text(
                      widget.athleteName,
                      style: Theme.of(context).textTheme.headlineSmall,
                    ),
                    const Text(
                      'Datos privados: acceso del atleta, sus entrenadores asignados y administración.',
                    ),
                    const SizedBox(height: 16),
                    if (error != null) ...[
                      Text(error!),
                      TextButton(
                        onPressed: load,
                        child: const Text('Reintentar'),
                      ),
                    ] else ...[
                      Card(
                        child: Padding(
                          padding: const EdgeInsets.all(20),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text(
                                'Perfil de alimentación',
                                style: TextStyle(
                                  fontSize: 22,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              if (profile == null)
                                const Text(
                                  'Completa tus datos personales y preferencias.',
                                ),
                              if (profile?['birth_date'] != null)
                                Text(
                                  'Fecha de nacimiento: ${profile!['birth_date']}',
                                ),
                              ...{
                                'goals': 'Objetivos',
                                'allergies': 'Alergias e intolerancias',
                                'preferences': 'Preferencias de comida',
                                'budget': 'Presupuesto',
                              }.entries.map(
                                (e) => Text(
                                  '${e.value}: ${(profile?[e.key] as String? ?? '').isEmpty ? 'Sin registrar' : profile![e.key]}',
                                ),
                              ),
                              OutlinedButton(
                                onPressed: () => edit(false),
                                child: const Text('Editar perfil'),
                              ),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(height: 12),
                      FilledButton.icon(
                        onPressed: () => edit(true),
                        icon: const Icon(Icons.add),
                        label: const Text('Registrar medición InBody'),
                      ),
                      const SizedBox(height: 12),
                      const Text(
                        'Copia los valores del reporte. El metabolismo basal no es una meta de calorías diarias. Los datos no se envían a una IA; las sugerencias de comidas todavía no están habilitadas.',
                      ),
                      if (rows.isEmpty)
                        const Padding(
                          padding: EdgeInsets.all(24),
                          child: Text('Aún no hay mediciones registradas.'),
                        ),
                      if (rows.isNotEmpty) ...[
                        InBodyChart(rows: rows),
                        const Text(
                          'Historial · hasta 500 mediciones recientes',
                          style: TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        ...rows.map(
                          (r) => Card(
                            child: Padding(
                              padding: const EdgeInsets.all(16),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    r['measured_on'],
                                    style: const TextStyle(
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                  ...measurementFields.entries
                                      .where((e) => r[e.key] != null)
                                      .map(
                                        (e) => Text('${e.value}: ${r[e.key]}'),
                                      ),
                                  if ((r['notes'] as String? ?? '').isNotEmpty)
                                    Text('Observaciones: ${r['notes']}'),
                                ],
                              ),
                            ),
                          ),
                        ),
                      ],
                    ],
                  ],
                ),
              ),
            ),
          ),
  );
}

class NutritionForm extends StatefulWidget {
  final bool measurement;
  final NutritionRecord? initial;
  final Future<void> Function(NutritionRecord) save;
  const NutritionForm({
    super.key,
    required this.measurement,
    this.initial,
    required this.save,
  });
  @override
  State<NutritionForm> createState() => _NutritionFormState();
}

class _NutritionFormState extends State<NutritionForm> {
  final form = GlobalKey<FormState>();
  late final fields = <String, TextEditingController>{
    for (final key
        in (widget.measurement
            ? [...measurementFields.keys, 'notes']
            : ['goals', 'allergies', 'preferences', 'budget']))
      key: TextEditingController(text: widget.initial?[key]?.toString()),
  };
  late DateTime? date = widget.measurement
      ? DateTime.now()
      : widget.initial?['birth_date'] == null
      ? null
      : DateTime.parse(widget.initial!['birth_date']);
  bool busy = false;
  String? error;
  @override
  void dispose() {
    for (final c in fields.values) {
      c.dispose();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => PopScope(
    canPop: !busy,
    child: AlertDialog(
      title: Text(
        widget.measurement
            ? 'Registrar medición InBody'
            : 'Perfil de alimentación',
      ),
      content: SizedBox(
        width: 500,
        child: SingleChildScrollView(
          child: Form(
            key: form,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  widget.measurement
                      ? 'Registra una evaluación nueva; las anteriores se conservan. Solo el peso y la fecha son obligatorios.'
                      : 'Completa solo los datos que quieras registrar. Se guardan en tu perfil privado.',
                ),
                OutlinedButton.icon(
                  icon: const Icon(Icons.calendar_month),
                  label: Text(
                    '${widget.measurement ? 'Fecha de medición' : 'Fecha de nacimiento'}: ${date == null ? 'Sin registrar' : date!.toIso8601String().substring(0, 10)}',
                  ),
                  onPressed: busy
                      ? null
                      : () async {
                          final selected = await showDatePicker(
                            context: context,
                            initialDate: date ?? DateTime.now(),
                            firstDate: DateTime(1900),
                            lastDate: DateTime.now(),
                          );
                          if (selected != null && mounted) {
                            setState(() => date = selected);
                          }
                        },
                ),
                if (!widget.measurement && date != null)
                  TextButton(
                    onPressed: busy ? null : () => setState(() => date = null),
                    child: const Text('Quitar fecha de nacimiento'),
                  ),
                ...fields.entries.map((entry) {
                  final numeric = measurementFields.containsKey(entry.key);
                  final label =
                      measurementFields[entry.key] ??
                      {
                        'notes': 'Observaciones del reporte o del nutriólogo',
                        'goals': 'Objetivos',
                        'allergies': 'Alergias e intolerancias',
                        'preferences': 'Preferencias de comida',
                        'budget': 'Presupuesto (indica moneda y periodo)',
                      }[entry.key]!;
                  return TextFormField(
                    controller: entry.value,
                    enabled: !busy,
                    key: ValueKey(entry.key),
                    decoration: InputDecoration(labelText: label),
                    keyboardType: numeric
                        ? const TextInputType.numberWithOptions(decimal: true)
                        : TextInputType.multiline,
                    maxLines: numeric ? 1 : 3,
                    maxLength: numeric
                        ? 10
                        : entry.key == 'budget'
                        ? 300
                        : entry.key == 'notes'
                        ? 3000
                        : 2000,
                    validator: numeric
                        ? (v) => validateMeasurement(
                            entry.key,
                            v ?? '',
                            weight: parseMeasurement(
                              fields['weight_kg']?.text ?? '',
                            ),
                          )
                        : null,
                  );
                }),
                if (error != null)
                  Text(error!, style: const TextStyle(color: Colors.red)),
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
          onPressed: busy
              ? null
              : () async {
                  if (!form.currentState!.validate()) return;
                  setState(() {
                    busy = true;
                    error = null;
                  });
                  final values = <String, dynamic>{
                    widget.measurement ? 'measured_on' : 'birth_date': date
                        ?.toIso8601String()
                        .substring(0, 10),
                    for (final e in fields.entries)
                      e.key: measurementFields.containsKey(e.key)
                          ? parseMeasurement(e.value.text)
                          : e.value.text.trim(),
                  };
                  try {
                    await widget.save(values);
                    if (context.mounted) Navigator.pop(context, true);
                  } catch (_) {
                    if (mounted) {
                      setState(
                        () => error = 'No se pudo guardar. Revisa la conexión y los permisos. Tus datos siguen en este formulario.',
                      );
                    }
                  } finally {
                    if (mounted) setState(() => busy = false);
                  }
                },
          child: Text(busy ? 'Guardando…' : 'Guardar'),
        ),
      ],
    ),
  );
}

class InBodyChart extends StatefulWidget {
  final List<NutritionRecord> rows;
  const InBodyChart({super.key, required this.rows});
  @override
  State<InBodyChart> createState() => _InBodyChartState();
}

class _InBodyChartState extends State<InBodyChart> {
  String metric = 'weight_kg';
  @override
  Widget build(BuildContext context) {
    final data = widget.rows.where((r) => r[metric] != null).toList()
      ..sort((a, b) {
        final day = (a['measured_on'] as String).compareTo(b['measured_on']);
        return day != 0
            ? day
            : (a['created_at'] as String? ?? '').compareTo(
                b['created_at'] as String? ?? '',
              );
      });
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const Text(
              'Evolución de tus mediciones',
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
            DropdownButton<String>(
              value: metric,
              isExpanded: true,
              items: measurementFields.entries
                  .map(
                    (e) => DropdownMenuItem(value: e.key, child: Text(e.value)),
                  )
                  .toList(),
              onChanged: (value) => setState(() => metric = value!),
            ),
            if (data.length < 2)
              const Text(
                'Registra al menos dos valores de esta medida para ver su evolución.',
              )
            else ...[
              Text(
                '${data.first[metric]} → ${data.last[metric]} · ${measurementFields[metric]}',
              ),
              SizedBox(
                height: 160,
                child: Semantics(
                  label:
                      'Gráfica de ${measurementFields[metric]}. Los valores completos están en el historial.',
                  child: CustomPaint(painter: _TrendPainter(data, metric)),
                ),
              ),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(data.first['measured_on']),
                  Text(data.last['measured_on']),
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _TrendPainter extends CustomPainter {
  final List<NutritionRecord> rows;
  final String metric;
  _TrendPainter(this.rows, this.metric);
  @override
  void paint(Canvas canvas, Size size) {
    final values = rows.map((r) => (r[metric] as num).toDouble()).toList();
    final low = values.reduce((a, b) => a < b ? a : b);
    final high = values.reduce((a, b) => a > b ? a : b);
    final start = DateTime.parse(rows.first['measured_on'])
        .millisecondsSinceEpoch;
    final end = DateTime.parse(rows.last['measured_on']).millisecondsSinceEpoch;
    final pen = Paint()
      ..color = const Color(0xff126755)
      ..strokeWidth = 2
      ..style = PaintingStyle.stroke;
    final path = Path();
    for (var i = 0; i < rows.length; i++) {
      final time = DateTime.parse(rows[i]['measured_on'])
          .millisecondsSinceEpoch;
      final x =
          12 +
          (size.width - 24) *
              (end == start
                  ? i / (rows.length - 1)
                  : (time - start) / (end - start));
      final y = high == low
          ? size.height / 2
          : 12 + (size.height - 24) * (high - values[i]) / (high - low);
      if (i == 0) {
        path.moveTo(x, y);
      } else {
        path.lineTo(x, y);
      }
      canvas.drawCircle(
        Offset(x, y),
        4,
        Paint()..color = const Color(0xff126755),
      );
    }
    canvas.drawPath(path, pen);
  }

  @override
  bool shouldRepaint(covariant _TrendPainter oldDelegate) => true;
}
