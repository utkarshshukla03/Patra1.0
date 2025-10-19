"""
Test script to verify ML Backend integration with Flutter app
"""

import requests
import json
import time

# Configuration
ML_BACKEND_URL = "http://localhost:5000"
TEST_USER_ID = "test_user_123"
TEST_TARGET_ID = "test_target_456"

def test_health():
    """Test if ML backend is running"""
    try:
        response = requests.get(f"{ML_BACKEND_URL}/health")
        if response.status_code == 200:
            print("✅ ML Backend is healthy")
            print(f"   Response: {response.json()}")
            return True
        else:
            print(f"❌ Health check failed: {response.status_code}")
            return False
    except Exception as e:
        print(f"❌ Cannot connect to ML backend: {e}")
        return False

def test_recommendations():
    """Test recommendation endpoint"""
    try:
        response = requests.get(f"{ML_BACKEND_URL}/recommend/{TEST_USER_ID}?top_n=5")
        if response.status_code == 200:
            data = response.json()
            print("✅ Recommendations working")
            print(f"   Got {len(data.get('recommendations', []))} recommendations")
            print(f"   Sample: {data.get('recommendations', [])[:2]}")
            return True
        else:
            print(f"❌ Recommendations failed: {response.status_code}")
            print(f"   Response: {response.text}")
            return False
    except Exception as e:
        print(f"❌ Recommendations error: {e}")
        return False

def test_record_interaction():
    """Test interaction recording"""
    try:
        data = {
            "user_id": TEST_USER_ID,
            "target_user_id": TEST_TARGET_ID,
            "action": "like"
        }
        response = requests.post(
            f"{ML_BACKEND_URL}/record_interaction",
            headers={"Content-Type": "application/json"},
            data=json.dumps(data)
        )
        if response.status_code == 200:
            print("✅ Interaction recording working")
            print(f"   Response: {response.json()}")
            return True
        else:
            print(f"❌ Interaction recording failed: {response.status_code}")
            print(f"   Response: {response.text}")
            return False
    except Exception as e:
        print(f"❌ Interaction recording error: {e}")
        return False

def test_user_stats():
    """Test user stats endpoint"""
    try:
        response = requests.get(f"{ML_BACKEND_URL}/user_stats/{TEST_USER_ID}")
        if response.status_code == 200:
            data = response.json()
            print("✅ User stats working")
            print(f"   Elo rating: {data.get('elo_rating', 'N/A')}")
            print(f"   Total swipes: {data.get('swipe_stats', {}).get('total_swipes', 'N/A')}")
            return True
        else:
            print(f"❌ User stats failed: {response.status_code}")
            print(f"   Response: {response.text}")
            return False
    except Exception as e:
        print(f"❌ User stats error: {e}")
        return False

def main():
    """Run all tests"""
    print("🧪 Testing Patra ML Backend Integration")
    print("=" * 50)
    
    tests = [
        ("Health Check", test_health),
        ("Recommendations", test_recommendations),
        ("Record Interaction", test_record_interaction),
        ("User Stats", test_user_stats),
    ]
    
    passed = 0
    total = len(tests)
    
    for test_name, test_func in tests:
        print(f"\n🔍 Testing {test_name}...")
        if test_func():
            passed += 1
        time.sleep(1)  # Small delay between tests
    
    print("\n" + "=" * 50)
    print(f"📊 Test Results: {passed}/{total} tests passed")
    
    if passed == total:
        print("🎉 All tests passed! ML Backend integration is working!")
        print("\n🚀 Next steps:")
        print("1. Run your Flutter app")
        print("2. Open homepage to see ML-ordered profiles")
        print("3. Swipe on profiles to train the algorithm")
        print("4. Check analytics to see improvements")
    else:
        print("⚠️  Some tests failed. Check the ML backend setup.")
        print("\n🔧 Troubleshooting:")
        print("1. Ensure ML backend is running: python api_server.py")
        print("2. Check Firebase credentials are set up")
        print("3. Verify all dependencies are installed")

if __name__ == "__main__":
    main()