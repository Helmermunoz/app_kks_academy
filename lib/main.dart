import 'academy_brand.dart';
import 'academy_portal.dart';
import 'academy_repository.dart';

import 'package:supabase_flutter/supabase_flutter.dart';

import 'session_videos_stub.dart'
    if (dart.library.js_interop) 'session_videos_web.dart';

import 'package:flutter/material.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  const url = String.fromEnvironment('SUPABASE_URL');
  const key = String.fromEnvironment('SUPABASE_PUBLISHABLE_KEY');
  AcademyRepository? repository;
  String? startupError;
  if (url.isNotEmpty && key.isNotEmpty) {
    try {
      await Supabase.initialize(url: url, publishableKey: key);
      repository = SupabaseAcademyRepository(Supabase.instance.client);
    } catch (_) {
      startupError = 'No se pudo conectar con la academia. Revisa la configuración y vuelve a abrir la app.';
    }
  }
  runApp(MyApp(repository: repository, startupError: startupError));
}

class MyApp extends StatelessWidget {
  final AcademyRepository? repository;
  final String? startupError;
  final bool demo;
  const MyApp({
    super.key,
    this.repository,
    this.startupError,
    this.demo = false,
  });
  @override
  Widget build(BuildContext context) => MaterialApp(
    title: 'KKs Academy',
    debugShowCheckedModeBanner: false,
    theme: ThemeData(
      colorScheme: ColorScheme.fromSeed(seedColor: const Color(0xff126755)),
      scaffoldBackgroundColor: const Color(0xffdcefea),
      useMaterial3: true,
    ),
    home: demo
        ? const AcademyHome()
        : repository != null
        ? AcademyPortal(repository: repository!)
        : SetupPage(error: startupError),
  );
}

class SetupPage extends StatelessWidget {
  final String? error;
  const SetupPage({super.key, this.error});
  @override
  Widget build(BuildContext context) => PortalFrame(
    title: 'KKs ACADEMY',
    child: Card(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Estamos preparando tu academia',
              style: TextStyle(fontSize: 26, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 12),
            Text(
              error ?? 'El acceso con cuentas todavía no está habilitado. Mientras tanto, puedes explorar el diseño con datos de ejemplo.',
            ),
            const SizedBox(height: 20),
            OutlinedButton(
              onPressed: () => Navigator.of(context).push(
                MaterialPageRoute<void>(builder: (_) => const AcademyHome()),
              ),
              child: const Text('Explorar demostración'),
            ),
          ],
        ),
      ),
    ),
  );
}

class AcademyHome extends StatefulWidget {
  const AcademyHome({super.key});
  @override
  State<AcademyHome> createState() => _AcademyHomeState();
}

class _AcademyHomeState extends State<AcademyHome> {
  String position = 'Pitcher';
  String assignedPosition = 'Pitcher';
  bool coach = false;
  int day = 0;
  final Set<int> completed = {};
  final positions = const ['Pitcher', 'Catcher', 'Cuadro', 'Jardinero'];
  final days = const ['Lun', 'Mar', 'Mié', 'Jue', 'Vie', 'Sáb', 'Dom'];
  final titles = const [
    'Técnica y movimiento',
    'Fuerza y movilidad',
    'Trabajo de posición',
    'Recuperación',
    'Técnica y coordinación',
    'Práctica de equipo',
    'Descanso',
  ];
  late final DateTime monday;

  @override
  void initState() {
    super.initState();
    final now = DateTime.now();
    monday = DateTime(
      now.year,
      now.month,
      now.day,
    ).subtract(Duration(days: now.weekday - 1));
  }

  String date(DateTime value) => '${value.day}/${value.month}';
  String get focus => switch (assignedPosition) {
    'Catcher' => 'Recepción, bloqueos y mecánica de tiro a bases',
    'Cuadro' => 'Fildeo de rodados, desplazamientos y tiros a primera',
    'Jardinero' => 'Lectura de elevados, rutas y tiros al cuadro',
    _ => 'Mecánica de lanzamiento y control',
  };

  Widget panel(String title, IconData icon, List<Widget> children) => Card(
    elevation: 0,
    color: Colors.white,
    margin: const EdgeInsets.only(bottom: 16),
    child: Padding(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, color: const Color(0xff126755)),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  title,
                  style: const TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          ...children,
        ],
      ),
    ),
  );

  Widget detail(IconData icon, String title, String value) => Padding(
    padding: const EdgeInsets.only(bottom: 16),
    child: Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, size: 20, color: Colors.grey.shade600),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: TextStyle(fontSize: 12, color: Colors.grey.shade700),
              ),
              const SizedBox(height: 3),
              Text(
                value,
                style: const TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
        ),
      ],
    ),
  );

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(
      backgroundColor: const Color(0xff071e3b),
      foregroundColor: Colors.white,
      title: const Text(
        'KKs ACADEMY',
        style: TextStyle(fontWeight: FontWeight.w900, letterSpacing: 2),
      ),
    ),
    body: AcademyBackground(
      child: SingleChildScrollView(
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 1200),
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const AcademyPlayers(),
                  Container(
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      color: const Color(0xffffefcf),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Text(
                      'DEMOSTRACIÓN · Datos de ejemplo. Los cambios duran hasta recargar. Las cuentas privadas aún no están habilitadas.',
                    ),
                  ),
                  const SizedBox(height: 24),
                  Wrap(
                    spacing: 16,
                    runSpacing: 12,
                    crossAxisAlignment: WrapCrossAlignment.center,
                    children: [
                      const Text(
                        'Mi semana',
                        style: TextStyle(
                          fontSize: 36,
                          fontWeight: FontWeight.w900,
                          color: Color(0xff123d34),
                        ),
                      ),
                      Chip(
                        label: Text(
                          '${date(monday)} — ${date(monday.add(const Duration(days: 6)))}',
                        ),
                      ),
                      FilterChip(
                        label: const Text('Vista de entrenador · demo'),
                        selected: coach,
                        onSelected: (value) => setState(() => coach = value),
                      ),
                    ],
                  ),
                  const SizedBox(height: 6),
                  Text(
                    'Hola, Alex. Cada sesión cuenta.',
                    style: TextStyle(fontSize: 18, color: Colors.grey.shade700),
                  ),
                  const SizedBox(height: 24),
                  if (coach)
                    panel('Asignar programa', Icons.edit_calendar_outlined, [
                      const Text(
                        'Selecciona una posición y aplica su plantilla a esta semana de ejemplo. El cambio conserva las sesiones completadas.',
                      ),
                      const SizedBox(height: 16),
                      DropdownButtonFormField<String>(
                        initialValue: position,
                        decoration: const InputDecoration(
                          labelText: 'Posición del programa',
                          border: OutlineInputBorder(),
                        ),
                        items: positions
                            .map(
                              (p) => DropdownMenuItem(value: p, child: Text(p)),
                            )
                            .toList(),
                        onChanged: (value) => setState(() => position = value!),
                      ),
                      const SizedBox(height: 16),
                      FilledButton(
                        onPressed: () {
                          setState(() => assignedPosition = position);
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text(
                                'Plantilla aplicada a la semana de ejemplo',
                              ),
                            ),
                          );
                        },
                        child: const Text('Asignar a esta semana'),
                      ),
                    ]),

                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(28),
                    decoration: BoxDecoration(
                      color: const Color(0xff123d34),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'TU PROGRAMA PERSONAL',
                          style: TextStyle(
                            color: Color(0xffb9e777),
                            letterSpacing: 2,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 12),
                        Text(
                          assignedPosition,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 30,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          focus,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 16,
                          ),
                        ),
                        const SizedBox(height: 22),
                        Text(
                          '${completed.length} de 5 entrenamientos completados',
                          style: const TextStyle(color: Colors.white),
                        ),
                        const SizedBox(height: 8),
                        LinearProgressIndicator(
                          value: completed.length / 5,
                          color: const Color(0xffb9e777),
                          backgroundColor: Colors.white24,
                          minHeight: 6,
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 24),
                  const Text(
                    'Tu calendario',
                    style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 12),
                  SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    child: Row(
                      children: List.generate(
                        7,
                        (i) => Padding(
                          padding: const EdgeInsets.only(right: 10),
                          child: ChoiceChip(
                            label: SizedBox(
                              width: 70,
                              child: Column(
                                children: [
                                  Text(days[i]),
                                  Text(
                                    '${monday.add(Duration(days: i)).day}',
                                    style: const TextStyle(
                                      fontSize: 24,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                  Text(
                                    completed.contains(i)
                                        ? 'Hecho'
                                        : (i == 3 || i == 6
                                              ? 'Descanso'
                                              : 'Sesión'),
                                    style: const TextStyle(fontSize: 11),
                                  ),
                                ],
                              ),
                            ),
                            selected: day == i,
                            onSelected: (_) => setState(() => day = i),
                          ),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 24),
                  LayoutBuilder(
                    builder: (context, constraints) {
                      final workout = panel(
                        titles[day],
                        Icons.sports_baseball_outlined,
                        [
                          Text(
                            '${days[day]} ${date(monday.add(Duration(days: day)))}',
                            style: const TextStyle(fontWeight: FontWeight.bold),
                          ),
                          const SizedBox(height: 20),
                          if (day == 3 || day == 6)
                            const Text(
                              'Sin entrenamiento asignado. Consulta las indicaciones de recuperación de tu entrenador.',
                            )
                          else ...[
                            detail(
                              Icons.schedule,
                              'Horario de ejemplo',
                              '16:00 – 17:15',
                            ),
                            detail(
                              Icons.location_on_outlined,
                              'Lugar de entrenamiento',
                              'Campo principal · ubicación por confirmar',
                            ),
                            detail(
                              Icons.fitness_center,
                              'Trabajo general',
                              'Calentamiento, movilidad y coordinación',
                            ),
                            detail(
                              Icons.sports_baseball,
                              'Trabajo de posición',
                              focus,
                            ),
                            detail(
                              Icons.straighten,
                              'Cantidad de tiros, distancia e intensidad',
                              'Pendientes de asignación del entrenador',
                            ),
                            const Divider(),
                            const SizedBox(height: 12),
                            FilledButton.icon(
                              onPressed: () => setState(() {
                                if (!completed.add(day)) {
                                  completed.remove(day);
                                }
                              }),
                              icon: Icon(
                                completed.contains(day)
                                    ? Icons.check_circle
                                    : Icons.check,
                              ),
                              label: Text(
                                completed.contains(day)
                                    ? 'Desmarcar entrenamiento'
                                    : 'Completé mi entrenamiento',
                              ),
                            ),
                          ],
                        ],
                      );
                      final support = Column(
                        children: [
                          panel('Alimentación', Icons.restaurant_outlined, [
                            detail(
                              Icons.local_fire_department_outlined,
                              'Gasto energético estimado',
                              'Pendiente de evaluación individual',
                            ),
                            const Text(
                              'Aquí verás tus comidas sugeridas y el objetivo de calorías cuando se asigne tu plan de alimentación.',
                            ),
                          ]),
                          panel(
                            'Terapia y recuperación',
                            Icons.favorite_border,
                            [
                              const Text('No hay citas asignadas esta semana.'),
                              const SizedBox(height: 10),
                              Text(
                                'Aquí aparecerán fecha, hora, especialista y lugar de tu próxima sesión.',
                                style: TextStyle(color: Colors.grey.shade700),
                              ),
                            ],
                          ),
                        ],
                      );
                      if (constraints.maxWidth < 750) {
                        return Column(children: [workout, support]);
                      }
                      return Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Expanded(flex: 3, child: workout),
                          const SizedBox(width: 20),
                          Expanded(flex: 2, child: support),
                        ],
                      );
                    },
                  ),
                  SessionVideos(day: day, coach: coach),
                  const SizedBox(height: 12),
                  const Text(
                    'KKs Academy · Entrena con un plan. Crece a tu ritmo.',
                    style: TextStyle(color: Color(0xff526b60)),
                  ),
                  const SizedBox(height: 24),
                ],
              ),
            ),
          ),
        ),
      ),
    ),
  );
}
