import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:toastification/toastification.dart';
import 'core/dio_client.dart';
import 'services/auth_service.dart';
import 'services/push_notification_service.dart';
import 'screens/main_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  SystemChrome.setSystemUIOverlayStyle(
    const SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
      statusBarIconBrightness: Brightness.dark,
    ),
  );

  // Khởi tạo DioClient với AuthService để TokenInterceptor hoạt động
  final authService = AuthService();
  DioClient().init(authService: authService);

  // Gán callback logout để xử lý khi user chủ động bấm Đăng xuất.
  // (Không dùng để handle session expired — session expired dùng stream bên dưới,
  //  giữ Home và chỉ hiện thông báo, KHÔNG đẩy LoginScreen.)
  authService.onLogoutRequired = () {
    authService.logout();
  };

  // Load token LAZY trong MainScreen  → app render ngay,
  // không treo màn đen 30-45s khi mạng yếu. MainScreen.initState()
  // sẽ gọi authService.loadToken() + render skeleton khi status == loading.

  // Lấy thời gian server để hiệu chỉnh Clock Skew


  DioClient().dio.get('/server-time').then((_) {}, onError: (_) {});


  PushNotificationService().initialize();

  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return ToastificationWrapper(
      child: MaterialApp(
        title: 'Đặt Lịch Khám',
        debugShowCheckedModeBanner: false,
        navigatorKey: PushNotificationService.navigatorKey,
        theme: ThemeData(
          colorScheme: ColorScheme.fromSeed(seedColor: Colors.blue),
          scaffoldBackgroundColor: Colors.white,
          useMaterial3: true,
        ),
        localizationsDelegates: const [
          GlobalMaterialLocalizations.delegate,
          GlobalWidgetsLocalizations.delegate,
          GlobalCupertinoLocalizations.delegate,
        ],
        supportedLocales: const [Locale('vi', 'VN'), Locale('en', 'US')],
        home: const MainScreen(),
      ),
    );
  }
}
