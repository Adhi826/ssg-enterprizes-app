# Sri Siva Gayathri Enterprizes (SSGE) Stock & Billing App

A premium, modern Android distribution inventory management and professional billing application built with Flutter & Firebase. Optimized for water bottles and soft drink distribution warehouses.

---

## 🎨 Core Design & Features

- **Glassmorphic Aesthetic**: Modern visual layouts using glass containers, neon overlays, and bright cyan/orange/blue gradient backdrops.
- **Unified Navigation**: 6-tab bottom navigations covering Home, Products inventory list, incoming/outgoing Stock loggers, Active invoice checkout cart, Reports graphs, and settings.
- **Stock Management Module**: Full CRUD for items, custom unit types (Single, Carton, Case), real-time stock-in/out logs syncing, and red color alerts for items falling under threshold limits.
- **Automated AI Insights**: Predictive stock out estimations (suggesting replenishment quantity) and dashboard sales tip summarizations.
- **Professional Billing Suite**: Fast invoice generation, automated subtotal / 18% GST / discounts addition, PDF receipt generation, print formatting, and WhatsApp distribution.
- **Dual Language Switcher**: English & తెలుగు (Telugu) configuration support.
- **Session Persistence**: Remembers signed-in credentials and settings theme (dark/light toggles).

---

## 📁 Codebase Directory Structure

```text
lib/
├── main.dart                  # MultiProvider configuration & styled Material App shell
├── models/
│   ├── product.dart           # Product items fields & low stock helpers
│   ├── stock_entry.dart       # Log tracking model for stock-in/out transactions
│   └── invoice.dart           # Cart items billing detail layout
├── providers/
│   ├── auth_provider.dart     # Handles mock bypass, user login & language preference
│   ├── inventory_provider.dart# Product additions, stock transactions & restock math
│   ├── billing_provider.dart  # Interactive shopping cart and historical invoices
│   └── theme_provider.dart    # Manages theme preferences persistent storage
├── screens/
│   ├── splash_screen.dart     # Logo scale and fade transition intro screen
│   ├── login_screen.dart      # Password visible toggle with validator inputs
│   ├── dashboard_screen.dart  # Shell holding tabs, KPI metrics cards & notification log
│   ├── product_management.dart# Item addition forms & category search filters
│   ├── stock_entry_screen.dart# Transaction logs visual timeline
│   ├── billing_screen.dart    # Cart checkout calculations and discount inputs
│   ├── invoice_preview.dart   # Interactive PDF print receipt visual layout
│   ├── reports_screen.dart    # Financial highlights tracker with progress bars
│   └── settings_screen.dart   # Dark mode toggle and language switch
├── widgets/
│   └── glass_container.dart   # Frosted glass card custom widget
└── services/
    ├── pdf_service.dart       # High-fidelity PDF builder using print layouts
    ├── excel_service.dart     # Syncfusion sheet exporter
    └── ai_insights_service.dart # Realtime replenishment prediction algorithms
```

---

## ☁️ Firebase Cloud Database Setup Instructions

To hook the database up, perform the following steps:

1. **Create Firebase Project**:
   - Go to [Firebase Console](https://console.firebase.google.com/) and click **Add Project**.
   - Input `Sri Siva Gayathri Enterprizes` as project name.

2. **Configure Android App**:
   - Register your Android app package name (`com.example.sri_siva_gayathri_enterprizes`).
   - Download the `google-services.json` file and place it under `android/app/` folder.

3. **Enable Firestore Database**:
   - Go to Build -> Firestore Database and click **Create Database**.
   - Start in Test mode or configure write rules:
     ```javascript
     rules_version = '2';
     service cloud.firestore {
       match /databases/{database}/documents {
         match /{document=**} {
           allow read, write: if request.auth != null;
         }
       }
     }
     ```

4. **Enable Firebase Authentication**:
   - Navigate to Build -> Authentication.
   - Go to Sign-in methods and enable **Email/Password**.
   - Create your administrator account (e.g. `admin@ssg.com` / `admin123`).

5. **Enable Firebase Storage**:
   - Navigate to Storage and click **Get Started** to store product images.

---

## 🛠️ Local Execution & APK Build Guide

Follow these steps to run or compile the code:

### 1. Initial Setup
```bash
# Check dependencies and clean local package cache
flutter clean
flutter pub get
```

### 2. Run App Locally
To test the visual design live on an emulator or plugged-in Android device:
```bash
flutter run
```

### 3. Generate Android Release APK
To compile a standalone APK to share with the owner of Sri Siva Gayathri Enterprizes:
```bash
# Build fat APK containing all target architectures
flutter build apk --release
```
The compiled installation file will be located at:
`build/app/outputs/flutter-apk/app-release.apk`
