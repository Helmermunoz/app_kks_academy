import 'package:supabase_flutter/supabase_flutter.dart';

typedef NutritionRecord = Map<String, dynamic>;

abstract class NutritionStore {
  Future<NutritionRecord?> profile(String athlete);
  Future<List<NutritionRecord>> measurements(String athlete);
  Future<void> saveProfile(
    String athlete,
    NutritionRecord values, {
    required bool exists,
  });
  Future<void> addMeasurement(String athlete, NutritionRecord values);
}

class SupabaseNutritionStore implements NutritionStore {
  final SupabaseClient client;
  SupabaseNutritionStore(this.client);
  @override
  Future<NutritionRecord?> profile(String athlete) => client
      .from('nutrition_profiles')
      .select()
      .eq('athlete_id', athlete)
      .maybeSingle();
  @override
  Future<List<NutritionRecord>> measurements(String athlete) => client
      .from('inbody_measurements')
      .select()
      .eq('athlete_id', athlete)
      .order('measured_on', ascending: false)
      .order('created_at', ascending: false)
      .limit(500);
  @override
  Future<void> saveProfile(
    String athlete,
    NutritionRecord values, {
    required bool exists,
  }) async {
    if (exists) {
      await client
          .from('nutrition_profiles')
          .update(values)
          .eq('athlete_id', athlete);
    } else {
      await client.from('nutrition_profiles').insert({
        ...values,
        'athlete_id': athlete,
      });
    }
  }

  @override
  Future<void> addMeasurement(String athlete, NutritionRecord values) async {
    await client.from('inbody_measurements').insert({
      ...values,
      'athlete_id': athlete,
    });
  }
}
