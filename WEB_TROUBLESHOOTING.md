# Web White Screen Troubleshooting Guide

## Common Causes of White Screen on Flutter Web

### 1. Firebase Initialization Issues
**Problem**: Firebase initialization might be blocking the Flutter app startup.

**Solution**: 
- Check browser console for Firebase errors
- The app now has error handling for Firebase initialization
- If Firebase fails, the app should still load

### 2. CORS Issues
**Problem**: Cross-Origin Resource Sharing issues with Firebase.

**Solution**:
- Ensure your domain is added to Firebase authorized domains
- Check Firebase Console → Authentication → Settings → Authorized domains

### 3. JavaScript Errors
**Problem**: JavaScript errors preventing Flutter from loading.

**Solution**:
- Open browser Developer Tools (F12)
- Check Console tab for errors
- Look for red error messages

### 4. Build Issues
**Problem**: Web build might be incomplete or corrupted.

**Solution**:
```bash
# Clean and rebuild
flutter clean
flutter pub get
flutter build web --no-tree-shake-icons
```

## Testing Steps

### 1. Local Testing
```bash
# Build the app
flutter build web --no-tree-shake-icons

# Serve locally
cd build/web
python -m http.server 8080
# or
npx serve .

# Open http://localhost:8080
```

### 2. Check Browser Console
1. Open Developer Tools (F12)
2. Go to Console tab
3. Look for:
   - "Firebase initialized successfully" - Good
   - "Firebase initialization failed" - Check Firebase config
   - Red error messages - Fix the specific error

### 3. Check Network Tab
1. Open Developer Tools (F12)
2. Go to Network tab
3. Refresh the page
4. Look for:
   - Failed requests (red)
   - Missing files (404 errors)
   - CORS errors

## Firebase Hosting Deployment

### 1. Install Firebase CLI
```bash
npm install -g firebase-tools
```

### 2. Login to Firebase
```bash
firebase login
```

### 3. Initialize Firebase Hosting
```bash
firebase init hosting
```

### 4. Deploy
```bash
firebase deploy
```

## Quick Fixes

### Fix 1: Remove Firebase Temporarily
If the app works without Firebase, the issue is Firebase-related:

1. Comment out Firebase initialization in `main.dart`
2. Rebuild and test
3. If it works, check Firebase configuration

### Fix 2: Check Firebase Config
Ensure your Firebase configuration matches:
- Project ID: expensetracker-9bb87
- Web App ID: 1:8264121967:web:d6cb44ab52018d1e2b179a
- API Key: AIzaSyDdEL9f8n33UbXni6NRqeqBoWIfdjU3VAo

### Fix 3: Check Authorized Domains
In Firebase Console:
1. Go to Authentication → Settings
2. Add your domain to "Authorized domains"
3. For local testing, add "localhost"

## Debug Files Created

- `web/index-debug.html` - Debug version without Firebase
- `web/firebase-config.js` - Separate Firebase config file

## Common Error Messages

### "Firebase: No Firebase App '[DEFAULT]' has been created"
- Firebase not initialized properly
- Check Firebase scripts in index.html

### "CORS error"
- Domain not authorized in Firebase
- Add domain to Firebase Console

### "Failed to load resource"
- Missing files in build
- Rebuild the web app

### "Uncaught TypeError"
- JavaScript error
- Check browser console for details

## Testing Commands

```bash
# Test locally
flutter run -d chrome --web-port 8080

# Build and serve
flutter build web --no-tree-shake-icons
cd build/web
python -m http.server 8080

# Deploy to Firebase
firebase deploy
```

## Next Steps

1. Test locally first
2. Check browser console for errors
3. Fix any JavaScript/Firebase errors
4. Test on Firebase Hosting
5. Check Firebase Console for any configuration issues
