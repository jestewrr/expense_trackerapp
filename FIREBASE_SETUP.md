# Firebase Integration Setup

This document describes the Firebase integration that has been added to your Flutter expense tracker app.

## What's Been Added

### 1. Firebase Dependencies
Added the following Firebase packages to `pubspec.yaml`:
- `firebase_core: ^3.6.0` - Core Firebase functionality
- `firebase_auth: ^5.3.1` - Authentication services
- `cloud_firestore: ^5.4.3` - NoSQL database
- `firebase_storage: ^12.3.2` - File storage

### 2. Configuration Files
- **Android**: `android/app/google-services.json` - Contains your Firebase project configuration
- **iOS**: `ios/Runner/GoogleService-Info.plist` - iOS Firebase configuration
- **Web**: `web/index.html` - Web Firebase configuration with SDK scripts
- **Android Build**: Updated `android/app/build.gradle.kts` and `android/build.gradle.kts` to include Google Services plugin

### 3. Package Name Update
Updated the Android package name from `com.example.expense_tracker_application` to `com.android.application` to match your Firebase project configuration.

### 4. Firebase Services
Created new service files:
- `lib/services/firebase_auth_service.dart` - Firebase Authentication wrapper
- `lib/services/firebase_expense_service.dart` - Firestore operations for expenses

### 5. Firebase Test Page
Added `lib/firebase_test_page.dart` - A test page to verify Firebase connectivity and functionality.

## Firebase Project Details
- **Project ID**: expensetracker-9bb87
- **Project Number**: 8264121967
- **Storage Bucket**: expensetracker-9bb87.firebasestorage.app
- **Android App ID**: 1:8264121967:android:cb5c0de07ca758942b179a
- **Web App ID**: 1:8264121967:web:d6cb44ab52018d1e2b179a
- **Measurement ID**: G-S18VYG29E7

## How to Test Firebase Integration

### Mobile (Android/iOS)
1. Run the app: `flutter run`
2. Navigate to the dashboard
3. Tap the blue cloud icon (FloatingActionButton) to open the Firebase test page
4. Use the test buttons to verify:
   - Firebase connection
   - Authentication service
   - Firestore database operations

### Web
1. Build for web: `flutter build web --no-tree-shake-icons`
2. Serve the web app: `flutter run -d web-server --web-port 8080`
3. Open http://localhost:8080 in your browser
4. Navigate to the dashboard and tap the blue cloud icon
5. Use the test buttons to verify Firebase functionality on web

## Available Firebase Services

### FirebaseAuthService
- `registerWithEmailAndPassword()` - Register new users
- `signInWithEmailAndPassword()` - Sign in existing users
- `signOut()` - Sign out current user
- `getUserData()` - Get user data from Firestore
- `updateUserData()` - Update user information

### FirebaseExpenseService
- `addExpense()` - Add new expense to Firestore
- `getExpenses()` - Get all expenses for a user
- `updateExpense()` - Update existing expense
- `deleteExpense()` - Delete expense
- `getExpensesByCategory()` - Filter expenses by category
- `getExpensesByDateRange()` - Filter expenses by date range
- `getTotalExpenses()` - Calculate total expenses
- `getExpensesStream()` - Real-time expense updates

## Next Steps

1. **Enable Authentication Methods**: Go to Firebase Console → Authentication → Sign-in method and enable Email/Password authentication
2. **Set up Firestore Rules**: Configure security rules in Firebase Console → Firestore Database
3. **Migrate Data**: Consider migrating existing local data to Firestore
4. **Add Offline Support**: Firebase automatically handles offline caching
5. **Implement Push Notifications**: Add Firebase Cloud Messaging for notifications

## Security Rules Example

For Firestore, you might want to add these security rules:

```javascript
rules_version = '2';
service cloud.firestore {
  match /databases/{database}/documents {
    // Users can only access their own data
    match /users/{userId} {
      allow read, write: if request.auth != null && request.auth.uid == userId;
    }
    
    // Users can only access their own expenses
    match /expenses/{expenseId} {
      allow read, write: if request.auth != null && 
        resource.data.userId == request.auth.uid;
    }
  }
}
```

## Troubleshooting

If you encounter issues:
1. Make sure you're using the correct package name (`com.android.application`)
2. Verify the `google-services.json` file is in the correct location
3. Check that Firebase is properly initialized in `main.dart`
4. Ensure all dependencies are installed with `flutter pub get`
