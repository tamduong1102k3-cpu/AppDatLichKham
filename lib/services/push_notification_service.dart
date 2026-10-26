import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'firebase_service.dart';
import 'device_token_api_service.dart';
import 'auth_service.dart';

/// Xử lý thông báo đến từ Firebase và hiển thị local notifications
class PushNotificationService {
  static final PushNotificationService _instance = PushNotificationService._internal();
  factory PushNotificationService() => _instance;
  PushNotificationService._internal();

  final _firebaseService = FirebaseService();
  final _deviceTokenApi = DeviceTokenApiService();
  final _authService = AuthService();
  bool _initialized = false;

  /// Plugin hiển thị local notification hệ thống
  final FlutterLocalNotificationsPlugin _localNotifications =
      FlutterLocalNotificationsPlugin();

  /// ID của notification channel cho thông báo tổng quát
  static const String _channelId = 'thong_bao_channel';
  static const String _channelName = 'Thông báo';
  static const String _channelDescription = 'Thông báo từ hệ thống đặt lịch khám';

  /// Global key để navigation từ notification
  static final GlobalKey<NavigatorState> navigatorKey = GlobalKey<NavigatorState>();

  /// Khởi tạo notification service
  Future<void> initialize() async {
    if (_initialized) return;

    try {
      // Khởi tạo Firebase
      await _firebaseService.initialize();

      // Cấu hình Firebase Messaging handlers
      await _setupFirebaseMessaging();

      // Khởi tạo local notifications plugin
      await _initializeLocalNotifications();

      // Yêu cầu quyền thông báo FCM (bắt buộc trên Android 13+)
      await requestPermission();

      _initialized = true;
      debugPrint('PushNotificationService initialized successfully');
    } catch (e) {
      debugPrint('PushNotificationService initialization error: $e');
    }
  }

  /// Khởi tạo FlutterLocalNotificationsPlugin và tạo channel
  Future<void> _initializeLocalNotifications() async {
    try {
      // Cấu hình cho Android
      const androidInitSettings = AndroidInitializationSettings('@mipmap/ic_launcher');


      const darwinInitSettings = DarwinInitializationSettings(
        requestAlertPermission: false,
        requestBadgePermission: false,
        requestSoundPermission: false,
      );

      const initSettings = InitializationSettings(
        android: androidInitSettings,
        iOS: darwinInitSettings,
      );

      await _localNotifications.initialize(
        initSettings,
        onDidReceiveNotificationResponse: _handleLocalNotificationTap,
      );


      const androidChannel = AndroidNotificationChannel(
        _channelId,
        _channelName,
        description: _channelDescription,
        importance: Importance.max,
        playSound: true,
        enableVibration: true,
        enableLights: true,
        showBadge: true,
      );

      await _localNotifications
          .resolvePlatformSpecificImplementation<
              AndroidFlutterLocalNotificationsPlugin>()
          ?.createNotificationChannel(androidChannel);

      debugPrint('Local notifications initialized successfully');
    } catch (e) {
      debugPrint('Error initializing local notifications: $e');
    }
  }

  /// Hiển thị local notification lên hệ thống
  Future<void> showNotification({
    required int id,
    required String title,
    required String body,
    Map<String, dynamic>? payload,
  }) async {
    try {
      // Kiểm tra quyền POST_NOTIFICATIONS trên Android 13+
      final androidImpl = _localNotifications
          .resolvePlatformSpecificImplementation<
              AndroidFlutterLocalNotificationsPlugin>();
      final isGranted = await androidImpl?.areNotificationsEnabled() ?? true;
      if (!isGranted) {
        debugPrint('Notifications are disabled, skipping local notification');
        return;
      }

      const androidDetails = AndroidNotificationDetails(
        _channelId,
        _channelName,
        channelDescription: _channelDescription,
        importance: Importance.max,
        priority: Priority.high,
        playSound: true,
        enableVibration: true,
        enableLights: true,
        showWhen: true,
      );

      const darwinDetails = DarwinNotificationDetails();

      const notificationDetails = NotificationDetails(
        android: androidDetails,
        iOS: darwinDetails,
      );

      await _localNotifications.show(
        id,
        title,
        body,
        notificationDetails,
        payload: payload != null ? jsonEncode(payload) : null,
      );
      debugPrint('Local notification shown: id=$id title=$title');
    } catch (e) {
      debugPrint('Error showing local notification: $e');
    }
  }

  /// Xử lý khi người dùng tap vào local notification
  void _handleLocalNotificationTap(NotificationResponse response) {
    debugPrint('Local notification tapped: ${response.payload}');
    if (response.payload == null) return;

    try {
      final data = jsonDecode(response.payload!) as Map<String, dynamic>;


      final route = data['route'];
      if (route != null) {
        navigatorKey.currentState?.pushNamed(route as String);
      }
    } catch (e) {
      debugPrint('Error parsing notification payload: $e');
    }
  }


  Future<bool> isNotificationGranted() async {
    try {
      final messaging = FirebaseMessaging.instance;
      final settings = await messaging.getNotificationSettings();
      return settings.authorizationStatus == AuthorizationStatus.authorized ||
          settings.authorizationStatus == AuthorizationStatus.provisional;
    } catch (_) {
      try {
        final androidImpl = _localNotifications
            .resolvePlatformSpecificImplementation<
                AndroidFlutterLocalNotificationsPlugin>();
        if (androidImpl != null) {
          final enabled = await androidImpl.areNotificationsEnabled();
          return enabled ?? false;
        }
      } catch (_) {}
      return false;
    }
  }

  /// Yêu cầu quyền thông báo - public để gọi lại khi cần
  /// Gọi FirebaseMessaging.instance.requestPermission() TRỰC TIẾP
  Future<bool> requestPermission() async {
    try {

      if (!_firebaseService.isInitialized) {
        try {
          await _firebaseService.initialize();
        } catch (_) {

          try {
            await Firebase.initializeApp();
          } catch (_) {}
        }
      }


      final messaging = FirebaseMessaging.instance;
      final settings = await messaging.requestPermission(
        alert: true,
        badge: true,
        sound: true,
        announcement: true,
        carPlay: false,
        criticalAlert: true,
        provisional: false,
      );

      final authorized = settings.authorizationStatus == AuthorizationStatus.authorized ||
          settings.authorizationStatus == AuthorizationStatus.provisional;
      debugPrint('Notification permission status: ${settings.authorizationStatus}');


      if (authorized) {
        final androidImpl = _localNotifications
            .resolvePlatformSpecificImplementation<
                AndroidFlutterLocalNotificationsPlugin>();
        if (androidImpl != null) {
          await androidImpl.requestNotificationsPermission();
        }


        try {
          final token = await messaging.getToken();
          _firebaseService.fcmToken = token;
          if (_authService.isLoggedIn) {
            await _deviceTokenApi.registerToken(
              token,
              notificationsEnabled: authorized,
              loginEvent: false,
            );
          }
        } catch (_) {}
      }
      return authorized;
    } catch (e) {
      debugPrint('Error requesting notification permission: $e');
      return false;
    }
  }

  /// Thiết lập Firebase Messaging handlers
  Future<void> _setupFirebaseMessaging() async {
    try {
      final messaging = FirebaseMessaging.instance;


      FirebaseMessaging.onMessage.listen(_handleForegroundMessage);

      FirebaseMessaging.onMessageOpenedApp.listen(_handleNotificationOpened);


      final initialMessage = await messaging.getInitialMessage();
      if (initialMessage != null) {
        _handleNotificationOpened(initialMessage);
      }


      _firebaseService.onTokenRefresh((newToken) async {
        if (!_authService.isLoggedIn) return;
        final granted = await isNotificationGranted();
        await _deviceTokenApi.registerToken(
          newToken,
          notificationsEnabled: granted,
          loginEvent: false,
        );
      });
    } catch (e) {
      debugPrint('Error setting up Firebase messaging: $e');
    }
  }

  /// Gọi khi đăng nhập thành công - đăng ký token.
  /// LUÔN tạo/cập nhật dòng device (loginEvent=true) kể cả khi quyền tắt:
  /// quyền bật -> enabled=true + token; quyền tắt -> enabled=false + token null.
  Future<void> onLoginSuccess() async {
    if (!_initialized) await initialize();
    final granted = await isNotificationGranted();
    String? token;
    try {
      token = _firebaseService.fcmToken ?? await _firebaseService.getFcmToken();
    } catch (_) {
      token = null;
    }
    if (!granted) token = null;
    await _deviceTokenApi.registerToken(
      token,
      notificationsEnabled: granted,
      loginEvent: true,
    );
    _firebaseService.fcmToken = token;
  }

  /// Gọi khi đăng xuất - xóa dòng của máy đó (best-effort, lỗi vẫn logout local).
  Future<void> onLogout() async {
    try {
      await _deviceTokenApi.removeToken(_firebaseService.fcmToken);
    } catch (_) {}
    try {
      await _deviceTokenApi.clearCache();
    } catch (_) {}
  }

  /// Logout im lặng khi nhận 401 (máy mới đã login, refresh-token máy này bị revoke).
  /// Không dialog/snackbar/notification. Bỏ qua lỗi removeToken, xóa cache.
  Future<void> onForcedLogout() async {
    try {
      await _deviceTokenApi.removeToken(_firebaseService.fcmToken);
    } catch (_) {}
    try {
      await _deviceTokenApi.clearCache();
    } catch (_) {}
    try {
      await _authService.logout();
    } catch (_) {}
  }

  /// Lấy FCM token hiện tại để đồng bộ khi resume (không đăng ký, không hỏi quyền).
  Future<String?> requestTokenForSync() async {
    try {
      final cached = _firebaseService.fcmToken;
      if (cached != null && cached.isNotEmpty) return cached;
      final token = await _firebaseService.getFcmToken();
      return token;
    } catch (_) {
      return null;
    }
  }

  /// Xử lý thông báo khi app đang ở foreground
  /// Hiển thị local notification để người dùng thấy thông báo ngay cả khi app đang mở
  Future<void> _handleForegroundMessage(RemoteMessage message) async {
    debugPrint('Foreground message received: ${message.messageId}');

    // Lấy title/body từ message.notification hoặc từ data
    final notification = message.notification;
    String title = notification?.title ?? 'Thông báo mới';
    String body = notification?.body ?? 'Bạn có thông báo mới từ hệ thống';

    // Ưu tiên dùng data nếu notification không có
    if (notification == null) {
      title = message.data['title'] as String? ?? 'Thông báo mới';
      body = message.data['body'] as String? ?? 'Bạn có thông báo mới từ hệ thống';
    }

    // Tạo payload để navigate khi tap vào notification
    final payload = <String, dynamic>{
      'messageId': message.messageId ?? '',
      ...message.data, // Copy toàn bộ data từ FCM
    };

    // Hiển thị local notification
    await showNotification(
      id: DateTime.now().millisecondsSinceEpoch.remainder(2147483647),
      title: title,
      body: body,
      payload: payload,
    );
  }

  /// Xử lý khi người dùng nhấn vào thông báo (từ FCM background)
  void _handleNotificationOpened(RemoteMessage message) {
    debugPrint('Notification opened: ${message.messageId}');
    final route = message.data['route'];
    if (route != null) {
      // Điều hướng đến route tương ứng
      navigatorKey.currentState?.pushNamed(route);
    }
  }
}