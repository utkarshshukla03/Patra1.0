"""
Test ML Backend Connection from Flutter
This script simulates what the Flutter app will do
"""

import requests
import json

# Configuration
BACKEND_URL = "http://localhost:5000"
TEST_USER_ID = "test_flutter_user_123"

def test_health():
    """Test if backend is healthy"""
    try:
        response = requests.get(f"{BACKEND_URL}/health")
        print(f"🏥 Health Check: {response.status_code}")
        if response.status_code == 200:
            data = response.json()
            print(f"   Status: {data['status']}")
            print(f"   Version: {data['version']}")
            return True
        return False
    except Exception as e:
        print(f"❌ Health check failed: {e}")
        return False

def test_recommendations():
    """Test recommendations endpoint"""
    try:
        response = requests.get(f"{BACKEND_URL}/recommend/{TEST_USER_ID}?top_n=5")
        print(f"🎯 Recommendations: {response.status_code}")
        if response.status_code == 200:
            data = response.json()
            recommendations = data.get('recommendations', [])
            print(f"   Got {len(recommendations)} recommendations")
            for i, rec in enumerate(recommendations[:3]):
                print(f"   {i+1}. User: {rec['user_id']}, Score: {rec['score']:.2f}")
            return True
        else:
            print(f"   Error: {response.text}")
        return False
    except Exception as e:
        print(f"❌ Recommendations failed: {e}")
        return False

def test_record_swipe():
    """Test swipe recording"""
    try:
        data = {
            "user_id": TEST_USER_ID,
            "target_user_id": "target_user_456",
            "action": "like"
        }
        response = requests.post(
            f"{BACKEND_URL}/record_interaction",
            headers={"Content-Type": "application/json"},
            data=json.dumps(data)
        )
        print(f"👆 Record Swipe: {response.status_code}")
        if response.status_code == 200:
            result = response.json()
            print(f"   Success: {result['success']}")
            print(f"   Message: {result['message']}")
            return True
        else:
            print(f"   Error: {response.text}")
        return False
    except Exception as e:
        print(f"❌ Record swipe failed: {e}")
        return False

def main():
    print("🔗 Testing Flutter → ML Backend Connection")
    print("=" * 50)
    
    tests = [
        ("Health Check", test_health),
        ("Get Recommendations", test_recommendations), 
        ("Record Swipe Action", test_record_swipe)
    ]
    
    all_passed = True
    for test_name, test_func in tests:
        print(f"\n🧪 {test_name}...")
        if not test_func():
            all_passed = False
    
    print("\n" + "=" * 50)
    if all_passed:
        print("✅ ALL TESTS PASSED!")
        print("🎉 Your Flutter app can now connect to the ML backend!")
        print("\n📱 Next steps:")
        print("1. Run your Flutter app")
        print("2. Open the homepage - it will fetch ML recommendations")
        print("3. Swipe on profiles - actions will be sent to ML backend")
        print("4. Check analytics to see the ML learning in action")
    else:
        print("❌ Some tests failed - check the backend logs")

if __name__ == "__main__":
    main()