import 'package:flutter/material.dart';
import '../services/auth_service.dart';

/// Banner vàng hiện khi app đang dùng phiên cũ (state = unverified:
/// có token nhưng backend chưa xác nhận do mạng yếu).
class NetworkBanner extends StatelessWidget {
  const NetworkBanner({super.key});

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<AuthStatus>(
      stream: AuthService().statusStream,
      initialData: AuthService().status,
      builder: (context, snapshot) {
        if (snapshot.data == AuthStatus.networkUnavailable) {
          return MaterialBanner(
            content: const Row(
              children: [
                Icon(Icons.wifi_off, color: Colors.red, size: 20),
                SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'Không có kết nối mạng. Vui lòng kiểm tra Wifi/4G.',
                    style: TextStyle(fontSize: 13, color: Colors.red),
                  ),
                ),
              ],
            ),
            backgroundColor: Colors.red[50],
            actions: [
              TextButton(
                onPressed: () => AuthService().loadToken(),
                child:
                    const Text('Thử lại', style: TextStyle(color: Colors.red)),
              ),
            ],
          );
        }

        if (snapshot.data != AuthStatus.unverified) {
          return const SizedBox.shrink();
        }
        return MaterialBanner(
          content: const Row(
            children: [
              Icon(Icons.wifi_off, color: Colors.orange, size: 20),
              SizedBox(width: 8),
              Expanded(
                child: Text(
                  'Đang dùng phiên cũ. Một số dữ liệu có thể chưa được cập nhật.',
                  style: TextStyle(fontSize: 13),
                ),
              ),
            ],
          ),
          backgroundColor: Colors.orange[50],
          actions: [
            TextButton(
              onPressed: () async {
                await AuthService().loadToken();
              },
              child: const Text('Thử lại'),
            ),
          ],
        );
      },
    );
  }
}
