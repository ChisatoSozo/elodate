# remove all files in server/public except .gitkeep
find server/public/ -mindepth 1 -maxdepth 1 -not -name '.gitkeep' -exec rm -rf {} \;
cp -r client/build/web/* server/public/
cp -r client/assets server/public/

cd server
cargo build --release

cp target/release/server ../build
cp -r public ../build
cp -r server/res ../build