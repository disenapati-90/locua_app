// Basic smoke test — just confirms the app builds and shows the shell.
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:locua/main.dart';

void main() {
  testWidgets('App launches without crashing', (WidgetTester tester) async {
    await tester.pumpWidget(const LocuaApp());
    await tester.pump();
    expect(find.byType(MaterialApp), findsOneWidget);
  });
}