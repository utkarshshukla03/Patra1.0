@echo off
cd /d "d:\app\Patra1.0\patra_initial\ml-backend"
call ml_env\Scripts\activate
echo 🚀 Starting Patra ML Backend Server...
echo 📊 Features: Firebase Direct, ML Recommendations, Elo System
echo 🔥 No more CSV files - everything runs directly from Firebase!
echo.
python api_server_firebase.py
pause