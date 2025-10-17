"""
data_match.py
-------------
Purpose:
    Compute basic feature-based similarity between users using real-time Firebase data.
    This module provides compatibility scoring based on age, location, interests, 
    and other profile attributes.

Updated to use Firebase real-time data instead of CSV files.
"""

import pandas as pd
import numpy as np
from production.logger import get_logger
from production.firebase_service import get_firebase_service
from datetime import datetime
from typing import List, Dict, Any, Optional

logger = get_logger(__name__)

# -----------------------------------------
# Jaccard similarity between list-like fields
# -----------------------------------------
def jaccard_score(list1, list2):
    """Calculate Jaccard similarity between two lists"""
    if not list1 or not list2:
        return 0.0
    
    # Handle different input types
    if isinstance(list1, str):
        list1 = [x.strip() for x in list1.split(',') if x.strip()]
    if isinstance(list2, str):
        list2 = [x.strip() for x in list2.split(',') if x.strip()]
    
    s1, s2 = set(list1), set(list2)
    return len(s1 & s2) / len(s1 | s2) if s1 | s2 else 0


# -----------------------------------------
# Compute basic match score (no bio similarity)
# -----------------------------------------
def match_score(u1_data: Dict[str, Any], u2_data: Dict[str, Any]) -> float:
    """
    Calculate compatibility score between two users based on profile data
    
    Args:
        u1_data: First user's data dictionary
        u2_data: Second user's data dictionary
        
    Returns:
        Compatibility score between 0 and 1
    """
    try:
        score = 0.0
        weight_sum = 0.0
        
        # Age similarity (weight: 0.3)
        age1 = u1_data.get('age', 25)
        age2 = u2_data.get('age', 25)
        age_diff = abs(age1 - age2)
        age_score = max(0, 1 - (age_diff / 15))  # Normalize by 15 years
        score += age_score * 0.3
        weight_sum += 0.3
        
        # Location similarity (weight: 0.2)
        loc1 = u1_data.get('location', '').lower()
        loc2 = u2_data.get('location', '').lower()
        if loc1 and loc2:
            if loc1 == loc2:
                loc_score = 1.0
            elif any(word in loc2 for word in loc1.split()) or any(word in loc1 for word in loc2.split()):
                loc_score = 0.6
            else:
                loc_score = 0.1
            score += loc_score * 0.2
            weight_sum += 0.2
        
        # Interests similarity (weight: 0.3)
        interests1 = u1_data.get('interests', [])
        interests2 = u2_data.get('interests', [])
        if interests1 or interests2:
            interests_score = jaccard_score(interests1, interests2)
            score += interests_score * 0.3
            weight_sum += 0.3
        
        # Gender preference compatibility (weight: 0.2)
        gender1 = u1_data.get('gender', '').lower()
        gender2 = u2_data.get('gender', '').lower()
        pref1 = u1_data.get('genderPreference', 'all').lower()
        pref2 = u2_data.get('genderPreference', 'all').lower()
        
        gender_compatible = True
        if pref1 != 'all' and gender2 and pref1 != gender2:
            gender_compatible = False
        if pref2 != 'all' and gender1 and pref2 != gender1:
            gender_compatible = False
        
        gender_score = 1.0 if gender_compatible else 0.0
        score += gender_score * 0.2
        weight_sum += 0.2
        
        # Normalize score
        if weight_sum > 0:
            score = score / weight_sum
        
        return min(1.0, max(0.0, score))
        
    except Exception as e:
        logger.error(f"Error computing match score: {e}")
        return 0.0


def get_top_matches(user_id: str, top_n: int = 20, use_swipe_logs: bool = True) -> pd.DataFrame:
    """
    Get top matches for a user using real-time Firebase data
    
    Args:
        user_id: Target user ID to find matches for
        top_n: Number of top matches to return
        use_swipe_logs: Whether to filter out already swiped users
        
    Returns:
        DataFrame with top matches and scores
    """
    try:
        firebase_service = get_firebase_service()
        if not firebase_service.is_connected():
            logger.error("Firebase not connected")
            return pd.DataFrame()
        
        # Get current user data
        current_user = firebase_service.get_user_by_id(user_id)
        if not current_user:
            logger.error(f"User {user_id} not found")
            return pd.DataFrame()
        
        # Get all users
        all_users_df = firebase_service.get_all_users()
        if all_users_df.empty:
            logger.error("No users found in database")
            return pd.DataFrame()
        
        # Filter out current user
        candidate_users = all_users_df[all_users_df['uid'] != user_id].copy()
        
        # Filter by age preferences
        user_age_min = current_user.get('ageMin', 18)
        user_age_max = current_user.get('ageMax', 50)
        candidate_users = candidate_users[
            (candidate_users['age'] >= user_age_min) & 
            (candidate_users['age'] <= user_age_max)
        ]
        
        # Filter by gender preferences
        user_gender_pref = current_user.get('genderPreference', 'all').lower()
        if user_gender_pref != 'all':
            candidate_users = candidate_users[
                candidate_users['gender'].str.lower() == user_gender_pref
            ]
        
        # Get swipe data if filtering is enabled
        swiped_users = set()
        if use_swipe_logs:
            user_interactions = firebase_service.get_user_interactions(user_id, days_back=90)
            if not user_interactions.empty:
                swiped_users = set(user_interactions['targetUserId'].unique())
        
        # Calculate match scores
        matches = []
        for _, candidate in candidate_users.iterrows():
            candidate_uid = candidate.get('uid', candidate.get('user_id'))
            
            # Skip if already swiped
            if use_swipe_logs and candidate_uid in swiped_users:
                continue
            
            # Calculate compatibility score
            score = match_score(current_user, candidate.to_dict())
            
            matches.append({
                'user_id': candidate_uid,
                'uid': candidate_uid,
                'name': candidate.get('username', candidate.get('name', 'Unknown')),
                'age': candidate.get('age', 0),
                'gender': candidate.get('gender', ''),
                'location': candidate.get('location', ''),
                'score': score,
                'timestamp': datetime.now()
            })
        
        # Convert to DataFrame and sort by score
        matches_df = pd.DataFrame(matches)
        if matches_df.empty:
            logger.warning(f"No matches found for user {user_id}")
            return pd.DataFrame()
        
        # Sort by score and return top N
        matches_df = matches_df.sort_values('score', ascending=False).head(top_n)
        matches_df.reset_index(drop=True, inplace=True)
        
        logger.info(f"Found {len(matches_df)} matches for user {user_id}")
        return matches_df
        
    except Exception as e:
        logger.error(f"Error getting top matches for {user_id}: {e}")
        return pd.DataFrame()


def prepare_candidate_pool(user_id: str, top_n: int = 50) -> pd.DataFrame:
    """
    Prepare candidate pool for a specific user with real-time Firebase data
    
    Args:
        user_id: User ID to prepare candidates for
        top_n: Number of candidates to prepare
        
    Returns:
        DataFrame with candidate matches
    """
    try:
        logger.info(f"Preparing candidate pool for user {user_id}")
        
        # Get top matches using Firebase data
        matches_df = get_top_matches(user_id, top_n=top_n, use_swipe_logs=True)
        
        if matches_df.empty:
            logger.warning(f"No candidates found for user {user_id}")
            return pd.DataFrame()
        
        logger.info(f"Candidate pool prepared: {len(matches_df)} candidates for user {user_id}")
        return matches_df
        
    except Exception as e:
        logger.error(f"Failed to prepare candidate pool for {user_id}: {e}")
        return pd.DataFrame()


def get_user_compatibility_scores(user_id: str, target_user_ids: List[str]) -> Dict[str, float]:
    """
    Get compatibility scores between a user and specific target users
    
    Args:
        user_id: Source user ID
        target_user_ids: List of target user IDs to score
        
    Returns:
        Dictionary mapping target user IDs to compatibility scores
    """
    try:
        firebase_service = get_firebase_service()
        if not firebase_service.is_connected():
            return {}
        
        # Get current user data
        current_user = firebase_service.get_user_by_id(user_id)
        if not current_user:
            return {}
        
        scores = {}
        for target_id in target_user_ids:
            target_user = firebase_service.get_user_by_id(target_id)
            if target_user:
                score = match_score(current_user, target_user)
                scores[target_id] = score
        
        return scores
        
    except Exception as e:
        logger.error(f"Error getting compatibility scores: {e}")
        return {}


# -----------------------------------------
# Standalone test mode
# -----------------------------------------
if __name__ == "__main__":
    # Test with a sample user ID
    test_user_id = "test_user_123"
    matches = get_top_matches(test_user_id, top_n=10)
    print("Top matches:")
    print(matches.head() if not matches.empty else "No matches found")