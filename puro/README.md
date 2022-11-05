# About

Puro is an experimental tool for installing and managing Flutter versions.

With Puro you can:

* Use multiple versions of Flutter at the same time
* Download new versions twice as fast
* Configure globally or per-project
* Switch with a single command, no more manually editing IDE settings!

## Installation

Puro is distributed as a precompiled executable, see the quick installation instructions at https://puro.dev/

## Quick start

Once puro is installed, set up a new environment with the [create](https://puro.dev/reference/commands/#create) command:

```sh
puro create my_env stable
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

See the [Command Reference](https://puro.dev/reference/commands/) for more information.

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