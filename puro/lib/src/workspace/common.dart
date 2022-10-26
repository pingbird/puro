import 'package:file/file.dart';

import '../provider.dart';

abstract class IdeConfig {
  IdeConfig({
    required this.workspaceDir,
    this.flutterSdkDir,
    this.dartSdkDir,
    required this.exists,
  });
  String get name;
  final Directory workspaceDir;
  Directory? flutterSdkDir;
  Directory? dartSdkDir;
  bool exists;
  Future<void> save({required Scope scope});
  Future<void> backup({required Scope scope});
  Future<void> restore({required Scope scope});
}
