"""
reject_superlike_like.py
------------------------
Purpose:
    Adjusts recommendation candidate scores based on past swipe interactions
    (like / superlike / reject). This helps the recommender personalize the
    feed using learned user preferences.

Integration Order:
    Runs AFTER:
        - data_match.py
        - bio_match.py
    BEFORE:
        - elo_update.py
        - recommender.py

Updated to use Firebase real-time data instead of CSV files.
"""

import pandas as pd
import numpy as np
from functools import lru_cache
from typing import Dict, List, Optional
from production.logger import get_logger
from production.config_loader import load_config
from production.firebase_service import get_firebase_service

# -------------------- INIT --------------------
logger = get_logger(__name__)
config = load_config()
firebase_service = get_firebase_service()

# Default interaction weight configuration
ACTION_WEIGHTS = {
    "superlike": 3.0,
    "like": 2.0,
    "reject": 0.0
}

DEFAULT_WEIGHT = 1.0


# -------------------- SBERT MODEL --------------------
def get_sbert_model():
    """
    Get SBERT model for semantic similarity matching.
    This is a placeholder function - SBERT integration can be added later.
    
    Returns:
        None for now (placeholder)
    """
    logger.info("SBERT model requested - using placeholder for now")
    return None


# -------------------- LOADERS --------------------
def load_users() -> pd.DataFrame:
    """Load user profiles from Firebase."""
    try:
        if not firebase_service.is_connected():
            logger.error("Firebase not connected")
            return pd.DataFrame()
        
        users_df = firebase_service.get_all_users()
        logger.info(f"Loaded {len(users_df)} users from Firebase")
        return users_df
    except Exception as e:
        logger.error(f"Error loading users from Firebase: {e}")
        return pd.DataFrame()


def load_swipe_logs(user_id: Optional[str] = None, days_back: int = 365) -> pd.DataFrame:
    """
    Load swipe interaction logs from Firebase.
    
    Args:
        user_id: If provided, only get logs for this user
        days_back: Number of days to look back
    """
    try:
        if not firebase_service.is_connected():
            logger.error("Firebase not connected")
            return pd.DataFrame()
        
        if user_id:
            # Get interactions for specific user
            interactions_df = firebase_service.get_user_interactions(user_id, days_back)
            # Rename columns to match expected format
            if not interactions_df.empty:
                interactions_df = interactions_df.rename(columns={
                    'target_id': 'target_user_id'
                })
        else:
            # Get all swipe data
            interactions_df = firebase_service.get_swipe_data(days_back)
            if not interactions_df.empty:
                interactions_df = interactions_df.rename(columns={
                    'target_id': 'target_user_id'
                })
        
        logger.info(f"Loaded {len(interactions_df)} interactions from Firebase")
        return interactions_df
    except Exception as e:
        logger.error(f"Error loading swipe logs from Firebase: {e}")
        return pd.DataFrame(columns=["user_id", "target_user_id", "action"])


# -------------------- CORE FUNCTIONS --------------------
def get_interaction_weight(action: str) -> float:
    """Return the weight multiplier for a given action."""
    return ACTION_WEIGHTS.get(action.lower(), DEFAULT_WEIGHT)


def adjust_candidate_scores(user_id: str, candidates_df: pd.DataFrame) -> pd.DataFrame:
    """
    Adjusts candidate scores based on user’s past interactions.

    Args:
        user_id: The active user's ID.
        candidates_df: DataFrame containing columns ['user_id', 'score'] from recommender/data_match.

    Returns:
        DataFrame with added column ['interaction_weight'] and adjusted 'score'.
    """
    users = load_users()
    
    if users.empty:
        logger.warning("No users loaded from Firebase")
        return candidates_df

    # Check if user exists (use 'id' column from Firebase)
    if user_id not in users["id"].values:
        logger.warning(f"User {user_id} not found in Firebase users collection.")
        return candidates_df

    # Get user's swipe history from Firebase
    user_swipes = load_swipe_logs(user_id, days_back=365)

    # Initialize weights
    candidates_df["interaction_weight"] = DEFAULT_WEIGHT

    for idx, row in candidates_df.iterrows():
        target_id = row["user_id"]
        previous_action = user_swipes[user_swipes["target_user_id"] == target_id]

        if not previous_action.empty:
            action = previous_action.iloc[-1]["action"]  # Get most recent action
            weight = get_interaction_weight(action)
            candidates_df.at[idx, "interaction_weight"] = weight

            # Optional: downweight rejects entirely
            if action.lower() == "reject":
                candidates_df.at[idx, "score"] = 0.0
            else:
                candidates_df.at[idx, "score"] *= weight

    logger.info(f"Adjusted candidate scores for user {user_id} based on Firebase swipe logs.")
    return candidates_df.sort_values(by="score", ascending=False).reset_index(drop=True)


# -------------------- UPDATE LOGS --------------------
def update_user_interactions(user_id: str, target_user_id: str, action: str):
    """
    Log a new interaction (like/superlike/reject) to Firebase.
    
    Args:
        user_id: ID of user performing action
        target_user_id: ID of target user
        action: Action performed (like, dislike, superlike)
    """
    try:
        if not firebase_service.is_connected():
            logger.error("Firebase not connected - cannot save interaction")
            return False
        
        success = firebase_service.save_interaction(user_id, target_user_id, action.lower())
        
        if success:
            logger.info(f"User {user_id} performed '{action}' on {target_user_id} - saved to Firebase.")
        else:
            logger.error(f"Failed to save interaction: {user_id} -> {target_user_id} ({action})")
        
        return success
    except Exception as e:
        logger.error(f"Error saving interaction to Firebase: {e}")
        return False


# -------------------- STANDALONE TEST --------------------
if __name__ == "__main__":
    test_user_id = "U001"
    # Dummy candidate scores (normally output of recommender)
    dummy_candidates = pd.DataFrame({
        "user_id": ["U002", "U003", "U004"],
        "score": [0.75, 0.60, 0.55]
    })

    print("Before adjustment:\n", dummy_candidates)
    adjusted = adjust_candidate_scores(test_user_id, dummy_candidates)
    print("\nAfter adjustment:\n", adjusted)
