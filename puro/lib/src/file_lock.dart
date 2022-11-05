import 'dart:convert';
import 'dart:typed_data';

import 'package:file/file.dart';

import 'progress.dart';
import 'provider.dart';

/// Locks the [file] for reading or writing, releasing the lock when [fn]
/// returns.
///
/// If [mode] is FileMode.write or FileMode.append, this will acquire an
/// exclusive lock that prevents any other process from locking it. Otherwise,
/// this acquires a shared lock which is useful if multiple processes should be
/// able to read from the file at the same time (while blocking exclusive
/// locks).
///
/// This does NOT prevent this file from being accessed more than once in our
/// own process and the behavior is undefined if that happens.
Future<T> lockFile<T>(
  Scope scope,
  File file,
  Future<T> fn(RandomAccessFile handle), {
  FileMode mode = FileMode.read,
  bool? exclusive,
}) async {
  exclusive ??= mode != FileMode.read;
  final handle = await file.open(mode: mode);
  await ProgressNode.of(scope).wrap((scope, node) async {
    node.description = 'Waiting for lock on ${file.path}';
    await handle.lock(
      exclusive! ? FileLock.blockingExclusive : FileLock.blockingShared,
    );
  });
  try {
    return await fn(handle);
  } finally {
    if (mode != FileMode.read) {
      await handle.flush();
    }
    await handle.close();
  }
}

Future<Uint8List> readBytesAtomic({
  required Scope scope,
  required File file,
}) async {
  return await lockFile(
    scope,
    file,
    (handle) async {
      return handle.read(handle.lengthSync());
    },
  );
}

/// Acquires an shared lock on a file before reading from it.
Future<String> readAtomic({
  required Scope scope,
  required File file,
}) async {
  final bytes = await readBytesAtomic(scope: scope, file: file);
  return utf8.decode(bytes);
}

Future<void> writeBytesAtomic({
  required Scope scope,
  required File file,
  required List<int> bytes,
}) async {
  await lockFile(
    scope,
    file,
    (handle) => handle.writeFrom(bytes),
    mode: FileMode.write,
  );
}

/// Acquires an exclusive lock on a file before writing to it.
Future<void> writeAtomic({
  required Scope scope,
  required File file,
  required String content,
}) {
  return writeBytesAtomic(
    scope: scope,
    file: file,
    bytes: utf8.encode(content),
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
}) async {
  if (file.existsSync()) {
    final existing = await readBytesAtomic(scope: scope, file: file);
    if (_bytesEqual(bytes, existing)) {
      return;
    }
  }
  await writeBytesAtomic(scope: scope, file: file, bytes: bytes);
}

Future<void> writePassiveAtomic({
  required Scope scope,
  required File file,
  required String content,
}) {
  return writeBytesPassiveAtomic(
    scope: scope,
    file: file,
    bytes: utf8.encode(content),
  );
}
