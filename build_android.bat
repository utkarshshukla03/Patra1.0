@echo off
cd /d "d:\app\Patra1.0\patra_initial"
flutter clean
flutter pub get
flutter build apk --debug
pause
