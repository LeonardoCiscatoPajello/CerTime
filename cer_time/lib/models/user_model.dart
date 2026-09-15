class AppUser{
  final int id;
  final String name;
  final String role;
  final int? managerId;
  final String avatarColor;

  AppUser({
    required this.id,
    required this.name,
    required this.role,
    this.managerId,
    required this.avatarColor
  });

  factory AppUser.fromMap(Map<String, dynamic> map){
    return AppUser(
      id: map['id'],
      name: map['name'],
      role: map['role'],
      managerId: map['manager_id'],
      avatarColor: map['avatar_color'],
    );
  }

  bool get isManager => role == 'manager';
}
