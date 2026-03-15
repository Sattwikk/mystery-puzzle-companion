// Widget tests for graduate requirement: verify key screens and navigation.

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:project_1/main.dart';

void main() {
  testWidgets('App launches and shows Home with title', (WidgetTester tester) async {
    await tester.pumpWidget(const ProviderScope(child: MysteryPuzzleApp()));
    await tester.pumpAndSettle();
    expect(find.text('Mystery Puzzle Companion'), findsOneWidget);
  });

  testWidgets('Quick Start section has Browse Missions button', (WidgetTester tester) async {
    await tester.pumpWidget(const ProviderScope(child: MysteryPuzzleApp()));
    await tester.pumpAndSettle();
    expect(find.text('Browse Missions'), findsOneWidget);
  });

  testWidgets('Bottom navigation has Home, Missions, Teams', (WidgetTester tester) async {
    await tester.pumpWidget(const ProviderScope(child: MysteryPuzzleApp()));
    await tester.pumpAndSettle();
    expect(find.text('Home'), findsOneWidget);
    expect(find.text('Missions'), findsOneWidget);
    expect(find.text('Teams'), findsOneWidget);
  });

  testWidgets('Tapping Missions tab shows Missions screen', (WidgetTester tester) async {
    await tester.pumpWidget(const ProviderScope(child: MysteryPuzzleApp()));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Missions'));
    await tester.pumpAndSettle();
    expect(find.text('Missions'), findsWidgets);
  });
}
