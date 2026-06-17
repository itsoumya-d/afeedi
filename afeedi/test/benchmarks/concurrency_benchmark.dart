import 'dart:async';

Future<void> simulateQuery(int delayMs) async {
  await Future.delayed(Duration(milliseconds: delayMs));
}

Future<int> runSequential() async {
  final stopwatch = Stopwatch()..start();

  await simulateQuery(100); // interactions
  await simulateQuery(100); // connections
  await simulateQuery(100); // scheduled
  await simulateQuery(100); // recommendations

  stopwatch.stop();
  return stopwatch.elapsedMilliseconds;
}

Future<int> runConcurrent() async {
  final stopwatch = Stopwatch()..start();

  await Future.wait([
    simulateQuery(100),
    simulateQuery(100),
    simulateQuery(100),
    simulateQuery(100),
  ]);

  stopwatch.stop();
  return stopwatch.elapsedMilliseconds;
}

void main() async {
  print('Starting benchmark...\n');

  // Warmup
  await runSequential();
  await runConcurrent();

  final seqTime = await runSequential();
  print('Sequential execution time: ${seqTime}ms');

  final conTime = await runConcurrent();
  print('Concurrent execution time: ${conTime}ms');

  final improvement = seqTime - conTime;
  final percentage = (improvement / seqTime) * 100;

  print('\nResults:');
  print('Improvement: ${improvement}ms (${percentage.toStringAsFixed(2)}% faster)');
}
