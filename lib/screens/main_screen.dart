import 'package:flutter/material.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'dart:async';
import 'home/home_screen.dart';
import 'profile/profile_screen.dart';
import 'appointment/appointment_booking_screen.dart';
import 'notification/notification_screen.dart';
import 'account/account_screen.dart';
import '../services/auth_service.dart';
import '../services/push_notification_service.dart';
import '../services/device_token_api_service.dart';
import '../services/thong_bao_api_service.dart';
import '../services/websocket_notification_service.dart';
import '../utils/auth_guard.dart';
import '../widgets/network_banner.dart';
import '../widgets/shimmer_loading.dart';

class MainScreen extends StatefulWidget {
  const MainScreen({super.key});

  @override
  State<MainScreen> createState() => _MainScreenState();
}

class _MainScreenState extends State<MainScreen> with WidgetsBindingObserver {
  int _selectedIndex = 0;
  int _unreadCount = 0;
  Timer? _unreadTimer;
  StreamSubscription<void>? _wsReloadSub;
  StreamSubscription<int>? _wsUnreadSub;
  StreamSubscription<void>? _sessionExpiredSub;
  StreamSubscription<AuthStatus>? _statusSub;
  final _authService = AuthService();
  final _wsService = WebSocketNotificationService();


  int _loginStateVersion = 0;


  static const List<int> _authRequiredTabs = [1, 2, 3, 4]; // profile, booking, notification, account

  List<Widget> get _screens {
    final key = _loginStateVersion;
    return [
      HomeScreen(key: ValueKey('home_$key')),
      ProfileScreen(key: ValueKey('profile_$key')),
      AppointmentBookingScreen(key: ValueKey('booking_$key')),
      NotificationScreen(key: ValueKey('notification_$key')),
      AccountScreen(key: ValueKey('account_$key')),
    ];
  }

  @override
  void initState() {
    super.initState();

    if (!_authService.isTokenLoaded) {
      _authService.loadToken();
    }
    // Đăng ký lifecycle observer
    WidgetsBinding.instance.addObserver(this);

    _wsUnreadSub = _wsService.onUnreadCountChanged.listen((increment) {
      if (!mounted) return;
      setState(() {
        _unreadCount += increment;
      });
    });

    _wsReloadSub = _wsService.onNotificationReload.listen((_) {
      _fetchUnreadCount();
    });


    _sessionExpiredSub = _authService.sessionExpiredStream.listen((_) {
      _handleSessionExpired();
    });


    _statusSub = _authService.statusStream.listen((status) {
      if (!mounted) return;
      if (status == AuthStatus.loading) return;
      setState(() {
        _loginStateVersion++;
      });
      _fetchUnreadCount();
      if (_authService.isLoggedIn) {
        _wsService.connect();
      }
    });


    _unreadTimer = Timer.periodic(const Duration(seconds: 30), (_) {
      _fetchUnreadCount();
    });


    WidgetsBinding.instance.addPostFrameCallback((_) {
      _fetchUnreadCount();
      if (_authService.isLoggedIn) {
        _wsService.connect();
      }
    });
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _unreadTimer?.cancel();
    _wsReloadSub?.cancel();
    _wsUnreadSub?.cancel();
    _sessionExpiredSub?.cancel();
    _statusSub?.cancel();
    super.dispose();
  }


  void _handleSessionExpired() {
    if (!mounted) return;


    _wsService.disconnect();

    setState(() {
      // isLoggedIn đã là false do handleSessionExpired() → chuyển về Home
      _selectedIndex = 0;
      _loginStateVersion++; // Force rebuild screens để cập nhật trạng thái guest
      _unreadCount = 0;
    });

  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    super.didChangeAppLifecycleState(state);
    if (state == AppLifecycleState.resumed) {
      // Khi app từ background quay lại → kiểm tra session
      _checkSessionOnResume();
    }
  }

  /// Kiểm tra session khi app resume từ background
  Future<void> _checkSessionOnResume() async {
    // Đảm bảo token đã load xong trước khi quyết định
    await _authService.ensureTokenLoaded();
    if (!mounted) return;

    if (!_authService.isLoggedIn) {
      // Nếu đang ở tab cần auth nhưng session đã hết → chuyển về Home
      if (_authRequiredTabs.contains(_selectedIndex)) {
        setState(() {
          _selectedIndex = 0;
          _loginStateVersion++; // Force rebuild screens
        });
      }
      return;
    }

    // Nếu đã login, fetch lại unread count
    _fetchUnreadCount();

    // Re-check quyền thông báo khi resume (OS Settings có thể đổi ngoài app).
    _syncNotificationStatusOnResume();
  }



  Future<void> _syncNotificationStatusOnResume() async {
    try {
      if (!_authService.isLoggedIn) return;
      final granted = await PushNotificationService().isNotificationGranted();
      if (granted) {
        String? token;
        try {
          token = await PushNotificationService().requestTokenForSync();
        } catch (_) {
          token = null;
        }

        // Nếu token null, thử lấy trực tiếp từ Firebase 1 lần nữa (tránh cache cũ)
        if (token == null || token.isEmpty) {
          debugPrint('[Resume] Token null từ cache, thử lấy trực tiếp từ Firebase...');
          try {
            token = await FirebaseMessaging.instance.getToken();
          } catch (e) {
            debugPrint('[Resume] Lỗi lấy token Firebase: $e');
          }
        }

        if (token != null && token.isNotEmpty) {
          // Có token -> gửi kèm token
          await DeviceTokenApiService().updateNotificationStatus(true, fcmToken: token);
          debugPrint('[Resume] Đã sync PATCH enabled=true kèm token');
        } else {
          // Không có token -> VẪN GỬI PATCH enabled=true (BE sẽ bật cờ, token bù sau)
          debugPrint('[Resume] Không có FCM token, vẫn bật cờ enabled=true');
          await DeviceTokenApiService().updateNotificationStatus(true);
        }
      } else {
        await DeviceTokenApiService().updateNotificationStatus(false);
      }
    } catch (_) {}
  }

  Future<void> _fetchUnreadCount() async {
    // Đảm bảo token đã load xong trước khi gọi API
    if (!_authService.isTokenLoaded) {
      await _authService.ensureTokenLoaded();
      if (!mounted) return;
    }

    // Nếu chưa đăng nhập thì không cần fetch unread count
    if (!_authService.isLoggedIn) return;

    // Gọi API lấy số thông báo chưa đọc
    try {
      final count = await ThongBaoApiService().getUnreadCount();
      if (!mounted) return;
      if (_unreadCount != count) {
        setState(() => _unreadCount = count);
      }
    } catch (e) {
      debugPrint('MainScreen._fetchUnreadCount error: $e');
    }
  }

  void _onItemTapped(int index) async {
    // Index 0 = Trang chủ (public), các index khác yêu cầu đăng nhập
    if (index > 0) {
      final loggedIn = await requireLogin(context);
      if (!loggedIn || !mounted) return;
    }

    setState(() {
      _selectedIndex = index;
    });

    // Refresh unread count when switching to notification tab
    if (index == 3) {
      _fetchUnreadCount();
    }
  }

  @override
  Widget build(BuildContext context) {
    // Khi status == loading (token chưa load xong) → hiện skeleton


    return StreamBuilder<AuthStatus>(
      stream: _authService.statusStream,
      initialData: _authService.status,
      builder: (context, snapshot) {
        if (snapshot.data == AuthStatus.loading) {
          return const _MainScreenSkeleton();
        }
        return _buildMainContent(context);
      },
    );
  }

  Widget _buildMainContent(BuildContext context) {
    return Scaffold(
      extendBody: true,
      extendBodyBehindAppBar: true,
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Container(
          color: Colors.white,
          width: double.infinity,
          height: double.infinity,
          child: Column(
            children: [
              const NetworkBanner(),
              Expanded(
                child: IndexedStack(
                  index: _selectedIndex,
                  children: _screens,
                ),
              ),
            ],
          ),
        ),
      ),
      bottomNavigationBar: BottomNavigationBar(
        type: BottomNavigationBarType.fixed,
        backgroundColor: Colors.white,
        selectedItemColor: Colors.blue,
        unselectedItemColor: Colors.grey,
        currentIndex: _selectedIndex,
        onTap: _onItemTapped,
        items: [
          const BottomNavigationBarItem(
            icon: Icon(Icons.home_outlined),
            activeIcon: Icon(Icons.home),
            label: 'Trang chủ',
          ),
          const BottomNavigationBarItem(
            icon: Icon(Icons.folder_outlined),
            activeIcon: Icon(Icons.folder),
            label: 'Hồ sơ',
          ),
          const BottomNavigationBarItem(
            icon: Icon(Icons.calendar_month_outlined),
            activeIcon: Icon(Icons.calendar_month),
            label: 'Đặt lịch hẹn',
          ),
          BottomNavigationBarItem(
            icon: _unreadCount > 0
                ? Badge(
                    label: Text(
                      _unreadCount > 99 ? '99+' : '$_unreadCount',
                      style: const TextStyle(fontSize: 10, color: Colors.white),
                    ),
                    child: const Icon(Icons.notifications_outlined),
                  )
                : const Icon(Icons.notifications_outlined),
            activeIcon: _unreadCount > 0
                ? Badge(
                    label: Text(
                      _unreadCount > 99 ? '99+' : '$_unreadCount',
                      style: const TextStyle(fontSize: 10, color: Colors.white),
                    ),
                    child: const Icon(Icons.notifications),
                  )
                : const Icon(Icons.notifications),
            label: 'Thông báo',
          ),
          const BottomNavigationBarItem(
            icon: Icon(Icons.person_outline),
            activeIcon: Icon(Icons.person),
            label: 'Tài khoản',
          ),
        ],
      ),
    );
  }
}

/// Skeleton hiển thị khi AuthService.status == loading (token chưa load xong),

class _MainScreenSkeleton extends StatelessWidget {
  const _MainScreenSkeleton();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Column(
          children: [
            // Header placeholder (logo + tên app)
            Container(
              height: 60,
              padding: const EdgeInsets.symmetric(horizontal: 16),
              alignment: Alignment.centerLeft,
              child: Row(
                children: [
                  Icon(
                    Icons.medical_services_outlined,
                    color: Colors.blue.shade600,
                    size: 28,
                  ),
                  const SizedBox(width: 12),
                  Text(
                    'Đặt Lịch Khám',
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: Colors.blue.shade700,
                    ),
                  ),
                ],
              ),
            ),
            // Body shimmer (reuse widget có sẵn — không nhận itemCount)
            const Expanded(child: ShimmerLoading()),
            // Bottom nav placeholder
            Container(
              height: 60,
              decoration: BoxDecoration(
                color: Colors.white,
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.05),
                    blurRadius: 8,
                    offset: const Offset(0, -2),
                  ),
                ],
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: List.generate(
                  5,
                  (_) => Container(
                    width: 24,
                    height: 24,
                    decoration: BoxDecoration(
                      color: Colors.grey[300],
                      borderRadius: BorderRadius.circular(4),
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}