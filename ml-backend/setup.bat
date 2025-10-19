@echo off
REM Setup script for Patra ML Backend on Windows

echo 🚀 Setting up Patra ML Backend...

REM Create virtual environment
echo 📦 Creating virtual environment...
python -m venv ml_env

REM Activate virtual environment
echo 🔧 Activating virtual environment...
call ml_env\Scripts\activate

REM Install requirements
echo 📚 Installing Python packages...
pip install -r requirements.txt

REM Create necessary directories
echo 📁 Creating data directories...
if not exist "data\images\assigned" mkdir data\images\assigned
if not exist "logs" mkdir logs

REM Download pre-trained sentence transformer model
echo 🧠 Downloading ML models...
python -c "from sentence_transformers import SentenceTransformer; model = SentenceTransformer('all-MiniLM-L6-v2'); print('✅ Sentence transformer model downloaded')"

echo ✅ Setup completed!
echo.
echo 🔥 Next steps:
echo 1. Add your Firebase service account key as 'firebase-adminsdk.json'
echo 2. Run: python api_server.py
echo 3. Test API at: http://localhost:5000/health

pause