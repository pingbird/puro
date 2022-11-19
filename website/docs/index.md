---
comments: true
hide:
- navigation
---

# About

Puro is an experimental tool for installing and managing [Flutter](https://flutter.dev/) versions.

With Puro you can:

* Use multiple versions of Flutter at the same time
{ ^ .star-list }
* Download new versions twice as fast
* Configure globally or per-project
* Switch with a single command, no more manually editing IDE settings!

## Installation

=== "Windows"

    Puro has a graphical installer for Windows:

    [:material-monitor-arrow-down-variant: Desktop Installer](https://puro.dev/builds/master/windows-x64/puro_installer.exe){ .md-button .md-button--primary }

    It can also be installed from powershell:

    ```ps1
    Invoke-WebRequest -Uri "https://puro.dev/builds/master/windows-x64/puro.exe" -OutFile "$env:temp\puro.exe"; Start-Process "$env:temp\puro.exe" install-puro --promote
    ```

    Or as a standalone executable:

    [:material-console: Standalone](https://puro.dev/builds/master/windows-x64/puro.exe){ .md-button }

    ---
        
    note: Flutter requires [git](https://git-scm.com/) which can be installed at [https://git-scm.com/download/win](https://git-scm.com/download/win)

=== "Linux"

    Puro can be installed on Linux with the following command:

    ```sh
    curl -o- https://puro.dev/install.sh | PURO_VERSION="master" bash
    ```

    Or as a standalone executable:

    [:material-console: Standalone](https://puro.dev/builds/master/linux-x64/puro){ .md-button }

    ---

    note: Flutter requires [git](https://git-scm.com/) which can be installed with most package managers e.g. apt:

    ```sh
    sudo apt install git
    ```

=== "Mac"

    Puro can be installed on Mac with the following command:

    ```sh
    curl -o- https://puro.dev/install.sh | PURO_VERSION="master" bash
    ```

    Or as a standalone executable:

    [:material-console: Standalone](https://puro.dev/builds/master/darwin-x64/puro){ .md-button }

    ---

    note: Flutter requires [git](https://git-scm.com/) which can be installed with [Homebrew](https://brew.sh/) for macOS:

    ```sh
    brew install git
    ```

<script src="/javascript/os_detect.js"></script>

## Quick Start

Once puro is installed, set up a new environment with the [create](/reference/commands/#create) command:

```
# Create new environment from a release channel
puro create my_env stable

# Or from a version
puro create my_env 3.3.6

# Or from a commit
puro create my_env d9111f6

# Or from a fork
puro create my_env --fork git@github.com:PixelToast/flutter.git
```

Inside a Flutter project, run the [use](/reference/commands/#use) command to switch to the environment you created:

```
puro use my_env
```

Puro will automatically detect if you are using VSCode or Android Studio (IntelliJ) and generate the necessary configs.
If this is a new project without a workspace, add `--vscode` or `--intellij` to generate them regardless.

You can also configure the global default with `--global` or `-g`:

```sh
puro use -g my_env
```

See the [Command Reference](/reference/commands/) for more information.

## Performance

Puro implements a few optimizations that make installing Flutter as fast as possible.
First-time installations are 20% faster while improving subsequent installations by a whopping 50-95%:

![](assets/install_time_comparison.svg)

This also translates into much lower network usage:

![](assets/network_usage_comparison.svg)

## How it works

Puro achieves these performance gains with a few smart optimizations:

* Parallel git clone and engine download
* Global cache for git history
* Global cache for engine versions

With other approaches, each Flutter repository is in its own folder, requiring you to download and store the git history, engine, and framework of each version:

![](assets/storage_without_puro.png)

Puro implements a technology similar to GitLab's [object deduplication](https://docs.gitlab.com/ee/development/git_object_deduplication.html) to avoid downloading the same git objects over and over again. It also uses symlinks to share the same engine version between multiple installations:

![](assets/storage_with_puro.png)