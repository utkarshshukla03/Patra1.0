# 🗺️ Mapbox Integration Setup Guide

## Overview
This guide explains how to set up Mapbox for the story map feature in Patra Dating App.

## Prerequisites
1. Mapbox account (free tier available)
2. Mapbox Access Token
3. Flutter environment

## Step 1: Get Mapbox Access Token

1. Go to [Mapbox Account](https://account.mapbox.com/)
2. Create an account or sign in
3. Navigate to **Access Tokens**
4. Create a new token with the following scopes:
   - `styles:read`
   - `fonts:read`
   - `datasets:read`
   - `vision:read`

## Step 2: Configure Environment Variables

1. Copy `api_keys.env.example` to `api_keys.env`
2. Add your Mapbox tokens:

```env
# ==============================================================================
# 🗺️ MAPBOX CONFIGURATION
# ==============================================================================
MAPBOX_ACCESS_TOKEN=pk.your_actual_mapbox_access_token_here
MAPBOX_SECRET_TOKEN=sk.your_actual_mapbox_secret_token_here
```

## Step 3: Install Dependencies

```bash
flutter pub get
```

## Step 4: Platform-Specific Setup

### Android Setup
Add to `android/app/src/main/AndroidManifest.xml`:

```xml
<uses-permission android:name="android.permission.ACCESS_FINE_LOCATION" />
<uses-permission android:name="android.permission.ACCESS_COARSE_LOCATION" />
```

### iOS Setup
Add to `ios/Runner/Info.plist`:

```xml
<key>NSLocationWhenInUseUsageDescription</key>
<string>This app needs location access to show nearby stories on the map.</string>
```

### Web Setup
The Mapbox GL JS library is already included in `web/index.html`:

```html
<script src='https://api.mapbox.com/mapbox-gl-js/v2.15.0/mapbox-gl.js'></script>
<link href='https://api.mapbox.com/mapbox-gl-js/v2.15.0/mapbox-gl.css' rel='stylesheet' />
```

## Features

### 🎯 Story Map Features
- **Heat Maps**: Visual representation of story density
- **Interactive Markers**: Tap to view stories at specific locations
- **Real-time Location**: Shows user's current location
- **Multiple Map Styles**: Satellite, outdoors, light, dark themes
- **Campus Focus**: Centered on Thapar Institute campus
- **Story Clustering**: Groups nearby stories for better visualization

### 🛠️ Technical Implementation
- **MapboxStoryMap**: Main widget using Mapbox GL
- **Story Models**: HeatPoint and UserStory data structures
- **Location Services**: GPS integration for user positioning
- **Animation**: Smooth transitions and pulse effects

## Usage

The story map is accessible through the Discovery page:

```dart
// In discovery.dart
MapboxStoryMap(
  heatPoints: _heatPoints,
  onHeatPointTapped: _onHeatPointTapped,
)
```

## Customization

### Map Styles
You can customize map styles in `MapboxStoryMap`:

```dart
styleString: MapboxStyles.SATELLITE_STREETS, // Default
// Other options:
// MapboxStyles.OUTDOORS
// MapboxStyles.LIGHT
// MapboxStyles.DARK
```

### Heat Point Colors
Customize heat point colors in `story_map.dart`:

```dart
Color get heatColor {
  if (intensity < 0.2) return Colors.blue.withOpacity(0.6);
  if (intensity < 0.4) return Colors.green.withOpacity(0.7);
  // ... more color mappings
}
```

## Migration from Google Maps

✅ **Completed**:
- Replaced `google_maps_flutter` with `mapbox_gl`
- Updated `real_snapchat_map.dart` → `mapbox_story_map.dart`
- Removed Google Maps API from `web/index.html`
- Added Mapbox GL JS to web platform
- Updated environment configuration

✅ **Benefits of Mapbox**:
- Better customization options
- Superior satellite imagery
- More map style options
- Better performance on web
- More affordable pricing
- Better offline support

## Troubleshooting

### Common Issues

1. **Token Not Working**
   - Verify token has correct scopes
   - Check token is active in Mapbox dashboard
   - Ensure token is properly set in `api_keys.env`

2. **Location Permission Denied**
   - Check platform-specific permission setup
   - Verify location services are enabled on device

3. **Map Not Loading**
   - Check network connectivity
   - Verify Mapbox token is valid
   - Check browser console for errors (web)

### Support
- [Mapbox Documentation](https://docs.mapbox.com/)
- [Flutter Mapbox Plugin](https://pub.dev/packages/mapbox_gl)
- [Mapbox Community](https://community.mapbox.com/)

## Cost Considerations

Mapbox pricing is based on monthly active users and map loads:
- **Free Tier**: 50,000 map loads per month
- **Pay-as-you-go**: $0.50 per 1,000 additional loads
- Much more affordable than Google Maps for most use cases

---

🎉 **Your story map is now powered by Mapbox!**