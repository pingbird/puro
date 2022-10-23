# Commands

## Create

```sh
puro create <name> [version]
```

Sets up a new Flutter environment.


#### Options

#### `--channel=<name>`

The Flutter channel, in case multiple channels have builds with the same version number.

---

## Ls

```sh
puro ls
```

List available environments.

---

## Use

```sh
puro use <name>
```

Select an environment to use in the current project.

---

## Clean

```sh
puro clean
```

Deletes puro configuration files from the current project and restores IDE settings.

---

## Rm

```sh
puro rm <name>
```

Delete an environment.

---

## Flutter

```sh
puro flutter [...args]
```

Forwards arguments to flutter in the current environment.

---

## Dart

```sh
puro dart [...args]
```

Forwards arguments to dart in the current environment.

---

# Global Options

#### `-h`, `--help`

Print this usage information.

#### `--git=<exe>`

Overrides the path to the git executable.

#### `--root=<dir>`

Overrides the global puro root directory. (defaults to `~/.puro`)

#### `--dir=<dir>`

Overrides the current working directory.

#### `-p`, `--project=<dir>`

Overrides the selected flutter project.

#### `-e`, `--env=<name>`

Overrides the selected environment.

#### `--flutter-git-url=<url>`

Overrides the Flutter SDK git url.

#### `--engine-git-url=<url>`

Overrides the Flutter Engine git url.

#### `--releases-json-url=<url>`

Overrides the Flutter releases json url.

#### `--flutter-storage-base-url=<url>`

Overrides the Flutter storage base url.

#### `--log-level=<0-4>`

Changes how much information is logged to the console, 0 being no logging at all, and 4 being extremely verbose.

#### `-v`, `--[no-]verbose`

Verbose logging, alias for --log-level=3.

#### `--[no-]color`

Enable or disable ANSI colors.

#### `--[no-]progress`

Enable progress bars.

#### `--json`

Output in JSON where possible.

