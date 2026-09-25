import 'dart:js_interop';

import 'package:flutter/material.dart';
import 'package:web/web.dart' as web;

class SessionVideos extends StatefulWidget {
  final int day;
  final bool coach;
  const SessionVideos({super.key, required this.day, required this.coach});
  @override
  State<SessionVideos> createState() => _SessionVideosState();
}

class _Clip {
  final String name, url, author, kind;
  final int day;
  final List<String> comments = [];
  _Clip(this.name, this.url, this.author, this.kind, this.day);
}

class _SessionVideosState extends State<SessionVideos> {
  final clips = <_Clip>[];
  String kind = 'Entrenamiento diario';
  final picker = web.HTMLInputElement()
    ..type = 'file'
    ..accept = 'video/*'
    ..multiple = true;
  @override
  void dispose() {
    picker.onchange = null;
    for (final clip in clips) {
      web.URL.revokeObjectURL(clip.url);
    }
    super.dispose();
  }

  void choose() {
    final sessionDay = widget.day;
    final author = widget.coach ? 'Entrenador' : 'Alumno';
    final sessionKind = kind;
    picker.value = '';
    picker.onchange = ((web.Event event) {
      if (!mounted) {
        return;
      }
      final files = picker.files;
      if (files == null) {
        return;
      }
      var rejected = false;
      setState(() {
        for (var i = 0; i < files.length; i++) {
          final file = files.item(i)!;
          if (!file.type.startsWith('video/') ||
              file.size > 250 * 1024 * 1024) {
            rejected = true;
            continue;
          }
          clips.add(
            _Clip(
              file.name,
              web.URL.createObjectURL(file),
              author,
              sessionKind,
              sessionDay,
            ),
          );
        }
      });
      if (rejected) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Selecciona videos de hasta 250 MB por archivo.'),
          ),
        );
      }
    }).toJS;
    picker.click();
  }

  @override
  Widget build(BuildContext context) => Card(
    elevation: 0,
    color: const Color(0xff132238),
    child: Padding(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Videos de la sesión',
            style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 8),
          const Text(
            'Demo local: los archivos y comentarios se pierden al recargar. No se envían a un servidor.',
          ),
          const SizedBox(height: 16),
          DropdownButtonFormField<String>(
            initialValue: kind,
            decoration: const InputDecoration(
              labelText: 'Tipo de sesión',
              border: OutlineInputBorder(),
            ),
            items: ['Entrenamiento diario', 'Bullpen', 'Sesión de lanzamientos']
                .map(
                  (value) => DropdownMenuItem(value: value, child: Text(value)),
                )
                .toList(),
            onChanged: (value) => setState(() => kind = value!),
          ),
          const SizedBox(height: 12),
          FilledButton.icon(
            onPressed: choose,
            icon: const Icon(Icons.video_library_outlined),
            label: Text(
              'Agregar videos como ${widget.coach ? 'entrenador' : 'alumno'}',
            ),
          ),
          const SizedBox(height: 8),
          const Text(
            'Hasta 250 MB por video. Reproducción según los formatos compatibles con tu navegador.',
          ),
          const SizedBox(height: 20),
          if (!clips.any((clip) => clip.day == widget.day))
            const Text('Todavía no hay videos para este día.'),
          ...clips
              .where((clip) => clip.day == widget.day)
              .map(
                (clip) => _ClipCard(
                  key: ValueKey(clip.url),
                  clip: clip,
                  coach: widget.coach,
                ),
              ),
        ],
      ),
    ),
  );
}

class _ClipCard extends StatefulWidget {
  final _Clip clip;
  final bool coach;
  const _ClipCard({super.key, required this.clip, required this.coach});
  @override
  State<_ClipCard> createState() => _ClipCardState();
}

class _ClipCardState extends State<_ClipCard> {
  web.HTMLVideoElement? video;
  final comment = TextEditingController();
  double speed = 1;
  @override
  void dispose() {
    video?.pause();
    comment.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.only(bottom: 28),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          widget.clip.name,
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
        Text('${widget.clip.kind} · Agregado por ${widget.clip.author}'),
        const SizedBox(height: 10),
        AspectRatio(
          aspectRatio: 16 / 9,
          child: HtmlElementView.fromTagName(
            tagName: 'video',
            onElementCreated: (element) {
              video = element as web.HTMLVideoElement;
              video!
                ..src = widget.clip.url
                ..controls = true
                ..preload = 'metadata'
                ..style.width = '100%'
                ..style.height = '100%'
                ..style.backgroundColor = '#10251f';
              video!.setAttribute('playsinline', '');
            },
          ),
        ),
        Wrap(
          spacing: 8,
          crossAxisAlignment: WrapCrossAlignment.center,
          children: [
            const Text('Velocidad:'),
            ...[0.25, 0.5, 1.0].map(
              (value) => ChoiceChip(
                label: Text('${value}x'),
                selected: speed == value,
                onSelected: (_) {
                  setState(() => speed = value);
                  video?.playbackRate = value;
                },
              ),
            ),
          ],
        ),
        if (widget.coach) ...[
          TextField(
            controller: comment,
            maxLength: 1000,
            maxLines: 2,
            decoration: const InputDecoration(
              labelText: 'Observación del entrenador',
              hintText: 'Pausa el video en el momento que quieras comentar.',
            ),
          ),
          TextButton.icon(
            icon: const Icon(Icons.add_comment_outlined),
            label: const Text('Comentar en el segundo actual'),
            onPressed: () {
              final text = comment.text.trim();
              if (text.isEmpty) {
                return;
              }
              final seconds = (video?.currentTime ?? 0).floor();
              final stamp =
                  '${seconds ~/ 60}:${(seconds % 60).toString().padLeft(2, '0')}';
              setState(() {
                widget.clip.comments.add('$stamp · Entrenador: $text');
                comment.clear();
              });
            },
          ),
        ],
        if (widget.clip.comments.isEmpty)
          const Text('Sin observaciones del entrenador.'),
        ...widget.clip.comments.map(
          (text) => Padding(
            padding: const EdgeInsets.only(top: 8),
            child: Text(text),
          ),
        ),
      ],
    ),
  );
}
