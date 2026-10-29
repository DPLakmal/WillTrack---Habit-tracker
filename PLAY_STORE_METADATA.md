# Google Play Store Listing & Metadata Guide for WillTrack

This guide provides the exact text, keywords, and declarations required when publishing **WillTrack** on the [Google Play Console](https://play.google.com/console).

---

## 📱 1. Store Listing Details

### App Title (Max 30 characters)
```text
WillTrack: Habit Tracker
```

### Short Description (Max 80 characters)
```text
Build lasting routines with Apple Glass UI, streaks, stacking & offline privacy.
```
*(Character count: 79 / 80)*

### Full Description (Max 4000 characters)
```text
Build better habits, master daily routines, and achieve your long-term goals with WillTrack — the elegant, offline-first habit tracker designed with stunning Apple Glass aesthetics.

Whether you want to read more books, drink more water, maintain a morning workout routine, or learn coding, WillTrack empowers you with intuitive tracking, smart routines, and actionable insights.

🌟 WHY WILLTRACK?

💎 STUNNING APPLE GLASS DESIGN
Experience a fluid, frosted-glass interface that feels natural, modern, and distraction-free on your device. Every transition, chart, and card is crafted for visual delight.

⏱️ 3 POWERFUL HABIT TYPES
• Boolean Habits: Simple Yes/No check-ins (e.g. "Take vitamins", "Make bed").
• Quantity Habits: Track countable metrics with custom units (e.g. "Drink 8 glasses", "Read 20 pages").
• Duration Habits: Built-in focus timer and quick-log buttons for time-based targets (e.g. "Study for 45 mins", "Meditate 15 mins").

🌅 TIME-OF-DAY ROUTINES
Organize habits into Morning, Afternoon, Evening, or Anytime routines. Stay focused on what matters right now without feeling overwhelmed by your entire day.

🔗 HABIT STACKING & CUES
Anchor new habits to established routines (e.g. "Drink water" immediately after "Morning Stretch"). WillTrack prompts you when prerequisite anchor habits are completed.

📈 STREAKS, CALENDARS & STATS
• Current & Longest Streaks: Stay motivated by watching your consistency grow.
• Monthly Calendar Heatmaps: Visual breakdown of your daily consistency.
• 1-10 Difficulty Scoring: Rate how hard each session was to analyze resistance patterns and prevent burnout.
• Weekly Completion Ratios: Clear weekly reviews to celebrate wins and identify growth opportunities.

🎯 LONG-TERM GOALS
Connect day-to-day habits directly to major milestones (e.g. connect "Run 5K" to "Complete Half Marathon").

🏆 11 MILESTONE ACHIEVEMENTS
Unlock celebratory badges as you hit key milestones: First Step, 3-Day Spark, Week Warrior, Habit Master, Century Club, Early Riser, and more.

🔔 TIMEZONE-AWARE REMINDERS
Set customizable daily reminders with exact alarm scheduling so you never miss a routine.

🔒 100% PRIVATE & OFFLINE-FIRST
Your habits are personal. WillTrack stores all data strictly on your local device.
• No account registration or sign-in required.
• No cloud tracking, analytics, or behavioral surveillance.
• Zero advertisements.

Start building habits that stick. Download WillTrack today!
```

---

## 🏷️ 2. Categorization & Contact Details

* **App Category**: `Productivity` (or `Health & Fitness`)
* **Tags**: `Habit Tracker`, `Productivity`, `Routine Planner`, `Self Care`, `Goal Tracker`
* **Contact Email**: `pubudu.lakmalc@gmail.com`
* **Privacy Policy URL**:
  `https://github.com/DPLakmal/WillTrack---Habit-tracker/blob/main/PRIVACY_POLICY.md`

---

## 🛡️ 3. Google Play Policy & Declarations

### A. Data Safety Questionnaire
| Question | Answer | Notes |
| :--- | :--- | :--- |
| Does your app collect or share user data? | **No** | All database records stay on local device |
| Does your app use encryption in transit? | **N/A** | No network requests performed |
| Can users request data deletion? | **Yes** | Deleting habit or clearing storage deletes data |

### B. Target Audience & Content Rating
* **Target Age**: 13 and older (or All Ages).
* **Ads Declaration**: Select **"No, my app does not contain ads"**.
* **Financial Features**: Select **"No"**.
* **Health / Medical Advice**: Select **"No"** (general habit tracker).

### C. Exact Alarm Declaration (`SCHEDULE_EXACT_ALARM`)
When Google Play asks for the reason for `SCHEDULE_EXACT_ALARM`:
* **Use Case Selection**: Choose **"Reminders / Calendar / Alarms"**.
* **Justification**:
  *"WillTrack is a habit tracking and routine planning application. The exact alarm permission is required so that users receive notifications for their scheduled habits at the precise hour and minute configured by the user."*

---

## 🎨 4. Store Graphic Assets Checklist

| Asset | Specifications | Status / Requirement |
| :--- | :--- | :--- |
| **App Icon** | 512 × 512 px, PNG (32-bit), max 1024 KB, no alpha/transparency | Can export from `assets/logo/app_logo.png` |
| **Feature Graphic** | 1024 × 500 px, PNG or JPEG, max 15 MB | Landscape promotional banner showcasing app title and glass UI |
| **Phone Screenshots** | Min 2, max 8 screenshots, 16:9 or 9:16 aspect ratio | Capture from Home, Habit Detail, Routines, and Weekly Review screens |
