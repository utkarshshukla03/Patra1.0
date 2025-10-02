# Firebase Setup for Stories Feature

## Required Firestore Indexes

The stories feature requires composite indexes for optimal performance. Follow these steps to set them up:

### Method 1: Automatic Setup (Recommended)
1. When you run the app and see the index error, click on the provided link in the console
2. Firebase will automatically create the required indexes

### Method 2: Manual Setup
1. Go to [Firebase Console](https://console.firebase.google.com/)
2. Navigate to your project → Firestore Database → Indexes
3. Create the following composite indexes:

#### Index 1: Active Stories
- Collection: `stories`
- Fields:
  - `expiresAt` (Ascending)
  - `timestamp` (Descending)

#### Index 2: User Stories
- Collection: `stories`
- Fields:
  - `userId` (Ascending)
  - `expiresAt` (Ascending) 
  - `timestamp` (Descending)

### Method 3: Using Firebase CLI
If you have Firebase CLI installed:

```bash
firebase deploy --only firestore:indexes
```

This will deploy the indexes defined in `firestore.indexes.json`.

## Story Collection Structure

Stories are stored in the `stories` collection with the following structure:

```javascript
{
  id: string,
  userId: string,
  username: string,
  userPhoto: string | null,
  storyImage: string,
  storyText: string,
  timestamp: Timestamp,
  location: {
    latitude: number,
    longitude: number,
    locationName: string
  },
  isViewed: boolean,
  expiresAt: Timestamp,
  viewedBy: string[]
}
```

## Security Rules

Add these security rules to your Firestore:

```javascript
// Allow users to create their own stories
match /stories/{storyId} {
  allow create: if request.auth != null 
    && request.auth.uid == resource.data.userId;
  
  // Allow reading all active stories
  allow read: if request.auth != null;
  
  // Allow users to update their own stories (for view tracking)
  allow update: if request.auth != null 
    && (request.auth.uid == resource.data.userId 
        || request.writeFields.size() == 1 
        && 'viewedBy' in request.writeFields);
  
  // Allow users to delete their own stories
  allow delete: if request.auth != null 
    && request.auth.uid == resource.data.userId;
}
```

## Performance Notes

- Stories automatically expire after 24 hours
- The app filters expired stories client-side for better performance
- Consider running a periodic cleanup function to remove expired stories
- Indexes improve query performance significantly

## Troubleshooting

If you see index-related errors:
1. Check the Firebase Console for pending index builds
2. Index creation can take several minutes for large datasets
3. Use the simplified queries in StoryService until indexes are ready