#!/bin/bash
# start_ml_backend.sh
# Startup script for Patra ML backend API server

echo "🤖 Starting Patra ML Backend API Server..."

# Check if virtual environment exists
if [ ! -d "ml_env" ]; then
    echo "❌ Virtual environment not found. Please run setup first:"
    echo "   python -m venv ml_env"
    echo "   source ml_env/bin/activate  # On Windows: ml_env\\Scripts\\activate"
    echo "   pip install -r requirements.txt"
    exit 1
fi

# Activate virtual environment
echo "🔄 Activating virtual environment..."
source ml_env/bin/activate

# Check if required packages are installed
echo "🔄 Checking dependencies..."
python -c "import flask, pandas, numpy, sklearn" 2>/dev/null
if [ $? -ne 0 ]; then
    echo "❌ Required packages not installed. Installing from requirements.txt..."
    pip install -r requirements.txt
fi

# Set environment variables
export FLASK_ENV=development
export FLASK_APP=api_server.py
export PORT=5000

# Start the server
echo "🚀 Starting ML API server on port $PORT..."
echo "📊 Server will be available at: http://localhost:$PORT"
echo "🔗 Health check endpoint: http://localhost:$PORT/api/health"
echo "💡 Press Ctrl+C to stop the server"
echo ""

python api_server.py