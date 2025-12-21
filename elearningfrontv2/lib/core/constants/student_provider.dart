class StudentState {
  final List<Map<String, dynamic>> enrollments;
  final List<Map<String, dynamic>> sessions;

  StudentState({
    this.enrollments = const [],
    this.sessions = const [],
  });
}
