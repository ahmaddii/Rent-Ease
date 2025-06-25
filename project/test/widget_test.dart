// This is a basic Flutter widget test.
//
// To perform an interaction with a widget in your test, use the WidgetTester
// utility in the flutter_test package. For example, you can send tap and scroll
// gestures. You can also use WidgetTester to find child widgets in the widget
// tree, read text, and verify that the values of widget properties are correct.

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:rentease/main.dart';

void main() {
  testWidgets('Welcome screen test', (WidgetTester tester) async {
    // Build our app and trigger a frame.
    await tester.pumpWidget(const MyApp());

    // Verify that the welcome screen is displayed
    expect(find.text('RentEase'), findsOneWidget);
    expect(find.text('Find Your Dream Home'), findsOneWidget);

    // Verify that login button is present
    expect(find.text('Login'), findsOneWidget);

    // Verify that sign up button is present
    expect(find.text('Sign Up'), findsOneWidget);

    // Verify that continue as guest button is present
    expect(find.text('Continue as Guest'), findsOneWidget);
  });

  testWidgets('Login screen navigation test', (WidgetTester tester) async {
    // Build our app and trigger a frame.
    await tester.pumpWidget(const MyApp());

    // Tap the login button
    await tester.tap(find.text('Login'));
    await tester.pumpAndSettle();

    // Verify that we're on the login screen
    expect(find.text('Welcome Back!'), findsOneWidget);
    expect(find.text('Sign in to continue'), findsOneWidget);

    // Verify that email and password fields are present
    expect(find.byIcon(Icons.email), findsOneWidget);
    expect(find.byIcon(Icons.lock), findsOneWidget);
  });

  testWidgets('Sign up screen navigation test', (WidgetTester tester) async {
    // Build our app and trigger a frame.
    await tester.pumpWidget(const MyApp());

    // Tap the sign up button
    await tester.tap(find.text('Sign Up'));
    await tester.pumpAndSettle();

    // Verify that we're on the sign up screen
    expect(find.text('Create Account'), findsOneWidget);
    expect(find.text('Sign up to get started'), findsOneWidget);

    // Verify that all required fields are present
    expect(find.byIcon(Icons.person), findsOneWidget);
    expect(find.byIcon(Icons.email), findsOneWidget);
    expect(find.byIcon(Icons.lock), findsNWidgets(2)); // Two password fields
  });
}
