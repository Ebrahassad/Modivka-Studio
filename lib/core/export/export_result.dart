class ExportResult {
  final int successCount;
  final int totalCount;
  final String outputDirectory;
  final List<String> savedPaths;

  const ExportResult({
    required this.successCount,
    required this.totalCount,
    required this.outputDirectory,
    required this.savedPaths,
  });

  bool get success => successCount > 0;
}
