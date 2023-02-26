import 'dart:io';

import '../config.dart';
import '../provider.dart';

Future<Directory> getDartSdkPackages({
  required Scope scope,
  required String commit,
  required String packageName,
}) async {
  final config = PuroConfig.of(scope);
  final pkgDir = config.sharedDartPkgDir.childDirectory(commit);
  return pkgDir;
}
