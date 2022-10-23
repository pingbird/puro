---
comments: true
---

# About

Puro is an experimental tool for installing and managing flutter versions.

## Quick start

To install puro, run:

```sh
dart pub global activate puro
```

Once installed you can create and use an environment:

```sh
puro create my_env stable
puro use my_env
```

And that's it! Your IDE will be automatically configured to use the new environment.

## Performance

Puro implements a few optimizations that make installing Flutter as fast as possible, including:

* Parallel framework / engine downloading
* Global repository with shared git objects, a technology similar to GitLab's [object deduplication](https://docs.gitlab.com/ee/development/git_object_deduplication.html)
* Symlinking flutter's engine cache to a shared folder depending on its commit hash

These optimizations make first-time installs 20% faster while improving subsequent installations by a whopping 50-95%:

![](https://puro.dev/assets/install_time_comparison.svg)

This also translates into much lower network and disk usage:

![](https://puro.dev/assets/network_usage_comparison.svg)