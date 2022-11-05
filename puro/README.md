# About

Puro is an experimental tool for installing and managing Flutter versions.

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

Puro implements a few optimizations that make installing Flutter as fast as possible.
First-time installations are 20% faster while improving subsequent installations by a whopping 50-95%:

![](https://puro.dev/assets/install_time_comparison.svg)

This also translates into much lower network usage:

![](https://puro.dev/assets/network_usage_comparison.svg)

## How it works

Puro achieves these performance gains with a few smart optimizations:

* Parallel git clone and engine download
* Global cache for git history
* Global cache for engine versions

With other approaches, each flutter repository is in its own folder, requiring you to download and store the git history, engine, and framework of each version:

![](https://puro.dev/assets/storage_without_puro.png)

Puro implements a technology similar to GitLab's [object deduplication](https://docs.gitlab.com/ee/development/git_object_deduplication.html) to avoid downloading the same git objects over and over again. It also uses symlinks to share the same engine version between multiple installs:

![](https://puro.dev/assets/storage_with_puro.png)