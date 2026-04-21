# UrbaOS - Gestor | Guia de Setup, Onboarding & Operações

**Checklist Completo para Equipe de Manutenção**

---

## Parte 1: Setup Inicial (First-Time Setup)

### 1.1. Environment Setup (macOS)

```bash
# 1. Instalar Homebrew (se não tiver)
/bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"

# 2. Instalar Git
brew install git

# 3. Instalar Flutter SDK
brew install flutter

# 4. Verificar versão
flutter --version
# Expected: Flutter 3.11.4+ & Dart 3.11.4+

# 5. Instalar Xcode (iOS development)
# macOS App Store: Search for "Xcode" and install
# OU via command line:
xcode-select --install

# 6. Setup iOS development certificates
# Open Xcode.app and accept license
sudo xcode-select --switch /Applications/Xcode.app/Contents/Developer
sudo xcodebuild -runFirstLaunch

# 7. Install CocoaPods (iOS dependency manager)
brew install cocoapods

# 8. Verify everything
flutter doctor
# All items should show ✓ green checkmarks
```

### 1.2. Clone Repository

```bash
# 1. Create working directory
mkdir -p ~/Development/urbaos
cd ~/Development/urbaos

# 2. Clone repository
git clone <repository-url>
cd urbaos_admin

# 3. Verify directory structure
ls -la
# Should show: lib/, android/, ios/, pubspec.yaml, etc.
```

### 1.3. Flutter Dependencies Installation

```bash
# 1. Get all dependencies
flutter pub get

# 2. Create iOS Pods (for iOS development)
cd ios
pod install --repo-update
pod update
cd ..

# 3. Verify installation
flutter analyze
# Should show "No issues found" (or minimal warnings)

# 4. Check lint rules
flutter analyze --no-fatal-infos --no-pub
```

### 1.4. Firebase Project Setup

#### A. Create Firebase Project

```
1. Go to: https://console.firebase.google.com
2. Click "Create Project"
3. Name: "urbaos-admin"
4. Enable Google Analytics (optional)
5. Create Project (wait for provisioning ~2 min)
```

#### B. Create Firestore Database

```
1. In Firebase Console, go to: Firestore Database
2. Click "Create Database"
3. Choose "Production Mode" (restrictive by default)
4. Select Region: "us-central1" (or closest to you)
5. Create Database (wait for provisioning ~1 min)
```

#### C. Enable Authentication

```
1. Firebase Console → Authentication → Sign-in method
2. Enable "Email/Password"
3. (Optional) Enable "Google Sign-In" for future
```

#### D. Create Storage (for photos)

```
1. Firebase Console → Storage
2. Click "Get Started"
3. Start in "Production Mode"
4. Choose region: "us-central1"
5. Create Bucket
```

#### E. Configure for Flutter

```bash
# From project root directory:
flutterfire configure

# Follow prompts:
# → Select Firebase project: urbaos-admin
# → Overwrite existing: y
# → Platforms to configure: ios, android, web, macos, windows, linux
# → Generate code: y

# This generates:
# - lib/firebase_options.dart (config file)
# - Updates android/build.gradle
# - Updates ios/Podfile
```

### 1.5. Configure Firestore Security Rules

⚠️ **CRITICAL**: Default rules block all access. Configure before testing!

```
1. Firebase Console → Firestore Database → Rules

2. Replace with:
```

```firestore
rules_version = '2';
service cloud.firestore {
  match /databases/{database}/documents {
    
    // Development: Allow authenticated users to read/write everything
    // (Replace with restrictive rules before production)
    
    match /{document=**} {
      allow read, write: if request.auth != null;
    }
  }
}
```

```
3. Click "Publish"
4. Test should now work

# For production, replace with proper rules (see DOCUMENTACAO_TECNICA_COMPLETA.md)
```

### 1.6. Initial Firestore Data Setup

```bash
# 1. Create test user for login

# Method 1: Firebase Console (Recommended)
# Firebase Console → Authentication → Add User
# Email: admin@urbaos.com
# Password: TempPass123!

# Method 2: Firebase CLI (advanced)
firebase auth:set-custom-claims admin@urbaos.com --claims '{"role":"manager","department":"all"}'

# 2. Add Firestore document for user
# Firebase Console → Firestore → users collection → Add document
# Document ID: <same UID from Firebase Auth>
# Fields:
{
  "name": "Admin User",
  "email": "admin@urbaos.com",
  "role": "manager",
  "department": "all",
  "isActive": true,
  "createdAt": timestamp,
  "lastLoginAt": null
}
```

### 1.7. Run on iOS Simulator

```bash
# 1. List available simulators
xcrun simctl list devices

# 2. Open simulator
open -a Simulator

# 3. Run app
flutter run -d ios

# Expected output:
# • Building for iPhone simulator...
# • Launching lib/main.dart on iPhone 14 Pro in debug mode...
# • Running app...

# 4. App should open, login screen visible
```

### 1.8. Run on Android Emulator

```bash
# 1. Open Android Studio
# Tools → Device Manager → Create Virtual Device

# 2. Select device (e.g., Pixel 6 Pro)

# 3. Select API level (minimum 21, recommend 30+)

# 4. Create emulator

# 5. Start emulator (bottom of Android Studio)

# 6. Run app
flutter run -d emulator-5554

# Expected: App opens, login screen visible
```

### 1.9. Run on Web (Development)

```bash
# 1. Enable web (if not already)
flutter config --enable-web

# 2. Run on Chrome
flutter run -d chrome

# 3. App opens at http://localhost:62968/

# 4. Can resize browser to test responsive design
```

### 1.10. Verify Installation (Troubleshooting)

```bash
# Run complete diagnostics
flutter doctor -v

# Expected output:
✓ Flutter (Channel stable, X.XX.X, on macOS 13.X.X)
✓ Android toolchain
✓ Xcode
✓ Android Studio
✓ VS Code
✓ Connected device

# If any ✗ marks appear, run:
flutter doctor --android-licenses  # Accept Android licenses
xcode-select --install                # Install Xcode CLI
pod repo update                        # Update CocoaPods
```

---

## Parte 2: Pre-Deployment Checklist

### 2.1. Code Quality Verification

```bash
# 1. Run analyzer (equivalent to ESLint)
flutter analyze
# No errors should appear

# 2. Format code
dart format lib/
# Formats all Dart files

# 3. Run tests (if implemented)
flutter test
# All tests should pass

# 4. Check dependencies for vulnerabilities
flutter pub outdated
# Review and update as needed

# 5. Generate code (if using build_runner)
flutter pub run build_runner build --delete-conflicting-outputs
```

### 2.2. Firebase Rules Review

```firestore
# Production-ready Firestore rules (COPY-PASTE):

rules_version = '2';
service cloud.firestore {
  match /databases/{database}/documents {
    
    function hasRole(role) {
      return request.auth.token.role == role;
    }

    function isManager() {
      return hasRole('manager');
    }

    function isCoordinator() {
      return hasRole('coordinator');
    }

    function sameOrAllDept(dept) {
      return request.auth.token.department == 'all' || 
             request.auth.token.department == dept;
    }

    function isOwner(userId) {
      return request.auth.uid == userId;
    }

    // ========== USERS ==========
    match /users/{userId} {
      allow read: if isManager() || isOwner(userId);
      allow write: if isManager();
    }

    // ========== SERVICE ORDERS ==========
    match /service_orders/{osId} {
      allow read: if isManager() || (isCoordinator() && 
        sameOrAllDept(resource.data.department));
      allow create: if isManager() || (isCoordinator() && 
        sameOrAllDept(request.resource.data.department));
      allow update: if isManager() || (isCoordinator() && 
        sameOrAllDept(resource.data.department));
      allow delete: if isManager();
    }

    // ========== MATERIAL REQUESTS ==========
    match /material_requests/{requestId} {
      allow read: if isManager() || (isCoordinator() && 
        sameOrAllDept(resource.data.department));
      allow create: if isManager() || (isCoordinator() && 
        sameOrAllDept(request.resource.data.department));
      allow update: if isManager() || (isCoordinator() && 
        sameOrAllDept(resource.data.department));
      allow delete: if isManager();
    }

    // ========== LOCATIONS ==========
    match /locations/{userId}/history/{locationId} {
      allow read: if isManager() || (isCoordinator() && 
        sameOrAllDept(get(/databases/$(database)/documents/users/$(userId)).data.department));
      allow write: if isOwner(userId);
    }

    // Deny everything else
    match /{document=**} {
      allow read, write: if false;
    }
  }
}
```

**To deploy:**
```
1. Firebase Console → Firestore → Rules
2. Paste the above rules
3. Click "Publish"
```

### 2.3. Create Firestore Indexes

```
Firebase Console → Firestore → Indexes → Composite Indexes

Create these indexes:

1. service_orders (department, createdAt)
2. service_orders (status, department)
3. material_requests (status, createdAt)
4. material_requests (department, status)
5. material_requests (technicianId, createdAt)
6. users (role, name)
7. users (department, name)

Note: Single field indexes are created automatically when first queried.
```

### 2.4. Configure Cloud Storage Rules

```
Firebase Console → Storage → Rules

Replace with:
```

```
rules_version = '2';
service firebase.storage {
  match /b/{bucket}/o {
    // Authenticated users can upload photos
    match /photos/{allPaths=**} {
      allow read: if request.auth != null;
      allow write: if request.auth != null && 
        request.resource.size < 10 * 1024 * 1024;  // 10MB max
    }
    
    // Deny everything else
    match /{allPaths=**} {
      allow read, write: if false;
    }
  }
}
```

### 2.5. Create Admin User (Production)

```bash
# Using Firebase CLI (requires Admin access):

firebase auth:set-custom-claims admin-uid '{"role":"manager","department":"all"}'

# Then create Firestore document:
# Collection: users
# Document ID: admin-uid
# Fields:
{
  "name": "Administrator",
  "email": "admin@urbaos.com",
  "role": "manager",
  "department": "all",
  "isActive": true,
  "createdAt": 2026-04-14T00:00:00Z,
  "lastLoginAt": null
}
```

### 2.6. Enable Monitoring & Logging

```
1. Firebase Console → Project Settings
2. Click "Cloud Logging"
3. View real-time logs

OR use CLI:
firebase functions:log

Important log levels to monitor:
- Errors in Cloud Functions
- Auth failures
- Database quota warnings
```

---

## Parte 3: Android Release Build

### 3.1. Generate Signing Key

```bash
# Create key for signing APK
keytool -genkey -v -keystore ~/upload-keystore.jks \
  -keyalg RSA -keysize 2048 -validity 10000 -alias upload

# Follow prompts:
# Keystore password: [create strong password]
# Key password: [same or different]
# First & Last name: UrbaOS
# Organizational unit: Engineering
# Organization: UrbaOS
# City: Your City
# State: Your State
# Country code: BR

# Output: ~/upload-keystore.jks (back this up!)
```

### 3.2. Configure Key Properties

```bash
# Create: android/key.properties

nano android/key.properties

# Paste:
storeFile=/Users/<your-username>/upload-keystore.jks
storePassword=<your-keystore-password>
keyPassword=<your-key-password>
keyAlias=upload

# Save (Ctrl+O, Enter, Ctrl+X in nano)

# Add to .gitignore (DO NOT COMMIT)
echo "android/key.properties" >> .gitignore
```

### 3.3. Build Release APK

```bash
# Build release APK
flutter build apk --release

# Output location:
# build/app/outputs/apk/release/app-release.apk

# To install on device:
adb install build/app/outputs/apk/release/app-release.apk
```

### 3.4. Build App Bundle (for Play Store)

```bash
# Build App Bundle for Play Store distribution
flutter build appbundle --release

# Output location:
# build/app/outputs/bundle/release/app-release.aab

# This is what you upload to Google Play Console
```

---

## Parte 4: iOS Release Build

### 4.1. Setup Certificates

```bash
# 1. Open Xcode project
open ios/Runner.xcworkspace

# 2. Select Runner project
# 3. Select Runner target
# 4. Go to "Signing & Capabilities" tab

# 5. Enable "Automatically manage signing"
# 6. Select your Apple Developer Team
# 7. Xcode auto-generates certificates

# 8. Close and verify
```

### 4.2. Build for iOS

```bash
# Build iOS app
flutter build ios --release

# Creates release build in Xcode
# Output: build/ios/iphoneos/Runner.app
```

### 4.3. Archive for App Store

```bash
# 1. Open project
open ios/Runner.xcworkspace

# 2. In Xcode, select Runner target
# 3. Product → Archive
# 4. Select team and provisioning profile
# 5. Archive builds...
# 6. Organizer window opens

# 7. Select build from Organizer
# 8. Click "Distribute App"
# 9. Choose "App Store Connect"
# 10. Follow upload wizard
```

### 4.4. Manage via App Store Connect

```
1. Go to: https://appstoreconnect.apple.com
2. Select "UrbaOS - Gestor" app
3. Manage builds, versions, release notes
4. Submit for Review
5. Apple reviews (typically 24-48 hours)
6. Release to App Store
```

---

## Parte 5: Web Deployment (Firebase Hosting)

### 5.1. Build Web Version

```bash
# Enable web (if not already)
flutter config --enable-web

# Build optimized web version
flutter build web --release

# Output: build/web/
# Files are optimized and minified
```

### 5.2. Deploy to Firebase Hosting

```bash
# Install Firebase CLI (if not done)
npm install -g firebase-tools

# Login to Firebase
firebase login

# Initialize Firebase for this project
firebase init hosting

# When prompted:
# Public directory: build/web
# Configure as single-page app: yes
# Overwrite existing file: yes

# Deploy
firebase deploy --only hosting

# Output:
# Hosting URL: https://urbaos-admin.web.app
# Visit URL to test
```

### 5.3. Custom Domain (Optional)

```
1. Firebase Console → Hosting
2. Click "Add custom domain"
3. Enter your domain (e.g., gestor.urbaos.com)
4. Verify ownership via DNS
5. Firebase generates SSL certificate automatically
6. Done! Access via your domain
```

---

## Parte 6: Monitoring & Maintenance

### 6.1. Firebase Monitoring

```
Daily checks:

1. Firebase Console → Firestore → Usage
   - Check daily Reads/Writes/Deletes
   - Monitor quota usage
   
2. Firestore → Storage → Usage
   - Check database size
   - Monitor growth rate

3. Authentication → Users
   - Check active users
   - Monitor failed login attempts

4. Cloud Logging
   - Review error logs
   - Check for exceptions
```

### 6.2. App Analytics

```
Firebase Console → Analytics

Monitor:
- Daily Active Users
- Crash rates
- Performance metrics
- User retention

Alerts:
Setup automated alerts for:
- Crash spike (>% increase in 24h)
- High latency (>2s response)
- Quota exceeded (80%+)
```

### 6.3. Database Backups

```bash
# Automated backups in Firebase (default: 7 days)
# Manual backup via CLI:

gcloud firestore databases backup create \
  --database=default \
  --location=us-central1

# Restore from backup (if needed):
gcloud firestore databases restore \
  --backup=projects/<PROJECT>/locations/us-central1/backups/<BACKUP_ID>
```

### 6.4. Security Audit

```
Monthly:
1. Review Firestore rules
2. Check Cloud Storage permissions
3. Audit user access logs
4. Verify API key restrictions
5. Review Cloud Functions

Quarterly:
1. Security audit of code
2. Dependency update check (flutter pub outdated)
3. Performance profiling
4. Load testing
```

---

## Parte 7: Common Issues & Solutions

### Issue #1: "Target of URI doesn't exist" iOS build error

**Symptom:**
```
Error: Target of URI doesn't exist: 'package:...'
```

**Solution:**
```bash
cd ios
rm -rf Pods Podfile.lock
cd ..
flutter pub get
pod install
flutter run
```

---

### Issue #2: Firebase initialization fails

**Symptom:**
```
Error: Firebase is not initialized
FirebaseException: [core/not-initialized]
```

**Solution:**
```dart
// In main.dart, ensure:
void main() async {
  WidgetsFlutterBinding.ensureInitialized();  // ← Critical
  await Firebase.initializeApp();              // ← Must be async
  runApp(MyApp());
}
```

---

### Issue #3: Firestore permission denied on production

**Symptom:**
```
Error: PERMISSION_DENIED: Missing or insufficient permissions
```

**Solution:**
1. Check Firestore Rules (see Section 2.2)
2. Verify user is authenticated
3. Check role/department in custom claims:
```bash
firebase auth:get-user admin-uid  # Inspect user claims
```

---

### Issue #4: App crashes on iOS

**Symptom:**
```
Xcode: *** Terminating app due to uncaught exception
```

**Solution:**
```bash
# 1. Check pod issues
cd ios && pod repair && cd ..

# 2. Update CocoaPods
pod repo update

# 3. Full rebuild
flutter clean
flutter pub get
cd ios && pod update && cd ..
flutter run
```

---

### Issue #5: Real-time updates not working

**Symptom:**
```
Firestore stream doesn't emit updates
UI doesn't refresh
```

**Solution:**
```dart
// Verify stream subscription is active:
_subscription = repository.watchOrders(user).listen(
  (orders) {
    add(OrdersUpdated(orders));  // ← Must call add()
  },
  onError: (error) {
    print('Stream error: $error');
  },
);

// In close():
@override
Future<void> close() {
  _subscription?.cancel();  // ← Must cancel
  return super.close();
}
```

---

### Issue #6: Build size too large

**Symptom:**
```
APK file > 100MB
App size warning on Google Play
```

**Solution:**
```bash
# 1. Enable code shrinking (Android)
# android/app/build.gradle:
buildTypes {
    release {
        shrinkResources true
        minifyEnabled true
    }
}

# 2. Build optimized APK
flutter build apk --release -t lib/main.dart --split-per-abi

# 3. Check binary size
flutter build apk --target=lib/main.dart -v > build.log 2>&1
grep -i "dart" build.log
```

---

### Issue #7: GPS tracking not working on Android

**Symptom:**
```
geolocator returns (0.0, 0.0) on Android
Location permission always denied
```

**Solution:**
```xml
<!-- android/app/src/main/AndroidManifest.xml: -->
<uses-permission android:name="android.permission.ACCESS_FINE_LOCATION" />
<uses-permission android:name="android.permission.ACCESS_COARSE_LOCATION" />

<!-- For background tracking: -->
<uses-permission android:name="android.permission.ACCESS_BACKGROUND_LOCATION" />
```

```dart
// In app code:
import 'package:geolocator/geolocator.dart';

Future<void> requestLocationPermission() async {
  final permission = await Geolocator.requestPermission();
  
  if (permission == LocationPermission.deniedForever) {
    await Geolocator.openLocationSettings();
  }
}
```

---

### Issue #8: Photos not uploading to Storage

**Symptom:**
```
FileUploadException: Upload failed
Photos stay in "syncing" state
```

**Solution:**
```dart
// Check Storage quotas:
// Firebase Console → Storage → Files

// Verify Storage rules (Section 2.4):
rules_version = '2';
service firebase.storage {
  match /b/{bucket}/o {
    match /photos/{allPaths=**} {
      allow read: if request.auth != null;
      allow write: if request.auth != null && 
        request.resource.size < 10 * 1024 * 1024;
    }
  }
}

// Compress photos before upload:
import 'dart:typed_data';
import 'package:image/image.dart' as img;

Future<Uint8List> compressImage(File imageFile) async {
  final bytes = await imageFile.readAsBytes();
  final image = img.decodeImage(bytes);
  final compressed = img.encodeJpg(image, quality: 70);
  return Uint8List.fromList(compressed);
}
```

---

### Issue #9: App slow to start

**Symptom:**
```
Splash screen takes >3 seconds
Cold start very slow
```

**Solution:**
```dart
// 1. Lazy-load heavy dependencies:
// In injection_container.dart:
sl.registerLazySingleton<Repository>(  // ← registerLazySingleton
  () => FirebaseRepository(...),        // Not created until first use
);

// 2. Pre-cache Firestore collections:
Future<void> precacheData() async {
  await FirebaseFirestore.instance
      .collection('service_orders')
      .limit(10)
      .get();  // Downloads to local cache
}

// 3. Profile startup:
flutter run --profile
# Use DevTools → Performance tab to analyze
```

---

### Issue #10: Tests failing in CI/CD

**Symptom:**
```
flutter test fails only in GitHub Actions
Works locally
```

**Solution:**
```yaml
# .github/workflows/test.yml

name: Tests
on: [push, pull_request]

jobs:
  test:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v2
      
      - uses: subosito/flutter-action@v2
        with:
          flutter-version: 3.11.4
      
      - run: flutter pub get
      
      - run: flutter test --coverage
      
      - uses: codecov/codecov-action@v2  # Upload coverage
```

---

## Parte 8: Operational Runbook

### Daily Task Checklist

```
☐ Check Firebase Console for errors (Cloud Logging)
☐ Monitor quota usage (Firestore reads/writes)
☐ Review authentication failures (if any)
☐ Test core features:
  ☐ Login/Logout
  ☐ Create Service Order
  ☐ Approve Material Request
  ☐ View Dashboard (real-time updates)
  ☐ GPS tracking (if in use)
```

### Weekly Task Checklist

```
☐ Review crash logs in Crashlytics (if enabled)
☐ Check app performance metrics
☐ Verify backups are triggered
☐ Test offline functionality
☐ Review error logs from cloud functions
☐ Check for dependency updates:
  flutter pub outdated
```

### Monthly Task Checklist

```
☐ Security audit:
  ☐ Review Firestore Rules
  ☐ Verify Cloud Storage permissions
  ☐ Audit user access logs
  ☐ Check API key restrictions
  
☐ Performance optimization:
  ☐ Analyze database query performance
  ☐ Review function execution times
  ☐ Check cache hit rates
  
☐ Update dependencies:
  flutter pub upgrade --major-versions
  flutter pub get
  
☐ Update release notes
☐ Plan for next release
```

### Quarterly Task Checklist

```
☐ Major security audit
☐ Code review pass
☐ Load testing
☐ Disaster recovery drill (restore from backup)
☐ Plan Q next features
☐ Stakeholder update meeting
```

---

## Parte 9: Emergency Procedures

### 9.1. App Crash Loop

**Symptoms:**
- App crashes immediately on launch
- Users cannot access app

**Recovery:**

```bash
# 1. Check logs
firebase functions:log

# 2. Identify problematic update
git log --oneline -10

# 3. Rollback to previous version
git revert <commit-hash>
git push

# 4. Rebuild and redeploy
flutter build apk --release
# Upload APK to Play Store

# 5. Notify users
# Email/in-app notification about update
```

### 9.2. Database Corruption

**Symptoms:**
- Firestore queries return unexpected results
- Data integrity issues

**Recovery:**

```bash
# 1. Backup current state
gcloud firestore databases backup create \
  --database=default \
  --location=us-central1

# 2. Restore from last known good backup
gcloud firestore databases restore \
  --backup=projects/<PROJECT>/locations/us-central1/backups/<BACKUP_ID>

# 3. Verify data integrity
# Check Firestore dashboard

# 4. Notify users if necessary
```

### 9.3. Large-Scale Outage

**Symptoms:**
- Service completely unavailable
- Multiple critical errors

**Response:**

```
1. Immediate (0-5 min):
   ☐ Check Firebase Status Page (status.firebase.google.com)
   ☐ If Firebase is down: Wait for recovery, communicate with users
   ☐ If code issue: Start rollback process
   
2. Short-term (5-30 min):
   ☐ Set status page: "Incident - Investigating"
   ☐ Identify root cause
   ☐ Begin fix or rollback
   ☐ Test in staging environment
   
3. Recovery (30+ min):
   ☐ Deploy fix/rollback to production
   ☐ Verify functionality restoration
   ☐ Update status page: "Recovered"
   ☐ Monitor for recurrence
   
4. Post-Incident (within 24h):
   ☐ Publish incident report
   ☐ Document what happened
   ☐ List improvements to prevent recurrence
   ☐ Send summary to stakeholders
```

---

## Parte 10: Training & Documentation

### 10.1. New Team Member Onboarding

**Week 1:**
- [ ] Clone repository, run ```flutter doctor```
- [ ] Set up Firebase project
- [ ] Run app locally (iOS/Android)
- [ ] Review code structure and architecture
- [ ] Read DOCUMENTACAO_TECNICA_COMPLETA.md

**Week 2:**
- [ ] Make first code change (bug fix or small feature)
- [ ] Create pull request, get code review
- [ ] Understand BLoC pattern and state management
- [ ] Understand Firebase integration

**Week 3:**
- [ ] Deploy to staging environment
- [ ] Test on physical device
- [ ] Understand deployment pipeline
- [ ] Shadow production monitoring

**Week 4:**
- [ ] Lead a feature development (with mentorship)
- [ ] Participate in code review
- [ ] On-call backup for urgent issues

### 10.2. Knowledge Transfer Sessions

**Recommended Topics:**

```
Session 1: Architecture Overview
- Clean Architecture principles
- BLoC pattern
- Dependency Injection

Session 2: Firebase Integration
- Firestore real-time streaming
- Authentication flow
- Offline-first strategy

Session 3: Deployment Pipeline
- Build process
- App Store/Play Store submission
- Firebase Hosting deployment

Session 4: Troubleshooting & Debugging
- Common issues
- DevTools usage
- Log analysis

Session 5: Performance & Optimization
- Profiling tools
- Database optimization
- App size reduction
```

### 10.3. Documentation Maintenance

```
Keep docs updated when:
- New feature added
- Dependency upgraded
- Issue solved
- Security rule changed
- API changed

Update files:
- DOCUMENTACAO_TECNICA_COMPLETA.md (if architecture changes)
- ARQUITETURA_E_DIAGRAMAS.md (if diagrams become outdated)
- This file (if setup/operations change)
- README.md (user-facing, if applicable)
```

---

## Sumário de Documentação

| Documento | Propósito | Audiência |
|-----------|-----------|-----------|
| [DOCUMENTACAO_TECNICA_COMPLETA.md](DOCUMENTACAO_TECNICA_COMPLETA.md) | Referência técnica abrangente | Engenheiros, Arquitetos |
| [ARQUITETURA_E_DIAGRAMAS.md](ARQUITETURA_E_DIAGRAMAS.md) | Diagramas visuais e arquitetura | Todos |
| [GUIA_SETUP_OPERACOES.md](GUIA_SETUP_OPERACOES.md) (este arquivo) | Setup, deployment, troubleshooting | Ops, DevOps, QA |
| README.md | Overview do projeto | Stakeholders, Public |

---

**Última Atualização:** 14 de abril de 2026  
**Versão:** 1.0 - Initial Release  
**Mantido Por:** Equipe de Manutenção UrbaOS

Para questões ou atualizações, contactar: #eng-urbaos-gestor (Slack)

