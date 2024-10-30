import 'package:safe_sky/models/user_model.dart';

class LocationModel {
  final double latitude;
  final double longitude;
  final UserModel? user; // Опциональный пользователь

  LocationModel({
    required this.latitude,
    required this.longitude,
    this.user,
  });

  // Фабричный метод для создания Location из JSON
  factory LocationModel.fromJson(Map<String, dynamic> json) {
    return LocationModel(
      latitude: json['latitude'],
      longitude: json['longitude'],
      user: json['user'] != null ? UserModel.fromJson(json['user']) : null,
    );
  }

  // Метод для преобразования модели в JSON
  Map<String, dynamic> toJson() {
    final data = {
      'latitude': latitude,
      'longitude': longitude,
    };
    // if (user != null) {
    //   data['user'] = user!.toJson();
    // }
    return data;
  }
}