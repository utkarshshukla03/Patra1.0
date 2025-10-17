# Patra ML Recommendation System
*AI-Powered Dating App Matching*

## 🎯 Overview

The Patra ML Recommendation System provides intelligent user matching using machine learning algorithms that combine multiple signals:

- **Structured Features**: Age, location, interests compatibility
- **Bio Similarity**: Natural language processing of user bios
- **Interaction History**: Learning from user swipe patterns  
- **Elo Ratings**: Popularity-based scoring system

## 🚀 Quick Start

### 1. Setup ML Backend

```bash
# Navigate to ML backend
cd ml-backend

# Create virtual environment (first time only)
python -m venv ml_env

# Activate environment
# Windows:
ml_env\Scripts\activate
# Linux/Mac:
source ml_env/bin/activate

# Install dependencies
pip install -r requirements.txt
```

### 2. Start ML API Server

```bash
# Windows:
start_ml_backend.bat

# Linux/Mac:
chmod +x start_ml_backend.sh
./start_ml_backend.sh
```

The ML API will be available at `http://localhost:5000`

### 3. Enable ML in Flutter App

The Flutter app automatically detects when the ML service is available and uses it for recommendations.

**Key Features:**
- ✅ Automatic fallback to regular matching if ML service is unavailable
- ✅ Real-time interaction recording for continuous learning
- ✅ Visual "AI Pick" badges on ML-recommended profiles
- ✅ Async interaction logging (doesn't block UI)

## 📡 API Endpoints

### Health Check
```http
GET /api/health
```

### Get Recommendations  
```http
GET /api/recommendations/{user_id}?count=10
```

### Record Interaction
```http
POST /api/interaction
Content-Type: application/json

{
  "user_id": "user123",
  "target_id": "user456", 
  "action": "like|dislike|superlike"
}
```

## 🎛️ Configuration

Edit `ml-backend/production/settings.yaml` to customize:

- **Recommendation weights** (base features vs bio vs interactions vs elo)
- **Elo rating parameters**
- **Bio similarity model settings**
- **API server configuration**

## 🔍 How It Works

### 1. Data Flow
```
User opens app → Flutter requests ML recommendations → 
ML backend combines multiple signals → Returns ranked user list →
Flutter displays with "AI Pick" badges
```

### 2. Learning Loop
```
User swipes → Flutter records interaction → ML updates weights →
Better recommendations next time
```

### 3. Recommendation Pipeline
1. **Base Matching**: Compare structured features (age, location, interests)
2. **Bio Analysis**: Semantic similarity of user bios using sentence transformers
3. **Interaction Weighting**: Adjust scores based on historical swipe patterns
4. **Elo Integration**: Factor in user popularity/attractiveness ratings
5. **Final Ranking**: Weighted combination of all signals

## 🛠️ Development

### Adding New Features

1. **New ML Signals**: Add to `production/recommender.py`
2. **API Endpoints**: Extend `api_server.py`
3. **Flutter Integration**: Update `lib/services/ml_service.dart`

### Data Files

- `data/users.csv` - User profiles for ML training
- `data/swipe_logs.csv` - Historical interaction data
- `data/elo_scores.csv` - User rating data

### Troubleshooting

**ML service not working?**
1. Check if Python virtual environment is activated
2. Verify all packages installed: `pip install -r requirements.txt`
3. Check server logs for errors
4. Test health endpoint: `curl http://localhost:5000/api/health`

**No ML recommendations?**
1. Ensure user data exists in `data/users.csv`
2. Check if user_id matches between Flutter and ML backend
3. Verify network connectivity between Flutter and ML service

## 🔮 Future Enhancements

- [ ] Real-time model retraining
- [ ] A/B testing for recommendation algorithms
- [ ] Deep learning models for image similarity
- [ ] Geographic clustering improvements
- [ ] Conversation success prediction

## 📊 Monitoring

The system logs all activities with emoji prefixes:
- 🤖 ML Service operations
- 📊 Data processing
- 🔄 Background tasks
- ⚠️ Warnings and errors

Monitor logs to ensure the system is working correctly and to identify optimization opportunities.