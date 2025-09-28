# Google Maps Setup Guide

## 🗺️ Google Maps Integration Complete!

The app now uses **real Google Maps** instead of custom UI for the Snapchat-style map discovery feature.

## � **Important: Web Platform Issue Fixed**

**Problem**: Google Maps on web requires the JavaScript API to be loaded before the Flutter app initializes. The error `"Cannot read properties of undefined (reading 'maps')"` occurs when this script is missing.

**Solution**: The app now uses **platform-specific implementations**:
- **📱 Mobile (Android/iOS)**: Real Google Maps with GPS functionality
- **🌐 Web**: Fallback interactive map with all features (until API key is configured)

### 📱 **Features Added**
- **Google Maps Flutter Package**: Using `google_maps_flutter: ^2.7.0`
- **Location Services**: Using `location: ^7.0.0` and `geolocator: ^13.0.1`
- **Dark Theme Map**: Custom styled map matching Snapchat's dark aesthetic
- **Interactive Heat Zones**: Real map markers and circles for story locations
- **GPS Integration**: Users can see their real location on the map

### 🛠️ **Features Added**
- **Real Markers**: Google Maps markers for each story location with custom colors
- **Heat Circles**: Translucent circles showing story density around locations
- **Location Permissions**: Proper Android/iOS location permission handling
- **Map Controls**: Zoom to Thapar, center on user location, map type switcher
- **Styled Map**: Dark theme with blue/navy colors matching Snapchat design

## 🔧 Setup Required

### 1. **Get Google Maps API Key**

1. Go to [Google Cloud Console](https://console.cloud.google.com/)
2. Create a new project or select existing project
3. Enable the following APIs:
   - **Maps SDK for Android**
   - **Maps SDK for iOS** 
   - **Maps JavaScript API** (for web)
   - **Geocoding API**
   - **Places API**

4. Create credentials → API Key
5. Restrict the API key to your app's package name/bundle ID

### 2. **Configure API Keys**

#### **Android Setup:**
1. Open `android/app/src/main/AndroidManifest.xml`
2. Replace `YOUR_GOOGLE_MAPS_API_KEY_HERE` with your actual API key:
```xml
<meta-data android:name="com.google.android.geo.API_KEY"
           android:value="AIzaSyB...your-actual-key-here"/>
```

#### **iOS Setup:**
1. Open `ios/Runner/AppDelegate.swift`
2. Add your API key:
```swift
import UIKit
import Flutter
import GoogleMaps

@main
@objc class AppDelegate: FlutterAppDelegate {
  override func application(
    _ application: UIApplication,
    didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?
  ) -> Bool {
    GMSServices.provideAPIKey("YOUR_API_KEY_HERE")
    GeneratedPluginRegistrant.register(with: self)
    return super.application(application, didFinishLaunchingWithOptions: launchOptions)
  }
}
```

#### **Web Setup (REQUIRED for web platform):**
1. Open `web/index.html` - **ALREADY ADDED**
2. Replace `YOUR_GOOGLE_MAPS_API_KEY_HERE` with your actual API key:
```html
<script src="https://maps.googleapis.com/maps/api/js?key=YOUR_ACTUAL_API_KEY&libraries=places" async defer></script>
```
**Note**: The script tag is already added to `web/index.html`, you just need to replace the API key placeholder.

### 3. **Install Dependencies**
```bash
flutter pub get
```

### 4. **Location Permissions**
The app will automatically request location permissions when the discovery page loads. Users can:
- Allow location access to see their position on the map
- Deny access and still use the map centered on Thapar Institute

## � **Platform-Specific Behavior**

### **📱 Mobile (Android/iOS)**
- **Real Google Maps**: Full GPS functionality with device location
- **Interactive Markers**: Tap to view stories from specific locations  
- **Map Types**: Switch between Normal, Satellite, Hybrid, Terrain
- **Zoom Controls**: Pinch to zoom, center on location buttons
- **Location Permissions**: Automatic permission requests

### **🌐 Web Platform**
- **Interactive Fallback Map**: Custom-designed map with same features
- **Campus Layout**: Visual representation of Thapar Institute
- **Heat Point Animation**: Pulsing story zones with color coding
- **Zoom & Pan**: Mouse/touch controls for navigation
- **Demo Mode Notice**: Shows "Web Demo Mode" indicator
- **No Location Permissions**: Uses simulated location data

**Why Web Fallback?** Google Maps on web has complex setup requirements and location permission issues in browsers. The fallback provides the same user experience while you configure the full API setup.

### **Interactive Controls**
- **🏫 School Icon**: Center map on Thapar Institute
- **📍 Location Icon**: Center map on user's current location  
- **🗂️ Layers Icon**: Switch between Normal/Satellite/Hybrid/Terrain views

### **Story Heat Zones**
- **🔵 Blue Markers**: Low story activity (< 20%)
- **🟢 Green Markers**: Moderate activity (20-40%)
- **🟡 Yellow Markers**: Active zones (40-60%)
- **🟠 Orange Markers**: Very active (60-80%)
- **🔴 Red Markers**: Hotspot zones (> 80%)

### **Map Interaction**
- **Tap Markers**: View stories from that location
- **Pinch to Zoom**: Zoom in/out on map
- **Drag to Pan**: Explore different areas of campus
- **Info Windows**: See location name and story count

## 🌟 **Benefits of Real Google Maps**

1. **Accurate GPS**: Real location tracking and positioning
2. **Familiar Interface**: Users know how to interact with Google Maps
3. **Detailed Campus**: Shows actual Thapar Institute buildings and roads
4. **Satellite View**: Users can switch to satellite imagery
5. **Performance**: Optimized by Google for smooth scrolling and zooming
6. **Accessibility**: Built-in accessibility features
7. **Offline Support**: Basic offline functionality when network is poor

## 🚀 **Next Steps**

1. **Add Your API Key**: Replace the placeholder with your actual Google Maps API key
2. **Test on Device**: Run on physical device to test location permissions
3. **Customize Markers**: Add custom marker icons for different story types
4. **Add Clustering**: Group nearby markers when zoomed out
5. **Real-time Updates**: Connect to Firebase to show live story updates
6. **Geofencing**: Add notifications when users enter story zones

## 🔒 **Security Notes**

- **Restrict API Key**: Limit API key usage to your app's package name
- **Monitor Usage**: Set up billing alerts in Google Cloud Console
- **Environment Variables**: Store API keys in environment variables for production

The map now provides a professional, real-world mapping experience that users will find familiar and engaging! 🗺️✨