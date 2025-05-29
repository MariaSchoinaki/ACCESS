# 📱 ACCESS — Accessible City Companion

**ACCESS** is a mobile and web platform designed to empower people with disabilities and mobility limitations to navigate urban environments with ease and confidence.

Built with Flutter, Dart, and modern geolocation technologies, ACCESS provides real-time accessibility data, user-generated feedback, and intelligent route planning based on accessibility scores.

---

## 🚀 Features

- **Interactive Accessibility Map**  
  View streets, sidewalks, and public spaces tagged with accessibility information (ramps, elevators, inclines, obstacles, etc.).

- **Smart Route Planning**  
  Get directions optimized not just for distance, but also for accessibility, with color-coded visualizations based on an accessibility score.

- **Crowdsourced Data**  
  Users can contribute:  
  📸 Photos of locations  
  📝 Comments about accessibility  
  🏷️ Tags (e.g., “no ramp”, “smooth surface”)

- **Real-time Navigation**  
  Step-by-step navigation with compass orientation, off-route detection, and accessible turn-by-turn instructions.

- **Geofencing-based Notifications**  
  Receive relevant alerts based on your location (e.g., "Ramp ahead", "Construction zone nearby").

- **Municipality Dashboard (Web)**  
  A separate interface for local authorities to:
    - Analyze accessibility reports
    - View usage statistics (via Power BI)
    - Export reports (PDF, charts)

---

## ⚙️ Tech Stack

| Layer     | Tech                                      |
| --------- | ---------------------------------------- |
| Frontend  | Flutter (Dart), Bloc, Mapbox              |
| Backend   | Dart (Custom Microservices), Docker Swarm |
| Auth      | Firebase Authentication                   |
| Notifications | Firebase Cloud Messaging (FCM), Geofencing |
| Data & Reports | Cloud Storage + Power BI (for admin analytics) |

---

## 🔒 Accessibility First

Every decision in ACCESS is guided by inclusivity. Whether you're using a wheelchair, walker, or just need easier routes due to temporary injuries, ACCESS adapts to you.

---

## 🌍 Target Users

- People with disabilities (mobility, vision)
- Elderly citizens
- Parents with strollers
- Urban planners and local governments

---

## 📦 Installation (for Devs)

```bash
# Clone the repo
git clone https://github.com/your-org/access-app.git

# Install Flutter dependencies
flutter pub get

# Run the app
flutter run