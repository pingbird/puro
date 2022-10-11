import '../config.dart';
import '../provider.dart';
import 'gitignore.dart';

/// Switches the environment of the current project.
Future<void> useEnvironment({
  required Scope scope,
  required String name,
}) async {
  final config = PuroConfig.of(scope);
  final model = config.readDotfile();
  config.getEnv(name).ensureExists();
  model.env = name;
  config.writeDotfile(model);
  await installGitignore(scope: scope);
}
