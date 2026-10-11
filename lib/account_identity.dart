String accountEmail(String input) {
  final value = input.trim().toLowerCase();
  return value.contains('@') ? value : '$value@users.kksacademy.invalid';
}

bool validAccountLogin(String value) =>
    value.trim().contains('@') ||
    RegExp(r'^[a-z0-9][a-z0-9._-]{2,31}$').hasMatch(value.trim().toLowerCase());
