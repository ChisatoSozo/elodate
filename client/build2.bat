@echo off
powershell -Command "Get-ChildItem -Recurse -Path 'lib/api/pkg' -Filter '*.dart' | ForEach-Object { (Get-Content -Raw $_.FullName) -replace 'const contentTypes = <String>\[\];', 'const contentTypes = <String>[\"application/json\"];' | Set-Content $_.FullName }"
