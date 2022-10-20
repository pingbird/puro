import 'dart:typed_data';

import 'package:file/file.dart';

import 'progress.dart';
import 'provider.dart';

/// Locks the [file] for reading or writing, releasing the lock when [fn]
/// returns.
///
/// If [exclusive] is true, this will acquire an exclusive lock that prevents
/// any other process from locking it. Otherwise, if [exclusive] is false, this
/// acquires a shared lock which is useful if multiple processes should be able
/// to read from the file at the same time (while blocking exclusive locks).
///
/// This does NOT prevent this file from being accessed more than once in our
/// own process and the behavior is undefined if that happens.
Future<T> lockFile<T>(
  Scope scope,
  File file,
  Future<T> fn(RandomAccessFile handle), {
  bool exclusive = true,
}) async {
  final handle = await file.open(mode: FileMode.write);
  await ProgressNode.of(scope).wrap((scope, node) async {
    node.description = 'Waiting for lock on ${file.path}';
    await handle.lock(
      exclusive ? FileLock.blockingExclusive : FileLock.blockingShared,
    );
  });
  try {
    return fn(handle);
  } finally {
    await handle.close();
  }
}

/// Acquires an exclusive lock on a file before writing to it.
Future<void> writeFileAtomic({
  required Scope scope,
  required Uint8List bytes,
  required File file,
}) async {
  await lockFile(
    scope,
    file,
    (handle) async {
      await handle.writeFrom(bytes);
      await handle.truncate(bytes.length);
    },
  );
}

/// Acquires an shared lock on a file before reading from it.
Future<Uint8List> readFileAtomic({
  required Scope scope,
  required File file,
}) async {
  return await lockFile(
    scope,
    file,
    (handle) async {
      return handle.read(handle.lengthSync());
    },
    exclusive: false,
  );
}
