/// Classifies user intents detected for Generative UI generation.
enum GenUiIntentType {
  healthSummary,
  trendAnalysis,
  educational,
  recommendation,
  reportGenerator,
  healthTimeline,
  navigation,
  multiWidget,
  generalQuery,
}

/// Structured intent response container
class GenUiIntentModel {
  final GenUiIntentType intentType;
  final String query;
  final Map<String, dynamic> metadata;

  const GenUiIntentModel({
    required this.intentType,
    required this.query,
    this.metadata = const {},
  });

  factory GenUiIntentModel.fromQuery(String query) {
    final lower = query.toLowerCase();

    if (lower.contains('summary') || lower.contains('today\'s health') || lower.contains('how am i doing today')) {
      return GenUiIntentModel(intentType: GenUiIntentType.healthSummary, query: query);
    }
    if (lower.contains('compare') || lower.contains('trend') || lower.contains('chart') || lower.contains('last month') || lower.contains('this year')) {
      return GenUiIntentModel(intentType: GenUiIntentType.trendAnalysis, query: query);
    }
    if (lower.contains('what is') || lower.contains('explain') || lower.contains('meaning') || lower.contains('definition') || lower.contains('systolic') || lower.contains('diastolic')) {
      return GenUiIntentModel(intentType: GenUiIntentType.educational, query: query);
    }
    if (lower.contains('recommend') || lower.contains('lower') || lower.contains('improve') || lower.contains('tip') || lower.contains('diet') || lower.contains('water')) {
      return GenUiIntentModel(intentType: GenUiIntentType.recommendation, query: query);
    }
    if (lower.contains('report') || lower.contains('pdf') || lower.contains('doctor visit') || lower.contains('generate report')) {
      return GenUiIntentModel(intentType: GenUiIntentType.reportGenerator, query: query);
    }
    if (lower.contains('timeline') || lower.contains('six months') || lower.contains('6 months') || lower.contains('history over time')) {
      return GenUiIntentModel(intentType: GenUiIntentType.healthTimeline, query: query);
    }
    if (lower.startsWith('open ') || lower.startsWith('show my reminders') || lower.startsWith('navigate to') || lower.contains('open my reports')) {
      return GenUiIntentModel(intentType: GenUiIntentType.navigation, query: query);
    }

    return GenUiIntentModel(intentType: GenUiIntentType.generalQuery, query: query);
  }
}
