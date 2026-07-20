# VitalAI 🩺✨

VitalAI is a premium, high-aesthetic Flutter application designed as an intelligent health companion. It combines robust local-first health vitals logging, trend analytics, custom reminders, and a generative AI health assistant powered by Gemini.

---

## 🌟 Key Features

### 1. High-Aesthetic UI & Branding
* **Breathing Gradient Backgrounds**: Dynamic, smooth background canvas that breathes between ambient states.
* **Glassmorphism**: Translucent cards, inputs, and borders for a modern, state-of-the-art UI feel.
* **Brand Logo**: Sleek, custom-designed glowing heart and neural network node emblem.

### 2. Generative AI Health Assistant
* **Context-Aware Educational Helper**: Integrates Gemini to explain vital measurements, trends, and terms.
* **Premium Chat UI**: Features glowing avatar profiles, glassmorphic bubbles, quick prompt cards, and inline actions (Copy, Reply, Delete).
* **Patient Integration**: Automatically attaches active patient records to request context for custom summaries.

### 3. Vitals Tracker & Log History
* **Supported Metrics**: Blood Pressure (Systolic/Diastolic), Blood Glucose, Heart Rate (BPM), Oxygen Saturation (SpO₂), Body Temperature, and Weight (with auto-BMI calculation).
* **Inclusive Date Filter**: Robust history filter checking records inclusive of the selected day range.
* **Abnormal Indicators**: Visual warnings for readings out of healthy ranges.
* **PDF Export**: Generate and share localized clinical reports.

### 4. Interactive Health Trends
* **Charts Panel**: Beautiful, color-coded interactive line charts showing 7D and 30D health metric trends.

### 5. Smart Notifications & Web Simulator
* **Permission Requests**: Aligns with modern Apple (Darwin) and Android specifications.
* **Web Simulator**: Intercepts notification triggers in simulated device previews (Web/Edge) to display custom, slide-down in-app alerts.

### 6. User Auth & Readable Errors
* **Friendly Translation**: Converts generic Firebase Auth codes into clean, reader-friendly guidance (e.g. invalid credentials or weak passwords) without verbose technical logs.

---

## 🛠️ Technology Stack
* **State Management**: Flutter BLoC (State Management / Events)
* **Local Storage**: Secure Storage & SharedPreferences via a central Database Service.
* **AI Service**: Google Generative AI (Gemini APIs).
* **Database/Auth**: Firebase Auth & Firestore sync integration.
* **Charts**: `fl_chart` integration.
* **Notifications**: `flutter_local_notifications`.

---

## 🚀 Getting Started

### Prerequisites
* Flutter SDK (3.12.1 or newer recommended)
* Dart SDK

### Installation
1. Clone the repository:
   ```bash
   git clone https://github.com/inositols/vitalAI.git
   cd vitalAI
   ```
2. Retrieve dependencies:
   ```bash
   flutter pub get
   ```
3. Run the project locally on your desired simulator or target platform:
   ```bash
   flutter run
   ```

---

## 🧪 Testing
Run the complete test suite (unit, BLoC, and widget tests) with:
```bash
flutter test
```
