import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:afeedi/widgets/common/loading_shimmer.dart';
import 'package:shimmer/shimmer.dart';

void main() {
  testWidgets('LoadingShimmer renders correct number of items', (WidgetTester tester) async {
    // Build our app and trigger a frame.
    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(
          body: LoadingShimmer(itemCount: 2),
        ),
      ),
    );

    // Verify that the correct number of Shimmer widgets are present
    expect(find.byType(Shimmer), findsNWidgets(2));
  });
}
