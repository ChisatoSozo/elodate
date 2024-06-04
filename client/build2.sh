#!/bin/bash

if [[ "$OSTYPE" == "darwin"* ]]; then
  # macOS
  find lib/api/pkg -type f -name "*.dart" -exec sed -i '' 's/const contentTypes = <String>\[\];/const contentTypes = <String>\["application\/json"\];/g' {} +
else
  # Linux
  find lib/api/pkg -type f -name "*.dart" -exec sed -i 's/const contentTypes = <String>\[\];/const contentTypes = <String>\["application\/json"\];/g' {} +
fi
