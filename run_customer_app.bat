@echo off
echo ========================================
echo  MbareToYou Customer App Launcher
echo ========================================
echo.

cd apps\customer_app

echo Step 1: Getting dependencies...
call flutter pub get

echo.
echo Step 2: Checking for connected devices...
call flutter devices

echo.
echo Step 3: Running the app...
echo Press Ctrl+C to stop the app
echo.

call flutter run

pause
