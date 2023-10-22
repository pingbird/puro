$puro_version = dart bin/puro.dart version --no-update-check --plain @args
Write-Output "Version: $puro_version"
dart compile exe bin/puro.dart -o bin/puro.exe --define=puro_version=$puro_version
