/// Feature flags remotos ou estáticos.
abstract final class FeatureFlags {
  FeatureFlags._();

  static bool get example => const bool.fromEnvironment('FF_EXAMPLE', defaultValue: false);
}
