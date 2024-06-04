del /f .dart_tool\openapi-generator-cache.json
rmdir /s /q lib\api\pkg
mkdir lib\api\pkg
type nul > lib\api\pkg\.keep
dart run build_runner build --delete-conflicting-outputs
