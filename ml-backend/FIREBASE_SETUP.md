# Firebase Service Account Setup Instructions

## Step 1: Get Your Firebase Service Account Key

1. Go to [Firebase Console](https://console.firebase.google.com/)
2. Select your Patra project
3. Go to **Project Settings** (gear icon) → **Service Accounts**
4. Click **"Generate new private key"**
5. Download the JSON file

## Step 2: Add the Service Account Key

1. Rename the downloaded file to `firebase-service-account.json`
2. Place it in the `ml-backend` directory: `d:\app\Patra1.0\patra_initial\ml-backend\firebase-service-account.json`

## Step 3: Update Environment (Optional)

You can also set an environment variable:
```bash
set FIREBASE_SERVICE_ACCOUNT_PATH=d:\app\Patra1.0\patra_initial\ml-backend\firebase-service-account.json
```

## Step 4: Test the Connection

Run the ML backend API server to test:
```bash
cd d:\app\Patra1.0\patra_initial\ml-backend
python api_server.py
```

Then visit: http://localhost:5000/api/health

## Security Notes

- **Never commit the actual service account key to git**
- The `.gitignore` already excludes `firebase-service-account.json`
- Keep this file secure and don't share it publicly

## Firestore Database Structure Expected

The ML backend expects these Firestore collections:

### `users` collection:
```json
{
  "userId": "user123",
  "name": "John Doe",
  "age": 25,
  "location": {
    "latitude": 40.7128,
    "longitude": -74.0060
  },
  "interests": ["music", "travel", "food"],
  "gender": "male",
  "preferredGender": "female",
  "bio": "Love to travel and explore new places",
  "profilePictures": ["url1", "url2"],
  "createdAt": "timestamp",
  "lastActive": "timestamp"
}
```

### `swipes` collection:
```json
{
  "userId": "user123",
  "targetId": "user456",
  "action": "like",
  "timestamp": "timestamp"
}
```

### `interactions` collection:
```json
{
  "userId": "user123",
  "targetId": "user456",
  "action": "like",
  "timestamp": "timestamp",
  "isMatch": false
}
```

## Firebase Rules

Make sure your Firestore rules allow the service account to read/write:

```javascript
rules_version = '2';
service cloud.firestore {
  match /databases/{database}/documents {
    // Allow service account full access
    match /{document=**} {
      allow read, write: if true;
    }
  }
}
```

## Testing Firebase Connection

Once you add the service account key, you can test the connection:

```bash
cd ml-backend
python -c "from production.firebase_service import FirebaseService; fs = FirebaseService(); fs.initialize(); print('Connected:', fs.is_connected())"
```