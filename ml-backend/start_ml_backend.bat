@echo off
REM start_ml_backend.bat
REM Startup script for Patra ML Backend API Server (Windows)

echo 🤖 Starting Patra ML Backend API Server...

REM Check if virtual environment exists
if not exist "ml_env" (
    echo ❌ Virtual environment not found. Please run setup first:
    echo    python -m venv ml_env
    echo    ml_env\Scripts\activate
    echo    pip install -r requirements.txt
    exit /b 1
)

REM Activate virtual environment
echo 🔄 Activating virtual environment...
call ml_env\Scripts\activate.bat

REM Check if required packages are installed
echo 🔄 Checking dependencies...
python -c "import flask, pandas, numpy, sklearn" >nul 2>&1
if %errorlevel% neq 0 (
    echo ❌ Required packages not installed. Installing from requirements.txt...
    pip install -r requirements.txt
)

REM Set environment variables
set FLASK_ENV=development
set FLASK_APP=api_server.py
set PORT=5000

REM Start the server
echo 🚀 Starting ML API server on port %PORT%...
echo 📊 Server will be available at: http://localhost:%PORT%
echo 🔗 Health check endpoint: http://localhost:%PORT%/api/health
echo 💡 Press Ctrl+C to stop the server
echo.

python api_server.py