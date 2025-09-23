#!/usr/bin/env python3
"""
🔍 ML Recommendations Diagnostic Tool
This script helps debug why ML recommendations are returning 0 results
"""

import sys
import os
import json
sys.path.append(os.path.dirname(os.path.abspath(__file__)))

# Import the ML service functions
from reject_superlike_like import users, swipe_logs, get_top_matches, match_score

def diagnose_user_recommendations(user_uid, verbose=True):
    """Diagnose why a specific user gets 0 ML recommendations"""
    
    print(f"🔍 DIAGNOSING ML RECOMMENDATIONS FOR USER: {user_uid}")
    print("=" * 70)
    
    # Step 1: Check if user exists
    user_row = users[users['uid'] == user_uid]
    if user_row.empty:
        print(f"❌ PROBLEM: User with UID {user_uid} not found in database")
        print(f"📊 Total users in database: {len(users)}")
        print(f"💡 Available UIDs (first 5): {list(users['uid'].head())}")
        return False
    
    user_data = user_row.iloc[0].to_dict()
    print(f"✅ User found: {user_data.get('username', 'Unknown')}")
    print(f"   Gender: {user_data.get('gender', 'Unknown')}")
    print(f"   Age: {user_data.get('age', 'Unknown')}")
    print(f"   Location: {user_data.get('location', 'Unknown')}")
    print(f"   Orientation: {user_data.get('orientation', [])}")
    print(f"   Interests: {user_data.get('interests', [])}")
    
    # Step 2: Check swipe history
    user_swipes = swipe_logs[swipe_logs['user_id'] == user_uid]
    print(f"\n📊 SWIPE HISTORY:")
    print(f"   Total swipes by user: {len(user_swipes)}")
    
    if not user_swipes.empty:
        swipe_summary = user_swipes['action'].value_counts()
        for action, count in swipe_summary.items():
            print(f"   {action.title()}: {count}")
        
        # Show recent swipes
        if verbose and len(user_swipes) > 0:
            print(f"\n📝 Recent swipes:")
            recent_swipes = user_swipes.tail(5)
            for _, swipe in recent_swipes.iterrows():
                target_user = users[users['uid'] == swipe['target_user_id']]
                target_name = target_user.iloc[0]['username'] if not target_user.empty else 'Unknown'
                print(f"   {swipe['action'].title()} → {target_name} ({swipe['target_user_id'][:8]}...)")
    else:
        print("   No swipes found for this user")
    
    # Step 3: Check potential candidates
    print(f"\n🎯 CANDIDATE ANALYSIS:")
    total_users = len(users)
    potential_candidates = users[users['uid'] != user_uid]  # Exclude self
    print(f"   Total potential candidates: {len(potential_candidates)}")
    
    # Check rejected users
    rejected_uids = set()
    if not user_swipes.empty:
        rejected_uids = set(user_swipes[user_swipes['action'] == 'reject']['target_user_id'])
    print(f"   Previously rejected: {len(rejected_uids)}")
    
    # Check remaining candidates
    remaining_candidates = potential_candidates[~potential_candidates['uid'].isin(rejected_uids)]
    print(f"   Remaining candidates: {len(remaining_candidates)}")
    
    # Step 4: Analyze gender/orientation filtering
    user_gender = user_data.get('gender', '').lower()
    user_orientation = user_data.get('orientation', [])
    
    print(f"\n🔍 ORIENTATION FILTERING:")
    print(f"   User gender: {user_gender}")
    print(f"   User orientation: {user_orientation}")
    
    if user_orientation and len(user_orientation) > 0:
        print("   Applying orientation filter...")
        orientation_filtered = 0
        for _, candidate in remaining_candidates.iterrows():
            candidate_gender = candidate.get('gender', '').lower()
            if any(str(orient).lower() in candidate_gender for orient in user_orientation):
                orientation_filtered += 1
        print(f"   Candidates after orientation filter: {orientation_filtered}")
    else:
        print("   No orientation filter applied (empty orientation)")
    
    # Step 5: Test the actual matching function
    print(f"\n🧪 TESTING MATCH FUNCTION:")
    try:
        matches = get_top_matches(user_uid, top_n=10)
        print(f"   get_top_matches returned: {len(matches)} matches")
        
        if matches:
            print(f"\n✅ TOP MATCHES FOUND:")
            for i, match in enumerate(matches[:5], 1):
                print(f"   {i}. {match[1]} ({match[0][:8]}...) - Score: {match[3]:.3f}")
        else:
            print(f"\n❌ NO MATCHES RETURNED")
            
            # Let's try to find out why
            print(f"\n🔧 DEBUGGING EMPTY RESULTS:")
            
            # Manual scoring of a few candidates
            if len(remaining_candidates) > 0:
                print(f"   Testing match scores with first 5 candidates:")
                for i, (_, candidate) in enumerate(remaining_candidates.head().iterrows()):
                    score = match_score(user_data, candidate.to_dict())
                    print(f"   → {candidate.get('username', 'Unknown')}: {score:.3f}")
            
    except Exception as e:
        print(f"❌ Error in match function: {e}")
        import traceback
        traceback.print_exc()
    
    # Step 6: Recommendations
    print(f"\n💡 RECOMMENDATIONS:")
    
    if len(remaining_candidates) == 0:
        print("   → User has rejected all available candidates")
        print("   → Consider refreshing/expanding the user pool")
        print("   → Or allow showing previously rejected users with lower priority")
    
    elif not user_orientation or len(user_orientation) == 0:
        print("   → User has no orientation preferences set")
        print("   → This might cause filtering issues")
        print("   → Consider setting default orientation or updating user profile")
    
    else:
        print("   → Check orientation compatibility logic")
        print("   → Verify match_score function weights")
        print("   → Consider lowering minimum score threshold")
    
    return True

def main():
    """Main diagnostic function"""
    if len(sys.argv) < 2:
        print("Usage: python diagnose_ml.py <user_uid>")
        print("\nAvailable user UIDs:")
        for uid in users['uid'].head(10):
            user = users[users['uid'] == uid].iloc[0]
            print(f"  {uid} - {user.get('username', 'Unknown')}")
        return
    
    user_uid = sys.argv[1]
    diagnose_user_recommendations(user_uid)

if __name__ == "__main__":
    main()