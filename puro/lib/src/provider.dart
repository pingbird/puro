abstract class Provider<T> {
  factory Provider(T Function(Scope scope) create) = LazyProvider;

  factory Provider.late() {
    return Provider(
      (scope) => throw AssertionError('Provider not in scope'),
    );
  }

  ProviderNode<T> createNode(Scope scope);
}

abstract class Scope {
  void add<T>(Provider<T> provider, T value);
  T read<T>(Provider<T> provider);
}

abstract class ProviderNode<T> implements Scope {
  ProviderNode(this.parent);

  final Scope parent;
  T get value;
  Provider<T> get provider;

  void dispose() {}

  @override
  void add<V>(Provider<V> provider, V value) => parent.add(provider, value);

  @override
  V read<V>(Provider<V> provider) => parent.read(provider);
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
  final nodes = <Provider, ProviderNode>{};
  final overrides = <Provider, Object?>{};

  @override
  void add<T>(Provider<T> provider, T value) {
    overrides[provider] = value;
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
