import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:timezone/timezone.dart' as tz;
import 'package:timezone/data/latest.dart' as tz;
import 'package:flutter/material.dart';

class LocalNotificationService {
  static final LocalNotificationService _instance =
      LocalNotificationService._internal();
  factory LocalNotificationService() => _instance;
  LocalNotificationService._internal();

  final FlutterLocalNotificationsPlugin flutterLocalNotificationsPlugin =
      FlutterLocalNotificationsPlugin();

  static const String _notificationPermissionKey =
      'notification_permission_granted';
  bool _permissionGranted = false; // Зберігаємо стан дозволу в пам'яті

  void onTapLocalNotification(NotificationResponse notificationResponse) async {
    final String? payload = notificationResponse.payload;
    if (payload != null && payload.isNotEmpty) {
      // Переходимо на сторінку деталей події, передаючи ID події
      // navigatorKey.currentState?.push(
      //   MaterialPageRoute(
      //     builder: (context) => ViewEventPage(event: payload),
      //   ),
      // );
    }
  }

  // Ініціалізація сповіщень (без прямого запиту дозволу тут)
  Future<void> initialize() async {
    tz.initializeTimeZones(); // Ініціалізація часових зон

    // Перевіряємо збережений стан дозволу
    final prefs = await SharedPreferences.getInstance();
    _permissionGranted = prefs.getBool(_notificationPermissionKey) ??
        false; // За замовчуванням false

    // Налаштування для Android
    const AndroidInitializationSettings initializationSettingsAndroid =
        AndroidInitializationSettings('@mipmap/ic_launcher');

    // Налаштування для iOS
    final DarwinInitializationSettings initializationSettingsDarwin =
        DarwinInitializationSettings();

    final InitializationSettings initializationSettings =
        InitializationSettings(
      android: initializationSettingsAndroid,
      iOS: initializationSettingsDarwin,
    );

    await flutterLocalNotificationsPlugin.initialize(
      initializationSettings,
      onDidReceiveNotificationResponse: onTapLocalNotification,
      // (NotificationResponse response) async {
      //   debugPrint('onDidReceiveNotificationResponse: ${response.payload}');
      // },
      // onDidReceiveBackgroundNotificationResponse:
      //     (NotificationResponse response) async {
      //   debugPrint(
      //       'onDidReceiveBackgroundNotificationResponse: ${response.payload}');
      // },
    );
  }

  // Метод для запиту дозволів на сповіщення, який приймає BuildContext
  Future<void> requestPermissions(BuildContext context) async {
    // Якщо дозвіл вже надано, немає сенсу запитувати знову
    if (_permissionGranted) {
      debugPrint(
          'Notification permission already granted. No need to request again.');
      return;
    }

    bool? permissionGrantedAndroid = true;
    bool? permissionGrantediOS = true;

    // Для Android (API 33+)
    // Запит дозволу тепер залежить від версії Android
    // Якщо requestNotificationsPermission повертає null, це означає, що запит не підтримується
    // (наприклад, API < 33) або дозвіл вже надано на системному рівні.
    final AndroidFlutterLocalNotificationsPlugin? androidImplementation =
        flutterLocalNotificationsPlugin.resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin>();

    if (androidImplementation != null) {
      // requestNotificationsPermission() повертає null, якщо API < 33.
      // На API < 33 дозволи на сповіщення надаються автоматично при встановленні.
      permissionGrantedAndroid =
          await androidImplementation.requestNotificationsPermission();
      // Якщо requestNotificationsPermission() повертає null (API < 33), вважаємо, що дозвіл є.
      permissionGrantedAndroid ??= true;
    }

    // Для iOS
    permissionGrantediOS = await flutterLocalNotificationsPlugin
        .resolvePlatformSpecificImplementation<
            IOSFlutterLocalNotificationsPlugin>()
        ?.requestPermissions(
          alert: true,
          badge: true,
          sound: true,
        );

    _permissionGranted =
        (permissionGrantedAndroid ?? false) && (permissionGrantediOS ?? false);
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_notificationPermissionKey, _permissionGranted);

    if (_permissionGranted) {
      debugPrint('Notification permissions granted by user.');
    } else {
      debugPrint('Notification permissions denied by user.');
      // Можна показати SnackBar, якщо користувач відмовився
      // ScaffoldMessenger.of(context).showSnackBar(
      //   const SnackBar(
      //       content: Text(
      //           'Сповіщення вимкнені. Щоб увімкнути, надайте дозвіл у налаштуваннях додатка.')),
      // );
    }
  }

  // Метод для перевірки, чи надано дозвіл
  bool hasPermission() {
    return _permissionGranted;
  }

  // Ваш існуючий метод для планування нагадування
  Future<void> scheduleNotification({
    required int id,
    required String title,
    required String body,
    required DateTime scheduledTime,
    String? payload,
  }) async {
    // Перевіряємо _permissionGranted зі стану сервісу, а не з SharedPreferences щоразу.
    if (!_permissionGranted) {
      debugPrint('Cannot schedule notification: permission not granted.');
      return;
    }

    // Налаштування для Android
    const AndroidNotificationDetails androidPlatformChannelSpecifics =
        AndroidNotificationDetails(
      'your_channel_id', // ID каналу (має бути унікальним)
      'Your Channel Name', // Ім'я каналу
      channelDescription:
          'Your channel description for notifications', // Опис каналу
      importance: Importance.max,
      priority: Priority.high,
      showWhen: false,
    );

    // Налаштування для iOS
    const DarwinNotificationDetails iOSPlatformChannelSpecifics =
        DarwinNotificationDetails();

    const NotificationDetails platformChannelSpecifics = NotificationDetails(
      android: androidPlatformChannelSpecifics,
      iOS: iOSPlatformChannelSpecifics,
    );

    final tz.TZDateTime scheduledDate = tz.TZDateTime.from(
      scheduledTime,
      tz.local,
    );

    await flutterLocalNotificationsPlugin.zonedSchedule(
      id,
      title,
      body,
      scheduledDate,
      platformChannelSpecifics,
      androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
      payload: payload,
    );
    debugPrint('Notification scheduled for $scheduledTime (ID: $id)');
  }

  // Метод для скасування сповіщення
  Future<void> cancelNotification(int id) async {
    await flutterLocalNotificationsPlugin.cancel(id);
    debugPrint('Notification with ID $id cancelled.');
  }

  // Метод для скасування всіх сповіщень
  Future<void> cancelAllNotifications() async {
    await flutterLocalNotificationsPlugin.cancelAll();
    debugPrint('All notifications cancelled.');
  }
}
