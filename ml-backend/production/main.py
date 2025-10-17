"""
main.py
-------
Purpose:
    Central orchestrator for Patra ML backend with Firebase integration.
    Calls all modules in sequence to generate recommendations,
    apply interactions, update Elo, and provide final feed using real-time data.
"""

import argparse
import pandas as pd
from typing import Optional, List, Dict

from production.logger import get_logger
from production.firebase_service import get_firebase_service, initialize_firebase_service
from production.data_match_firebase import get_top_matches, prepare_candidate_pool
from production.bio_match import top_similar_bios_firebase
from production.reject_superlike_like import adjust_candidate_scores, update_user_interactions
from production.elo_update import process_interaction_firebase, get_elo_scores_firebase

# -------------------- INIT --------------------
logger = get_logger(__name__)

def initialize_firebase(service_account_path: Optional[str] = None):
    """Initialize Firebase service"""
    firebase_service = get_firebase_service()
    success = firebase_service.initialize(service_account_path)
    
    if not success:
        logger.error("Failed to connect to Firebase")
        return False
    
    logger.info("Firebase service initialized successfully")
    return True


# -------------------- CORE FUNCTIONS --------------------
def generate_user_feed(user_id: str, top_n: int = 10) -> pd.DataFrame:
    """
    Generate top recommendations for a given user using Firebase data.
    Combines base features, bio similarity, interaction weights, and Elo.
    """
    try:
        logger.info(f"Generating feed for user {user_id} (top {top_n})")
        
        # 1. Get base matches from Firebase
        base_matches = get_top_matches(user_id, top_n=top_n * 2, use_swipe_logs=True)
        if base_matches.empty:
            logger.warning(f"No base matches found for user {user_id}")
            return pd.DataFrame()
        
        # 2. Apply interaction weights (if implemented)
        try:
            weighted_matches = adjust_candidate_scores(user_id, base_matches)
        except:
            logger.warning("Interaction weighting not available, using base scores")
            weighted_matches = base_matches
        
        # 3. Apply Elo scores (if implemented)
        try:
            elo_enhanced = apply_elo_scores_firebase(weighted_matches)
        except:
            logger.warning("Elo scoring not available, using weighted scores")
            elo_enhanced = weighted_matches
        
        # 4. Final ranking and selection
        final_feed = elo_enhanced.head(top_n)
        final_feed = final_feed.rename(columns={'score': 'final_score'})
        
        logger.info(f"Generated feed with {len(final_feed)} recommendations for user {user_id}")
        return final_feed
        
    except Exception as e:
        logger.error(f"Error generating feed for user {user_id}: {e}")
        return pd.DataFrame()


def record_interaction(user_id: str, target_id: str, action: str) -> bool:
    """
    Record a user interaction and update Firebase accordingly.
    
    Args:
        user_id: ID of the user performing the action
        target_id: ID of the target user
        action: Type of action ('like', 'dislike', 'superlike')
        
    Returns:
        True if successful, False otherwise
    """
    try:
        logger.info(f"Recording interaction: {user_id} -> {target_id} ({action})")
        
        # Save interaction to Firebase
        firebase_service = get_firebase_service()
        success = firebase_service.save_interaction(user_id, target_id, action)
        
        if success:
            # Update Elo if available
            try:
                process_interaction_firebase(user_id, target_id, action)
            except:
                logger.warning("Elo update not available")
            
            # Update interaction weights if available
            try:
                update_user_interactions(user_id, target_id, action)
            except:
                logger.warning("Interaction weight update not available")
                
            logger.info(f"Successfully recorded interaction: {user_id} -> {target_id} ({action})")
            return True
        
        return False
        
    except Exception as e:
        logger.error(f"Error recording interaction: {e}")
        return False


def apply_elo_scores_firebase(matches_df: pd.DataFrame) -> pd.DataFrame:
    """
    Apply Elo scores to matches (placeholder implementation)
    
    Args:
        matches_df: DataFrame with match data
        
    Returns:
        DataFrame with Elo scores applied
    """
    try:
        # For now, just add a default Elo score
        matches_df = matches_df.copy()
        matches_df['elo_score'] = 1500  # Default Elo
        
        # Combine with existing score
        matches_df['final_score'] = (
            0.7 * matches_df['score'] + 
            0.3 * (matches_df['elo_score'] / 3000)  # Normalize Elo to 0-1 range
        )
        
        return matches_df.sort_values('final_score', ascending=False)
        
    except Exception as e:
        logger.error(f"Error applying Elo scores: {e}")
        return matches_df


def get_user_recommendations(user_id: str, count: int = 10) -> List[Dict]:
    """
    Get formatted recommendations for API response
    
    Args:
        user_id: User ID to get recommendations for
        count: Number of recommendations to return
        
    Returns:
        List of recommendation dictionaries
    """
    try:
        feed_df = generate_user_feed(user_id, top_n=count)
        
        if feed_df.empty:
            return []
        
        recommendations = []
        for idx, row in feed_df.iterrows():
            recommendations.append({
                'user_id': row['user_id'],
                'name': row.get('name', 'Unknown'),
                'gender': row.get('gender', ''),
                'score': float(row.get('final_score', row.get('score', 0))),
                'rank': idx + 1
            })
        
        return recommendations
        
    except Exception as e:
        logger.error(f"Error getting user recommendations: {e}")
        return []
    
    logger.info(f"Recorded interaction: {user_id} -> {target_id} [{action}]")


# -------------------- CLI / RUNNER --------------------
def main():
    parser = argparse.ArgumentParser(description="Patra ML Backend Main Orchestrator")
    parser.add_argument("--user_id", type=str, required=True, help="Active user ID")
    parser.add_argument("--top_n", type=int, default=None, help="Number of recommendations")
    parser.add_argument("--interact", nargs=2, metavar=("TARGET_ID", "ACTION"),
                        help="Optional: record an interaction (e.g., U002 like)")

    args = parser.parse_args()

    user_id = args.user_id

    # Record interaction if provided
    if args.interact:
        target_id, action = args.interact
        record_interaction(user_id, target_id, action)

    # Generate final feed
    feed = generate_user_feed(user_id, top_n=args.top_n)
    print("\nTop Recommendations:")
    print(feed.to_string(index=False))


# -------------------- ENTRY POINT --------------------
if __name__ == "__main__":
    main()
