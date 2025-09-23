import pandas as pd
from sklearn.feature_extraction.text import TfidfVectorizer
from sklearn.metrics.pairwise import cosine_similarity
import firebase_admin
from firebase_admin import credentials, firestore
from datetime import datetime
import numpy as np
from flask import Flask, request, jsonify
from flask_cors import CORS
import os

# -------------------- FIREBASE CONFIG --------------------
# Initialize Firebase Admin SDK (you need to download service account key)
# Place your Firebase service account key JSON file in the same directory
try:
    cred = credentials.Certificate("firebase-service-account.json")  # You need to add this file
    firebase_admin.initialize_app(cred)
except Exception as e:
    print(f"Firebase initialization failed: {e}")
    print("Please ensure firebase-service-account.json is in the same directory")
    exit(1)

db = firestore.client()

# -------------------- LOAD DATA FROM FIREBASE --------------------
def fetch_users_from_firebase():
    """Fetch all users from Firebase Firestore"""
    try:
        users_ref = db.collection('users')
        docs = users_ref.stream()
        
        users_data = []
        for doc in docs:
            user_data = doc.to_dict()
            user_data['user_id'] = doc.id  # Use document ID as user_id
            users_data.append(user_data)
        
        print(f"✅ Fetched {len(users_data)} users from Firebase")
        return pd.DataFrame(users_data)
    except Exception as e:
        print(f"❌ Error fetching users from Firebase: {e}")
        return pd.DataFrame()

def fetch_swipes_from_firebase():
    """Fetch all swipe actions from Firebase Firestore"""
    try:
        swipes_ref = db.collection('swipes')
        docs = swipes_ref.stream()
        
        swipes_data = []
        for doc in docs:
            swipe_data = doc.to_dict()
            # Convert actionType to action for compatibility
            if 'actionType' in swipe_data:
                action_map = {'dislike': 'reject', 'like': 'like', 'superlike': 'superlike'}
                swipe_data['action'] = action_map.get(swipe_data['actionType'], 'like')
            elif 'isLike' in swipe_data:
                swipe_data['action'] = 'like' if swipe_data['isLike'] else 'reject'
            else:
                swipe_data['action'] = 'like'  # default
                
            swipes_data.append({
                'user_id': swipe_data.get('userId'),
                'target_user_id': swipe_data.get('targetUserId'),
                'action': swipe_data['action']
            })
        
        print(f"✅ Fetched {len(swipes_data)} swipe actions from Firebase")
        return pd.DataFrame(swipes_data)
    except Exception as e:
        print(f"❌ Error fetching swipes from Firebase: {e}")
        return pd.DataFrame(columns=["user_id", "target_user_id", "action"])

# Load data from Firebase
print("🔄 Loading data from Firebase...")
users = fetch_users_from_firebase()
swipe_logs = fetch_swipes_from_firebase()

if users.empty:
    print("❌ No users found in Firebase. Exiting.")
    exit(1)

# Prepare data for ML processing
users.reset_index(inplace=True)  # for bio mapping

# Handle missing bio data
users['bio'] = users['bio'].fillna('No bio available')

# Create TF-IDF vectorizer for bio embeddings
vectorizer = TfidfVectorizer(stop_words="english", max_features=500)
bio_embeddings = vectorizer.fit_transform(users["bio"])

# -------------------- HELPER FUNCTIONS --------------------
def jaccard_score(list1, list2):
    """Calculate Jaccard similarity between two lists"""
    if not list1 or not list2:
        return 0
    s1, s2 = set(list1), set(list2)
    return len(s1 & s2) / len(s1 | s2) if s1 | s2 else 0

def calculate_age(date_of_birth):
    """Calculate age from date of birth"""
    if pd.isna(date_of_birth) or date_of_birth is None:
        return 25  # Default age
    
    if isinstance(date_of_birth, str):
        try:
            dob = datetime.strptime(date_of_birth, '%Y-%m-%d')
        except:
            return 25
    else:
        dob = date_of_birth
    
    today = datetime.now()
    age = today.year - dob.year - ((today.month, today.day) < (dob.month, dob.day))
    return max(18, min(80, age))  # Ensure age is between 18-80

def parse_location(location_str):
    """Parse location string to extract city and state"""
    if pd.isna(location_str) or not location_str:
        return "Unknown", "Unknown"
    
    parts = str(location_str).split(',')
    if len(parts) >= 2:
        return parts[0].strip(), parts[1].strip()
    else:
        return parts[0].strip(), "Unknown"

def match_score(u1, u2):
    """Calculate match score between two users"""
    # Age compatibility (within 10 years)
    age1 = u1.get('age', calculate_age(u1.get('dateOfBirth')))
    age2 = u2.get('age', calculate_age(u2.get('dateOfBirth')))
    age_score = max(0, 1 - abs(age1 - age2) / 10)
    
    # Location compatibility
    loc1_city, loc1_state = parse_location(u1.get('location'))
    loc2_city, loc2_state = parse_location(u2.get('location'))
    
    loc_score = 0
    if loc1_city == loc2_city:
        loc_score = 1
    elif loc1_state == loc2_state:
        loc_score = 0.5

    # Interests compatibility
    interests1 = u1.get('interests', [])
    # Safe null checking for interests1
    if interests1 is None:
        interests1 = []
    elif isinstance(interests1, (np.ndarray, pd.Series)):
        # Check if it's a pandas null array
        if len(interests1) == 0 or (len(interests1) == 1 and pd.isna(interests1[0])):
            interests1 = []
        else:
            interests1 = interests1.tolist()
    elif not isinstance(interests1, list):
        # Handle scalar values or other types
        try:
            if pd.isna(interests1):
                interests1 = []
            else:
                interests1 = [interests1] if interests1 else []
        except (TypeError, ValueError):
            interests1 = []
    
    interests2 = u2.get('interests', [])
    # Safe null checking for interests2
    if interests2 is None:
        interests2 = []
    elif isinstance(interests2, (np.ndarray, pd.Series)):
        # Check if it's a pandas null array
        if len(interests2) == 0 or (len(interests2) == 1 and pd.isna(interests2[0])):
            interests2 = []
        else:
            interests2 = interests2.tolist()
    elif not isinstance(interests2, list):
        # Handle scalar values or other types
        try:
            if pd.isna(interests2):
                interests2 = []
            else:
                interests2 = [interests2] if interests2 else []
        except (TypeError, ValueError):
            interests2 = []
    
    hobby_score = jaccard_score(interests1, interests2)
    
    # Orientation compatibility
    orientation1 = u1.get('orientation', [])
    # Safe null checking for orientation1
    if orientation1 is None:
        orientation1 = []
    elif isinstance(orientation1, (np.ndarray, pd.Series)):
        # Check if it's a pandas null array
        if len(orientation1) == 0 or (len(orientation1) == 1 and pd.isna(orientation1[0])):
            orientation1 = []
        else:
            orientation1 = orientation1.tolist()
    elif not isinstance(orientation1, list):
        # Handle scalar values or other types
        try:
            if pd.isna(orientation1):
                orientation1 = []
            else:
                orientation1 = [orientation1] if orientation1 else []
        except (TypeError, ValueError):
            orientation1 = []
    
    orientation2 = u2.get('orientation', [])
    # Safe null checking for orientation2
    if orientation2 is None:
        orientation2 = []
    elif isinstance(orientation2, (np.ndarray, pd.Series)):
        # Check if it's a pandas null array
        if len(orientation2) == 0 or (len(orientation2) == 1 and pd.isna(orientation2[0])):
            orientation2 = []
        else:
            orientation2 = orientation2.tolist()
    elif not isinstance(orientation2, list):
        # Handle scalar values or other types
        try:
            if pd.isna(orientation2):
                orientation2 = []
            else:
                orientation2 = [orientation2] if orientation2 else []
        except (TypeError, ValueError):
            orientation2 = []
    
    lf_score = jaccard_score(orientation1, orientation2)
    
    # Bio similarity using TF-IDF
    u1_index = u1.get('index', 0)
    u2_index = u2.get('index', 0)
    
    if u1_index < len(bio_embeddings.toarray()) and u2_index < len(bio_embeddings.toarray()):
        bio_score = cosine_similarity(bio_embeddings[u1_index:u1_index+1], 
                                     bio_embeddings[u2_index:u2_index+1])[0][0]
    else:
        bio_score = 0
    
    # Gender preference (simplified)
    gender1 = u1.get('gender', '').lower()
    gender2 = u2.get('gender', '').lower()
    gender_score = 0.5  # Neutral score
    
    # Calculate weighted final score
    final_score = (0.25*age_score + 0.15*loc_score + 0.25*hobby_score + 
                  0.10*lf_score + 0.15*bio_score + 0.10*gender_score)
    
    return final_score

# -------------------- SWIPE LOG --------------------
def load_swipe_logs():
    """Return the global swipe logs DataFrame"""
    return swipe_logs

def action_weight(action):
    """Get weight for different swipe actions"""
    return {"superlike": 3, "like": 2, "reject": 0}.get(action, 1)

# -------------------- GET TOP MATCHES --------------------
def get_top_matches(user_uid, top_n=10, use_swipe_logs=True):
    """Get top matches for a user by UID"""
    try:
        print(f"🔍 Finding user with UID: {user_uid}")
        # Find user by UID
        user_row = users[users['uid'] == user_uid]
        if user_row.empty:
            print(f"❌ User with UID {user_uid} not found")
            return []
        
        # Convert pandas Series to dict to avoid ambiguous truth value errors
        u1 = user_row.iloc[0].to_dict()
        print(f"✅ Found user: {u1.get('username', 'Unknown')}")
        current_swipe_logs = load_swipe_logs()

        candidates = []
        print(f"🔄 Processing {len(users)} users for matching...")
        for i, u2_series in users.iterrows():
            if u2_series['uid'] == user_uid:  # Skip self
                continue
            
            # Convert u2 Series to dict as well
            u2 = u2_series.to_dict()
            
            # Calculate match score
            score = match_score(u1, u2)
            candidates.append((u2['uid'], u2.get('username', 'Unknown'), u2.get('gender', 'Unknown'), score))
        
        print(f"✅ Generated {len(candidates)} candidate scores")
    except Exception as e:
        print(f"❌ Error in get_top_matches: {str(e)}")
        return []

    # Separate swiped vs new candidates
    swiped = []
    new_candidates = []
    
    for c in candidates:
        # Check if user has swiped on this candidate
        swipe = current_swipe_logs[
            (current_swipe_logs['user_id'] == user_uid) & 
            (current_swipe_logs['target_user_id'] == c[0])
        ]
        
        if not swipe.empty:
            act = swipe.iloc[0]["action"]
            if act == "reject":
                continue  # skip rejected users completely
            elif act in ["like", "superlike"]:
                weighted_score = c[3] * action_weight(act)
                swiped.append((c[0], c[1], c[2], weighted_score))
        else:
            new_candidates.append(c)

    # Gender-based filtering (simplified orientation logic)
    user_gender = u1.get('gender', '').lower()
    user_orientation = u1.get('orientation', [])
    
    # Safe null checking for user_orientation
    if user_orientation is None:
        user_orientation = []
    elif isinstance(user_orientation, (np.ndarray, pd.Series)):
        # Check if it's a pandas null array
        if len(user_orientation) == 0 or (len(user_orientation) == 1 and pd.isna(user_orientation[0])):
            user_orientation = []
        else:
            user_orientation = user_orientation.tolist()
    elif not isinstance(user_orientation, list):
        # Handle scalar values or other types
        try:
            if pd.isna(user_orientation):
                user_orientation = []
            else:
                user_orientation = [user_orientation] if user_orientation else []
        except (TypeError, ValueError):
            user_orientation = []
    
    # Filter candidates based on orientation preferences
    if len(user_orientation) > 0:
        filtered_candidates = []
        for c in new_candidates:
            candidate_gender = c[2].lower()
            # Enhanced orientation matching logic
            should_include = False
            
            for orient in user_orientation:
                orient_lower = str(orient).lower()
                
                # Map orientation preferences to gender compatibility
                if orient_lower == 'straight':
                    # Straight males interested in females, straight females interested in males
                    if (user_gender == 'male' and candidate_gender == 'female') or \
                       (user_gender == 'female' and candidate_gender == 'male'):
                        should_include = True
                        break
                elif orient_lower in ['friendship', 'fun', 'bisexual', 'pansexual']:
                    # Open to all genders for friendship, fun, or bisexual/pansexual
                    should_include = True
                    break
                elif orient_lower == 'gay':
                    # Gay: same gender preferences
                    if user_gender == candidate_gender:
                        should_include = True
                        break
                elif orient_lower == 'lesbian':
                    # Lesbian: female seeking female
                    if user_gender == 'female' and candidate_gender == 'female':
                        should_include = True
                        break
                elif orient_lower in candidate_gender:
                    # Direct gender match (fallback)
                    should_include = True
                    break
            
            if should_include:
                filtered_candidates.append(c)
        
        if filtered_candidates:
            new_candidates = filtered_candidates
        else:
            # If no matches after filtering, include all candidates (be more lenient)
            print(f"⚠️ No candidates after orientation filter, including all candidates")
            # Keep original new_candidates

    # Sort by score
    mixed_new = sorted(new_candidates, key=lambda x: x[3], reverse=True)

    # -------------------- FINAL TOP MATCHES --------------------
    if use_swipe_logs:
        swiped_sorted = sorted(swiped, key=lambda x: x[3], reverse=True)
        remaining_slots = top_n - len(swiped_sorted)
        if remaining_slots <= 0:
            final_list = swiped_sorted[:top_n]
        else:
            final_list = swiped_sorted + mixed_new[:remaining_slots]
    else:
        # Ignore swiped users, show only new candidates
        final_list = mixed_new[:top_n]

    return final_list

def get_matches_for_user_by_username(username, top_n=10):
    """Get matches for a user by username (for backward compatibility)"""
    user_row = users[users['username'].str.lower() == username.lower()]
    if user_row.empty:
        print(f"❌ User with username {username} not found")
        return []
    
    user_uid = user_row.iloc[0]['uid']
    return get_top_matches(user_uid, top_n)

# -------------------- API ENDPOINT FUNCTIONS --------------------
def get_recommendations_api(user_uid, count=10):
    """API function to get recommendations for Flutter app"""
    try:
        print(f"🔍 Getting recommendations for user: {user_uid}")
        matches = get_top_matches(user_uid, top_n=count)
        print(f"📊 Found {len(matches)} matches")
        
        recommendations = []
        for match in matches:
            # Get full user data for each match
            user_data = users[users['uid'] == match[0]]
            if not user_data.empty:
                user_info = user_data.iloc[0]
                # Safe extraction with null checks
                age_value = user_info.get('age')
                if pd.isna(age_value) or age_value is None:
                    age_value = calculate_age(user_info.get('dateOfBirth'))
                
                location_value = user_info.get('location', '')
                if pd.isna(location_value):
                    location_value = ''
                
                bio_value = user_info.get('bio', '')
                if pd.isna(bio_value):
                    bio_value = ''
                
                interests_value = user_info.get('interests', [])
                if pd.isna(interests_value) or interests_value is None:
                    interests_value = []
                
                photo_url_value = user_info.get('photoUrl', '')
                if pd.isna(photo_url_value):
                    photo_url_value = ''
                    
                photo_urls_value = user_info.get('photoUrls', [])
                if pd.isna(photo_urls_value) or photo_urls_value is None:
                    photo_urls_value = []
                
                recommendations.append({
                    'uid': match[0],
                    'username': match[1],
                    'gender': match[2],
                    'match_score': float(match[3]),
                    'bio': str(bio_value),
                    'age': int(age_value),
                    'location': str(location_value),
                    'interests': list(interests_value) if isinstance(interests_value, list) else [],
                    'photoUrl': str(photo_url_value),
                    'photoUrls': list(photo_urls_value) if isinstance(photo_urls_value, list) else []
                })
        
        return {
            'success': True,
            'user_uid': user_uid,
            'recommendations': recommendations,
            'count': len(recommendations)
        }
    except Exception as e:
        return {
            'success': False,
            'error': str(e),
            'user_uid': user_uid,
            'recommendations': [],
            'count': 0
        }

# -------------------- FLASK API --------------------
app = Flask(__name__)
CORS(app)  # Enable CORS for Flutter web app

@app.route('/health', methods=['GET'])
def health_check():
    """Health check endpoint"""
    return jsonify({
        'status': 'healthy',
        'users_count': len(users),
        'swipes_count': len(swipe_logs)
    })

@app.route('/recommendations/<user_uid>', methods=['GET'])
def get_recommendations(user_uid):
    """Get recommendations for a specific user"""
    try:
        count = int(request.args.get('count', 10))
        count = min(count, 50)  # Limit to 50 recommendations max
        
        result = get_recommendations_api(user_uid, count)
        return jsonify(result)
    except Exception as e:
        return jsonify({
            'success': False,
            'error': f'Server error: {str(e)}',
            'user_uid': user_uid,
            'recommendations': [],
            'count': 0
        }), 500

@app.route('/refresh-data', methods=['POST'])
def refresh_data():
    """Refresh user and swipe data from Firebase"""
    try:
        global users, swipe_logs, bio_embeddings, vectorizer
        
        print("🔄 Refreshing data from Firebase...")
        users = fetch_users_from_firebase()
        swipe_logs = fetch_swipes_from_firebase()
        
        if not users.empty:
            users.reset_index(inplace=True)
            users['bio'] = users['bio'].fillna('No bio available')
            
            vectorizer = TfidfVectorizer(stop_words="english", max_features=500)
            bio_embeddings = vectorizer.fit_transform(users["bio"])
        
        return jsonify({
            'success': True,
            'users_count': len(users),
            'swipes_count': len(swipe_logs),
            'message': 'Data refreshed successfully'
        })
    except Exception as e:
        return jsonify({
            'success': False,
            'error': str(e)
        }), 500

# -------------------- TESTING --------------------
if __name__ == "__main__":
    print("🚀 Firebase ML Matching Algorithm")
    print("=" * 50)
    
    if users.empty:
        print("❌ No users loaded from Firebase")
        exit(1)
    
    print(f"📊 Loaded {len(users)} users and {len(swipe_logs)} swipe actions")
    
    # Check if we should run as API server or test mode
    if len(os.sys.argv) > 1 and os.sys.argv[1] == 'server':
        print("🌐 Starting Flask API server...")
        print("📍 API Endpoints:")
        print("   GET  /health - Health check")
        print("   GET  /recommendations/<user_uid>?count=10 - Get recommendations")
        print("   POST /refresh-data - Refresh data from Firebase")
        print("\n� Server starting on http://localhost:5000")
        app.run(host='0.0.0.0', port=5000, debug=True)
    else:
        # Test mode
        print(f"�👥 Available users: {list(users['username'].head(10))}")
        
        # Test with first available user
        if not users.empty:
            test_user = users.iloc[0]
            user_uid = test_user['uid']
            username = test_user.get('username', 'Unknown')
            
            print(f"\n🔍 Finding matches for {username} (UID: {user_uid})...")
            print("-" * 50)
            
            top_matches = get_top_matches(user_uid, top_n=10)
            
            if top_matches:
                print(f"✅ Found {len(top_matches)} matches:")
                for i, match in enumerate(top_matches, 1):
                    print(f"{i:2d}. {match[1]} ({match[0][:8]}...) [{match[2]}] → Match: {match[3]*100:.1f}%")
            else:
                print("❌ No matches found")
            
            # Test API function
            print(f"\n🔧 Testing API function...")
            api_result = get_recommendations_api(user_uid, 5)
            print(f"API Success: {api_result['success']}")
            print(f"Recommendations count: {api_result['count']}")
        
        print(f"\n✅ ML Matching Algorithm ready for integration!")
        print("💡 Run 'python reject_superlike_like.py server' to start API server")
        print("💡 Use get_recommendations_api(user_uid, count) to get matches for Flutter app")
