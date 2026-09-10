// vehicle_profiles.dart — SAFE//SPIT
//
// PLANNED vehicle profile data (Phase 4/8).
// RULE 2: No Flutter imports.
// RULE 20: Car is the identity profile — reproduces proven formula exactly.
// All values are fictional heuristics, NOT realistic physics.
//
// Initial reference build ships Car + Bus + Bike (three profiles).
// Other vehicles (Train, Tractor, Aircraft, Walking) come in Phase 8.

import 'safe_spit_calculator.dart';

/// The catalog of available vehicle profiles for the reference build.
/// Only Car, Bus, and Bike are fully tuned. Others are stubs.
class VehicleProfiles {
  /// The identity profile — reproduces the proven formula exactly (D-4, TV-08).
  static const VehicleProfile car = VehicleProfile(
    id: 'car',
    displayName: 'Car',
    turbulenceFactor: 1.0,
    angleBias: 0.0,
    windSensitivity: 1.0,
    difficulty: 0.0,
    eitherSide: true,
  );

  /// Bus — heavy, turbulent, high angleBias from road vibration.
  /// Fictional heuristic: turbulence means you need to hold pitch slightly longer.
  static const VehicleProfile bus = VehicleProfile(
    id: 'bus',
    displayName: 'Bus',
    turbulenceFactor: 1.15,
    angleBias: 2.0,
    windSensitivity: 1.3,
    difficulty: 0.4,
  );

  /// Bike — nimble, low turbulence, but highly wind-sensitive.
  /// Fictional: moving fast on a bike amplifies wind deflection.
  static const VehicleProfile bike = VehicleProfile(
    id: 'bike',
    displayName: 'Bike',
    turbulenceFactor: 0.9,
    angleBias: -1.0,
    windSensitivity: 1.8,
    difficulty: 0.3,
    eitherSide: true,
  );

  /// Auto (Rickshaw) — chaotic, unpredictable, maximum fun.
  static const VehicleProfile auto = VehicleProfile(
    id: 'auto',
    displayName: 'Auto-Rickshaw',
    turbulenceFactor: 1.25,
    angleBias: 3.0,
    windSensitivity: 1.5,
    difficulty: 0.6,
  );

  /// Train — heavy, steady, low turbulence, high wind sensitivity from long body.
  static const VehicleProfile train = VehicleProfile(
    id: 'train',
    displayName: 'Train',
    turbulenceFactor: 1.1,
    angleBias: 1.5,
    windSensitivity: 1.2,
    difficulty: 0.5,
  );
  /// Tractor � very high turbulence, unpredictable angle.
  static const VehicleProfile tractor = VehicleProfile(
    id: 'tractor',
    displayName: 'Tractor',
    turbulenceFactor: 1.35,
    angleBias: 4.0,
    windSensitivity: 1.0,
    difficulty: 0.8,
  );

  /// Aircraft � high speed, low ground turbulence, high wind at altitude.
  static const VehicleProfile aircraft = VehicleProfile(
    id: 'aircraft',
    displayName: 'Aircraft',
    turbulenceFactor: 0.95,
    angleBias: -0.5,
    windSensitivity: 2.0,
    difficulty: 0.7,
  );

  /// Walking - very low speed, high directional variability.
  static const VehicleProfile walking = VehicleProfile(
    id: 'walking',
    displayName: 'Walking',
    turbulenceFactor: 1.0,
    angleBias: -2.0,
    windSensitivity: 1.5,
    difficulty: 0.2,
    eitherSide: true,
  );

  /// Still - stationary, zero aerodynamic forces.
  static const VehicleProfile still = VehicleProfile(
    id: 'still',
    displayName: 'Still',
    turbulenceFactor: 0.0,
    angleBias: 0.0,
    windSensitivity: 0.5,
    difficulty: 0.1,
    eitherSide: true,
  );

  /// All available vehicles for the reference build (Phase 8).
  static const List<VehicleProfile> all = [car, bus, bike, auto, train, tractor, aircraft, walking, still];

  /// Find a profile by id (case-insensitive). Returns [car] if not found.
  static VehicleProfile byId(String id) {
    final lower = id.toLowerCase();
    for (final v in all) {
      if (v.id == lower) return v;
    }
    return car;
  }
}
