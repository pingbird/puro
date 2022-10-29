$puro_version = dart bin/puro.dart version --plain @args
dart compile exe bin/puro.dart --define=puro_version=$puro_version