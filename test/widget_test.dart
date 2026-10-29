import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:portfoy_app/main.dart';
import 'package:portfoy_app/providers/portfolio_provider.dart';

void main() {
  testWidgets('PortfoyApp desktop smoke test', (WidgetTester tester) async {
    tester.view.physicalSize = const Size(1280, 800);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(
      ChangeNotifierProvider(
        create: (_) => PortfolioProvider(),
        child: const PortfoyApp(),
      ),
    );

    await tester.pump();
    await tester.pump(const Duration(milliseconds: 200));

    expect(find.text('Toplam Portföy Değeri'), findsOneWidget);
    expect(find.text('Toplam Kâr / Zarar'), findsOneWidget);
    expect(find.text('Gerçekleşen Kâr / Zarar'), findsOneWidget);
    expect(find.text('Yeni Portföy'), findsOneWidget);
  });
}
