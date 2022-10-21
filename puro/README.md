# Puro

## About

Puro is an advanced tool for installing and managing flutter versions.

Unlike the current approaches, puro uses a global cache of git objects and engine artifacts, allowing you to get a
working fork of Flutter in as little as **3 seconds**.

## Quick start

To install puro, run:

```
dart pub global activate puro
```

Once installed you can create and use an environment:

```
puro create my_env stable
puro use my_env
```

And that's it! Your IDE will be automatically configured to use the new environment.

## Usage

```
An experimental tool for managing flutter versions.

Usage: puro <command> [arguments]

Global options:
-h, --help                              Print this usage information.
    --git=<exe>                         Overrides the path to the git executable.
    --root=<dir>                        Overrides the global puro root directory. (defaults to `~/.puro`)
    --dir=<dir>                         Overrides the current working directory.
-p, --project=<dir>                     Overrides the selected flutter project.
-e, --env=<name>                        Overrides the selected environment.
    --flutter-git-url=<url>             Overrides the Flutter SDK git url.
    --engine-git-url=<url>              Overrides the Flutter Engine git url.
    --releases-json-url=<url>           Overrides the Flutter releases json url.
    --flutter-storage-base-url=<url>    Overrides the Flutter storage base url.
    --log-level=<0-4>                   Changes how much information is logged to the console, 0 being no logging at all, and 4 being extremely verbose.
-v, --[no-]verbose                      Verbose logging, alias for --log-level=3.
    --[no-]color                        Enable or disable ANSI colors.
    --json                              Output in JSON where possible.

Available commands:
  create    Sets up a new Flutter environment.
  dart      Forwards arguments to dart in the current environment.
  flutter   Forwards arguments to flutter in the current environment.
  ls        List available environments.
  rm        Delete an environment.
  use       Select an environment to use in the current project.

Run "puro help <command>" for more information about a command.
```