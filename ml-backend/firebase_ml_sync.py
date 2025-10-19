import pandas as pd
import json
import os
from datetime import datetime
import firebase_admin
from firebase_admin import credentials, firestore
from typing import List, Dict, Any, Optional

class FirebaseMLDataSync:
    """
    Synchronizes Firebase data with ML backend CSV files.
    Converts Firebase user and swipe data to ML-compatible format.
    """
    
    def __init__(self, firebase_credentials_path: str, ml_data_path: str = "data"):
        """
        Initialize Firebase connection and set ML data paths.
        
        Args:
            firebase_credentials_path: Path to Firebase service account key
            ml_data_path: Path to ML backend data directory
        """
        # Initialize Firebase Admin SDK
        if not firebase_admin._apps:
            cred = credentials.Certificate(firebase_credentials_path)
            firebase_admin.initialize_app(cred)
        
        self.db = firestore.client()
        self.ml_data_path = ml_data_path
        
        # Ensure data directory exists
        os.makedirs(ml_data_path, exist_ok=True)
        
        print(f"🔥 Firebase ML Data Sync initialized")
        print(f"📁 ML data path: {ml_data_path}")
    
    def sync_users_to_csv(self) -> bool:
        """
        Sync Firebase users collection to users.csv for ML backend.
        Maps Firebase user structure to ML expected format.
        """
        try:
            print("🔄 Syncing users from Firebase to ML backend...")
            
            # Fetch all users from Firebase
            users_ref = self.db.collection('users')
            users_docs = users_ref.stream()
            
            users_data = []
            
            for doc in users_docs:
                if doc.exists:
                    user_data = doc.to_dict()
                    user_id = user_data.get('uid', doc.id)
                
                # Map Firebase user data to ML format
                ml_user = {
                    'user_id': user_id,
                    'password': user_id,  # Not used in ML, placeholder
                    'name': user_data.get('name', 'Unknown'),
                    'dob': self._format_date(user_data.get('dateOfBirth')),
                    'age': self._calculate_age(user_data.get('dateOfBirth')),
                    'city': user_data.get('location', {}).get('city', 'Unknown'),
                    'state': user_data.get('location', {}).get('state', 'Unknown'),
                    'profession': user_data.get('profession', 'Unknown'),
                    'photo_path': self._get_primary_photo(user_data.get('photoUrls', [])),
                    'gender': user_data.get('gender', 'Unknown'),
                    'looking_for': ','.join(user_data.get('lookingFor', [])),
                    'hobbies': ','.join(user_data.get('interests', [])),
                    'bio': user_data.get('bio', ''),
                    'elo': 1000  # Default Elo rating for new users
                }
                
                users_data.append(ml_user)
            
            # Create DataFrame and save to CSV with UTF-8 encoding
            df = pd.DataFrame(users_data)
            users_csv_path = os.path.join(self.ml_data_path, 'users.csv')
            df.to_csv(users_csv_path, index=False, encoding='utf-8')
            
            print(f"✅ Synced {len(users_data)} users to {users_csv_path}")
            return True
            
        except Exception as e:
            print(f"❌ Error syncing users: {e}")
            return False
    
    def sync_swipes_to_csv(self) -> bool:
        """
        Sync Firebase swipes collection to swipe_log.csv for ML backend.
        """
        try:
            print("🔄 Syncing swipes from Firebase to ML backend...")
            
            # Fetch all swipes from Firebase
            swipes_ref = self.db.collection('swipes')
            swipes_docs = swipes_ref.stream()
            
            swipes_data = []
            
            for doc in swipes_docs:
                if doc.exists:
                    swipe_data = doc.to_dict()
                    
                    # Map Firebase swipe data to ML format
                    ml_swipe = {
                        'user_id': swipe_data.get('userId'),
                        'target_user_id': swipe_data.get('targetUserId'),
                        'action': swipe_data.get('actionType', 'like')
                    }
                    
                    swipes_data.append(ml_swipe)
            
            # Create DataFrame and save to CSV with UTF-8 encoding
            df = pd.DataFrame(swipes_data)
            swipes_csv_path = os.path.join(self.ml_data_path, 'swipe_log.csv')
            df.to_csv(swipes_csv_path, index=False, encoding='utf-8')
            
            print(f"✅ Synced {len(swipes_data)} swipes to {swipes_csv_path}")
            return True
            
        except Exception as e:
            print(f"❌ Error syncing swipes: {e}")
            return False
    
    def update_user_elo(self, user_id: str, new_elo: float) -> bool:
        """
        Update user's Elo rating in both CSV and Firebase.
        """
        try:
            # Update in CSV
            users_csv_path = os.path.join(self.ml_data_path, 'users.csv')
            if os.path.exists(users_csv_path):
                df = pd.read_csv(users_csv_path)
                df.loc[df['user_id'] == user_id, 'elo'] = new_elo
                df.to_csv(users_csv_path, index=False)
            
            # Update in Firebase
            user_ref = self.db.collection('users').document(user_id)
            user_ref.update({'eloRating': new_elo})
            
            print(f"✅ Updated Elo for user {user_id}: {new_elo}")
            return True
            
        except Exception as e:
            print(f"❌ Error updating Elo: {e}")
            return False
    
    def add_swipe_to_log(self, user_id: str, target_id: str, action: str) -> bool:
        """
        Add a new swipe to the ML swipe log.
        """
        try:
            swipes_csv_path = os.path.join(self.ml_data_path, 'swipe_log.csv')
            
            # Create new swipe entry
            new_swipe = pd.DataFrame([{
                'user_id': user_id,
                'target_user_id': target_id,
                'action': action
            }])
            
            # Append to existing CSV or create new one
            if os.path.exists(swipes_csv_path):
                existing_df = pd.read_csv(swipes_csv_path)
                updated_df = pd.concat([existing_df, new_swipe], ignore_index=True)
            else:
                updated_df = new_swipe
            
            updated_df.to_csv(swipes_csv_path, index=False)
            
            print(f"✅ Added swipe to ML log: {user_id} -> {target_id} [{action}]")
            return True
            
        except Exception as e:
            print(f"❌ Error adding swipe to log: {e}")
            return False
    
    def get_ml_recommendations(self, user_id: str, top_n: int = 10) -> List[str]:
        """
        Get ML recommendations for a user (placeholder - will be called from API).
        """
        try:
            # This will be replaced by actual ML backend API call
            print(f"🤖 Getting ML recommendations for user: {user_id}")
            
            # For now, return mock recommendations
            # In production, this calls your ML backend
            return [f"recommended_user_{i}" for i in range(top_n)]
            
        except Exception as e:
            print(f"❌ Error getting ML recommendations: {e}")
            return []
    
    def _format_date(self, date_obj) -> str:
        """Convert Firebase date to DD-MM-YYYY format."""
        if not date_obj:
            return "01-01-2000"
        
        try:
            if hasattr(date_obj, 'timestamp'):
                # Firestore timestamp
                dt = date_obj.to_datetime()
            else:
                # Already a datetime
                dt = date_obj
            
            return dt.strftime("%d-%m-%Y")
        except:
            return "01-01-2000"
    
    def _calculate_age(self, date_obj) -> int:
        """Calculate age from date of birth."""
        if not date_obj:
            return 25
        
        try:
            if hasattr(date_obj, 'timestamp'):
                birth_date = date_obj.to_datetime()
            else:
                birth_date = date_obj
            
            today = datetime.now()
            age = today.year - birth_date.year
            
            if today.month < birth_date.month or \
               (today.month == birth_date.month and today.day < birth_date.day):
                age -= 1
            
            return max(18, age)  # Minimum age 18
        except:
            return 25
    
    def _get_primary_photo(self, photo_urls: List[str]) -> str:
        """Get primary photo URL or placeholder."""
        if photo_urls and len(photo_urls) > 0:
            return photo_urls[0]
        return "data/images/placeholder.jpg"
    
    def ensure_csv_files_exist(self):
        """Ensure CSV files exist with proper headers even if empty."""
        users_csv_path = os.path.join(self.ml_data_path, 'users.csv')
        swipes_csv_path = os.path.join(self.ml_data_path, 'swipe_log.csv')
        
        # Create empty users.csv if it doesn't exist
        if not os.path.exists(users_csv_path):
            users_df = pd.DataFrame(columns=[
                'user_id', 'name', 'age', 'location', 'interests', 
                'bio', 'photos', 'elo_score', 'profile_completeness'
            ])
            users_df.to_csv(users_csv_path, index=False, encoding='utf-8')
            print(f"📄 Created empty users.csv at {users_csv_path}")
        
        # Create empty swipe_log.csv if it doesn't exist
        if not os.path.exists(swipes_csv_path):
            swipes_df = pd.DataFrame(columns=['user_id', 'target_user_id', 'action'])
            swipes_df.to_csv(swipes_csv_path, index=False, encoding='utf-8')
            print(f"📄 Created empty swipe_log.csv at {swipes_csv_path}")

# Usage example
if __name__ == "__main__":
    # Initialize sync service
    sync = FirebaseMLDataSync(
        firebase_credentials_path="path/to/firebase-adminsdk.json",
        ml_data_path="../data"
    )
    
    # Sync all data
    sync.sync_users_to_csv()
    sync.sync_swipes_to_csv()
    
    print("🎉 Firebase to ML data sync completed!")