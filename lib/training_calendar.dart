import 'package:flutter/material.dart';

import 'academy_theme.dart';

const _months = [
  'ENERO',
  'FEBRERO',
  'MARZO',
  'ABRIL',
  'MAYO',
  'JUNIO',
  'JULIO',
  'AGOSTO',
  'SEPTIEMBRE',
  'OCTUBRE',
  'NOVIEMBRE',
  'DICIEMBRE',
];
const _weekdays = ['L', 'M', 'X', 'J', 'V', 'S', 'D'];
const _fullWeekdays = [
  'lunes',
  'martes',
  'miércoles',
  'jueves',
  'viernes',
  'sábado',
  'domingo',
];

String _monthLabel(DateTime date) => '${_months[date.month - 1]} ${date.year}';
String _dateKey(DateTime date) => '${date.year}-${date.month}-${date.day}';

/// Date navigation only; the parent owns selection and workout filtering.
class TrainingCalendar extends StatefulWidget {
  final DateTime selectedDate;
  final Set<DateTime> workoutDays;
  final ValueChanged<DateTime> onSelected;

  const TrainingCalendar({
    super.key,
    required this.selectedDate,
    required this.workoutDays,
    required this.onSelected,
  });

  @override
  State<TrainingCalendar> createState() => _TrainingCalendarState();
}

class _TrainingCalendarState extends State<TrainingCalendar> {
  bool expanded = false;
  double dragDistance = 0;
  late DateTime month = DateTime(
    widget.selectedDate.year,
    widget.selectedDate.month,
  );

  @override
  void didUpdateWidget(TrainingCalendar oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (!DateUtils.isSameDay(oldWidget.selectedDate, widget.selectedDate)) {
      month = DateTime(widget.selectedDate.year, widget.selectedDate.month);
    }
  }

  void select(DateTime date) {
    setState(() => expanded = false);
    widget.onSelected(DateUtils.dateOnly(date));
  }

  void moveWeek(int direction) {
    final date = widget.selectedDate;
    select(DateTime(date.year, date.month, date.day + direction * 7));
  }

  Widget day(DateTime date, {bool showWeekday = false}) {
    final selected = DateUtils.isSameDay(date, widget.selectedDate);
    final today = DateUtils.isSameDay(date, DateTime.now());
    final scheduled = widget.workoutDays.contains(DateUtils.dateOnly(date));
    final label =
        '${_fullWeekdays[date.weekday - 1]}, ${date.day} '
        '${_months[date.month - 1].toLowerCase()} ${date.year}'
        '${today ? ', hoy' : ''}${scheduled ? ', entrenamiento programado' : ''}';
    return Expanded(
      child: Semantics(
        selected: selected,
        button: true,
        label: label,
        excludeSemantics: true,
        child: Tooltip(
          message: label,
          child: InkWell(
            key: ValueKey('training-day-${_dateKey(date)}'),
            borderRadius: BorderRadius.circular(12),
            onTap: () => select(date),
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 6),
              child: Column(
                children: [
                  if (showWeekday) ...[
                    Text(
                      _weekdays[date.weekday - 1],
                      style: const TextStyle(color: AcademyColors.muted),
                    ),
                    const SizedBox(height: 6),
                  ],
                  Container(
                    width: 36,
                    height: 36,
                    alignment: Alignment.center,
                    decoration: BoxDecoration(
                      color: selected ? AcademyColors.blue : null,
                      shape: BoxShape.circle,
                      border: today && !selected
                          ? Border.all(color: AcademyColors.blue)
                          : null,
                    ),
                    child: Text(
                      '${date.day}',
                      style: TextStyle(
                        color: selected
                            ? AcademyColors.background
                            : AcademyColors.text,
                        fontWeight: selected || today
                            ? FontWeight.bold
                            : FontWeight.normal,
                      ),
                    ),
                  ),
                  const SizedBox(height: 5),
                  Container(
                    key: scheduled
                        ? ValueKey('training-dot-${_dateKey(date)}')
                        : null,
                    height: 5,
                    width: 5,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: scheduled
                          ? AcademyColors.blue
                          : Colors.transparent,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget monthGrid() {
    final first = DateTime(month.year, month.month);
    final offset = first.weekday - 1;
    final count = DateUtils.getDaysInMonth(month.year, month.month);
    return Column(
      key: const ValueKey('training-month-grid'),
      children: [
        Row(
          children: [
            IconButton(
              tooltip: 'Mes anterior',
              onPressed: () =>
                  setState(() => month = DateTime(month.year, month.month - 1)),
              icon: const Icon(Icons.chevron_left),
            ),
            Expanded(
              child: Text(
                _monthLabel(month),
                textAlign: TextAlign.center,
                style: const TextStyle(fontWeight: FontWeight.bold),
              ),
            ),
            IconButton(
              tooltip: 'Mes siguiente',
              onPressed: () =>
                  setState(() => month = DateTime(month.year, month.month + 1)),
              icon: const Icon(Icons.chevron_right),
            ),
          ],
        ),
        Row(
          children: [
            for (final weekday in _weekdays)
              Expanded(
                child: Center(
                  child: Text(
                    weekday,
                    style: const TextStyle(color: AcademyColors.muted),
                  ),
                ),
              ),
          ],
        ),
        const SizedBox(height: 6),
        for (int row = 0; row < (offset + count + 6) ~/ 7; row++)
          Row(
            children: [
              for (int column = 0; column < 7; column++)
                if (row * 7 + column - offset + 1 < 1 ||
                    row * 7 + column - offset + 1 > count)
                  const Expanded(child: SizedBox())
                else
                  day(
                    DateTime(
                      month.year,
                      month.month,
                      row * 7 + column - offset + 1,
                    ),
                  ),
            ],
          ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final date = widget.selectedDate;
    final monday = DateTime(date.year, date.month, date.day - date.weekday + 1);
    return Align(
      alignment: Alignment.centerLeft,
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 560),
        child: Card(
          margin: const EdgeInsets.symmetric(vertical: 8),
          child: Padding(
            padding: const EdgeInsets.all(12),
            child: Column(
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        _monthLabel(date),
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          letterSpacing: 1,
                        ),
                      ),
                    ),
                    TextButton(
                      onPressed: () => setState(() {
                        expanded = !expanded;
                        month = DateTime(date.year, date.month);
                      }),
                      child: Text(expanded ? 'Cerrar mes' : 'Ver mes ›'),
                    ),
                  ],
                ),
                if (expanded)
                  monthGrid()
                else
                  GestureDetector(
                    key: const ValueKey('training-week-strip'),
                    behavior: HitTestBehavior.opaque,
                    onHorizontalDragStart: (_) => dragDistance = 0,
                    onHorizontalDragUpdate: (details) =>
                        dragDistance += details.primaryDelta ?? 0,
                    onHorizontalDragEnd: (details) {
                      final velocity = details.primaryVelocity ?? 0;
                      if (dragDistance.abs() >= 40 || velocity.abs() > 100) {
                        final direction = dragDistance.abs() >= 40
                            ? dragDistance
                            : velocity;
                        moveWeek(direction < 0 ? 1 : -1);
                      }
                    },
                    child: Row(
                      children: [
                        for (int i = 0; i < 7; i++)
                          day(
                            DateTime(monday.year, monday.month, monday.day + i),
                            showWeekday: true,
                          ),
                      ],
                    ),
                  ),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    if (expanded)
                      const SizedBox(width: 48)
                    else
                      IconButton(
                        tooltip: 'Semana anterior',
                        onPressed: () => moveWeek(-1),
                        icon: const Icon(Icons.chevron_left),
                      ),
                    TextButton(
                      onPressed: () => select(DateTime.now()),
                      child: const Text('Hoy'),
                    ),
                    if (expanded)
                      const SizedBox(width: 48)
                    else
                      IconButton(
                        tooltip: 'Semana siguiente',
                        onPressed: () => moveWeek(1),
                        icon: const Icon(Icons.chevron_right),
                      ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
