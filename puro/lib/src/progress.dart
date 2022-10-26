import 'package:clock/clock.dart';
import 'package:http/http.dart';
import 'package:neoansi/neoansi.dart';

import 'git.dart';
import 'logger.dart';
import 'provider.dart';
import 'terminal.dart';

abstract class ProgressNode {
  ProgressNode({required this.scope});

  final Scope scope;

  late final terminal = Terminal.of(scope);

  void Function()? _onChanged;

  final children = <ActiveProgressNode>[];

  void addNode(ActiveProgressNode node) {
    assert(!children.contains(node));
    assert(node._onChanged == null);
    node._onChanged = () {
      if (_onChanged != null) _onChanged!();
    };
    children.add(node);
    if (_onChanged != null) _onChanged!();
  }

  void removeNode(ActiveProgressNode node) {
    assert(children.contains(node));
    node._onChanged = null;
    children.remove(node);
    if (_onChanged != null) _onChanged!();
  }

  Future<T> wrap<T>(
    Future<T> Function(Scope scope, ActiveProgressNode node) fn, {
    bool removeWhenComplete = true,
    bool optional = false,
  }) async {
    final start = clock.now();
    final log = PuroLogger.of(scope);
    final node = ActiveProgressNode(
      scope: OverrideScope(parent: scope),
    );
    node.scope.add(ProgressNode.provider, node);
    addNode(node);
    try {
      return await fn(scope, node);
    } catch (exception, stackTrace) {
      if (node.description != null) {
        log.e('Exception while ${node.description}');
      }
      if (optional) {
        log.e('$exception\n$stackTrace');
        return null as T;
      }
      rethrow;
    } finally {
      node.complete = true;
      if (removeWhenComplete) removeNode(node);
      log.v(
        '${node.description} took ${clock.now().difference(start).inMilliseconds}ms',
      );
    }
  }

  String render();

  static final provider = Provider<ProgressNode>((scope) {
    return RootProgressNode(scope: scope);
  });
  static ProgressNode of(Scope scope) => scope.read(provider);
}

class ActiveProgressNode extends ProgressNode {
  ActiveProgressNode({required super.scope});

  String? _description;
  String? get description => _description;
  set description(String? description) {
    if (description != null) {
      PuroLogger.of(scope).v(
        'Started ${description.substring(0, 1).toLowerCase()}'
        '${description.substring(1)}',
      );
    }
    if (_description == description) return;
    _description = description;
    if (_onChanged != null) _onChanged!();
  }

  num? _progress;
  num? get progress => _progress;
  set progress(num? progress) {
    if (_progress == progress) return;
    _progress = progress;
    if (_onChanged != null) _onChanged!();
  }

  num? _progressTotal;
  num? get progressTotal => _progressTotal;
  set progressTotal(num? progressTotal) {
    if (_progressTotal == progressTotal) return;
    _progressTotal = progressTotal;
    if (_onChanged != null) _onChanged!();
  }

  var _complete = false;
  bool get complete => _complete;
  set complete(bool complete) {
    if (_complete == complete) return;
    _complete = complete;
    if (_onChanged != null) _onChanged!();
  }

  Stream<List<int>> wrapHttpResponse(StreamedResponse response) {
    progressTotal = response.contentLength;
    progress = 0;
    return wrapByteStream(response.stream);
  }

  Stream<List<int>> wrapByteStream(Stream<List<int>> stream) {
    return stream.map((event) {
      progress = (progress ?? 0) + event.length;
      return event;
    });
  }

  void onCloneProgress(GitCloneStep step, double progress) {
    progressTotal = GitCloneStep.values.length;
    this.progress = step.index + progress;
  }

  double? get progressFraction {
    if (_progress == null || _progressTotal == null) {
      return null;
    }
    return (_progress! / _progressTotal!).clamp(0.0, 1.0);
  }

  static String _indentString(
    String input,
    String indent,
  ) {
    return input.split('\n').map((e) => '$indent$e').join('\n');
  }

  @override
  String render() {
    const width = 15;
    final progressFraction = this.progressFraction;
    String text;
    if (progressFraction == null) {
      text = '[${('/ ' * (width ~/ 2 + 1)).substring(0, width)}]';
    } else {
      final progressChars = (progressFraction * width).round();
      text = '[${('=' * progressChars).padRight(width)}]';
    }
    text = terminal.format.color(
      text,
      foregroundColor: Ansi8BitColor.blue,
      bold: true,
    );
    if (_description != null) {
      text = '$text $description';
    }
    if (children.isNotEmpty) {
      text = '$text\n${_indentString(
        '${children.map((e) => e.render()).join('\n')}',
        '  ',
      )}';
    }
    return text;
  }
}

class RootProgressNode extends ProgressNode {
  RootProgressNode({
    required super.scope,
  }) {
    _onChanged = () {
      terminal.status = render();
    };
  }

  @override
  String render() {
    return children.map((e) => e.render()).join('\n');
  }
}
