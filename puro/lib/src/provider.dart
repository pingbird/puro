abstract class Provider<T> {
  factory Provider(T Function(Scope scope) create) = LazyProvider;

  factory Provider.late() {
    return Provider((scope) => throw AssertionError('Provider not in scope'));
  }

  ProviderNode<T> createNode(Scope scope);
}

abstract class Scope {
  void add<T>(Provider<T> provider, T value);
  void replace<T>(Provider<T> provider, T value);
  T read<T>(Provider<T> provider);
}

abstract class ProxyScope implements Scope {
  Scope get parent;

  @override
  void add<V>(Provider<V> provider, V value) => parent.add(provider, value);

  @override
  void replace<V>(Provider<V> provider, V value) =>
      parent.replace(provider, value);

  @override
  V read<V>(Provider<V> provider) => parent.read(provider);
}

abstract class ProviderNode<T> extends ProxyScope {
  ProviderNode(this.parent);

  @override
  final Scope parent;

  T get value;
  Provider<T> get provider;

  void dispose() {}
}

class LazyProvider<T> implements Provider<T> {
  LazyProvider(this.create);

  final T Function(Scope scope) create;

  @override
  ProviderNode<T> createNode(Scope scope) {
    return LazyProviderNode<T>(scope, this);
  }
}

class LazyProviderNode<T> extends ProviderNode<T> {
  LazyProviderNode(super.parent, this.provider);

  @override
  final LazyProvider<T> provider;

  @override
  late final value = provider.create(this);
}

class RootScope extends Scope {
  final nodes = <Provider<Object?>, ProviderNode<Object?>>{};
  final overrides = <Provider<Object?>, Object?>{};

  @override
  void add<T>(Provider<T> provider, T value) {
    overrides[provider] = value;
  }

  @override
  void replace<T>(Provider<T> provider, T value) {
    assert(overrides.containsKey(provider) || nodes.containsKey(provider));
    overrides[provider] = value;
    final node = nodes[provider];
    if (node != null) {
      node.dispose();
      nodes.remove(provider);
    }
  }

  @override
  T read<T>(Provider<T> provider) {
    if (overrides.containsKey(provider)) {
      return overrides[provider] as T;
    }
    final node = nodes[provider] ??= provider.createNode(this);
    return node.value as T;
  }
}

class OverrideScope extends Scope {
  OverrideScope({required this.parent});

  final Scope parent;

  final overrides = <Provider<Object?>, Object?>{};

  @override
  void add<T>(Provider<T> provider, T value) {
    overrides[provider] = value;
  }

  @override
  void replace<T>(Provider<T> provider, T value) {
    if (overrides.containsKey(provider)) {
      overrides[provider] = value;
      return;
    }
    parent.replace(provider, value);
  }

  @override
  T read<T>(Provider<T> provider) {
    if (overrides.containsKey(provider)) {
      return overrides[provider] as T;
    }
    return parent.read<T>(provider);
  }
}
