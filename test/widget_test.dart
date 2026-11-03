import 'package:blood_connect_sl/widgets/prana_logo.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:blood_connect_sl/main.dart';
import 'package:blood_connect_sl/screens/splash_screen.dart';
import 'package:blood_connect_sl/screens/login_screen.dart';

void main() {
  setUp(() {
    FlutterSecureStorage.setMockInitialValues({});
  });
  testWidgets(
    'App smoke test - verifies initial splash screen and navigation',
    (WidgetTester tester) async {
      await tester.pumpWidget(const PranaApp());

      // Verify SplashScreen is loaded
      expect(find.byType(SplashScreen), findsOneWidget);
      expect(find.byType(PranaLogo), findsOneWidget);

      // Fast-forward animation & 2 second splash timer
      await tester.pump();
      await tester.pump(const Duration(seconds: 3));
      await tester.pumpAndSettle();

      // Verify transition to LoginScreen
      expect(find.byType(LoginScreen), findsOneWidget);
      expect(find.text('Welcome to Prana'), findsOneWidget);
      expect(find.text('Login'), findsOneWidget);
      expect(find.text('Create account'), findsOneWidget);
    },
  );
}
