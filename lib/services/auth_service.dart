import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:intl/intl.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../config/api_routes.dart';
import '../models/user_model.dart';

class AuthService {

  // Метод для входа пользователя
  Future<bool> login(String username, String password) async {
    final url = Uri.parse(ApiRoutes.login);

    try {
      final response = await http.post(
        url,
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
        },
        body: jsonEncode({'username': username, 'password': password}),
      );

      // Декодируем ответ в правильной кодировке UTF-8
      final String responseBody = utf8.decode(response.bodyBytes);
      final Map<String, dynamic> responseData = jsonDecode(responseBody);

      print('Server response: $responseData');  // Логируем ответ сервера

      if (response.statusCode == 200) {
        // Сохраняем токен и дату истечения
        SharedPreferences prefs = await SharedPreferences.getInstance();
        await prefs.setString('auth_token', responseData['token']);
        await prefs.setString('token_expire_at', responseData['expireAt']);

        print('Token saved: ${responseData['token']}');  // Лог токена

        return true;  // Успешный вход
      } else {
        // Логируем сообщение об ошибке и выбрасываем исключение
        print('Login error: ${responseData['message']}');
        throw Exception(responseData['message'] ?? 'Ошибка при входе');
      }
    } catch (e) {
      print('Network error occurred: $e');
      throw Exception('Не удалось подключиться к серверу: $e');
    }
  }


  // Метод для отправки email
  Future<Map<String, dynamic>> sendEmail(String username) async {
    final token = await _getToken();
    final url = Uri.parse(ApiRoutes.sendEmail);

    try {
      final response = await http.post(
        url,
        headers: {
          'Content-Type': 'application/json',
        },
        body: jsonEncode({'username': username}),
      );

      if (response.statusCode == 200) {
        return jsonDecode(response.body);
      } else {
        // Обработка ошибок
        final errorData = jsonDecode(response.body);
        throw Exception(errorData['message'] ?? 'Failed to send email');
      }
    } catch (e) {
      throw Exception('Не удалось подключиться к серверу: $e');
    }
  }


  // Метод для регистрации
  Future<void> register({
    required String email,
    required String password,
    required String confirmPassword,
    required String otp,
    required String surname,
    required String name,
    required String phoneNumber,
  }) async {
    final url = Uri.parse(ApiRoutes.register);

    try {
      final response = await http.post(
        url,
        headers: {
          'Content-Type': 'application/json',
        },
        body: jsonEncode({
          'username': email,
          'password': password,
          'passwordConfirm': confirmPassword,
          'otp': otp,
          'surname': surname,
          'name': name,
          'phone': phoneNumber,
        }),
      );

      // Декодируем ответ в правильной кодировке UTF-8
      final String responseBody = utf8.decode(response.bodyBytes);

      if (response.statusCode == 200) {
        print('Registration successful');
      } else {
        final Map<String, dynamic> errorResponse = jsonDecode(responseBody);
        print('Server error: ${errorResponse['message']}');
        throw Exception('Failed to register: ${errorResponse['message']}');
      }
    } catch (e) {
      print('Network error occurred: $e');  // Логируем ошибку сети
      throw Exception('Network error: ${e.toString()}');
    }
  }


  Future<UserModel> getUserInfo() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    String? token = prefs.getString('auth_token');

    if (token == null) {
      throw Exception('Authorization token is missing');
    }

    final response = await http.get(
      Uri.parse(ApiRoutes.userInfo),
      headers: {
        'Content-Type': 'application/json',
        'Accept': 'application/json',
        'Authorization': 'Bearer $token',
      },
    );

    final String responseBody = utf8.decode(response.bodyBytes);
    if (response.statusCode == 200) {
      final Map<String, dynamic> jsonData = jsonDecode(responseBody);

      UserModel user = UserModel.fromJson({
        'id': jsonData['id'],
        'email': jsonData['email'],
        'name': jsonData['name'],
        'surname': jsonData['surname'],
        'phoneNumber': jsonData['phone'],
        'applicantId': jsonData['applicantId'],
        'applicant': jsonData['applicant'],
        'token': token,
      });

      // Сохраняем applicant в SharedPreferences
      await prefs.setString('applicant', user.applicant);
      await prefs.setInt('userId', user.id);

      print('USER ID: ${user.id}');

      return user;
    } else {
      final Map<String, dynamic> errorResponse = jsonDecode(responseBody);
      throw Exception(errorResponse['message'] ?? 'Ошибка получения профиля');
    }
  }

  // Получение токена из SharedPreferences
  Future<String?> _getToken() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    return prefs.getString('auth_token');
  }

  Future<bool> checkToken() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('auth_token');

    // Если токена нет совсем, сразу возвращаем false
    if (token == null) return false;

    final url = Uri.parse(ApiRoutes.checkToken);
    try {
      final response = await http.get(
        url,
        headers: {
          'Authorization': 'Bearer $token',
        },
      );

      // 200 - всё ОК, токен валидный
      if (response.statusCode == 200) {
        return true;
      } else {
        // Любой другой статус код означает, что токен недействителен
        return false;
      }
    } catch (e) {
      // Сюда попадём, если нет сети или любая другая ошибка при запросе
      return false;
    }
  }



// Метод для изменения данных профиля
  Future<void> changeProfileData(
      String name, String surname, String phone) async {
    final token = await _getToken();
    final url = Uri.parse(ApiRoutes.changeProfileData);

    final response = await http.post(
      url,
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token',
      },
      body: jsonEncode({
        'surname': surname,
        'name': name,
        'phone': phone,
      }),
    );

    if (response.statusCode != 200) {
      final errorData = jsonDecode(utf8.decode(response.bodyBytes));
      throw Exception(errorData['message'] ?? 'Failed to update profile data');
    }
  }

// Метод для изменения пароля
  Future<void> changePassword(
      String oldPassword, String newPassword, String passwordConfirm) async {
    final token = await _getToken();
    final url = Uri.parse(ApiRoutes.changePassword);

    final response = await http.post(
      url,
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token',
      },
      body: jsonEncode({
        'oldPassword': oldPassword,
        'password': newPassword,
        'passwordConfirm': passwordConfirm,
      }),
    );

    if (response.statusCode != 200) {
      final errorData = jsonDecode(utf8.decode(response.bodyBytes));
      throw Exception(errorData['message'] ?? 'Failed to change password');
    }
    logout();
  }
  // Метод для выхода
  Future<void> logout() async {
      // Удаляем токен из SharedPreferences
      SharedPreferences prefs = await SharedPreferences.getInstance();
      await prefs.remove('auth_token');
  }
}
