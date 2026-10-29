import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

void main() {
  test('bundled Classmate page contains the app navigation', () async {
    final html = await File('assets/web/app/index.html').readAsString();

    expect(html, contains('Classmate'));
    expect(html, contains('id="dashboard"'));
    expect(html, contains('id="attendance"'));
    expect(html, contains('id="timetable"'));
    expect(html, contains('id="calendar"'));
    expect(html, contains('id="alerts"'));
  });
}
