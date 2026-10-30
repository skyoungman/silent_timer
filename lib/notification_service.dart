import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/data/latest_all.dart' as tz;
import 'package:timezone/timezone.dart' as tz;

class NotificationService {
  static final NotificationService _instance = NotificationService._internal();
  factory NotificationService() => _instance;
  NotificationService._internal();

  final FlutterLocalNotificationsPlugin flutterLocalNotificationsPlugin =
      FlutterLocalNotificationsPlugin();

  Future<void> init() async {
    tz.initializeTimeZones();

    const DarwinInitializationSettings initializationSettingsDarwin =
        DarwinInitializationSettings(
      requestAlertPermission: true,
      requestBadgePermission: true,
      requestSoundPermission: true,
    );

    const InitializationSettings initializationSettings =
        InitializationSettings(
      iOS: initializationSettingsDarwin,
    );

    await flutterLocalNotificationsPlugin.initialize(initializationSettings);
  }

  /// 指定秒数後から数秒おきに連続で通知を予約する
  Future<void> scheduleContinuousNotifications({
    required int seconds,
    int repeatCount = 6, // 連続で鳴らす回数（6回 = 約x秒間）
    int intervalSeconds = 4, // 通知と通知の間隔（秒）
    String title = 'SilentTimer',
    String body = '設定した時間になりました。',
  }) async {
    // 既存の未配信通知をすべてクリア
    await cancelNotification();

    if (seconds <= 0) return;

    const DarwinNotificationDetails darwinNotificationDetails =
        DarwinNotificationDetails(
      sound: 'silent.caf',
      presentAlert: true,
      presentBadge: true,
      presentSound: true,
    );

    const NotificationDetails notificationDetails = NotificationDetails(
      iOS: darwinNotificationDetails,
    );

    // 指定間隔で複数の通知をまとめてキューに登録
    for (int i = 0; i < repeatCount; i++) {
      final scheduledDate = tz.TZDateTime.now(tz.local).add(
        Duration(seconds: seconds + (i * intervalSeconds)),
      );

      await flutterLocalNotificationsPlugin.zonedSchedule(
        i, // 一意の通知ID (0, 1, 2...)
        title,
        body,
        scheduledDate,
        notificationDetails,
        uiLocalNotificationDateInterpretation:
            UILocalNotificationDateInterpretation.absoluteTime,
      );
    }
  }

  /// 予約されているすべての通知をキャンセル
  Future<void> cancelNotification() async {
    await flutterLocalNotificationsPlugin.cancelAll();
  }
}