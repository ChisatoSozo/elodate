find lib/api/pkg -type f -name "*.dart" -exec sed -i '' 's/const contentTypes = <String>\[\];/const contentTypes = <String>\["application\/json"\];/g' {} +

