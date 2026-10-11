typedef JsonMap = Map<String, Object?>;

/// Reads the list stored under [key], or an empty list when it is absent.
List<T> readList<T>(JsonMap json, String key, T Function(JsonMap) fromJson) {
  final raw = json[key] as List<Object?>?;
  if (raw == null) return <T>[];
  return [for (final item in raw) fromJson(item as JsonMap)];
}
