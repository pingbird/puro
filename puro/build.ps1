$puro_version = dart bin/puro.dart version --plain @args
Write-Output "Version: $puro_version"
dart compile exe bin/puro.dart -o bin/puro.exe --define=puro_version=$puro_version