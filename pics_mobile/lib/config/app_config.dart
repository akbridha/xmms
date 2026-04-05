class AppUser {
  final String name;
  final String role;
  final String section;

  const AppUser({
    required this.name,
    required this.role,
    required this.section,
  });

  @override
  String toString() => '$name ($role)';
}

class AppConfig {
  // For Docker/local API on REAL device, do not use localhost.
  // Use your PC/Laptop LAN IP, e.g. http://192.168.1.10:9090/api
  // static const String host = 'http://192.168.1.10:9090/api';

  // For local API on emulator only.
  static const String host = 'http://localhost:9090/api';

  // For public API.
  // static const String host = 'https://app-saptaindra.msappproxy.net/PlantAdmo/api';

  static const List<String> sections = [
    'PLANT PRIME MOVER',
    'PLANT VESSEL',
    'PLANT TYRE SUPPORT',
  ];

  static const List<AppUser> users = [
    AppUser(name: 'Admin Dev', role: 'Admin', section: 'PLANT PRIME MOVER'),
    AppUser(name: 'Mekanik A', role: 'Mekanik', section: 'PLANT PRIME MOVER'),
    AppUser(
      name: 'Mekanik B',
      role: 'Mekanik',
      section: 'PLANT SUPPORT EQUIPMENT',
    ),
    AppUser(
      name: 'Inspector C',
      role: 'Inspector',
      section: 'PLANT ELECTRICAL',
    ),
  ];

  static AppUser currentUser = users.first;
}
