puro_version="$(dart bin/puro.dart version --no-update-check --plain "$@")"
echo "version: $puro_version"
dart compile exe bin/puro.dart -o bin/puro "--define=puro_version=$puro_version"
