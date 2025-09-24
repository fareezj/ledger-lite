import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:ledgerlite/widgets/text_widgets.dart';

class SplashPage extends ConsumerStatefulWidget {
  const SplashPage({super.key});

  @override
  ConsumerState<ConsumerStatefulWidget> createState() => _SplashPageState();
}

class _SplashPageState extends ConsumerState<SplashPage> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Color(0xFFF9F6F1),
      body: SafeArea(
        child: Column(
          children: [
            TextWidgets.mainBold(title: 'LedgerLite', fontSize: 24),
            Center(
              child: Image.asset('assets/images/splash-illus.png', scale: 2.3),
            ),
            SizedBox(height: 24),
            TextWidgets.mainBold(title: 'Track as you go', fontSize: 35),
            SizedBox(height: 12),
            TextWidgets.mainSemiBold(
              title: 'LedgerLite travels light, just like you.',
              fontSize: 18,
            ),
            SizedBox(height: 32),
            GestureDetector(
              onTap: () => Navigator.pushNamed(context, '/dashboard'),
              child: Container(
                width: 200,
                height: 48,
                padding: const EdgeInsets.symmetric(vertical: 13.0),
                decoration: BoxDecoration(
                  color: Colors.black,
                  borderRadius: BorderRadius.circular(24),
                ),
                alignment: Alignment.center,
                child: TextWidgets.mainSemiBold(
                  title: 'Get started',
                  fontSize: 16,
                  color: Colors.white,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
