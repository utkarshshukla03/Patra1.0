"""
Firebase-based Recommender Module
Generates ML recommendations directly from Firebase data
"""

import pandas as pd
import numpy as np
from typing import List, Dict
from production.logger import get_logger
from production.config_loader import load_config

logger = get_logger(__name__)
config = load_config()

def get_recommendations_from_firebase(user_id: str, candidates_df: pd.DataFrame, top_n: int = 10) -> List[Dict]:
    """
    Generate recommendations from Firebase data using ML algorithms
    
    Args:
        user_id: Target user ID
        candidates_df: DataFrame of candidate users
        top_n: Number of recommendations to return
    
    Returns:
        List of recommended users with scores
    """
    try:
        if candidates_df.empty:
            return []
        
        # Get user preferences (this could be enhanced with more ML)
        current_user = candidates_df[candidates_df['user_id'] == user_id].iloc[0] if not candidates_df[candidates_df['user_id'] == user_id].empty else None
        
        recommendations = []
        
        for _, candidate in candidates_df.iterrows():
            if candidate['user_id'] == user_id:
                continue
                
            # Calculate recommendation score
            score = calculate_compatibility_score(current_user, candidate)
            
            recommendation = {
                'user_id': candidate['user_id'],
                'name': candidate['name'],
                'age': candidate['age'],
                'location': candidate['location'],
                'bio': candidate['bio'],
                'photos': candidate['photos'],
                'elo_score': candidate['elo_score'],
                'compatibility_score': score,
                'profile_completeness': candidate['profile_completeness']
            }
            
            recommendations.append(recommendation)
        
        # Sort by compatibility score and return top N
        recommendations.sort(key=lambda x: x['compatibility_score'], reverse=True)
        return recommendations[:top_n]
        
    except Exception as e:
        logger.error(f"Error generating recommendations: {e}")
        return []

def calculate_compatibility_score(current_user: pd.Series, candidate: pd.Series) -> float:
    """
    Calculate compatibility score between two users
    
    Args:
        current_user: Current user data
        candidate: Candidate user data
    
    Returns:
        Compatibility score (0-100)
    """
    try:
        score = 0.0
        
        # Base score from Elo rating
        elo_score = candidate.get('elo_score', 1200) / 1200.0 * 30  # Max 30 points from Elo
        score += elo_score
        
        # Age compatibility (prefer similar ages)
        if current_user is not None:
            current_age = current_user.get('age', 25)
            candidate_age = candidate.get('age', 25)
            age_diff = abs(current_age - candidate_age)
            age_score = max(0, 20 - age_diff)  # Max 20 points for age compatibility
            score += age_score
        else:
            score += 15  # Default age score
        
        # Profile completeness bonus
        completeness = candidate.get('profile_completeness', 0.5)
        completeness_score = completeness * 20  # Max 20 points for complete profile
        score += completeness_score
        
        # Bio quality (longer bio = higher score)
        bio = candidate.get('bio', '')
        bio_length = len(bio) if bio else 0
        bio_score = min(bio_length / 50.0 * 15, 15)  # Max 15 points for bio
        score += bio_score
        
        # Photo bonus
        photos = candidate.get('photos', [])
        photo_count = len(photos) if photos else 0
        photo_score = min(photo_count * 3, 15)  # Max 15 points for photos
        score += photo_score
        
        # Add some randomness to avoid always showing the same order
        randomness = np.random.uniform(-5, 5)
        score += randomness
        
        return round(max(0, min(100, score)), 2)
        
    except Exception as e:
        logger.error(f"Error calculating compatibility score: {e}")
        return 50.0  # Default score

def calculate_bio_similarity(bio1: str, bio2: str) -> float:
    """
    Calculate similarity between two bios using simple keyword matching
    
    Args:
        bio1: First bio
        bio2: Second bio
    
    Returns:
        Similarity score (0-1)
    """
    try:
        if not bio1 or not bio2:
            return 0.0
        
        # Simple keyword matching (can be enhanced with NLP)
        words1 = set(bio1.lower().split())
        words2 = set(bio2.lower().split())
        
        if not words1 or not words2:
            return 0.0
        
        intersection = words1.intersection(words2)
        union = words1.union(words2)
        
        return len(intersection) / len(union) if union else 0.0
        
    except Exception as e:
        logger.error(f"Error calculating bio similarity: {e}")
        return 0.0

def calculate_interest_similarity(interests1: str, interests2: str) -> float:
    """
    Calculate similarity between interests
    
    Args:
        interests1: First user's interests (comma-separated)
        interests2: Second user's interests (comma-separated)
    
    Returns:
        Similarity score (0-1)
    """
    try:
        if not interests1 or not interests2:
            return 0.0
        
        # Convert comma-separated interests to sets
        int1 = set(interest.strip().lower() for interest in interests1.split(','))
        int2 = set(interest.strip().lower() for interest in interests2.split(','))
        
        if not int1 or not int2:
            return 0.0
        
        intersection = int1.intersection(int2)
        union = int1.union(int2)
        
        return len(intersection) / len(union) if union else 0.0
        
    except Exception as e:
        logger.error(f"Error calculating interest similarity: {e}")
        return 0.0