class SearchHistoryItem {
  final String query;
  final DateTime timestamp;

  SearchHistoryItem({
    required this.query,
    required this.timestamp,
  });

  factory SearchHistoryItem.fromJson(Map<String, dynamic> json) {
    return SearchHistoryItem(
      query: json['query'] as String,
      timestamp: DateTime.parse(json['timestamp'] as String),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'query': query,
      'timestamp': timestamp.toIso8601String(),
    };
  }

  SearchHistoryItem copyWith({
    String? query,
    DateTime? timestamp,
  }) {
    return SearchHistoryItem(
      query: query ?? this.query,
      timestamp: timestamp ?? this.timestamp,
    );
  }
}
