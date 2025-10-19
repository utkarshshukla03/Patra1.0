#!/bin/bash
# Setup script for Patra ML Backend

echo "🚀 Setting up Patra ML Backend..."

# Create virtual environment
echo "📦 Creating virtual environment..."
python -m venv ml_env

# Activate virtual environment
echo "🔧 Activating virtual environment..."
source ml_env/bin/activate  # For Linux/Mac
# For Windows: ml_env\Scripts\activate

# Install requirements
echo "📚 Installing Python packages..."
pip install -r requirements.txt

# Create necessary directories
echo "📁 Creating data directories..."
mkdir -p data/images/assigned
mkdir -p logs

# Download pre-trained sentence transformer model
echo "🧠 Downloading ML models..."
python -c "
from sentence_transformers import SentenceTransformer
model = SentenceTransformer('all-MiniLM-L6-v2')
print('✅ Sentence transformer model downloaded')
"

echo "✅ Setup completed!"
echo ""
echo "🔥 Next steps:"
echo "1. Add your Firebase service account key as 'firebase-adminsdk.json'"
echo "2. Run: python api_server.py"
echo "3. Test API at: http://localhost:5000/health"