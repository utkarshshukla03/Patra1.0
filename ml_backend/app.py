from scripts.reject_superlike_like import app

# This is a wrapper file that imports the Flask app from reject_superlike_like.py
# Render will use this file as the entry point

if __name__ == "__main__":
    import os
    port = int(os.environ.get('PORT', 5000))
    app.run(host='0.0.0.0', port=port)

# Global variables
db = None
users = pd.DataFrame()
swipe_logs = pd.DataFrame() 
bio_embeddings = None
vectorizer = None

# -------------------- FIREBASE CONFIG --------------------
def initialize_firebase():
    """Initialize Firebase Admin SDK"""
    try:
        # Try to get Firebase credentials from environment variable
        firebase_config = os.environ.get('FIREBASE_SERVICE_ACCOUNT')
        if firebase_config:
            # Parse JSON from environment variable
            cred_dict = json.loads(firebase_config)
            cred = credentials.Certificate(cred_dict)
            print("✅ Using Firebase credentials from environment")
        else:
            # Fallback to local file (for development)
            cred = credentials.Certificate("scripts/firebase-service-account.json")
            print("✅ Using local Firebase credentials file")
        
        firebase_admin.initialize_app(cred)
        print("✅ Firebase initialized successfully")
        return firestore.client()
    except Exception as e:
        print(f"❌ Firebase initialization failed: {e}")
        return None

# Initialize Firebase
db = initialize_firebase()

# -------------------- DATA LOADING --------------------
def fetch_users_from_firebase():
    """Fetch all users from Firebase Firestore"""
    if not db:
        return pd.DataFrame()
    
    try:
        users_ref = db.collection('users')
        docs = users_ref.stream()
        
        users_data = []
        for doc in docs:
            user_data = doc.to_dict()
            user_data['uid'] = doc.id  # Use document ID as uid
            users_data.append(user_data)
        
        df = pd.DataFrame(users_data)
        print(f"✅ Fetched {len(df)} users from Firebase")
        return df
    except Exception as e:
        print(f"❌ Error fetching users from Firebase: {e}")
        return pd.DataFrame()

def fetch_swipes_from_firebase():
    """Fetch all swipe actions from Firebase Firestore"""
    if not db:
        return pd.DataFrame()
    
    try:
        swipes_ref = db.collection('swipes')
        docs = swipes_ref.stream()
        
        swipes_data = []
        for doc in docs:
            swipe_data = doc.to_dict()
            swipe_data['swipe_id'] = doc.id
            swipes_data.append(swipe_data)
        
        df = pd.DataFrame(swipes_data)
        print(f"✅ Fetched {len(df)} swipes from Firebase")
        return df
    except Exception as e:
        print(f"❌ Error fetching swipes from Firebase: {e}")
        return pd.DataFrame()

def refresh_data():
    """Refresh all data from Firebase"""
    global users, swipe_logs, bio_embeddings, vectorizer
    
    print("🔄 Refreshing data from Firebase...")
    users = fetch_users_from_firebase()
    swipe_logs = fetch_swipes_from_firebase()
    
    if not users.empty:
        users.reset_index(inplace=True)
        users['bio'] = users['bio'].fillna('No bio available')
        
        try:
            vectorizer = TfidfVectorizer(stop_words="english", max_features=500)
            bio_embeddings = vectorizer.fit_transform(users["bio"])
            print("✅ Bio embeddings created successfully")
        except Exception as e:
            print(f"⚠️ Warning: Could not create bio embeddings: {e}")
            bio_embeddings = None
            vectorizer = None

# -------------------- MATCHING ALGORITHM --------------------
def calculate_compatibility_score(user1_data, user2_data):
    """Calculate compatibility score between two users"""
    try:
        score = 0.0
        
        # Age compatibility (within 5 years gets higher score)
        age1 = user1_data.get('age', 25)
        age2 = user2_data.get('age', 25)
        age_diff = abs(age1 - age2)
        if age_diff <= 2:
            score += 0.3
        elif age_diff <= 5:
            score += 0.2
        elif age_diff <= 10:
            score += 0.1
        
        # Location compatibility
        location1 = str(user1_data.get('location', '')).lower()
        location2 = str(user2_data.get('location', '')).lower()
        if location1 and location2 and location1 == location2:
            score += 0.2
        
        # Interests compatibility
        interests1 = user1_data.get('interests', [])
        interests2 = user2_data.get('interests', [])
        if isinstance(interests1, list) and isinstance(interests2, list) and interests1 and interests2:
            common_interests = len(set(interests1) & set(interests2))
            total_interests = len(set(interests1) | set(interests2))
            if total_interests > 0:
                score += 0.3 * (common_interests / total_interests)
        
        # Bio similarity
        bio1 = str(user1_data.get('bio', ''))
        bio2 = str(user2_data.get('bio', ''))
        if bio1 and bio2 and len(bio1) > 10 and len(bio2) > 10:
            try:
                temp_vectorizer = TfidfVectorizer(stop_words='english')
                tfidf_matrix = temp_vectorizer.fit_transform([bio1, bio2])
                similarity = cosine_similarity(tfidf_matrix[0:1], tfidf_matrix[1:2])[0][0]
                score += 0.2 * similarity
            except:
                pass
        
        return min(score, 1.0)  # Cap at 1.0
    except Exception as e:
        print(f"Error calculating compatibility: {e}")
        return 0.5  # Default score

def get_recommendations_for_user(user_uid, count=10):
    """Get recommendations for a specific user"""
    global users, swipe_logs
    
    try:
        # Find the target user
        target_user = users[users['uid'] == user_uid]
        if target_user.empty:
            return {
                'success': False,
                'error': 'User not found',
                'user_uid': user_uid,
                'recommendations': [],
                'count': 0
            }
        
        target_user_data = target_user.iloc[0].to_dict()
        
        # Get users this person has already swiped on
        swiped_user_ids = set()
        if not swipe_logs.empty and 'userId' in swipe_logs.columns:
            user_swipes = swipe_logs[swipe_logs['userId'] == user_uid]
            if not user_swipes.empty and 'targetUserId' in user_swipes.columns:
                swiped_user_ids = set(user_swipes['targetUserId'].tolist())
        
        # Get potential matches (exclude self and already swiped)
        potential_matches = users[
            (users['uid'] != user_uid) & 
            (~users['uid'].isin(swiped_user_ids))
        ]
        
        if potential_matches.empty:
            return {
                'success': True,
                'user_uid': user_uid,
                'recommendations': [],
                'count': 0,
                'message': 'No new users to recommend'
            }
        
        # Calculate compatibility scores
        recommendations = []
        for _, potential_match in potential_matches.iterrows():
            match_data = potential_match.to_dict()
            compatibility_score = calculate_compatibility_score(target_user_data, match_data)
            
            recommendation = {
                'uid': match_data['uid'],
                'username': match_data.get('username', 'Unknown'),
                'name': match_data.get('name', match_data.get('username', 'Unknown')),
                'age': int(match_data.get('age', 0)) if match_data.get('age') else 0,
                'location': match_data.get('location', ''),
                'bio': match_data.get('bio', ''),
                'interests': match_data.get('interests', []),
                'photos': match_data.get('photos', []),
                'compatibility_score': round(compatibility_score, 3),
                'distance': match_data.get('distance', 0)
            }
            recommendations.append(recommendation)
        
        # Sort by compatibility score (descending) and limit results
        recommendations = sorted(recommendations, key=lambda x: x['compatibility_score'], reverse=True)
        recommendations = recommendations[:count]
        
        return {
            'success': True,
            'user_uid': user_uid,
            'recommendations': recommendations,
            'count': len(recommendations),
            'timestamp': datetime.now().isoformat()
        }
        
    except Exception as e:
        print(f"Error getting recommendations: {e}")
        return {
            'success': False,
            'error': str(e),
            'user_uid': user_uid,
            'recommendations': [],
            'count': 0
        }

# -------------------- API ENDPOINTS --------------------

@app.route('/', methods=['GET'])
def home():
    """Home endpoint"""
    return jsonify({
        'message': 'Patra Dating App ML Service',
        'version': '1.0.0',
        'status': 'running',
        'firebase_connected': db is not None,
        'users_loaded': len(users),
        'swipes_loaded': len(swipe_logs),
        'endpoints': {
            'health': '/health',
            'recommendations': '/recommendations/<user_uid>',
            'refresh': '/refresh-data'
        }
    }), 200

@app.route('/health', methods=['GET'])
def health_check():
    """Health check endpoint"""
    status = {
        'status': 'healthy',
        'firebase_connected': db is not None,
        'users_count': len(users),
        'swipes_count': len(swipe_logs),
        'timestamp': datetime.now().isoformat()
    }
    return jsonify(status), 200

@app.route('/recommendations/<user_uid>', methods=['GET'])
def get_recommendations(user_uid):
    """Get recommendations for a specific user"""
    try:
        count = int(request.args.get('count', 10))
        count = min(max(count, 1), 50)  # Limit between 1 and 50
        
        result = get_recommendations_for_user(user_uid, count)
        return jsonify(result), 200 if result['success'] else 404
        
    except Exception as e:
        print(f"Error in recommendations endpoint: {e}")
        return jsonify({
            'success': False,
            'error': f'Server error: {str(e)}',
            'user_uid': user_uid,
            'recommendations': [],
            'count': 0
        }), 500

@app.route('/refresh-data', methods=['POST'])
def refresh_data_endpoint():
    """Refresh ML model data from Firebase"""
    try:
        refresh_data()
        
        return jsonify({
            'success': True,
            'users_count': len(users),
            'swipes_count': len(swipe_logs),
            'message': 'Data refreshed successfully',
            'timestamp': datetime.now().isoformat()
        }), 200
        
    except Exception as e:
        print(f"Error refreshing data: {e}")
        return jsonify({
            'success': False,
            'error': str(e)
        }), 500

# -------------------- STARTUP --------------------
if __name__ == '__main__':
    print("🚀 Patra Dating App ML Service Starting...")
    print("=" * 50)
    
    if db:
        print("✅ Firebase connected successfully")
        refresh_data()
        print(f"📊 Loaded {len(users)} users and {len(swipe_logs)} swipes")
    else:
        print("❌ Firebase connection failed - running in limited mode")
    
    # Get port from environment (for Render/Heroku) or default to 5000
    port = int(os.environ.get('PORT', 5000))
    
    print(f"🌐 Starting server on port {port}")
    print("📍 API Endpoints available:")
    print("   GET  / - Service info")
    print("   GET  /health - Health check")
    print("   GET  /recommendations/<user_uid>?count=10 - Get recommendations")
    print("   POST /refresh-data - Refresh data from Firebase")
    print("=" * 50)
    
    app.run(host='0.0.0.0', port=port, debug=False)