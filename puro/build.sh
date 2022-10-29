puro_version="$(dart bin/puro.dart version --plain "$@")"
dart compile exe bin/puro.dart -o bin/puro "--define=puro_version=$puro_version"