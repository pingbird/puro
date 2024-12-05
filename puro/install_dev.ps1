# Builds and installs puro from source, for development purposes.

& "$PSScriptRoot/build.ps1"
bin/puro.exe install-puro --log-level=4 --promote
