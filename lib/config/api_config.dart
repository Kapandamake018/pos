class ApiConfig {
  // Use --dart-define=BASE_URL=... to override per device
  static const String baseUrl = String.fromEnvironment(
    'BASE_URL',
    defaultValue: 'http://10.0.2.2:8001', // Android emulator default
  );
  static const String taxApiBaseUrl = String.fromEnvironment(
    'TAX_BASE_URL',
    defaultValue: 'http://10.0.2.2:8002', // Mock tax server
  );

  // API endpoints
  static const String login = '/login';
  static const String products = '/api/products';
  static const String dailySales = '/api/reports/daily-sales';
  static const String taxReport = '/api/reports/tax';
  static const String sales = '/api/reports/sales';

  // Headers
  static Map<String, String> getHeaders([String? token]) => {
    'Content-Type': 'application/json',
    if (token != null) 'Authorization': 'Bearer $token',
  };
}
