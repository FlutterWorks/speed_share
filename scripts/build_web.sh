rm -rf assets/web.zip
flutter build web --web-renderer html
cp -f ./scripts/index.html ./build/web/