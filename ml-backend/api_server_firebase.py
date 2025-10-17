""""""

Flask API Server for Patra ML RecommendationsFlask API Server for Patra ML Backend

============================================Provides RESTful endpoints for Flutter app integration

Now works directly with Firebase - no more CSV files needed!

This server provides ML-powered user recommendations and handles user interactions"""

for the Patra dating app using Firebase real-time data.

from flask import Flask, request, jsonify

Endpoints:from flask_cors import CORS

- GET /api/recommendations/<user_id> - Get ML recommendations for a userimport os

- POST /api/interaction - Record user interaction (like/dislike/superlike)import sys

- GET /api/health - Health check endpointfrom datetime import datetime

"""import traceback



from flask import Flask, request, jsonify# Add production modules to path

from flask_cors import CORSsys.path.append(os.path.join(os.path.dirname(__file__), 'production'))

import os

import sys# Import ML modules

import pandas as pdfrom production.main import generate_user_feed, record_interaction

import loggingfrom production.config_loader import load_config

from typing import Dict, List, Anyfrom production.logger import get_logger

import traceback

app = Flask(__name__)

# Add production directory to pathCORS(app)  # Enable CORS for Flutter web

sys.path.append(os.path.join(os.path.dirname(__file__), 'production'))

# Initialize

try:logger = get_logger(__name__)

    from production.main import generate_user_feed, record_interaction, get_user_recommendations, initialize_firebaseconfig = load_config()

    from production.logger import get_logger

    from production.firebase_service import get_firebase_service# Initialize Firebase service (no more CSV dependencies)

except ImportError as e:firebase_service = None

    print(f"Error importing ML modules: {e}")try:

    print("Make sure the production modules are properly installed")    # Import and initialize Firebase service

    sys.exit(1)    from production.firebase_service import FirebaseService

    

app = Flask(__name__)    if os.path.exists("firebase-adminsdk.json"):

CORS(app)  # Enable CORS for Flutter web app        firebase_service = FirebaseService("firebase-adminsdk.json")

        print("🔥 Firebase service initialized - working directly with Firebase")

# Setup logging    else:

logging.basicConfig(level=logging.INFO)        print("⚠️ Firebase credentials not found - running in offline mode")

logger = get_logger(__name__)        print("   Add firebase-adminsdk.json to enable Firebase integration")

except Exception as e:

# Initialize Firebase    print(f"⚠️ Firebase service not initialized: {e}")

service_account_path = os.getenv('FIREBASE_SERVICE_ACCOUNT_PATH', 'firebase-service-account.json')    print("   Running in offline mode")

firebase_initialized = initialize_firebase(service_account_path if os.path.exists(service_account_path) else None)

@app.route('/', methods=['GET'])

if not firebase_initialized:def health_check():

    logger.warning("Firebase initialization failed - some features may not work")    """Health check endpoint"""

    return jsonify({

@app.route('/api/health', methods=['GET'])        'status': 'healthy',

def health_check():        'service': 'Patra ML Backend',

    """Health check endpoint"""        'version': '2.0',

    try:        'firebase_connected': firebase_service is not None,

        firebase_service = get_firebase_service()        'timestamp': datetime.now().isoformat(),

        firebase_status = firebase_service.is_connected()    })

        

        # Test Firebase connectivity@app.route('/health', methods=['GET'])

        user_count = 0def health_check_alt():

        if firebase_status:    """Alternative health check endpoint for compatibility"""

            try:    return jsonify({

                users_df = firebase_service.get_all_users()        'status': 'healthy',

                user_count = len(users_df)        'service': 'Patra ML Backend',

            except:        'version': '2.0',

                firebase_status = False        'firebase_connected': firebase_service is not None,

                'timestamp': datetime.now().isoformat(),

        return jsonify({    })

            'status': 'healthy' if firebase_status else 'degraded',

            'message': 'Patra ML API is running',@app.route('/recommend/<user_id>', methods=['GET'])

            'version': '2.0.0',def get_recommendations(user_id):

            'firebase_connected': firebase_status,    """

            'users_in_database': user_count,    Get ML-powered recommendations for a user directly from Firebase

            'features': {    """

                'ml_recommendations': firebase_status,    try:

                'interaction_tracking': firebase_status,        top_n = request.args.get('top_n', 10, type=int)

                'real_time_data': firebase_status        

            }        logger.info(f"Getting recommendations for user: {user_id}, top_n: {top_n}")

        })        

    except Exception as e:        if not firebase_service:

        logger.error(f"Health check failed: {e}")            return jsonify({

        return jsonify({                'success': False,

            'status': 'unhealthy',                'error': 'Firebase service not available',

            'message': 'API health check failed',                'user_id': user_id

            'error': str(e)            }), 503

        }), 500        

        # Generate recommendations directly from Firebase

@app.route('/api/recommendations/<user_id>', methods=['GET'])        recommendations_list = generate_user_feed(user_id, top_n)

def get_recommendations(user_id: str):        

    """        # Convert to API response format

    Get ML-powered recommendations for a user using Firebase data        recommendations = []

            for i, rec in enumerate(recommendations_list):

    Args:            recommendations.append({

        user_id: The ID of the user to get recommendations for                'user_id': rec['user_id'],

                        'name': rec['name'],

    Query Parameters:                'age': rec['age'],

        count: Number of recommendations to return (default: 10)                'location': rec['location'],

    """                'bio': rec['bio'],

    try:                'photos': rec['photos'],

        # Check Firebase connection                'elo_score': rec['elo_score'],

        firebase_service = get_firebase_service()                'compatibility_score': rec['compatibility_score'],

        if not firebase_service.is_connected():                'rank': i + 1

            return jsonify({            })

                'success': False,        

                'error': 'Service unavailable',        return jsonify({

                'message': 'Firebase connection not available'            'success': True,

            }), 503            'user_id': user_id,

                    'recommendations': recommendations,

        # Get count from query params            'total_count': len(recommendations),

        count = int(request.args.get('count', 10))            'algorithm': 'firebase_ml',

        count = min(count, 50)  # Maximum 50 recommendations            'timestamp': datetime.now().isoformat()

                })

        logger.info(f"Getting recommendations for user {user_id}, count: {count}")        

            except Exception as e:

        # Generate recommendations using Firebase ML backend        logger.error(f"Error generating recommendations for user {user_id}: {e}")

        recommendations = get_user_recommendations(user_id, count)        logger.error(traceback.format_exc())

                

        if not recommendations:        return jsonify({

            # Try to check if user exists            'success': False,

            user_data = firebase_service.get_user_by_id(user_id)            'error': str(e),

            if not user_data:            'user_id': user_id

                return jsonify({        }), 500

                    'success': False,

                    'error': 'User not found',@app.route('/record_interaction', methods=['POST'])

                    'message': f'User {user_id} not found in database'def record_swipe_interaction():

                }), 404    """

            else:    Record a swipe interaction (like, dislike, superlike)

                # User exists but no recommendations available    """

                return jsonify({    try:

                    'success': True,        data = request.get_json()

                    'user_id': user_id,        

                    'count': 0,        user_id = data.get('user_id')

                    'recommendations': [],        target_user_id = data.get('target_user_id') 

                    'message': 'No recommendations available for this user'        action = data.get('action')  # 'like', 'dislike', 'superlike'

                })        

                if not all([user_id, target_user_id, action]):

        logger.info(f"Generated {len(recommendations)} recommendations for user {user_id}")            return jsonify({

                        'success': False,

        return jsonify({                'error': 'Missing required fields: user_id, target_user_id, action'

            'success': True,            }), 400

            'user_id': user_id,        

            'count': len(recommendations),        logger.info(f"Recording interaction: {user_id} -> {target_user_id} [{action}]")

            'recommendations': recommendations,        

            'generated_at': pd.Timestamp.now().isoformat(),        # Record interaction directly in Firebase and update algorithms

            'ml_version': '2.0.0'        success = record_interaction(user_id, target_user_id, action)

        })        

                return jsonify({

    except ValueError as e:            'success': success,

        logger.error(f"Invalid input: {e}")            'message': f'Recorded {action} interaction',

        return jsonify({            'timestamp': datetime.now().isoformat()

            'success': False,        })

            'error': 'Invalid input',        

            'message': str(e)    except Exception as e:

        }), 400        logger.error(f"Error recording interaction: {e}")

                return jsonify({

    except Exception as e:            'success': False,

        logger.error(f"Error generating recommendations: {e}")            'error': str(e)

        logger.error(traceback.format_exc())        }), 500

        return jsonify({

            'success': False,@app.route('/user/<user_id>/stats', methods=['GET'])

            'error': 'Internal server error',def get_user_stats(user_id):

            'message': 'Failed to generate recommendations'    """Get user statistics and Elo score"""

        }), 500    try:

        if not firebase_service:

@app.route('/api/interaction', methods=['POST'])            return jsonify({'error': 'Firebase service not available'}), 503

def record_user_interaction():        

    """        # Get user data directly from Firebase

    Record a user interaction (like, dislike, superlike) to Firebase        user_data = firebase_service.get_user_data(user_id)

            

    Expected JSON payload:        if user_data.empty:

    {            return jsonify({

        "user_id": "user123",                'success': False,

        "target_id": "user456",                 'error': 'User not found'

        "action": "like|dislike|superlike"            }), 404

    }        

    """        user_info = user_data.iloc[0]

    try:        

        # Check Firebase connection        # Get user's swipe statistics

        firebase_service = get_firebase_service()        swipe_data = firebase_service.get_swipe_data(user_id)

        if not firebase_service.is_connected():        

            return jsonify({        stats = {

                'success': False,            'user_id': user_id,

                'error': 'Service unavailable',            'elo_score': user_info['elo_score'],

                'message': 'Firebase connection not available'            'profile_completeness': user_info['profile_completeness'],

            }), 503            'total_swipes': len(swipe_data),

                    'likes_given': len(swipe_data[swipe_data['action'] == 'like']) if not swipe_data.empty else 0,

        data = request.get_json()            'dislikes_given': len(swipe_data[swipe_data['action'] == 'dislike']) if not swipe_data.empty else 0,

                    'superlikes_given': len(swipe_data[swipe_data['action'] == 'superlike']) if not swipe_data.empty else 0,

        if not data:        }

            return jsonify({        

                'success': False,        return jsonify({

                'error': 'Invalid request',            'success': True,

                'message': 'JSON payload required'            'stats': stats,

            }), 400            'timestamp': datetime.now().isoformat()

                })

        user_id = data.get('user_id')        

        target_id = data.get('target_id')    except Exception as e:

        action = data.get('action')        logger.error(f"Error getting user stats: {e}")

                return jsonify({

        # Validate required fields            'success': False,

        if not all([user_id, target_id, action]):            'error': str(e)

            return jsonify({        }), 500

                'success': False,

                'error': 'Missing fields',@app.route('/sync', methods=['POST'])

                'message': 'user_id, target_id, and action are required'def test_firebase_connectivity():

            }), 400    """Test Firebase connectivity and data availability"""

            try:

        # Validate action        if not firebase_service:

        if action not in ['like', 'dislike', 'superlike']:            return jsonify({'error': 'Firebase service not available'}), 503

            return jsonify({        

                'success': False,        # Test Firebase connectivity

                'error': 'Invalid action',        user_count = len(firebase_service.get_user_data())

                'message': 'action must be one of: like, dislike, superlike'        swipe_count = len(firebase_service.get_swipe_data())

            }), 400        

                return jsonify({

        logger.info(f"Recording interaction: {user_id} -> {target_id} ({action})")            'success': True,

                    'message': 'Firebase connectivity verified',

        # Record the interaction using Firebase ML backend            'data': {

        success = record_interaction(user_id, target_id, action)                'users_count': user_count,

                        'swipes_count': swipe_count,

        if success:                'direct_firebase': True

            return jsonify({            },

                'success': True,            'timestamp': datetime.now().isoformat()

                'message': 'Interaction recorded successfully',        })

                'user_id': user_id,        

                'target_id': target_id,    except Exception as e:

                'action': action,        logger.error(f"Error testing Firebase connectivity: {e}")

                'recorded_at': pd.Timestamp.now().isoformat()        return jsonify({

            })            'success': False,

        else:            'error': str(e)

            return jsonify({        }), 500

                'success': False,

                'error': 'Recording failed',@app.route('/status', methods=['GET'])

                'message': 'Failed to record interaction'def get_status():

            }), 500    """Get ML backend status and configuration"""

            return jsonify({

    except Exception as e:        'service': 'Patra ML Backend',

        logger.error(f"Error recording interaction: {e}")        'version': '2.0',

        logger.error(traceback.format_exc())        'status': 'running',

        return jsonify({        'features': {

            'success': False,            'firebase_service': firebase_service is not None,

            'error': 'Internal server error',            'direct_firebase': True,

            'message': 'Failed to record interaction'            'csv_deprecated': True,

        }), 500            'ml_recommendations': True,

            'elo_system': True

@app.route('/api/users/<user_id>/stats', methods=['GET'])        },

def get_user_stats(user_id: str):        'timestamp': datetime.now().isoformat()

    """Get user statistics and ML metrics from Firebase"""    })

    try:

        firebase_service = get_firebase_service()if __name__ == '__main__':

        if not firebase_service.is_connected():    print("🚀 Starting Patra ML Backend Server...")

            return jsonify({    print("📊 Features: Firebase Direct, ML Recommendations, Elo System")

                'success': False,    print("🔥 No more CSV files - everything runs directly from Firebase!")

                'error': 'Service unavailable'    print()

            }), 503    

            # Start Flask development server

        # Get user interactions    app.run(

        interactions_df = firebase_service.get_user_interactions(user_id, days_back=30)        host='localhost',

                port=5000,

        # Calculate stats        debug=True,

        total_interactions = len(interactions_df)        use_reloader=False

        likes_given = len(interactions_df[interactions_df['action'] == 'like']) if not interactions_df.empty else 0    )
        
        # Get user data
        user_data = firebase_service.get_user_by_id(user_id)
        ml_score = user_data.get('ml_score', 0) if user_data else 0
        
        return jsonify({
            'success': True,
            'user_id': user_id,
            'stats': {
                'total_interactions': total_interactions,
                'likes_given': likes_given,
                'ml_score': ml_score,
                'last_30_days': True
            }
        })
    except Exception as e:
        logger.error(f"Error getting user stats: {e}")
        return jsonify({
            'success': False,
            'error': 'Internal server error',
            'message': 'Failed to get user stats'
        }), 500

@app.route('/api/debug/firebase', methods=['GET'])
def debug_firebase():
    """Debug endpoint to test Firebase connectivity"""
    try:
        firebase_service = get_firebase_service()
        
        if not firebase_service.is_connected():
            return jsonify({
                'firebase_connected': False,
                'error': 'Firebase not connected'
            })
        
        # Test operations
        users_df = firebase_service.get_all_users()
        swipes_df = firebase_service.get_swipe_data()
        
        return jsonify({
            'firebase_connected': True,
            'users_count': len(users_df),
            'swipes_count': len(swipes_df),
            'sample_users': users_df.head(3).to_dict('records') if not users_df.empty else []
        })
    except Exception as e:
        return jsonify({
            'firebase_connected': False,
            'error': str(e),
            'traceback': traceback.format_exc()
        })

if __name__ == '__main__':
    # Check if running in development mode
    debug_mode = os.getenv('FLASK_ENV') == 'development'
    port = int(os.getenv('PORT', 5000))
    
    logger.info(f"Starting Patra ML API server on port {port}")
    logger.info(f"Debug mode: {debug_mode}")
    logger.info(f"Firebase initialized: {firebase_initialized}")
    
    app.run(host='0.0.0.0', port=port, debug=debug_mode)