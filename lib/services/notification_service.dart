import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import '../viewmodels/map_share_location_viewmodel.dart';
import 'package:provider/provider.dart';


class NotificationService {
  static final FlutterLocalNotificationsPlugin _notifications = FlutterLocalNotificationsPlugin();
  static final GlobalKey<NavigatorState> navigatorKey = GlobalKey<NavigatorState>(); // добавляем navigatorKey

  static Future<void> init() async {
    const AndroidInitializationSettings initializationSettingsAndroid = AndroidInitializationSettings('@mipmap/ic_launcher');

    final InitializationSettings initializationSettings = InitializationSettings(android: initializationSettingsAndroid);

    await _notifications.initialize(
      initializationSettings,
      onDidReceiveNotificationResponse: (NotificationResponse notificationResponse) {
        // Обработка действий в уведомлении
        final String? payload = notificationResponse.payload;
        if (notificationResponse.actionId == 'stop_action') {
          // Вызовем метод для остановки задачи, если нажата кнопка «Завершить»
          _stopLocationSharing();
        } else if (payload != null) {
          _handleNotificationTap(payload);
        }
      },
    );
  }

  static void _handleNotificationTap(String payload) {
    if (payload == 'location_view') {
      navigatorKey.currentState?.pushNamed('/location_view');
    }
  }

  static Future<void> showLocationSharingNotification() async {
    const AndroidNotificationDetails androidDetails = AndroidNotificationDetails(
      'location_channel',
      'Location Sharing',
      channelDescription: 'Notification for location sharing',
      importance: Importance.max,
      priority: Priority.high,
      ongoing: true,
      autoCancel: false,
      showWhen: false,
      actions: <AndroidNotificationAction>[
        AndroidNotificationAction(
          'stop_action', // Уникальный идентификатор действия
          'Stop Sharing', // Название кнопки завершения
          cancelNotification: true, // Убирает уведомление при нажатии
        ),
      ],
    );

    const NotificationDetails platformDetails = NotificationDetails(android: androidDetails);

    await _notifications.show(
      0,
      'Location Sharing Active',
      'Your location is being shared',
      platformDetails,
      payload: 'location_view', // Указываем payload для определения целевого view
    );
  }

  static Future<void> updateLocationNotification(String newText) async {
    const AndroidNotificationDetails androidDetails = AndroidNotificationDetails(
      'location_channel',
      'Location Sharing',
      channelDescription: 'Notification for location sharing',
      importance: Importance.max,
      priority: Priority.high,
      ongoing: true,
      showWhen: false,
      actions: <AndroidNotificationAction>[
        AndroidNotificationAction(
          'stop_action',
          'Stop Sharing',
          cancelNotification: true,
        ),
      ],
    );

    const NotificationDetails platformDetails = NotificationDetails(android: androidDetails);

    await _notifications.show(
      0,
      'Location Sharing Active',
      newText,
      platformDetails,
    );
  }

  static Future<void> cancelNotification() async {
    await _notifications.cancel(0);
  }

  static Future<void> _stopLocationSharing() async {
    final locationVM = navigatorKey.currentContext?.read<MapShareLocationViewModel>();
    if (locationVM != null) {
      locationVM.resetLocationSharing(); // Останавливаем задачу и сбрасываем статус
    }
  }

}
