# Đặt Lịch Khám

Ứng dụng hỗ trợ bệnh nhân tra cứu thông tin phòng khám, đặt lịch hẹn trực tuyến và theo dõi hồ sơ khám chữa bệnh. Ứng dụng được phát triển bằng **Flutter** (hỗ trợ Android & Web) và kết nối với hệ thống Backend **Java Spring Boot** qua REST API và WebSocket.

## Chức năng chính

- **Xác thực & Bảo mật:** Đăng ký, đăng nhập (JWT), xác minh email qua OTP, quên và đổi mật khẩu.
- **Tra cứu thông tin:** Tìm kiếm chuyên khoa, dịch vụ khám và thông tin bác sĩ.
- **Quản lý lịch hẹn:** Đặt lịch theo chuyên khoa, dịch vụ, bác sĩ, ngày và ca làm việc; xem, cập nhật hoặc hủy lịch hẹn.
- **Hồ sơ bệnh nhân:** Quản lý thông tin cá nhân, theo dõi chỉ số sinh tồn, đơn thuốc và lịch sử khám bệnh.
- **Kết quả cận lâm sàng & Thanh toán:** Xem chỉ định dịch vụ, kết quả xét nghiệm, chẩn đoán hình ảnh, hóa đơn thanh toán và lịch tái khám.
- **Thông báo thời gian thực:** Nhận thông báo đẩy qua Firebase Cloud Messaging (FCM) và cập nhật trạng thái tức thì qua WebSocket.

## Công nghệ sử dụng

- **Frontend (Mobile/Web):** Flutter, Dart *(AI-assisted UI)*
- **Backend & Database:** Java, Spring Boot, Spring Security (JWT), MySQL
- **Realtime & Notification:** WebSocket, Firebase Cloud Messaging (FCM)

## Trải nghiệm ứng dụng

- **Trải nghiệm trực tiếp trên Web:** [Mở ứng dụng Web](https://app-dat-lich-kham1.vercel.app/)
- **Tải file cài đặt Android (APK):** [Tải app-release.apk tại đây](https://drive.google.com/file/d/1rBeQFHac6j90IooU1mkmw1yQuY35ECNy/view?usp=drive_link)
- **Tài khoản demo:**
  - **Email:** `demoappdatlich@gmail.com`
  - **Mật khẩu:** `123456`

> **Lưu ý khi cài đặt bản Android:** Vui lòng cấp quyền *"Cài đặt ứng dụng từ nguồn không xác định"* trên thiết bị Android để cài đặt file APK.
