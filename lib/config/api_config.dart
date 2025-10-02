class ApiConfig {
  static const String baseUrl = 'http://10.0.2.2:8000';  // Android emulator
  // static const String baseUrl = 'http://localhost:8000';  // iOS simulator
  
  // API endpoints
  static const String login = '/login';
  static const String products = '/api/products';
  static const String dailySales = '/api/reports/daily-sales';
  static const String taxReport = '/api/reports/tax';
  
  // Headers
  static Map<String, String> getHeaders([String? token]) => {
    'Content-Type': 'application/json',
    if (token != null) 'Authorization': 'Bearer $token',
  };
}