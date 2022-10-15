enum ProgressUnit {
  bytes,
}

abstract class ProgressNodeBase {
  void addNode(ProgressNode node);
  void removeNode(ProgressNode node);
  Future<T> wrap<T>(
    Future<T> Function(ProgressNode layer) fn, {
    bool removeWhenComplete = true,
  }) async {
    final node = ProgressNode();
    addNode(node);
    try {
      return await fn(node);
    } finally {
      node.complete = true;
      if (removeWhenComplete) removeNode(node);
    }
  }
}

class ProgressNode extends ProgressNodeBase {
  void Function()? _onChanged;

  final children = <ProgressNode>[];

  @override
  void addNode(ProgressNode node) {
    assert(!children.contains(node));
    assert(node._onChanged == null);
    node._onChanged = () {
      if (_onChanged != null) _onChanged!();
    };
    children.add(node);
  }

  @override
  void removeNode(ProgressNode node) {
    assert(children.contains(node));
    node._onChanged = null;
    children.remove(node);
  }

  String? _description;
  String? get description => _description;
  set description(String? description) {
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
}

class ProgressController extends ProgressNodeBase {
  ProgressController({
    required this.onChanged,
  });

  final void Function() onChanged;

  ProgressNode? root;

  @override
  void addNode(ProgressNode node) {
    assert(root == null);
    assert(node._onChanged == null);
    node._onChanged = onChanged;
  }

  @override
  void removeNode(ProgressNode node) {
    assert(root == node);
    root!._onChanged = null;
    root = null;
  }
}
