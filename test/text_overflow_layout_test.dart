import 'package:datlichkham/models/chi_tiet_ca_kham.dart';
import 'package:datlichkham/models/vital_signs_model.dart';
import 'package:datlichkham/screens/patient/lam_sang/lam_sang_screen.dart';
import 'package:datlichkham/screens/profile/widgets/vital_signs_section.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  setUp(() {
    TestWidgetsFlutterBinding.ensureInitialized();
  });

  testWidgets('long dental values wrap and hide inapplicable status', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(360, 800);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    const value = 'Răng hàm bị tổn thương, cần tiếp tục theo dõi và điều trị';
    final data = ChiTietCaKham(
      maPhieuKham: 1,
      maChuyenKhoa: 5,
      tinhTrangRang: value,
      phieuChiDinh: const [],
      toaThuoc: const [],
    );

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(body: LamSangScreen(data: data)),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text(value), findsOneWidget);
    expect(find.text('N/A'), findsNothing);
    expect(tester.takeException(), isNull);
  });

  testWidgets('short vital values retain their assessed status', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(360, 800);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    final data = ChiTietCaKham(
      maPhieuKham: 1,
      maChuyenKhoa: 1,
      nhietDo: '36.7',
      phieuChiDinh: const [],
      toaThuoc: const [],
    );

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(body: LamSangScreen(data: data)),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('36.7'), findsOneWidget);
    expect(find.text('Bình thường'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('vital signs reflow into columns on a narrow screen', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(320, 800);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: VitalSignsSection(
            profile: null,
            vitalSigns: VitalSignsModel(
              nhietDo: 36.7,
              nhipTim: 120,
              nhipTho: 18,
              canNang: 65.5,
              chieuCao: 172,
            ),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Nhiệt độ'), findsOneWidget);
    expect(find.text('Chiều cao'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
}
