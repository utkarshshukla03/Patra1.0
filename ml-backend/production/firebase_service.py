"""
Firebase Service for Patra ML Backend
=====================================

This module handles all Firebase interactions for the ML recommendation system.
It provides real-time data access and replaces the old CSV-based approach.
"""

import firebase_admin
from firebase_admin import credentials, firestore
import pandas as pd
from datetime import datetime, timedelta
import logging
from typing import Dict, List, Optional, Any
import os
import json

class FirebaseService:
    """
    Handles all Firebase operations for the ML backend
    """
    
    def __init__(self):
        self.db = None
        self.connected = False
        self.logger = logging.getLogger(__name__)
    
    def _clean_data(self, data):
        """Clean data for JSON serialization, handling pandas NaT and other issues"""
        if isinstance(data, dict):
            return {k: self._clean_data(v) for k, v in data.items()}
        elif isinstance(data, list):
            return [self._clean_data(item) for item in data]
        elif pd.isna(data):
            return None
        elif isinstance(data, pd.Timestamp):
            return data.isoformat() if not pd.isna(data) else None
        elif isinstance(data, datetime):
            return data.isoformat()
        else:
            return data
        
    def initialize(self, service_account_path: Optional[str] = None):
        """
        Initialize Firebase connection
        
        Args:
            service_account_path: Path to Firebase service account JSON file
        """
        try:
            if not firebase_admin._apps:
                if service_account_path and os.path.exists(service_account_path):
                    cred = credentials.Certificate(service_account_path)
                    firebase_admin.initialize_app(cred)
                    self.logger.info("Firebase initialized with service account")
                else:
                    # Try to initialize with default credentials (for production)
                    firebase_admin.initialize_app()
                    self.logger.info("Firebase initialized with default credentials")
            
            self.db = firestore.client()
            self.connected = True
            self.logger.info("Firebase service connected successfully")
            return True
            
        except Exception as e:
            self.logger.error(f"Failed to initialize Firebase: {e}")
            self.connected = False
            return False
    
    def is_connected(self) -> bool:
        """Check if Firebase is connected"""
        return self.connected and self.db is not None
    
    def get_all_users(self) -> pd.DataFrame:
        """
        Get all users from Firebase
        
        Returns:
            DataFrame with user data
        """
        try:
            if not self.is_connected():
                raise Exception("Firebase not connected")
            
            users_ref = self.db.collection('users')
            docs = users_ref.stream()
            
            users_data = []
            for doc in docs:
                user_data = doc.to_dict()
                user_data['id'] = doc.id
                # Clean data to handle NaT and other serialization issues
                user_data = self._clean_data(user_data)
                users_data.append(user_data)
            
            df = pd.DataFrame(users_data)
            self.logger.info(f"Retrieved {len(df)} users from Firebase")
            return df
            
        except Exception as e:
            self.logger.error(f"Error getting users: {e}")
            return pd.DataFrame()
    
    def get_user_by_id(self, user_id: str) -> Optional[Dict]:
        """
        Get specific user by ID
        
        Args:
            user_id: User ID to fetch
            
        Returns:
            User data dictionary or None
        """
        try:
            if not self.is_connected():
                return None
            
            user_ref = self.db.collection('users').document(user_id)
            doc = user_ref.get()
            
            if doc.exists:
                user_data = doc.to_dict()
                user_data['id'] = doc.id
                return user_data
            else:
                return None
                
        except Exception as e:
            self.logger.error(f"Error getting user {user_id}: {e}")
            return None
    
    def get_swipe_data(self, days_back: int = 30) -> pd.DataFrame:
        """
        Get swipe interaction data
        
        Args:
            days_back: Number of days to look back
            
        Returns:
            DataFrame with swipe data
        """
        try:
            if not self.is_connected():
                raise Exception("Firebase not connected")
            
            cutoff_date = datetime.now() - timedelta(days=days_back)
            
            swipes_ref = self.db.collection('swipes')
            query = swipes_ref.where('timestamp', '>=', cutoff_date)
            docs = query.stream()
            
            swipes_data = []
            for doc in docs:
                swipe_data = doc.to_dict()
                swipe_data['id'] = doc.id
                swipes_data.append(swipe_data)
            
            df = pd.DataFrame(swipes_data)
            self.logger.info(f"Retrieved {len(df)} swipes from last {days_back} days")
            return df
            
        except Exception as e:
            self.logger.error(f"Error getting swipe data: {e}")
            return pd.DataFrame()
    
    def get_user_interactions(self, user_id: str, days_back: int = 30) -> pd.DataFrame:
        """
        Get interactions for a specific user
        
        Args:
            user_id: User ID
            days_back: Number of days to look back
            
        Returns:
            DataFrame with user interactions
        """
        try:
            if not self.is_connected():
                raise Exception("Firebase not connected")
            
            cutoff_date = datetime.now() - timedelta(days=days_back)
            
            interactions_ref = self.db.collection('interactions')
            query = interactions_ref.where('user_id', '==', user_id).where('timestamp', '>=', cutoff_date)
            docs = query.stream()
            
            interactions_data = []
            for doc in docs:
                interaction_data = doc.to_dict()
                interaction_data['id'] = doc.id
                interactions_data.append(interaction_data)
            
            df = pd.DataFrame(interactions_data)
            self.logger.info(f"Retrieved {len(df)} interactions for user {user_id}")
            return df
            
        except Exception as e:
            self.logger.error(f"Error getting user interactions: {e}")
            return pd.DataFrame()
    
    def save_interaction(self, user_id: str, target_id: str, action: str) -> bool:
        """
        Save user interaction to Firebase
        
        Args:
            user_id: ID of user performing action
            target_id: ID of target user
            action: Type of action (like, dislike, superlike)
            
        Returns:
            True if successful, False otherwise
        """
        try:
            if not self.is_connected():
                return False
            
            interaction_data = {
                'user_id': user_id,
                'target_id': target_id,
                'action': action,
                'timestamp': datetime.now(),
                'ml_version': '2.0.0'
            }
            
            # Save to interactions collection
            interactions_ref = self.db.collection('interactions')
            interactions_ref.add(interaction_data)
            
            # Also save to swipes collection for compatibility
            swipes_ref = self.db.collection('swipes')
            swipes_ref.add(interaction_data)
            
            self.logger.info(f"Saved interaction: {user_id} -> {target_id} ({action})")
            return True
            
        except Exception as e:
            self.logger.error(f"Error saving interaction: {e}")
            return False
    
    def get_user_elo_score(self, user_id: str) -> int:
        """
        Get user's Elo rating score
        
        Args:
            user_id: User ID
            
        Returns:
            Elo score (default 1200 if not found)
        """
        try:
            user_data = self.get_user_by_id(user_id)
            if user_data:
                return user_data.get('elo_score', 1200)
            return 1200
            
        except Exception as e:
            self.logger.error(f"Error getting Elo score for {user_id}: {e}")
            return 1200
    
    def update_user_elo_score(self, user_id: str, new_score: int) -> bool:
        """
        Update user's Elo rating score
        
        Args:
            user_id: User ID
            new_score: New Elo score
            
        Returns:
            True if successful, False otherwise
        """
        try:
            if not self.is_connected():
                return False
            
            user_ref = self.db.collection('users').document(user_id)
            user_ref.update({
                'elo_score': new_score,
                'elo_updated': datetime.now()
            })
            
            self.logger.info(f"Updated Elo score for {user_id}: {new_score}")
            return True
            
        except Exception as e:
            self.logger.error(f"Error updating Elo score: {e}")
            return False
    
    def get_potential_matches(self, user_id: str, limit: int = 50) -> pd.DataFrame:
        """
        Get potential matches for a user (excluding already swiped users)
        
        Args:
            user_id: User ID
            limit: Maximum number of matches to return
            
        Returns:
            DataFrame with potential matches
        """
        try:
            if not self.is_connected():
                raise Exception("Firebase not connected")
            
            # Get user's own data first
            user_data = self.get_user_by_id(user_id)
            if not user_data:
                return pd.DataFrame()
            
            # Get all users except self
            all_users_df = self.get_all_users()
            potential_matches = all_users_df[all_users_df['id'] != user_id].copy()
            
            # Filter by gender preferences
            user_looking_for = user_data.get('looking_for', [])
            user_gender = user_data.get('gender', '')
            
            if user_looking_for:
                potential_matches = potential_matches[
                    potential_matches['gender'].isin(user_looking_for)
                ]
            
            # Filter out users who don't want this user's gender
            if user_gender:
                potential_matches = potential_matches[
                    potential_matches['looking_for'].apply(
                        lambda x: isinstance(x, list) and user_gender in x
                    )
                ]
            
            # Get user's interaction history to exclude already swiped users
            interactions_df = self.get_user_interactions(user_id, days_back=365)  # Last year
            if not interactions_df.empty:
                swiped_user_ids = set(interactions_df['target_id'].tolist())
                potential_matches = potential_matches[
                    ~potential_matches['id'].isin(swiped_user_ids)
                ]
            
            # Limit results
            potential_matches = potential_matches.head(limit)
            
            self.logger.info(f"Found {len(potential_matches)} potential matches for {user_id}")
            return potential_matches
            
        except Exception as e:
            self.logger.error(f"Error getting potential matches: {e}")
            return pd.DataFrame()

# Global Firebase service instance
_firebase_service = None

def get_firebase_service() -> FirebaseService:
    """
    Get the global Firebase service instance
    
    Returns:
        FirebaseService instance
    """
    global _firebase_service
    if _firebase_service is None:
        _firebase_service = FirebaseService()
    return _firebase_service

def initialize_firebase_service(service_account_path: Optional[str] = None) -> bool:
    """
    Initialize the global Firebase service
    
    Args:
        service_account_path: Path to Firebase service account JSON file
        
    Returns:
        True if successful, False otherwise
    """
    firebase_service = get_firebase_service()
    return firebase_service.initialize(service_account_path)