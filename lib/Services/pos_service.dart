import 'dart:convert';
import 'package:http/http.dart' as http;
import '../Models/product_model.dart';
import '../config/api_config.dart';
import 'auth_service.dart';

class APIException implements Exception {
  final String message;
  final int? statusCode;

  APIException(this.message, [this.statusCode]);

  @override
  String toString() => 'APIException: $message (Status: $statusCode)';
}

class POSService {
  final AuthService _authService = AuthService();
  
  Future<http.Response> _authenticatedRequest(
    String endpoint,
    {
      String method = 'GET',
      Map<String, dynamic>? body,
    }
  ) async {
    final token = await _authService.getToken();
    final uri = Uri.parse('${ApiConfig.baseUrl}$endpoint');
    final headers = ApiConfig.getHeaders(token);

    try {
      late http.Response response;
      
      switch (method) {
        case 'GET':
          response = await http.get(uri, headers: headers);
          break;
        case 'POST':
          response = await http.post(
            uri, 
            headers: headers,
            body: json.encode(body),
          );
          break;
        default:
          throw APIException('Unsupported HTTP method: $method');
      }

      if (response.statusCode == 401) {
        await _authService.deleteToken();
        throw APIException('Authentication expired', response.statusCode);
      }

      return response;
    } catch (e) {
      if (e is APIException) rethrow;
      throw APIException('Network error: ${e.toString()}');
    }
  }

  Future<String> login(String username, String password) async {
    try {
      final response = await http.post(
        Uri.parse('${ApiConfig.baseUrl}${ApiConfig.login}'),
        headers: ApiConfig.getHeaders(),
        body: json.encode({
          'username': username,
          'password': password,
        }),
      );

      if (response.statusCode == 200) {
        final token = json.decode(response.body)['access_token'];
        await _authService.saveToken(token);
        return token;
      } else {
        throw APIException(
          'Login failed: ${json.decode(response.body)['detail']}',
          response.statusCode
        );
      }
    } catch (e) {
      throw APIException('Login error: ${e.toString()}');
    }
  }

  Future<List<Product>> getProducts() async {
    final response = await _authenticatedRequest(ApiConfig.products);
    
    if (response.statusCode == 200) {
      final List<dynamic> data = json.decode(response.body);
      return data.map((json) => Product.fromJson(json)).toList();
    }
    
    throw APIException(
      'Failed to load products: ${json.decode(response.body)['detail']}',
      response.statusCode
    );
  }

  Future<Map<String, dynamic>> getDailySales(String date) async {
    final response = await _authenticatedRequest(
      '${ApiConfig.dailySales}?date_str=$date'
    );
    
    if (response.statusCode == 200) {
      return json.decode(response.body);
    }
    
    throw APIException(
      'Failed to load sales report: ${json.decode(response.body)['detail']}',
      response.statusCode
    );
  }
}