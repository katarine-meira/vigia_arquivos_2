class UserModel {
  final String uid;
  final String email;
  final String displayName;

  const UserModel({
    required this.uid,
    required this.email,
    required this.displayName,
  });

  String get initials {
    final parts = displayName.trim().split(' ');
    if (parts.length >= 2 && parts[0].isNotEmpty && parts[1].isNotEmpty) {
      return '${parts.first[0]}${parts.last[0]}'.toUpperCase();
    }
    if (displayName.isNotEmpty) return displayName[0].toUpperCase();
    return '?';
  }

  String get firstName => displayName.split(' ').first;
}
