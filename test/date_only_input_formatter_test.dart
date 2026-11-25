import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:datlichkham/utils/date_only_input_formatter.dart';

void main() {
  final formatter = DateOnlyInputFormatter();
  const empty = TextEditingValue.empty;

  TextEditingValue apply(String input) {
    return formatter.formatEditUpdate(
      empty,
      TextEditingValue(
        text: input,
        selection: TextSelection.collapsed(offset: input.length),
      ),
    );
  }

  group('Chỉ cho nhập số + tự chèn "/"', () {
    test('nhập 2 số đầu → tự động chèn "/"', () {
      expect(apply('20').text, '20/');
    });

    test('nhập 4 số → dd/MM/', () {
      expect(apply('2005').text, '20/05/');
    });

    test('nhập đủ 8 số → dd/MM/yyyy', () {
      expect(apply('20052000').text, '20/05/2000');
    });

    test('nhập 5 số → dd/MM/y', () {
      expect(apply('20052').text, '20/05/2');
    });

    test('loại bỏ ký tự không phải số', () {
      expect(apply('a2b0c').text, '20/');
      expect(apply('20/05/2000').text, '20/05/2000');
      expect(apply('20-05-2000').text, '20/05/2000');
    });

    test('giới hạn tối đa 8 chữ số', () {
      expect(apply('20052000123').text, '20/05/2000');
    });

    test('trộn ký tự + số', () {
      expect(apply('2x0/05y2000').text, '20/05/2000');
    });
  });
}