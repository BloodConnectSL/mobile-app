# 🩸 Prana (ප්‍රාණ) — National Blood Donation & Request Platform

A unified, life-saving mobile application designed to streamline blood donation, urgent hospital requests, donor recognition, and emergency alerts across Sri Lanka.

---

## ✨ Features Overview

### 1. 🩸 Core Foundation & Authentication
- **Onboarding & Splash**: Welcoming walkthrough explaining donor impact and eligibility.
- **Secure Authentication**: Sign Up & Sign In flows with blood group registration and form validation.
- **Bottom Navigation Layout**: Fast access to Home, Drives/Events, My QR code, and Profile.
- **Role-Based Portals**:
  - 🏥 **Hospital Portal**: Manage emergency stock requests, blood unit verification.
  - 📋 **Organizer Portal**: Plan and track community blood donation drives.
  - 🛡️ **Admin & SuperAdmin Portals**: National audit logs, user management, and analytics.

### 2. 🚨 Emergency Blood Requests (`/blood-request`)
- **Urgency Classification**: Critical (Immediate), Urgent (2–4 hours), Moderate (24 hours), Scheduled.
- **Interactive Blood Group Selector**: Visual selector for A+, A-, B+, B-, AB+, AB-, O+, O-.
- **Hospital / Ward Dispatch**: Direct dispatch with contact details and patient case notes.

### 3. 📜 Donation History & Timeline (`/donation-history`)
- **Impact Summary**: Total blood volume donated, lives touched, and earned points.
- **Interactive Timeline**: Vertical chronologic history with recipient ward details.
- **Eligibility Countdown**: Smart reminder card calculating the exact date for next safe donation.

### 4. 🔔 Notification Centre & Emergency SOS (`/notifications`, `/emergency-sos`)
- **Alert Triage**: Categorized notifications for urgent requests, community drives, and achievements.
- **Emergency SOS One-Touch Alert**: Pulsing red distress button dispatching emergency alerts to nearby donors and medical hotlines.
- **Emergency Directory**: 1990 Suwa Seriya, National Blood Transfusion Service (NBTS), and hotline direct contacts.

### 5. 🏆 Leaderboard & Donor Recognition (`/leaderboard`)
- **National Podium**: Top 3 donor podium with gold, silver, and bronze badges.
- **Ranked Leaderboard**: Gamified point system to encourage regular donation.
- **Achievement Badges**: First Drop, Life Saver, Hero Donor, Champion, and Legend milestones.

---

## 🏗️ Project Architecture

```
lib/
├── main.dart                      # App entry point & named routing table
├── theme.dart                     # Custom theme system (AppTheme, colors, typography)
└── screens/
    ├── splash_screen.dart         # Splash & redirect
    ├── onboarding_screen.dart     # Walkthrough
    ├── login_screen.dart          # Authentication login
    ├── sign_up_screen.dart        # Donor registration
    ├── main_layout.dart           # 4-tab bottom navigation scaffold
    ├── home_tab.dart              # Home tab with quick actions & nearby drives
    ├── events_tab.dart            # Community donation campaigns
    ├── my_qr_tab.dart             # Digital donor card with QR verification
    ├── profile_tab.dart           # Donor settings, profile, and feature access
    ├── blood_request_screen.dart  # Urgent blood request creation
    ├── donation_history_screen.dart # Chronological donation timeline
    ├── notifications_screen.dart  # Multi-category notification center
    ├── emergency_sos_screen.dart  # One-touch emergency distress trigger
    ├── leaderboard_screen.dart    # National donor rankings & reward badges
    └── portals/
        └── all_portals.dart       # Organizer, Hospital, Admin, SuperAdmin dashboards
```

---

## 🚀 Getting Started

### Prerequisites
- [Flutter SDK](https://flutter.dev) (v3.19.0 or higher)
- Dart SDK (v3.3.0 or higher)
- Android Studio / Xcode / VS Code with Flutter extension

### Installation
```bash
# Clone the repository
git clone https://github.com/BloodConnectSL/mobile-app.git

# Navigate to project
cd mobile-app

# Install dependencies
flutter pub get

# Run the app
flutter run
```

---

## 👥 Authors & Contributions
- **Author**: [@shashigew](https://github.com/shashigew)
- **Organization**: [BloodConnectSL](https://github.com/BloodConnectSL)
