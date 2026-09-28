class StaffProfile {
  const StaffProfile({
    required this.id,
    required this.fullName,
    required this.email,
    this.department = '',
    this.company = '',
    this.designation = '',
    this.joinedYear,
    this.avatarUrl = '',
  });

  static const companies = ['VMO Aero', 'CHL', 'VMO Agro'];

  final String id;
  final String fullName;
  final String email;
  final String department;
  final String company;
  final String designation;
  final int? joinedYear;
  final String avatarUrl;

  bool get isComplete =>
      department.trim().isNotEmpty &&
      companies.contains(company) &&
      designation.trim().isNotEmpty &&
      joinedYear != null &&
      avatarUrl.trim().isNotEmpty;

  StaffProfile copyWith({
    String? fullName,
    String? department,
    String? company,
    String? designation,
    int? joinedYear,
    String? avatarUrl,
  }) {
    return StaffProfile(
      id: id,
      fullName: fullName ?? this.fullName,
      email: email,
      department: department ?? this.department,
      company: company ?? this.company,
      designation: designation ?? this.designation,
      joinedYear: joinedYear ?? this.joinedYear,
      avatarUrl: avatarUrl ?? this.avatarUrl,
    );
  }
}
