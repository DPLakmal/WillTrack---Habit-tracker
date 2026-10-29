# Privacy Policy for WillTrack

**Last updated:** October 30, 2026

WillTrack ("we", "our", or "us") is committed to protecting your privacy. This Privacy Policy explains how our mobile application handles user information.

---

### 1. Zero Data Collection & Offline-First Design

WillTrack is built on an offline-first architecture. 

* **No User Accounts**: You do not need to register an account, sign in, or provide an email address, name, or phone number to use WillTrack.
* **Local Storage Only**: All your habit tracking data—including habit names, descriptions, completion history, streaks, routines, targets, difficulties, and personal reflection notes—is stored exclusively on your device in a local SQLite database (`Drift`).
* **No Remote Servers**: We do not operate remote databases or cloud servers that store, process, or sync your habits. Your data stays with you on your device.

---

### 2. Device Permissions & Why We Use Them

WillTrack requests only the minimal Android permissions necessary to provide its habit-tracking functionality:

* **Post Notifications (`android.permission.POST_NOTIFICATIONS`)**:
  Used solely to display habit reminder notifications at times you explicitly configure.
* **Exact Alarms (`android.permission.SCHEDULE_EXACT_ALARM`)**:
  Used strictly to ensure habit reminders trigger at the precise hour and minute you choose, even when the app is in the background or device power-saving mode.
* **Vibrate (`android.permission.VIBRATE`)**:
  Used to provide haptic feedback when a scheduled habit reminder fires.
* **Receive Boot Completed (`android.permission.RECEIVE_BOOT_COMPLETED`)**:
  Used to re-register your active habit reminder schedules with the Android system after your device reboots.

We do **not** access your contacts, camera, microphone, GPS location, or external files.

---

### 3. Third-Party Services & Analytics

* **No Ad Networks**: WillTrack contains zero advertising networks and does not display ads.
* **No Analytics or Trackers**: We do not integrate third-party analytics trackers (such as Google Analytics for Firebase, Facebook SDK, or Mixpanel). We do not track your behavioral interactions or habit completion rates.
* **No Third-Party Sharing**: We do not sell, rent, trade, or share any personal information with third parties.

---

### 4. Data Retention & Deletion

Because all data resides locally on your device:
* You can delete individual habits, check-ins, or notes directly in the app at any time.
* Uninstalling the application or clearing the application storage in your Android device settings permanently deletes all data associated with WillTrack.

---

### 5. Children's Privacy

WillTrack does not knowingly collect any personally identifiable information from children under the age of 13. The application is completely private and functional without data transmission.

---

### 6. Changes to This Privacy Policy

We may update our Privacy Policy from time to time. Any changes will be posted in this document within our public code repository.

---

### 7. Contact Us

If you have any questions or feedback regarding this Privacy Policy, please contact us at:

* **Developer**: Pubudu Lakmal
* **Email**: pubudu.lakmalc@gmail.com
* **Repository**: [https://github.com/DPLakmal/WillTrack---Habit-tracker](https://github.com/DPLakmal/WillTrack---Habit-tracker)
