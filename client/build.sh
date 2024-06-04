rm -f .dart_tool/openapi-generator-cache.json
rm -rf lib/api/pkg/*
touch lib/api/pkg/.keep
dart run build_runner build --delete-conflicting-outputs