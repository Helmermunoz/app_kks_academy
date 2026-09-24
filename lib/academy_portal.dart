import 'dart:async';

import 'package:flutter/material.dart';

import 'academy_brand.dart';
import 'academy_repository.dart';
import 'session_details.dart';
import 'video_panel.dart';

String roleLabel(String role) => switch (role) {
  'admin' => 'Administrador',
  'coach' => 'Entrenador',
  _ => 'Atleta',
};

class AcademyPortal extends StatefulWidget {
  final AcademyRepository repository;
  const AcademyPortal({super.key, required this.repository});
  @override
  State<AcademyPortal> createState() => _AcademyPortalState();
}

class _AcademyPortalState extends State<AcademyPortal> {
  StreamSubscription<String?>? subscription;
  String? user;
  @override
  void initState() {
    super.initState();
    user = widget.repository.userId;
    subscription = widget.repository.sessions.listen((id) {
      if (mounted) setState(() => user = id);
    });
  }

  @override
  void dispose() {
    subscription?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => user == null
      ? LoginPage(repository: widget.repository)
      : MemberPage(key: ValueKey(user), repository: widget.repository);
}

class PortalFrame extends StatelessWidget {
  final String title;
  final Widget child;
  final List<Widget>? actions;
  const PortalFrame({
    super.key,
    required this.title,
    required this.child,
    this.actions,
  });
  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(
      title: Text(title),
      actions: actions,
      backgroundColor: const Color(0xff071e3b),
      foregroundColor: Colors.white,
    ),
    body: AcademyBackground(
      child: SizedBox.expand(
        child: SingleChildScrollView(
          child: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 1000),
              child: Padding(padding: const EdgeInsets.all(20), child: child),
            ),
          ),
        ),
      ),
    ),
  );
}

class LoginPage extends StatefulWidget {
  final AcademyRepository repository;
  const LoginPage({super.key, required this.repository});
  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  final email = TextEditingController();
  final password = TextEditingController();
  final form = GlobalKey<FormState>();
  bool busy = false;
  String? error;
  @override
  void dispose() {
    email.dispose();
    password.dispose();
    super.dispose();
  }

  Future<void> login() async {
    if (!form.currentState!.validate() || busy) return;
    setState(() {
      busy = true;
      error = null;
    });
    try {
      await widget.repository.signIn(email.text, password.text);
    } catch (_) {
      if (mounted) {
        setState(
          () => error = 'No se pudo iniciar sesión. Revisa tu correo, contraseña y conexión.',
        );
      }
    } finally {
      if (mounted) setState(() => busy = false);
    }
  }

  @override
  Widget build(BuildContext context) => PortalFrame(
    title: 'KKs ACADEMY',
    child: Center(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 440),
        child: Card(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Form(
              key: form,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  const Text(
                    'Tu próximo entrenamiento empieza aquí',
                    style: TextStyle(fontSize: 26, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 12),
                  const Text('Entra con la cuenta que te entregó la academia.'),
                  const SizedBox(height: 24),
                  TextFormField(
                    controller: email,
                    decoration: const InputDecoration(
                      labelText: 'Correo electrónico',
                    ),
                    keyboardType: TextInputType.emailAddress,
                    autofillHints: const [AutofillHints.username],
                    validator: (v) => v != null && v.contains('@')
                        ? null
                        : 'Escribe tu correo',
                  ),
                  TextFormField(
                    controller: password,
                    decoration: const InputDecoration(labelText: 'Contraseña'),
                    obscureText: true,
                    autofillHints: const [AutofillHints.password],
                    onFieldSubmitted: (_) => login(),
                    validator: (v) =>
                        v == null || v.isEmpty ? 'Escribe tu contraseña' : null,
                  ),
                  const SizedBox(height: 24),
                  if (error != null)
                    Text(error!, style: const TextStyle(color: Colors.red)),
                  FilledButton(
                    onPressed: busy ? null : login,
                    child: Text(busy ? 'Entrando…' : 'Entrar'),
                  ),
                  const SizedBox(height: 12),
                  const Text(
                    'Si necesitas recuperar el acceso, contacta al administrador de la academia.',
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    ),
  );
}

class MemberPage extends StatefulWidget {
  final AcademyRepository repository;
  const MemberPage({super.key, required this.repository});
  @override
  State<MemberPage> createState() => _MemberPageState();
}

class _MemberPageState extends State<MemberPage> {
  Record? profile;
  List<Record> people = [], links = [], workouts = [];
  Set<String> completed = {};
  String? athlete, error;
  bool loading = true, busy = false;
  int request = 0;
  AcademyRepository get repo => widget.repository;
  bool get staff => profile?['role'] == 'admin' || profile?['role'] == 'coach';
  bool get admin => profile?['role'] == 'admin';
  @override
  void initState() {
    super.initState();
    reload();
  }

  Future<void> reload() async {
    final ticket = ++request;
    setState(() {
      loading = true;
      error = null;
      workouts = [];
      completed = {};
    });
    try {
      final me = await repo.profile();
      final members = await repo.people();
      final assignments = me['role'] == 'admin'
          ? await repo.assignments()
          : <Record>[];
      final athletes = members.where((p) => p['role'] == 'athlete').toList();
      final selected = me['role'] == 'athlete'
          ? me['id'] as String
          : athletes.any((p) => p['id'] == athlete)
          ? athlete
          : athletes.isEmpty
          ? null
          : athletes.first['id'] as String;
      final rows = selected == null
          ? <Record>[]
          : await repo.workouts(selected);
      final done = selected == null
          ? <String>{}
          : await repo.completions(selected);
      if (!mounted || ticket != request) return;
      setState(() {
        profile = me;
        people = members;
        links = assignments;
        athlete = selected;
        workouts = rows;
        completed = done;
      });
    } catch (_) {
      if (mounted && ticket == request) {
        setState(
          () => error = 'No se pudieron cargar tus datos. Revisa la conexión o contacta al administrador.',
        );
      }
    } finally {
      if (mounted && ticket == request) setState(() => loading = false);
    }
  }

  Future<void> perform(Future<void> Function() action) async {
    if (busy) return;
    setState(() => busy = true);
    try {
      await action();
      if (mounted) await reload();
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(
              'No se pudo guardar el cambio. Revisa la conexión y tus permisos e intenta de nuevo.',
            ),
          ),
        );
      }
    } finally {
      if (mounted) setState(() => busy = false);
    }
  }

  Future<void> editWorkout([Record? workout]) async {
    final target = athlete;
    if (target == null) return;
    final saved = await showDialog<bool>(
      context: context,
      builder: (_) => WorkoutDialog(
        workout: workout,
        save: (day, title, instructions, details) => repo.saveWorkout(
          target,
          workout?['id'],
          day,
          title,
          instructions,
          details: details,
        ),
      ),
    );
    if (saved == true && mounted) await reload();
  }

  @override
  Widget build(BuildContext context) => PortalFrame(
    title: 'KKs ACADEMY',
    actions: [
      IconButton(
        tooltip: 'Actualizar',
        onPressed: loading || busy ? null : reload,
        icon: const Icon(Icons.refresh),
      ),
      IconButton(
        tooltip: 'Cerrar sesión',
        onPressed: busy
            ? null
            : () async {
                try {
                  await repo.signOut();
                } catch (_) {
                  if (context.mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text(
                          'No se pudo cerrar sesión. Intenta de nuevo.',
                        ),
                      ),
                    );
                  }
                }
              },
        icon: const Icon(Icons.logout),
      ),
    ],
    child: loading
        ? const Center(child: CircularProgressIndicator())
        : error != null
        ? Column(
            children: [
              Text(error!),
              FilledButton(onPressed: reload, child: const Text('Reintentar')),
            ],
          )
        : profile?['must_change_password'] == true
        ? PasswordForm(repository: repo, onSaved: reload)
        : Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const AcademyPlayers(),
              Text(
                'Hola, ${profile!['name']}',
                style: const TextStyle(
                  fontSize: 28,
                  fontWeight: FontWeight.bold,
                ),
              ),
              Text(roleLabel(profile!['role'])),
              const SizedBox(height: 20),
              if (admin) ...[
                Align(
                  alignment: Alignment.centerLeft,
                  child: FilledButton.icon(
                    onPressed: busy
                        ? null
                        : () async {
                            final saved = await showDialog<bool>(
                              context: context,
                              builder: (_) => AccountDialog(repository: repo),
                            );
                            if (saved == true && mounted) await reload();
                          },
                    icon: const Icon(Icons.person_add),
                    label: const Text('Crear cuenta'),
                  ),
                ),
                const SizedBox(height: 16),
              ],
              if (staff && people.any((p) => p['role'] == 'athlete'))
                DropdownButtonFormField<String>(
                  key: ValueKey(athlete),
                  initialValue: athlete,
                  isExpanded: true,
                  decoration: const InputDecoration(
                    labelText: 'Atleta',
                    border: OutlineInputBorder(),
                  ),
                  items: people
                      .where((p) => p['role'] == 'athlete')
                      .map(
                        (p) => DropdownMenuItem<String>(
                          value: p['id'],
                          child: Text(p['name']),
                        ),
                      )
                      .toList(),
                  onChanged: busy
                      ? null
                      : (value) {
                          athlete = value;
                          reload();
                        },
                ),
              if (admin && athlete != null)
                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Entrenadores de este atleta',
                          style: TextStyle(fontWeight: FontWeight.bold),
                        ),
                        if (!people.any((p) => p['role'] == 'coach'))
                          const Text(
                            'Crea una cuenta de entrenador para asignarla.',
                          ),
                        ...people
                            .where((p) => p['role'] == 'coach')
                            .map(
                              (p) => CheckboxListTile(
                                title: Text(p['name']),
                                contentPadding: EdgeInsets.zero,
                                value: links.any(
                                  (l) =>
                                      l['coach_id'] == p['id'] &&
                                      l['athlete_id'] == athlete,
                                ),
                                onChanged: busy
                                    ? null
                                    : (value) => perform(
                                        () => repo.assign(
                                          p['id'],
                                          athlete!,
                                          value!,
                                        ),
                                      ),
                              ),
                            ),
                      ],
                    ),
                  ),
                ),
              const SizedBox(height: 20),
              const Text(
                'Entrenamientos personales',
                style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
              ),
              Text(
                staff
                    ? 'Solo el atleta, sus entrenadores y administración pueden ver este plan.'
                    : 'Este plan está asignado a tu cuenta.',
              ),
              const SizedBox(height: 12),
              if (staff && athlete != null)
                Align(
                  alignment: Alignment.centerLeft,
                  child: FilledButton.icon(
                    onPressed: busy ? null : () => editWorkout(),
                    icon: const Icon(Icons.add),
                    label: const Text('Agregar entrenamiento'),
                  ),
                ),
              if (athlete == null)
                const Padding(
                  padding: EdgeInsets.all(24),
                  child: Text('Todavía no tienes atletas asignados.'),
                )
              else if (workouts.isEmpty)
                const Padding(
                  padding: EdgeInsets.all(24),
                  child: Text('Todavía no hay entrenamientos asignados.'),
                ),
              TherapyNotice(sessions: workouts, completed: completed),
              if (repo.videoStore != null)
                OutlinedButton.icon(
                  icon: const Icon(Icons.video_library),
                  label: const Text('Videos de la academia'),
                  onPressed: () => showDialog<void>(
                    context: context,
                    builder: (_) => VideoPanel(store: repo.videoStore!),
                  ),
                ),
              ...workouts.map(
                (w) => Card(
                  child: Padding(
                    padding: const EdgeInsets.all(20),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          w['day'],
                          style: const TextStyle(color: Color(0xff126755)),
                        ),
                        Text(
                          w['title'],
                          style: const TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 10),
                        Text(w['instructions']),
                        SessionDetails(session: w),
                        if (repo.videoStore != null && w['kind'] != 'therapy')
                          OutlinedButton.icon(
                            icon: const Icon(Icons.video_collection),
                            label: const Text(
                              'Ver / subir videos de esta sesión',
                            ),
                            onPressed: () => showDialog<void>(
                              context: context,
                              builder: (_) => VideoPanel(
                                store: repo.videoStore!,
                                workout: w,
                              ),
                            ),
                          ),
                        const SizedBox(height: 12),
                        if (staff)
                          Wrap(
                            spacing: 12,
                            crossAxisAlignment: WrapCrossAlignment.center,
                            children: [
                              OutlinedButton.icon(
                                onPressed: busy ? null : () => editWorkout(w),
                                icon: const Icon(Icons.edit),
                                label: const Text('Editar'),
                              ),
                              Text(
                                completed.contains(w['id'])
                                    ? 'Completado por el atleta'
                                    : 'Pendiente',
                              ),
                            ],
                          )
                        else
                          CheckboxListTile(
                            contentPadding: EdgeInsets.zero,
                            title: const Text('Completé mi entrenamiento'),
                            value: completed.contains(w['id']),
                            onChanged: busy
                                ? null
                                : (value) => perform(
                                    () => repo.complete(
                                      athlete!,
                                      w['id'],
                                      value!,
                                    ),
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
}

class PasswordForm extends StatefulWidget {
  final AcademyRepository repository;
  final Future<void> Function() onSaved;
  const PasswordForm({
    super.key,
    required this.repository,
    required this.onSaved,
  });
  @override
  State<PasswordForm> createState() => _PasswordFormState();
}

class _PasswordFormState extends State<PasswordForm> {
  final password = TextEditingController();
  final form = GlobalKey<FormState>();
  bool busy = false;
  String? error;
  @override
  void dispose() {
    password.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => Form(
    key: form,
    child: Column(
      children: [
        const Text(
          'Elige tu contraseña personal',
          style: TextStyle(fontSize: 24),
        ),
        const Text('Reemplaza la contraseña temporal antes de continuar.'),
        TextFormField(
          controller: password,
          obscureText: true,
          decoration: const InputDecoration(labelText: 'Nueva contraseña'),
          validator: (v) =>
              (v?.length ?? 0) < 12 ? 'Usa al menos 12 caracteres' : null,
        ),
        TextFormField(
          obscureText: true,
          decoration: const InputDecoration(labelText: 'Confirmar contraseña'),
          validator: (v) =>
              v != password.text ? 'Las contraseñas no coinciden' : null,
        ),
        if (error != null)
          Text(error!, style: const TextStyle(color: Colors.red)),
        const SizedBox(height: 16),
        FilledButton(
          onPressed: busy
              ? null
              : () async {
                  if (!form.currentState!.validate()) return;
                  setState(() {
                    busy = true;
                    error = null;
                  });
                  try {
                    await widget.repository.changePassword(password.text);
                    if (mounted) await widget.onSaved();
                  } catch (_) {
                    if (mounted) {
                      setState(
                        () => error = 'No se pudo cambiar. Usa una contraseña distinta y revisa tu conexión.',
                      );
                    }
                  } finally {
                    if (mounted) setState(() => busy = false);
                  }
                },
          child: Text(busy ? 'Guardando…' : 'Guardar contraseña'),
        ),
      ],
    ),
  );
}

class WorkoutDialog extends StatefulWidget {
  final Record? workout;
  final Future<void> Function(
    String day,
    String title,
    String instructions,
    Record details,
  )
  save;
  const WorkoutDialog({super.key, this.workout, required this.save});
  @override
  State<WorkoutDialog> createState() => _WorkoutDialogState();
}

class _WorkoutDialogState extends State<WorkoutDialog> {
  late String kind = widget.workout?['kind'] ?? 'training';
  late final location = TextEditingController(
    text: widget.workout?['location'],
  );
  late final throwingPlan = TextEditingController(
    text: widget.workout?['throwing_plan'],
  );
  late final startTime = TextEditingController(
    text: (widget.workout?['start_time'] as String?)?.substring(0, 5),
  );
  final form = GlobalKey<FormState>();
  late final title = TextEditingController(text: widget.workout?['title']);
  late final instructions = TextEditingController(
    text: widget.workout?['instructions'],
  );
  late DateTime day = widget.workout == null
      ? DateTime.now()
      : DateTime.parse(widget.workout!['day']);
  bool busy = false;
  String? error;
  String get date =>
      '${day.year.toString().padLeft(4, '0')}-${day.month.toString().padLeft(2, '0')}-${day.day.toString().padLeft(2, '0')}';
  @override
  void dispose() {
    title.dispose();
    instructions.dispose();
    location.dispose();
    throwingPlan.dispose();
    startTime.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => PopScope(
    canPop: !busy,
    child: AlertDialog(
      title: Text(
        widget.workout == null
            ? 'Agregar entrenamiento'
            : 'Editar entrenamiento',
      ),
      content: SizedBox(
        width: 500,
        child: SingleChildScrollView(
          child: Form(
            key: form,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                OutlinedButton.icon(
                  onPressed: busy
                      ? null
                      : () async {
                          final selected = await showDatePicker(
                            context: context,
                            initialDate: day,
                            firstDate: DateTime(2000),
                            lastDate: DateTime(2100),
                          );
                          if (selected != null && mounted) {
                            setState(() => day = selected);
                          }
                        },
                  icon: const Icon(Icons.calendar_month),
                  label: Text(date),
                ),
                DropdownButtonFormField<String>(
                  initialValue: kind,
                  decoration: const InputDecoration(
                    labelText: 'Tipo de sesión',
                  ),
                  items: sessionKinds.entries
                      .map(
                        (e) => DropdownMenuItem(
                          value: e.key,
                          child: Text(e.value),
                        ),
                      )
                      .toList(),
                  onChanged: busy ? null : (v) => setState(() => kind = v!),
                ),
                if (kind == 'therapy')
                  const Text(
                    'Se mostrará un aviso de terapia agendada al atleta y a su entrenador.',
                  ),
                TextFormField(
                  controller: location,
                  maxLength: 300,
                  decoration: const InputDecoration(
                    labelText: 'Lugar',
                    hintText: 'Campo, pista o consultorio',
                  ),
                  validator: (v) =>
                      (v ?? '').trim().isEmpty ? 'Indica el lugar' : null,
                ),
                TextFormField(
                  controller: startTime,
                  decoration: const InputDecoration(
                    labelText: 'Hora local (HH:mm)',
                    hintText: '16:30',
                  ),
                  validator: (v) =>
                      RegExp(r'^([01]\d|2[0-3]):[0-5]\d$').hasMatch(v ?? '')
                      ? null
                      : 'Usa una hora válida, por ejemplo 16:30',
                ),
                TextFormField(
                  controller: title,
                  maxLength: 150,
                  decoration: const InputDecoration(
                    labelText: 'Nombre del entrenamiento',
                  ),
                  validator: (v) => v == null || v.trim().isEmpty
                      ? 'Escribe un nombre'
                      : null,
                ),
                TextFormField(
                  controller: instructions,
                  minLines: 4,
                  maxLines: 10,
                  maxLength: 10000,
                  decoration: const InputDecoration(
                    labelText: 'Ejercicios e indicaciones',
                    hintText: 'Incluye series, repeticiones y descansos.',
                  ),
                  validator: (v) => v == null || v.trim().isEmpty
                      ? 'Agrega las indicaciones'
                      : null,
                ),
                if (kind != 'therapy')
                  TextFormField(
                    controller: throwingPlan,
                    minLines: 2,
                    maxLines: 5,
                    maxLength: 5000,
                    decoration: const InputDecoration(
                      labelText: 'Plan de tiros',
                      hintText: 'Cantidad, distancia, intensidad, tipos de lanzamiento y descansos',
                    ),
                    validator: (v) =>
                        kind == 'bullpen' && (v ?? '').trim().isEmpty
                        ? 'Agrega el plan de tiros del bullpen'
                        : null,
                  ),
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
                  try {
                    await widget.save(date, title.text, instructions.text, {
                      'kind': kind,
                      'location': location.text.trim(),
                      'start_time': startTime.text,
                      'throwing_plan': kind == 'therapy'
                          ? ''
                          : throwingPlan.text.trim(),
                    });
                    if (context.mounted) Navigator.pop(context, true);
                  } catch (_) {
                    if (mounted) {
                      setState(
                        () => error = 'No se pudo guardar. Revisa tu conexión y permisos.',
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

class AccountDialog extends StatefulWidget {
  final AcademyRepository repository;
  const AccountDialog({super.key, required this.repository});
  @override
  State<AccountDialog> createState() => _AccountDialogState();
}

class _AccountDialogState extends State<AccountDialog> {
  final form = GlobalKey<FormState>();
  final name = TextEditingController(),
      email = TextEditingController(),
      password = TextEditingController();
  String role = 'athlete';
  String? error;
  bool busy = false;
  @override
  void dispose() {
    name.dispose();
    email.dispose();
    password.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => PopScope(
    canPop: !busy,
    child: AlertDialog(
      title: const Text('Crear cuenta'),
      content: SizedBox(
        width: 440,
        child: SingleChildScrollView(
          child: Form(
            key: form,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextFormField(
                  controller: name,
                  maxLength: 100,
                  decoration: const InputDecoration(labelText: 'Nombre'),
                  validator: (v) => v == null || v.trim().isEmpty
                      ? 'Escribe un nombre'
                      : null,
                ),
                TextFormField(
                  controller: email,
                  keyboardType: TextInputType.emailAddress,
                  decoration: const InputDecoration(
                    labelText: 'Correo electrónico',
                  ),
                  validator: (v) => v != null && v.contains('@')
                      ? null
                      : 'Escribe un correo válido',
                ),
                DropdownButtonFormField<String>(
                  initialValue: role,
                  decoration: const InputDecoration(
                    labelText: 'Tipo de cuenta',
                  ),
                  items: ['athlete', 'coach']
                      .map(
                        (r) => DropdownMenuItem(
                          value: r,
                          child: Text(roleLabel(r)),
                        ),
                      )
                      .toList(),
                  onChanged: (v) => role = v!,
                ),
                TextFormField(
                  controller: password,
                  obscureText: true,
                  decoration: const InputDecoration(
                    labelText: 'Contraseña temporal',
                  ),
                  validator: (v) => (v?.length ?? 0) < 12
                      ? 'Usa al menos 12 caracteres'
                      : null,
                ),
                const SizedBox(height: 12),
                const Text(
                  'Entrega el correo y la contraseña temporal directamente al usuario. Tendrá que cambiarla al entrar.',
                ),
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
                  try {
                    await widget.repository.createAccount(
                      name.text,
                      email.text,
                      password.text,
                      role,
                    );
                    if (context.mounted) Navigator.pop(context, true);
                  } catch (_) {
                    if (mounted) {
                      setState(
                        () => error = 'No se pudo crear la cuenta. Revisa si el correo ya existe, tu conexión o la configuración del servidor.',
                      );
                    }
                  } finally {
                    if (mounted) setState(() => busy = false);
                  }
                },
          child: Text(busy ? 'Creando…' : 'Crear cuenta'),
        ),
      ],
    ),
  );
}
