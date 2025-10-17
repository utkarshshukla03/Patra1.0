"""
Flask API Server for Patra ML Recommendations
============================================

This server provides ML-powered user recommendations and handles user interactions
for the Patra dating app using Firebase real-time data.

Endpoints:
- GET /api/recommendations/<user_id> - Get ML recommendations for a user
- POST /api/interaction - Record user interaction (like/dislike/superlike)
- GET /api/health - Health check endpoint
"""

from flask import Flask, request, jsonify
from flask_cors import CORS
import os
import sys
import pandas as pd
import logging
from typing import Dict, List, Any
import traceback

# Add production directory to path
sys.path.append(os.path.join(os.path.dirname(__file__), 'production'))

try:
    from production.main import generate_user_feed, record_interaction, get_user_recommendations, initialize_firebase
    from production.logger import get_logger
    from production.firebase_service import get_firebase_service
except ImportError as e:
    print(f"Error importing ML modules: {e}")
    print("Make sure the production modules are properly installed")
    sys.exit(1)

app = Flask(__name__)
CORS(app)  # Enable CORS for Flutter web app

# Setup logging
logging.basicConfig(level=logging.INFO)
logger = get_logger(__name__)

# Initialize Firebase
service_account_path = os.getenv('FIREBASE_SERVICE_ACCOUNT_PATH', 'firebase-service-account.json')
firebase_initialized = initialize_firebase(service_account_path if os.path.exists(service_account_path) else None)

if not firebase_initialized:
    logger.warning("Firebase initialization failed - some features may not work")

@app.route('/api/health', methods=['GET'])
def health_check():
    """Health check endpoint"""
    try:
        firebase_service = get_firebase_service()
        firebase_status = firebase_service.is_connected()
        
        # Test Firebase connectivity
        user_count = 0
        if firebase_status:
            try:
                users_df = firebase_service.get_all_users()
                user_count = len(users_df)
            except:
                firebase_status = False
        
        return jsonify({
            'status': 'healthy' if firebase_status else 'degraded',
            'message': 'Patra ML API is running',
            'version': '2.0.0',
            'firebase_connected': firebase_status,
            'users_in_database': user_count,
            'features': {
                'ml_recommendations': firebase_status,
                'interaction_tracking': firebase_status,
                'real_time_data': firebase_status
            }
        })
    except Exception as e:
        logger.error(f"Health check failed: {e}")
        return jsonify({
            'status': 'unhealthy',
            'message': 'API health check failed',
            'error': str(e)
        }), 500

@app.route('/api/recommendations/<user_id>', methods=['GET'])
def get_recommendations(user_id: str):
    """
    Get ML-powered recommendations for a user using Firebase data
    
    Args:
        user_id: The ID of the user to get recommendations for
        
    Query Parameters:
        count: Number of recommendations to return (default: 10)
    """
    try:
        # Check Firebase connection
        firebase_service = get_firebase_service()
        if not firebase_service.is_connected():
            return jsonify({
                'success': False,
                'error': 'Service unavailable',
                'message': 'Firebase connection not available'
            }), 503
        
        # Get count from query params
        count = int(request.args.get('count', 10))
        count = min(count, 50)  # Maximum 50 recommendations
        
        logger.info(f"🤖 ML API: Getting recommendations for user {user_id}, count: {count}")
        
        # Generate recommendations using Firebase ML backend
        recommendations = get_user_recommendations(user_id, count)
        
        # Enhanced logging for debugging
        if recommendations:
            logger.info(f"🎯 ML API: Generated {len(recommendations)} recommendations for user {user_id}")
            logger.info("📊 TOP RECOMMENDATIONS:")
            for i, rec in enumerate(recommendations[:10]):  # Log first 10 recommendations
                logger.info(f"   #{i+1}: User {rec.get('user_id', 'Unknown')}")
                logger.info(f"        💯 Compatibility: {rec.get('compatibility_score', 'N/A')}")
                logger.info(f"        🎪 Age Score: {rec.get('age_score', 'N/A')}")
                logger.info(f"        📍 Location Score: {rec.get('location_score', 'N/A')}")
                logger.info(f"        💝 Interest Score: {rec.get('interest_score', 'N/A')}")
        else:
            logger.info(f"⚠️  ML API: No recommendations generated for user {user_id}")
        
        if not recommendations:
            # Try to check if user exists
            user_data = firebase_service.get_user_by_id(user_id)
            if not user_data:
                return jsonify({
                    'success': False,
                    'error': 'User not found',
                    'message': f'User {user_id} not found in database'
                }), 404
            else:
                # User exists but no recommendations available
                return jsonify({
                    'success': True,
                    'user_id': user_id,
                    'count': 0,
                    'recommendations': [],
                    'message': 'No recommendations available for this user'
                })
        
        logger.info(f"✅ ML API: Successfully returning {len(recommendations)} recommendations for user {user_id}")
        
        return jsonify({
            'success': True,
            'user_id': user_id,
            'count': len(recommendations),
            'recommendations': recommendations,
            'generated_at': pd.Timestamp.now().isoformat(),
            'ml_version': '2.0.0'
        })
        
    except ValueError as e:
        logger.error(f"Invalid input: {e}")
        return jsonify({
            'success': False,
            'error': 'Invalid input',
            'message': str(e)
        }), 400
        
    except Exception as e:
        logger.error(f"Error generating recommendations: {e}")
        logger.error(traceback.format_exc())
        return jsonify({
            'success': False,
            'error': 'Internal server error',
            'message': 'Failed to generate recommendations'
        }), 500

@app.route('/api/interaction', methods=['POST'])
def record_user_interaction():
    """
    Record a user interaction (like, dislike, superlike) to Firebase
    
    Expected JSON payload:
    {
        "user_id": "user123",
        "target_id": "user456", 
        "action": "like|dislike|superlike"
    }
    """
    try:
        # Check Firebase connection
        firebase_service = get_firebase_service()
        if not firebase_service.is_connected():
            return jsonify({
                'success': False,
                'error': 'Service unavailable',
                'message': 'Firebase connection not available'
            }), 503
        
        data = request.get_json()
        
        if not data:
            return jsonify({
                'success': False,
                'error': 'Invalid request',
                'message': 'JSON payload required'
            }), 400
        
        user_id = data.get('user_id')
        target_id = data.get('target_id')
        action = data.get('action')
        
        # Validate required fields
        if not all([user_id, target_id, action]):
            return jsonify({
                'success': False,
                'error': 'Missing fields',
                'message': 'user_id, target_id, and action are required'
            }), 400
        
        # Validate action
        if action not in ['like', 'dislike', 'superlike']:
            return jsonify({
                'success': False,
                'error': 'Invalid action',
                'message': 'action must be one of: like, dislike, superlike'
            }), 400
        
        logger.info(f"Recording interaction: {user_id} -> {target_id} ({action})")
        
        # Record the interaction using Firebase ML backend
        success = record_interaction(user_id, target_id, action)
        
        if success:
            return jsonify({
                'success': True,
                'message': 'Interaction recorded successfully',
                'user_id': user_id,
                'target_id': target_id,
                'action': action,
                'recorded_at': pd.Timestamp.now().isoformat()
            })
        else:
            return jsonify({
                'success': False,
                'error': 'Recording failed',
                'message': 'Failed to record interaction'
            }), 500
        
    except Exception as e:
        logger.error(f"Error recording interaction: {e}")
        logger.error(traceback.format_exc())
        return jsonify({
            'success': False,
            'error': 'Internal server error',
            'message': 'Failed to record interaction'
        }), 500

@app.route('/api/debug/firebase', methods=['GET'])
def debug_firebase():
    """Debug endpoint to test Firebase connectivity and show sample data"""
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
        
        # Get sample user IDs safely
        sample_user_ids = []
        sample_users = []
        
        if not users_df.empty:
            try:
                # Get sample user IDs
                if 'id' in users_df.columns:
                    sample_user_ids = users_df['id'].head(5).fillna('').astype(str).tolist()
                
                # Get sample users with safe conversion
                sample_users_raw = users_df.head(3).fillna('').to_dict('records')
                for user in sample_users_raw:
                    cleaned_user = {}
                    for k, v in user.items():
                        try:
                            if v is None or (hasattr(v, '__len__') and len(str(v)) == 0):
                                cleaned_user[k] = None
                            elif hasattr(v, 'isoformat'):  # datetime objects
                                cleaned_user[k] = v.isoformat()
                            else:
                                cleaned_user[k] = str(v) if v is not None else None
                        except:
                            cleaned_user[k] = str(v) if v is not None else None
                    sample_users.append(cleaned_user)
            except Exception as e:
                logger.error(f"Error processing sample data: {e}")
                sample_user_ids = []
                sample_users = []
        
        return jsonify({
            'firebase_connected': True,
            'users_count': len(users_df),
            'swipes_count': len(swipes_df),
            'sample_user_ids': sample_user_ids,
            'sample_users': sample_users
        })
    except Exception as e:
        return jsonify({
            'firebase_connected': False,
            'error': str(e),
            'traceback': traceback.format_exc()
        })

if __name__ == '__main__':
    debug_mode = os.getenv('FLASK_ENV') == 'development'
    port = int(os.getenv('PORT', 5000))
    
    logger.info(f"Starting Patra ML API server on port {port}")
    logger.info(f"Debug mode: {debug_mode}")
    logger.info(f"Firebase initialized: {firebase_initialized}")
    
    app.run(host='0.0.0.0', port=port, debug=debug_mode)