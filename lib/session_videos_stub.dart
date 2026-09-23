import 'package:flutter/material.dart';

class SessionVideos extends StatelessWidget {
  final int day;
  final bool coach;
  const SessionVideos({super.key, required this.day, required this.coach});
  @override
  Widget build(BuildContext context) =>
      const Text('Videos disponibles en la versión web.');
}
