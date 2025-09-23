@echo off
echo 🚀 Starting Patra ML Matching Service...
echo.

cd /d "d:\app\Patra1.0\patra_initial\ml_backend\scripts"

echo 📦 Checking Python dependencies...
pip install -r requirements.txt

echo.
echo 🔥 Starting ML API Server...
echo 📍 API will be available at: http://localhost:5000
echo.
echo 🔧 Available endpoints:
echo    GET  /health - Health check
echo    GET  /recommendations/^<user_uid^>?count=10 - Get ML recommendations  
echo    POST /refresh-data - Refresh data from Firebase
echo.
echo ⚠️  Keep this window open while using the app
echo 🛑 Press Ctrl+C to stop the ML service
echo.

python reject_superlike_like.py server

pause