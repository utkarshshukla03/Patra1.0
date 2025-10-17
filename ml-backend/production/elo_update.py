"""
elo_update.py
-------------
Purpose:
    Maintain and update dynamic Elo ratings for users based on interactions
    (like / superlike / reject). Works in tandem with recommender and
    interaction modules. Updated to use Firebase real-time data.

Integration Order:
    Runs AFTER:
        - reject_superlike_like.py (user actions)
    BEFORE:
        - recommender.py (to influence ranking)
"""

import pandas as pd
from functools import lru_cache
from production.config_loader import load_config
from production.logger import get_logger
from production.firebase_service import get_firebase_service

# -------------------- INIT --------------------
logger = get_logger(__name__)
config = load_config()
firebase_service = get_firebase_service()

K = config.get("elo_k", 32)

# Default action scoring
ACTION_SCORES = {
    "like": (1, 0),
    "superlike": (1, 0),
    "reject": (0, 1)
}


# -------------------- HELPER FUNCTIONS --------------------
def expected_score(rating_a: float, rating_b: float) -> float:
    """Elo expected score of player A vs B."""
    return 1 / (1 + 10 ** ((rating_b - rating_a) / 400))


def update_elo_score(rating_a: float, rating_b: float, score_a: float, score_b: float, k: float = K):
    """Compute new Elo ratings for two users."""
    exp_a = expected_score(rating_a, rating_b)
    exp_b = expected_score(rating_b, rating_a)
    new_a = rating_a + k * (score_a - exp_a)
    new_b = rating_b + k * (score_b - exp_b)
    return new_a, new_b


# -------------------- DATA LOADING --------------------
def load_users() -> pd.DataFrame:
    """Load users from Firebase and ensure Elo column exists."""
    try:
        if not firebase_service.is_connected():
            logger.error("Firebase not connected")
            return pd.DataFrame()
        
        users = firebase_service.get_all_users()
        if users.empty:
            return pd.DataFrame()
        
        # Ensure required columns exist
        if "elo_score" not in users.columns:
            users["elo_score"] = 1200  # default Elo
        if "id" not in users.columns:
            raise ValueError("Firebase users must contain 'id' field.")
        
        # Rename for compatibility
        users = users.rename(columns={'id': 'user_id', 'elo_score': 'elo'})
        return users
        
    except Exception as e:
        logger.error(f"Error loading users from Firebase: {e}")
        return pd.DataFrame()


# -------------------- CORE FUNCTIONS --------------------
def process_interaction(user_id: str, target_id: str, action: str):
    """
    Update Elo ratings for two users based on a single interaction using Firebase.

    Args:
        user_id: Active user performing the action.
        target_id: Target user receiving the action.
        action: Action type (like, superlike, reject).
    """
    # Use the Firebase version
    process_interaction_firebase(user_id, target_id, action)


def get_elo_scores() -> pd.DataFrame:
    """Return current Elo scores for all users from Firebase."""
    return get_elo_scores_firebase()


def process_interaction_firebase(user_id: str, target_id: str, action: str):
    """
    Update Elo ratings for two users based on a single interaction using Firebase.

    Args:
        user_id: Active user performing the action.
        target_id: Target user receiving the action.
        action: Action type (like, superlike, reject).
    """
    try:
        if not firebase_service.is_connected():
            logger.error("Firebase not connected - cannot update Elo scores")
            return
        
        # Get current Elo scores
        user_elo = firebase_service.get_user_elo_score(user_id)
        target_elo = firebase_service.get_user_elo_score(target_id)
        
        if user_elo is None or target_elo is None:
            logger.warning(f"Could not get Elo scores for users {user_id}, {target_id}")
            return
        
        # Determine scores
        Sa, Sb = ACTION_SCORES.get(action.lower(), (0, 0))
        
        # Update Elo
        new_user_elo, new_target_elo = update_elo_score(user_elo, target_elo, Sa, Sb)
        
        # Save updated Elo ratings to Firebase
        firebase_service.update_user_elo_score(user_id, new_user_elo)
        firebase_service.update_user_elo_score(target_id, new_target_elo)
        
        logger.info(f"Updated Elo → {user_id}: {new_user_elo:.1f}, {target_id}: {new_target_elo:.1f}")
        
    except Exception as e:
        logger.error(f"Error updating Elo scores: {e}")


def get_elo_scores_firebase() -> pd.DataFrame:
    """Return current Elo scores for all users from Firebase."""
    try:
        if not firebase_service.is_connected():
            logger.error("Firebase not connected")
            return pd.DataFrame()
        
        users_df = firebase_service.get_all_users()
        if users_df.empty:
            return pd.DataFrame()
        
        # Ensure elo_score column exists
        if 'elo_score' not in users_df.columns:
            users_df['elo_score'] = 1200  # Default Elo
        
        # Return with consistent column names
        result_df = users_df[['id', 'elo_score']].copy()
        result_df = result_df.rename(columns={'id': 'user_id', 'elo_score': 'elo'})
        
        return result_df
        
    except Exception as e:
        logger.error(f"Error getting Elo scores from Firebase: {e}")
        return pd.DataFrame()


# -------------------- STANDALONE TEST --------------------
if __name__ == "__main__":
    process_interaction("U001", "U002", "like")
    print(get_elo_scores().head(10))
