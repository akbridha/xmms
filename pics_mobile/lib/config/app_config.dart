import '../models/user.dart';

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
  // Use your PC/Laptop LAN IP, e.g. http://192.168.1.115:9090/api
  // static const String host = 'http://192.168.1.10:9090/api';

  // For local API on emulator only.
  // static const String host = 'http://10.0.2.2:9090/api';
  // static const String host = 'http://172.20.144.226:9090/api';
  // static const String host = 'http://192.168.8.115:9090/api';
  static const String host = 'https://app-saptaindra.msappproxy.net/PlantAdmo/api';



  static const List<String> sections = [
    'PLANT PRIME MOVER',
    'PLANT VESSEL',
    'PLANT TYRE SUPPORT',
  ];

  static const Map<String, List<String>> partOfCheckBySection = {
    'PLANT PRIME MOVER': [
      'BAGIAN ATAS',
      'BAGIAN BAWAH',
      'BAGIAN CABIN',
    ],
    'PLANT VESSEL': [
      'BAGIAN ATAS',
      'BAGIAN BAWAH',
      'HUB DRUM TEMPERATUR',
      'GREASING SET TRAILER',
    ],
  };

  static const Map<String, String> partOfCheckAliases = {
  
  };

  static String normalizePartOfCheck(String raw) {
    final normalized = raw.trim().toUpperCase();
    return partOfCheckAliases[normalized] ?? normalized;
  }

  static const List<String> inspectors = [
    '0115118',
    '4111682',
    '80001668',
  ];

  static String currentInspector = inspectors.first;

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

  // Logged-in user from API
  static User? loggedInUser;

  // Set logged-in user and update inspector
  static void setLoggedInUser(User user) {
    loggedInUser = user;
    currentInspector = user.nrp;
  }

  // Clear logged-in user
  static void clearLoggedInUser() {
    loggedInUser = null;
    currentInspector = inspectors.first;
  }

  // Get current inspector (from logged-in user if available)
  static String getInspector() {
    return loggedInUser?.nrp ?? currentInspector;
  }
}
