import 'dart:convert';

import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:http/http.dart' as http;

Future<void> _firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  await Firebase.initializeApp();
}

const AndroidNotificationChannel channel = AndroidNotificationChannel(
    'high_importance_channel', // id
    'High Importance Notifications', // title
    description:
        'This channel is used for important notifications.', // description
    importance: Importance.max,
    playSound: true);

Future<void> showNotification(RemoteMessage event) async {
  print(event.toMap());
  RemoteNotification? notification = event.notification;
  AndroidNotification? android = event.notification?.android;
  BigPictureStyleInformation? bigPictureStyleInformation;
  if (notification != null && android != null) {
    if (android.imageUrl != null && (android.imageUrl ?? '').isNotEmpty) {
      final http.Response response =
          await http.get(Uri.parse(android.imageUrl ?? ''));
      bigPictureStyleInformation =
          BigPictureStyleInformation(ByteArrayAndroidBitmap.fromBase64String(
              base64Encode(response.bodyBytes)));
    }
    flutterLocalNotificationsPlugin.show(
        notification.hashCode,
        notification.title,
        notification.body,
        NotificationDetails(
            android: AndroidNotificationDetails(
              channel.id,
              channel.name,
              channelDescription: channel.description,
              color: Colors.blue,
              playSound: true,
              icon: '@mipmap/ic_launcher',
              styleInformation: bigPictureStyleInformation,
            ),
            iOS: DarwinNotificationDetails()));
  }
}

final FlutterLocalNotificationsPlugin flutterLocalNotificationsPlugin =
    FlutterLocalNotificationsPlugin();

class Notifications {
  static Future<void> initNotifications() async {
    FirebaseMessaging.onBackgroundMessage(_firebaseMessagingBackgroundHandler);

    await flutterLocalNotificationsPlugin
        .resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin>()
        ?.createNotificationChannel(channel);

    await FirebaseMessaging.instance
        .setForegroundNotificationPresentationOptions(
            alert: true, badge: true, sound: true);

    FirebaseMessaging messaging = FirebaseMessaging.instance;
    NotificationSettings settings = await messaging.requestPermission(
      alert: true,
      announcement: false,
      badge: true,
      carPlay: false,
      criticalAlert: false,
      provisional: false,
      sound: true,
    );
    print('User granted permission: ${settings.authorizationStatus}');

    FirebaseMessaging.onMessage.listen((event) {
      showNotification(event);
    });

    FirebaseMessaging.onMessageOpenedApp.listen((event) {
      showNotification(event);
    });

  }
}
