import 'package:supabase_flutter/supabase_flutter.dart';

import 'video_store.dart';
import 'nutrition_store.dart';

typedef Record = Map<String, dynamic>;

abstract class AcademyRepository {
  NutritionStore? get nutritionStore;
  VideoStore? get videoStore;
  String? get userId;
  Stream<String?> get sessions;
  Future<void> signIn(String email, String password);
  Future<void> signOut();
  Future<void> changePassword(String password);
  Future<Record> profile();
  Future<List<Record>> people();
  Future<List<Record>> assignments();
  Future<void> assign(String coach, String athlete, bool assigned);
  Future<void> createAccount(
    String name,
    String email,
    String password,
    String role,
  );
  Future<List<Record>> workouts(String athlete);
  Future<Set<String>> completions(String athlete);
  Future<void> saveWorkout(
    String athlete,
    String? id,
    String day,
    String title,
    String instructions, {
    Record details = const {},
  });
  Future<void> complete(String athlete, String workout, bool value);
}

class SupabaseAcademyRepository implements AcademyRepository {
  final SupabaseClient client;
  SupabaseAcademyRepository(this.client);
  @override
  NutritionStore get nutritionStore => SupabaseNutritionStore(client);
  @override
  VideoStore get videoStore => VideoStore(client);
  @override
  String? get userId => client.auth.currentUser?.id;
  @override
  Stream<String?> get sessions => client.auth.onAuthStateChange
      .map((event) => event.session?.user.id)
      .distinct();
  @override
  Future<void> signIn(String email, String password) async {
    await client.auth.signInWithPassword(
      email: email.trim(),
      password: password,
    );
  }

  @override
  Future<void> signOut() => client.auth.signOut();
  @override
  Future<void> changePassword(String password) async {
    await client.auth.updateUser(UserAttributes(password: password));
  }

  @override
  Future<Record> profile() =>
      client.from('profiles').select().eq('id', userId!).single();
  @override
  Future<List<Record>> people() =>
      client.from('profiles').select().order('name');
  @override
  Future<List<Record>> assignments() => client.from('coach_athletes').select();
  @override
  Future<void> assign(String coach, String athlete, bool assigned) async {
    if (assigned) {
      await client.from('coach_athletes').insert({
        'coach_id': coach,
        'athlete_id': athlete,
      });
    } else {
      await client
          .from('coach_athletes')
          .delete()
          .eq('coach_id', coach)
          .eq('athlete_id', athlete);
    }
  }

  @override
  Future<void> createAccount(
    String name,
    String email,
    String password,
    String role,
  ) async {
    await client.functions.invoke(
      'create-account',
      body: {
        'name': name.trim(),
        'email': email.trim(),
        'password': password,
        'role': role,
      },
    );
  }

  @override
  Future<List<Record>> workouts(String athlete) => client
      .from('workouts')
      .select()
      .eq('athlete_id', athlete)
      .order('day')
      .order('created_at');
  @override
  Future<Set<String>> completions(String athlete) async {
    final rows = await client
        .from('workout_completions')
        .select('workout_id')
        .eq('athlete_id', athlete);
    return rows.map((row) => row['workout_id'] as String).toSet();
  }

  @override
  Future<void> saveWorkout(
    String athlete,
    String? id,
    String day,
    String title,
    String instructions, {
    Record details = const {},
  }) async {
    final values = {
      ...details,
      'day': day,
      'title': title.trim(),
      'instructions': instructions.trim(),
    };
    if (id == null) {
      await client.from('workouts').insert({...values, 'athlete_id': athlete});
    } else {
      await client
          .from('workouts')
          .update(values)
          .eq('id', id)
          .eq('athlete_id', athlete);
    }
  }

  @override
  Future<void> complete(String athlete, String workout, bool value) async {
    if (value) {
      await client.from('workout_completions').insert({
        'workout_id': workout,
        'athlete_id': athlete,
      });
    } else {
      await client
          .from('workout_completions')
          .delete()
          .eq('workout_id', workout)
          .eq('athlete_id', athlete);
    }
  }
}
