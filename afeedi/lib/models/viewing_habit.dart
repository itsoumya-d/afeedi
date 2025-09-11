class ViewingHabit {
  final String id;
  final String title;
  final String description;
  final String timeOfDay;
  final List<String> daysOfWeek;
  final int averageDuration; // in minutes
  final List<String> preferredGenres;
  final List<String> preferredPlatforms;
  
  ViewingHabit({
    required this.id,
    required this.title,
    required this.description,
    required this.timeOfDay,
    required this.daysOfWeek,
    required this.averageDuration,
    required this.preferredGenres,
    required this.preferredPlatforms,
  });
  
  ViewingHabit copyWith({
    String? id,
    String? title,
    String? description,
    String? timeOfDay,
    List<String>? daysOfWeek,
    int? averageDuration,
    List<String>? preferredGenres,
    List<String>? preferredPlatforms,
  }) {
    return ViewingHabit(
      id: id ?? this.id,
      title: title ?? this.title,
      description: description ?? this.description,
      timeOfDay: timeOfDay ?? this.timeOfDay,
      daysOfWeek: daysOfWeek ?? this.daysOfWeek,
      averageDuration: averageDuration ?? this.averageDuration,
      preferredGenres: preferredGenres ?? this.preferredGenres,
      preferredPlatforms: preferredPlatforms ?? this.preferredPlatforms,
    );
  }
  
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': title,
      'description': description,
      'timeOfDay': timeOfDay,
      'daysOfWeek': daysOfWeek,
      'averageDuration': averageDuration,
      'preferredGenres': preferredGenres,
      'preferredPlatforms': preferredPlatforms,
    };
  }
  
  factory ViewingHabit.fromJson(Map<String, dynamic> json) {
    return ViewingHabit(
      id: json['id'],
      title: json['title'],
      description: json['description'],
      timeOfDay: json['timeOfDay'],
      daysOfWeek: List<String>.from(json['daysOfWeek']),
      averageDuration: json['averageDuration'],
      preferredGenres: List<String>.from(json['preferredGenres']),
      preferredPlatforms: List<String>.from(json['preferredPlatforms']),
    );
  }
}