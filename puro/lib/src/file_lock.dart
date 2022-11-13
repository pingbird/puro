import 'dart:convert';
import 'dart:typed_data';

import 'package:file/file.dart';
import 'package:mutex/mutex.dart';
import 'package:path/path.dart' as path;

import 'progress.dart';
import 'provider.dart';

/// Linux has some quirky behavior when a process has multiple locks on the same
/// file that we want to avoid.
final _fileMutexes = <String, Mutex>{};

/// Locks the [file] for reading or writing, releasing the lock when [fn]
/// returns.
///
/// If [mode] is FileMode.write or FileMode.append, this will acquire an
/// exclusive lock that prevents any other process from locking it. Otherwise,
/// this acquires a shared lock which is useful if multiple processes should be
/// able to read from the file at the same time (while blocking exclusive
/// locks).
Future<T> lockFile<T>(
  Scope scope,
  File file,
  Future<T> fn(RandomAccessFile handle), {
  FileMode mode = FileMode.read,
  bool? exclusive,
  bool background = false,
}) async {
  final canonicalPath = path.join(
    file.absolute.parent.resolveSymbolicLinksSync(),
    file.basename,
  );
  final mutex = _fileMutexes.putIfAbsent(canonicalPath, () => Mutex());
  await mutex.acquire();
  try {
    exclusive ??= mode != FileMode.read;
    final fileLock =
        exclusive ? FileLock.blockingExclusive : FileLock.blockingShared;
    final handle = await file.open(mode: mode);
    if (background) {
      await handle.lock(fileLock);
    } else {
      await ProgressNode.of(scope).wrap((scope, node) async {
        node.description = 'Waiting for lock on ${file.path}';
        await handle.lock(fileLock);
      });
    }
    try {
      return await fn(handle);
    } finally {
      if (mode != FileMode.read) {
        await handle.flush();
      }
      await handle.close();
    }
  } finally {
    mutex.release();
  }
}

Future<Uint8List> readBytesAtomic({
  required Scope scope,
  required File file,
  bool background = false,
}) async {
  return await lockFile(
    scope,
    file,
    (handle) async {
      return handle.read(handle.lengthSync());
    },
    background: background,
  );
}

/// Acquires an shared lock on a file before reading from it.
Future<String> readAtomic({
  required Scope scope,
  required File file,
  bool background = false,
}) async {
  final bytes = await readBytesAtomic(
    scope: scope,
    file: file,
    background: background,
  );
  return utf8.decode(bytes);
}

Future<void> writeBytesAtomic({
  required Scope scope,
  required File file,
  required List<int> bytes,
  bool background = false,
}) async {
  await lockFile(
    scope,
    file,
    (handle) => handle.writeFrom(bytes),
    mode: FileMode.write,
    background: background,
  );
}

/// Acquires an exclusive lock on a file before writing to it.
Future<void> writeAtomic({
  required Scope scope,
  required File file,
  required String content,
  bool background = false,
}) {
  return writeBytesAtomic(
    scope: scope,
    file: file,
    bytes: utf8.encode(content),
    background: background,
  );
}

bool _bytesEqual(List<int> a, List<int> b) {
  if (a.length != b.length) return false;
  for (var i = 0; i < a.length; i++) {
    if (a[i] != b[i]) return false;
  }
  return true;
}

/// Writes to file atomically only if it differs from the input.
Future<void> writeBytesPassiveAtomic({
  required Scope scope,
  required File file,
  required List<int> bytes,
  bool background = false,
}) async {
  if (file.existsSync()) {
    final existing = await readBytesAtomic(
      scope: scope,
      file: file,
      background: background,
    );
    if (_bytesEqual(bytes, existing)) {
      return;
    }
  }
  await writeBytesAtomic(
    scope: scope,
    file: file,
    bytes: bytes,
    background: background,
  );
}

Future<void> writePassiveAtomic({
  required Scope scope,
  required File file,
  required String content,
  bool background = false,
}) {
  return writeBytesPassiveAtomic(
    scope: scope,
    file: file,
    bytes: utf8.encode(content),
    background: background,
  );
}

Future<bool> compareFileBytesAtomic({
  required Scope scope,
  required File file,
  required List<int> bytes,
  bool prefix = false,
}) {
  return lockFile(scope, file, (handle) async {
    if (prefix
        ? handle.lengthSync() < bytes.length
        : handle.lengthSync() != bytes.length) return false;
    return _bytesEqual(await handle.read(bytes.length), bytes);
  });
}

Future<bool> compareFileAtomic({
  required Scope scope,
  required File file,
  required String content,
  bool prefix = false,
}) {
  return compareFileBytesAtomic(
    scope: scope,
    file: file,
    bytes: utf8.encode(content),
    prefix: prefix,
  );
}

/// Acquires a shared lock on a file and checks a condition.
///
/// If [onFail] is provided and [condition] returns false, this function
/// acquires an exclusive lock which is released when [onFail] completes.
Future<bool> checkAtomic({
  required Scope scope,
  required File file,
  required Future<bool> Function() condition,
  Future<void> Function()? onFail,
}) async {
  final pass = await lockFile(scope, file, (handle) => condition());
  if (pass || onFail == null) return pass;
  return await lockFile(scope, file, (handle) async {
    if (await condition()) return true;
    await onFail();
    return false;
  });
}
