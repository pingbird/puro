---
comments: true
---

# About

Puro is an advanced tool for installing and managing flutter versions.

Unlike the current approaches, puro uses a global cache of git objects and engine artifacts, allowing you to get a working fork of Flutter in as little as **3 seconds**. 

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