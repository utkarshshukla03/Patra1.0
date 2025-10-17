"""
bio_match.py
-----------------
Handles semantic similarity and bio-based user matching using transformer embeddings.
Updated to work with Firebase real-time data.

Responsibilities:
- Load and cache the SentenceTransformer model
- Compute cosine similarity between user bios
- Return top similar bios for a given user using Firebase data
"""

import pandas as pd
from sentence_transformers import SentenceTransformer
from sklearn.metrics.pairwise import cosine_similarity
from functools import lru_cache
from typing import Optional
from production.firebase_service import get_firebase_service
from production.logger import get_logger

logger = get_logger(__name__)

# ==========================================================
# MODEL MANAGEMENT
# ==========================================================
@lru_cache(maxsize=1)
def get_model(model_name: str = "all-MiniLM-L6-v2") -> SentenceTransformer:
    """
    Load and cache the sentence transformer model for embedding bios.
    """
    print(f"[bio_match] Loading model: {model_name}")
    return SentenceTransformer(model_name)


# ==========================================================
# CORE FUNCTIONS
# ==========================================================
def bio_similarity(
    bio_a: str,
    bio_b: str,
    model: Optional[SentenceTransformer] = None
) -> float:
    """
    Compute cosine similarity between two bios.

    Args:
        bio_a (str): First bio text.
        bio_b (str): Second bio text.
        model (SentenceTransformer, optional): Preloaded model.

    Returns:
        float: Cosine similarity between bio embeddings.
    """
    if model is None:
        model = get_model()

    embeddings = model.encode([bio_a, bio_b])
    similarity = cosine_similarity([embeddings[0]], [embeddings[1]])[0][0]
    return float(similarity)


def top_similar_bios(
    users_df: pd.DataFrame,
    target_user_id: str,
    top_n: int = 10,
    model: Optional[SentenceTransformer] = None
) -> pd.DataFrame:
    """
    Find top N users whose bios are semantically similar to the target user.

    Args:
        users_df (pd.DataFrame): DataFrame with columns ['user_id', 'bio'].
        target_user_id (str): User ID of the target user.
        top_n (int): Number of similar users to return.
        model (SentenceTransformer, optional): Preloaded model.

    Returns:
        pd.DataFrame: DataFrame with ['user_id', 'bio', 'similarity'].
    """
    if model is None:
        model = get_model()

    if not {"user_id", "bio"}.issubset(users_df.columns):
        raise ValueError("DataFrame must contain 'user_id' and 'bio' columns.")

    # Encode all bios
    bios = users_df["bio"].fillna("").tolist()
    bio_embeddings = model.encode(bios, convert_to_numpy=True)

    # Get target user embedding
    if target_user_id not in users_df["user_id"].values:
        raise ValueError(f"User {target_user_id} not found in dataset.")

    target_idx = users_df.index[users_df["user_id"] == target_user_id][0]
    target_emb = bio_embeddings[target_idx]

    # Compute similarities
    similarities = cosine_similarity([target_emb], bio_embeddings)[0]
    similarities[target_idx] = -1  # Exclude self-match

    # Get top N similar users
    top_indices = similarities.argsort()[::-1][:top_n]

    # Prepare and return results
    results = users_df.iloc[top_indices].copy()
    results["similarity"] = similarities[top_indices]

    return results[["user_id", "bio", "similarity"]]


def top_similar_bios_firebase(
    target_user_id: str,
    top_n: int = 10,
    model: Optional[SentenceTransformer] = None
) -> pd.DataFrame:
    """
    Find top N users whose bios are semantically similar to the target user using Firebase data.

    Args:
        target_user_id (str): User ID of the target user.
        top_n (int): Number of similar users to return.
        model (SentenceTransformer, optional): Preloaded model.

    Returns:
        pd.DataFrame: DataFrame with ['user_id', 'bio', 'similarity'].
    """
    try:
        firebase_service = get_firebase_service()
        if not firebase_service.is_connected():
            logger.error("Firebase not connected - cannot perform bio matching")
            return pd.DataFrame()
        
        # Get all users from Firebase
        users_df = firebase_service.get_all_users()
        if users_df.empty:
            logger.warning("No users found in Firebase")
            return pd.DataFrame()
        
        # Ensure required columns exist
        if 'bio' not in users_df.columns:
            logger.warning("Bio column not found in user data")
            users_df['bio'] = ""  # Add empty bio column
        
        # Use the existing function with Firebase data
        # Rename 'id' column to 'user_id' for compatibility
        if 'id' in users_df.columns and 'user_id' not in users_df.columns:
            users_df = users_df.rename(columns={'id': 'user_id'})
        
        return top_similar_bios(users_df, target_user_id, top_n, model)
        
    except Exception as e:
        logger.error(f"Error in Firebase bio matching: {e}")
        return pd.DataFrame()


# ==========================================================
# EXAMPLE USAGE (for testing)
# ==========================================================
if __name__ == "__main__":
    from data import load_user_data  # <-- Example integration point

    df = load_user_data()
    user_id = "U001"

    print(f"\nTop bios similar to user {user_id}:")
    similar_bios = top_similar_bios(df, user_id, top_n=5)
    print(similar_bios)
