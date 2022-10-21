# Commands

---

```sh
puro create <name> [version]
```

Sets up a new Flutter environment.


#### Options

#### `--channel=<name>`

The Flutter channel, in case multiple channels have builds with the same version number.

---

```sh
puro ls
```

List available environments.

---

```sh
puro use <name>
```

Select an environment to use in the current project.

---

```sh
puro clean
```

Deletes puro configuration files from the current project and restores IDE settings.

---

```sh
puro rm <name>
```

Delete an environment.

---

```sh
puro flutter [...args]
```

Forwards arguments to flutter in the current environment.

---

```sh
puro dart [...args]
```

Forwards arguments to dart in the current environment.

---

