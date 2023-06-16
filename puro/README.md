# About

Puro is a powerful tool for installing and upgrading [Flutter](https://flutter.dev/) versions, it is essential for any
developers that work on multiple projects or have slower internet.

With Puro you can:

* Use different versions of Flutter at the same time
* Download new versions twice as fast with significantly less disk space and internet bandwidth
* Use versions globally or per-project
* Automatically configure IDE settings with a single command

## Installation

Puro is distributed as a precompiled executable (you do not need Dart installed), see the quick installation
instructions at https://puro.dev/

## Quick start

Once puro is installed, set up a new environment with the [create](https://puro.dev/reference/commands/#create) command:

```sh
# Create a new environment from branch
puro create my_env stable

# Or from a version
puro create my_env 3.3.6

# Or from a commit
puro create my_env d9111f6

# Or from a fork
puro create my_env --fork git@github.com:pingbird/flutter.git
```

Inside a Flutter project, run the [use](https://puro.dev/reference/commands/#use) command to switch to the environment you created:

```sh
puro use my_env
```

Puro will automatically detect if you are using VSCode or Android Studio (IntelliJ) and generate the necessary configs.
If this is a new project without a workspace, add `--vscode` or `--intellij` to generate them regardless.

You can also configure the global default with `--global` or `-g`:

```sh
puro use -g my_env
```

See the [Manual](https://puro.dev/reference/manual/) for more information.

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

With other approaches, each Flutter repository is in its own folder, requiring you to download and store the git history, engine, and framework of each version:

![](https://puro.dev/assets/storage_without_puro.png)

Puro implements a technology similar to GitLab's [object deduplication](https://docs.gitlab.com/ee/development/git_object_deduplication.html) to avoid downloading the same git objects over and over again. It also uses symlinks to share the same engine version between multiple installations:

![](https://puro.dev/assets/storage_with_puro.png)
