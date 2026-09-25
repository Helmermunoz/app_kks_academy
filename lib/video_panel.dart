import 'package:flutter/material.dart';

import 'session_details.dart';
import 'video_store.dart';
import 'video_platform_stub.dart'
    if (dart.library.js_interop) 'video_platform_web.dart';

class VideoPanel extends StatefulWidget {
  final VideoStore store;
  final Map<String, dynamic>? workout;
  const VideoPanel({super.key, required this.store, this.workout});
  @override
  State<VideoPanel> createState() => _VideoPanelState();
}

class _VideoPanelState extends State<VideoPanel> {
  final title = TextEditingController();
  List<Map<String, dynamic>> rows = [];
  bool loading = true, uploading = false;
  String? error, playbackUrl, playingId;
  @override
  void initState() {
    super.initState();
    load();
  }

  @override
  void dispose() {
    title.dispose();
    super.dispose();
  }

  Future<void> load() async {
    setState(() {
      loading = true;
      error = null;
    });
    try {
      final data = await widget.store.list(workoutId: widget.workout?['id']);
      if (mounted) setState(() => rows = data);
    } catch (failure) {
      if (mounted) {
        setState(() => error = videoLoadError(failure));
      }
    } finally {
      if (mounted) setState(() => loading = false);
    }
  }

  Future<void> upload() async {
    if (title.text.trim().isEmpty) {
      setState(() => error = 'Escribe un título para el video.');
      return;
    }
    final caption = title.text.trim();
    setState(() {
      uploading = true;
      error = null;
    });
    try {
      final file = await pickVideo();
      if (file == null || !mounted) return;
      await widget.store.upload(widget.workout!['id'], caption, file);
      if (!mounted) return;
      title.clear();
      await load();
    } catch (_) {
      if (mounted) {
        setState(
          () => error = 'No se pudo subir el video. Usa MP4, WebM o MOV de hasta 50 MB. Revisa tu conexión y permisos; actualiza la lista antes de reintentar.',
        );
      }
    } finally {
      if (mounted) setState(() => uploading = false);
    }
  }

  @override
  Widget build(BuildContext context) => PopScope(
    canPop: !uploading,
    child: AlertDialog(
      title: Text(
        widget.workout == null
            ? 'Videos de la academia'
            : 'Videos · ${widget.workout!['day']}',
      ),
      content: SizedBox(
        width: 700,
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const Text(
                'Los videos son visibles para los miembros con cuenta de la academia. Se muestran los 100 más recientes.',
              ),
              if (widget.workout != null) ...[
                Text('Sesión: ${widget.workout!['title']}'),
                TextField(
                  controller: title,
                  maxLength: 150,
                  enabled: !uploading,
                  decoration: const InputDecoration(
                    labelText: 'Título del video',
                  ),
                ),
                FilledButton.icon(
                  onPressed: uploading ? null : upload,
                  icon: const Icon(Icons.upload),
                  label: Text(
                    uploading ? 'Cargando video…' : 'Seleccionar y subir video',
                  ),
                ),
                const Text(
                  'Máximo 50 MB. MP4 recomendado para reproducir en más dispositivos.',
                ),
              ],
              if (error != null)
                Text(error!, style: const TextStyle(color: Color(0xffffa4ad))),
              if (loading || uploading) const LinearProgressIndicator(),
              if (!loading && rows.isEmpty && error == null)
                const Padding(
                  padding: EdgeInsets.all(16),
                  child: Text('Todavía no hay videos.'),
                ),
              if (playbackUrl != null) ...[
                videoPlayer(playbackUrl!),
                const Text(
                  'Si el video no reproduce, actualiza y vuelve a abrirlo. El formato también debe ser compatible con tu navegador.',
                ),
              ],
              ...rows.map(
                (v) => ListTile(
                  contentPadding: EdgeInsets.zero,
                  title: Text(v['title']),
                  subtitle: Text(
                    '${v['athlete_name']} · ${v['day']} · ${sessionKinds[v['kind']]}',
                  ),
                  trailing: const Icon(Icons.play_circle),
                  selected: playingId == v['id'],
                  onTap: uploading
                      ? null
                      : () async {
                          setState(() {
                            playingId = v['id'];
                            error = null;
                            playbackUrl = null;
                          });
                          try {
                            final url = await widget.store.playback(
                              v['object_path'],
                            );
                            if (mounted && playingId == v['id']) {
                              setState(() => playbackUrl = url);
                            }
                          } catch (_) {
                            if (mounted) {
                              setState(
                                () => error = 'No se pudo abrir el video. Actualiza y vuelve a intentar.',
                              );
                            }
                          }
                        },
                ),
              ),
            ],
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: loading || uploading ? null : load,
          child: const Text('Actualizar'),
        ),
        TextButton(
          onPressed: uploading ? null : () => Navigator.pop(context),
          child: const Text('Cerrar'),
        ),
      ],
    ),
  );
}
