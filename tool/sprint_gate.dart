import 'dart:io';

void main(List<String> args) async {
  stdout.writeln('====================================================');
  stdout.writeln('OmniCart Quality & Sprint Gatekeeper Pipeline');
  stdout.writeln('====================================================');

  final steps = [
    _GateStep(
      name: 'Dependencies Check',
      command: 'flutter',
      args: ['pub', 'get'],
    ),
    _GateStep(
      name: 'Source Code Format Verification',
      command: 'dart',
      args: ['format', '--set-exit-if-changed', 'lib', 'test', 'tool'],
    ),
    _GateStep(
      name: 'Static Code Analysis (Flutter 3.47+ Safety)',
      command: 'flutter',
      args: ['analyze', '--no-fatal-infos', '--no-pub'],
    ),
    _GateStep(
      name: 'Automated Test Suite Execution',
      command: 'flutter',
      args: ['test', '--no-pub'],
    ),
  ];

  final stopwatch = Stopwatch()..start();

  for (final step in steps) {
    stdout.writeln('\n[RUN] ${step.name}...');
    final result = await Process.run(step.command, step.args, runInShell: true);

    if (result.exitCode != 0) {
      stderr.writeln(
        '[FAIL] ${step.name} failed with exit code ${result.exitCode}',
      );
      if (result.stdout.toString().trim().isNotEmpty) {
        stdout.writeln('STDOUT:\n${result.stdout}');
      }
      if (result.stderr.toString().trim().isNotEmpty) {
        stderr.writeln('STDERR:\n${result.stderr}');
      }
      exit(result.exitCode);
    } else {
      stdout.writeln('[PASS] ${step.name} completed successfully.');
      final stdoutStr = result.stdout.toString().trim();
      if (stdoutStr.isNotEmpty && stdoutStr.contains('All tests passed!')) {
        stdout.writeln('       $stdoutStr');
      }
    }
  }

  // Device telemetry check if ADB is active
  await _checkConnectedDevice();

  stopwatch.stop();
  stdout.writeln('\n====================================================');
  stdout.writeln(
    '[SUCCESS] All OmniCart Sprint Gates Passed in ${stopwatch.elapsedMilliseconds}ms.',
  );
  stdout.writeln('====================================================');
  exit(0);
}

Future<void> _checkConnectedDevice() async {
  try {
    final adbResult = await Process.run('adb', ['devices'], runInShell: true);
    if (adbResult.exitCode == 0) {
      final lines = adbResult.stdout.toString().split('\n');
      final devices = lines
          .where(
            (l) =>
                l.trim().isNotEmpty &&
                !l.startsWith('List of devices attached'),
          )
          .toList();
      if (devices.isNotEmpty) {
        stdout.writeln('\n[INFO] Connected physical/virtual devices detected:');
        for (final dev in devices) {
          stdout.writeln('       - ${dev.trim()}');
        }
      } else {
        stdout.writeln(
          '\n[INFO] No ADB physical devices currently attached (CI/Offline Mode).',
        );
      }
    }
  } catch (_) {
    // ADB not in PATH, non-fatal
    stdout.writeln('\n[INFO] ADB command skipped (Environment clean).');
  }
}

class _GateStep {
  final String name;
  final String command;
  final List<String> args;

  const _GateStep({
    required this.name,
    required this.command,
    required this.args,
  });
}
