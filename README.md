<div align="center">

# 🔍 Sprout Camera Quest

### *Little minds. Big adventures.*

---
## 📸 Demo

> 🎥 [Watch 2-Minute Demo Video](https://drive.google.com/drive/folders/1ts_C2jEUhWeiYRKFZXBkQPmaCat1lhoc)

---

![Flutter](https://img.shields.io/badge/Flutter-3.41.4-02569B?style=for-the-badge&logo=flutter&logoColor=white)
![Dart](https://img.shields.io/badge/Dart-3.11.1-0175C2?style=for-the-badge&logo=dart&logoColor=white)
![Android](https://img.shields.io/badge/Android-Supported-3DDC84?style=for-the-badge&logo=android&logoColor=white)
![ML Kit](https://img.shields.io/badge/Google_ML_Kit-Image_Labeling-4285F4?style=for-the-badge&logo=google&logoColor=white)

> A camera-powered learning adventure app for children aged 3–8.  
> Kids explore the real world around them, snap photos, and complete exciting quests!


</div>

---

## 🎮 What is Sprout Camera Quest?

Sprout Camera Quest turns the real world into a playground. Kids pick a quest, point their camera at objects around them, and the app uses **Google ML Kit** to identify what they found. Complete all 5 finds to win confetti, stars, and a celebration!

No reading required. No wrong answers. Just pure exploration and joy.

---

## ✨ Features

| Feature | Description |
|---|---|
| 🎯 **6 Unique Quests** | Flower Hunt, Animal Safari, Food Quest, Vehicle Hunt, Nature Walk, Home Explorer |
| 📸 **Live Camera** | Real-time camera with viewfinder and capture button |
| 🤖 **ML Object Detection** | Google ML Kit identifies real-world objects instantly |
| 💾 **Progress Saving** | Quest progress saved locally — resumes exactly where you left off |
| ⭐ **Star System** | Earn 3 stars per completed quest, track total stars on home screen |
| 🏆 **Win Screen** | Photo collection grid, confetti explosion, and cheer sound on completion |
| 🔄 **Play Again** | Replay any completed quest anytime |
| 👤 **Personalised** | Saves child's name on first launch, greets them by name every time |
| 🌅 **Dynamic Greeting** | Good morning / afternoon / evening based on time of day |
| 🎵 **Sound Effects** | Camera snap sound + cheer celebration music |

---

## 📱 App Screens

```
🌱 Splash Screen        — Animated logo, floating emojis, quest preview pills
      ↓
👋 Name Entry           — First launch only, saved permanently on device  
      ↓
🏠 Home Screen          — Greeting, stats bar, 6 quest cards with live status
      ↓
📸 Camera Screen        — Live camera, viewfinder, progress dots, toast alerts
      ↓
🏆 Win Screen           — Trophy, stars, photo collection grid, play again
```

---

## 🗂️ Project Structure

```
sprout_camera_quest/
├── lib/
│   ├── main.dart                    # App entry point, portrait lock, theme
│   ├── models/
│   │   └── quest.dart               # Quest data model
│   ├── utils/
│   │   └── prefs.dart               # SharedPreferences helper (name, progress, stars)
│   └── screens/
│       ├── splash_screen.dart       # Animated splash with floating emojis
│       ├── name_entry_screen.dart   # First-time name entry
│       ├── home_screen.dart         # Quest selection + stats dashboard
│       ├── camera_screen.dart       # Live camera + ML Kit labeling
│       └── win_screen.dart          # Celebration + photo collection
├── assets/
│   └── sounds/
│       ├── snap.mp3                 # Camera shutter sound
│       └── cheer.mp3                # Win celebration music
└── pubspec.yaml
```

---

## 🛠️ Tech Stack

| Package | Version | Purpose |
|---|---|---|
| `flutter` | 3.41.4 | UI framework |
| `dart` | 3.11.1 | Programming language |
| `camera` | ^0.11.0 | Device camera access and live preview |
| `google_mlkit_image_labeling` | ^0.13.0 | Real-world object identification |
| `permission_handler` | ^11.3.1 | Runtime camera permission |
| `shared_preferences` | ^2.3.2 | Local storage for name, progress, stars |
| `confetti` | ^0.7.0 | Win celebration confetti animation |
| `audioplayers` | ^6.0.0 | Snap + cheer sound effects |
| `animate_do` | ^3.3.4 | Smooth screen entry animations |

---

## 🎯 How the Quests Work

Each quest has a **theme-specific label list**. When the child taps 📸:

1. Photo is captured silently
2. ML Kit scans the image and returns detected labels
3. App checks if any label matches the **quest's allowed list**
4. If matched → added to collection ✅
5. Same label allowed up to **2 times** (shown as "Car" and "Car 2")
6. After **5 items** collected → Quest complete! 🏆

| Quest | Theme Labels Include |
|---|---|
| 🌸 Flower Hunt | flower, rose, tulip, plant, blossom, petal... |
| 🐾 Animal Safari | cat, dog, bird, fish, rabbit, parrot... |
| 🍎 Food Quest | fruit, apple, bread, snack, cake, juice... |
| 🚗 Vehicle Hunt | car, truck, bus, bicycle, motorcycle... |
| 🌿 Nature Walk | tree, leaf, rock, sky, cloud, grass... |
| 🏠 Home Explorer | chair, table, lamp, book, cup, clock... |

---

## 💾 Data Persistence

All data is stored **locally on the device** using `SharedPreferences`:

```
user_name                     → Child's name (set once, never asked again)
quest_{id}_status             → notstarted / inprogress / completed
quest_{id}_progress           → Number of items found (0–5)
quest_{id}_stars              → Stars earned (0–3)
quest_{id}_items              → JSON list of collected photos + labels
total_stars                   → Total stars across all quests
```

**No internet required. No accounts. No data leaves the device.**

---

## 🎨 Design Decisions

### Why no login?
Kids aged 3–8 don't have emails or passwords. A simple one-time name entry gives a personal experience with zero friction. Parents don't need to set anything up.

### Why resume progress?
If a child closes the app mid-quest, their photos and progress are saved. Reopening the quest shows "Welcome back! You found 3 so far!" — no frustration, no starting over.

### Why allow same label twice?
A child doing Vehicle Hunt should be able to snap two different cars. Blocking the second car is confusing and frustrating. Allowing up to 2 of the same label encourages exploration while preventing lazy single-object spamming.

### Why quest-specific label matching?
Without filtering, ML Kit would accept a keyboard during Vehicle Hunt or a pencil during Flower Hunt. Theme-specific labels make each quest feel distinct and purposeful — kids feel like real explorers on a specific mission.

### Why confetti + sound on win?
Young children need multi-sensory reward signals. Visual (confetti), audio (cheer), and social (trophy screen with photos) together create a powerful emotional peak that motivates replaying.

---


## 👨‍💻 Author

**Mohammad Kapadia**


---
