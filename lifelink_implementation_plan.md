# 🩸 LifeLink — Flutter Implementation Plan

> **Project**: LifeLink Blood Donation App  
> **Stack**: Flutter + Firebase (Auth, Firestore, Storage, FCM) + Riverpod + Razorpay  
> **Target**: Android (primary), iOS (secondary)

---

## 📋 Overview

Given the scale of this project (40+ screens, 30+ widgets, 20+ services, 25+ models), we will implement it in **6 phases**, prioritizing a functional app skeleton first, then layering in complexity.

> Important: Since Firebase configuration requires environment-specific keys, screens will use mock/local state until Firebase is connected. Each phase is independently runnable.

---

## Phase 1: Foundation & Infrastructure ← START HERE

**Goal**: Set up project architecture, dependencies, theme, and navigation skeleton.

### 1.1 Dependencies (pubspec.yaml)
- `flutter_riverpod` — State management
- `go_router` — Navigation
- `firebase_core`, `firebase_auth`, `cloud_firestore`, `firebase_storage`, `firebase_messaging` — Firebase
- `google_fonts` — Typography (Poppins, Inter)
- `cached_network_image` — Image caching
- `image_picker`, `image_cropper` — Photo upload
- `geolocator`, `geocoding` — Location
- `flutter_local_notifications` — Local notifications
- `shared_preferences` — Local storage
- `razorpay_flutter` — Payments
- `fl_chart` — Analytics charts
- `google_maps_flutter` — Map screen
- `intl` — Date/time formatting
- `lottie` — Animations
- `shimmer` — Loading skeletons
- `flutter_animate` — Micro-animations
- `dio` — Networking
- `encrypt` — Medical data encryption
- `pin_code_fields` — OTP input

### 1.2 Project Structure
Create full folder structure as specified:
- `lib/config/` — theme, routes, constants
- `lib/models/` — all data models
- `lib/services/` — business logic
- `lib/repositories/` — Firebase data access
- `lib/providers/` — Riverpod providers
- `lib/ui/screens/` — all screens
- `lib/ui/widgets/` — reusable widgets
- `lib/utils/` — validators, formatters, helpers

### 1.3 Theme (lib/config/theme.dart)
- Primary: Deep crimson red #C0392B
- Secondary: Warm coral #E74C3C
- Accent: Golden yellow #F39C12
- Background: Dark #0D0D0D / Light #FAFAFA
- Surface dark: #1A1A1A
- Success: #27AE60
- Warning: #F39C12
- Error: #E74C3C
- Font: Poppins (headings) + Inter (body)
- Dark mode first design

### 1.4 Routes (lib/config/routes.dart)
- GoRouter with nested navigation
- Role-based redirects
- Authentication guards

### 1.5 Models (all 25+)
Create all data models with:
- fromJson / toJson
- copyWith
- Enum definitions

---

## Phase 2: Authentication Screens

Screens 1.1 – 1.6: Splash, Login, Signup, Email Verification, Forgot Password, Phone Verification

---

## Phase 3: Donor Flow

Screens 2.1 – 2.6: Donor Home, Profile, Edit Profile, Donation History, Availability, Settings

---

## Phase 4: Requester Flow

Screens 3.1 – 3.5: Requester Home, Create Request, Request Detail, Active Requests, History

---

## Phase 5: Admin, Chat, Search & Map

Screens 4.x, 5.x, 7.x, 8.x

---

## Phase 6: Payments, Notifications & Polish

Screens 6.x, 9.x, 10.x

---

## Architecture Decisions

| Concern | Approach |
|---|---|
| State management | Riverpod (StateNotifier + AsyncNotifier patterns) |
| Navigation | GoRouter with shell routes for bottom nav |
| Data layer | Repository pattern (Repositories → Services → Providers) |
| Auth guard | GoRouter redirect based on auth state |
| Real-time data | Firestore snapshots() streams via StreamProvider |
| Images | Firebase Storage + cached_network_image |
| Encryption | encrypt package for medical details (AES-256) |
| Error handling | AsyncValue from Riverpod for loading/error/data states |
