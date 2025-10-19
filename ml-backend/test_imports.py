"""
Test script to verify package installations
"""

def test_imports():
    try:
        print("Testing basic imports...")
        
        # Test Flask
        try:
            import flask
            print("✅ Flask imported successfully")
        except ImportError as e:
            print(f"❌ Flask import failed: {e}")
            
        # Test pandas
        try:
            import pandas as pd
            print("✅ Pandas imported successfully")
        except ImportError as e:
            print(f"❌ Pandas import failed: {e}")
            
        # Test numpy
        try:
            import numpy as np
            print("✅ Numpy imported successfully")
        except ImportError as e:
            print(f"❌ Numpy import failed: {e}")
            
        # Test flask-cors
        try:
            from flask_cors import CORS
            print("✅ Flask-CORS imported successfully")
        except ImportError as e:
            print(f"❌ Flask-CORS import failed: {e}")
            
        print("\n🧪 Testing basic functionality...")
        
        # Test Flask app creation
        try:
            from flask import Flask, jsonify
            app = Flask(__name__)
            print("✅ Flask app creation works")
        except Exception as e:
            print(f"❌ Flask app creation failed: {e}")
            
        # Test pandas basic operation
        try:
            import pandas as pd
            df = pd.DataFrame({'test': [1, 2, 3]})
            print("✅ Pandas DataFrame creation works")
        except Exception as e:
            print(f"❌ Pandas DataFrame creation failed: {e}")
            
        print("\n🎉 All basic tests completed!")
        
    except Exception as e:
        print(f"❌ Unexpected error: {e}")

if __name__ == "__main__":
    test_imports()