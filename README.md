# Gentleman Barber Shop App

A complete Flutter application for a barber shop booking system.

## Features
- **Authentication**: Login/Register with Email & Password.
- **Roles**: Client, Barber, Admin.
- **Booking System**: Select Barber -> Service -> Date/Time -> Confirm.
- **Slot Management**: Automatic calculation of free slots based on barber hours and existing bookings.
- **Calendar**: View appointments.
- **Admin Dashboard**: Overview of all bookings.

## Setup Instructions

### 1. Firebase Setup
1. Create a new Firebase project at [console.firebase.google.com](https://console.firebase.google.com).
2. Enable **Authentication** (Email/Password provider).
3. Enable **Firestore Database**.
4. Add an Android app to the project and download `google-services.json` to `android/app/`. 
5. Add an iOS app to the project and download `GoogleService-Info.plist` to `ios/Runner/`.
6. (Optional) For Web, add a Web app and update `lib/firebase_options.dart` (run `flutterfire configure`).

### 2. Run the App
```bash
flutter pub get
flutter run
```

### 3. Initial Data Seeding
To make the app usable, you need to manually add some data to Firestore via the Firebase Console:

**Collection: `barbers`**
Document ID: (auto-id)
```json
{
  "name": "John Doe",
  "imageUrl": "https://...",
  "specialties": ["Hair", "Beard"],
  "startHour": 9,
  "endHour": 17
}
```

**Collection: `services`**
Document ID: (auto-id)
```json
{
  "name": "Haircut",
  "durationMinutes": 30,
  "price": 25.0,
  "description": "Classic cut"
}
```

## Architecture
- **State Management**: Riverpod
- **Routing**: GoRouter
- **Backend**: Firebase (Auth + Firestore)
- **UI**: Material 3
