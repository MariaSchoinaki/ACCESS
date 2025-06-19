<div align="center">  <h1>ACCESS</h1> </div> 
<div align="center">
    <img src =https://github.com/user-attachments/assets/e282bbde-a32d-4079-b9dc-67cb6d140c5e  width = "300px">
</div>

**ACCESS** is a mobile and web platform designed to empower people with disabilities and mobility limitations to navigate urban environments with ease and confidence.


Built with Flutter, Dart, and modern geolocation technologies, ACCESS provides real-time accessibility data, user-generated feedback, and intelligent route planning based on accessibility scores.

[Video](https://drive.google.com/file/d/1coYtmAbKNWtAcGz6Zxd1Ak_M5o4avgtl/view)

---

##  Overview

ACCESS provides a holistic experience for both everyday users and city authorities. It allows users to:

- Discover the most accessible routes.
- Report obstacles or issues in real time.
- View detailed feedback, photos, and accessibility tags.
- Get personalized suggestions via geo-push notifications.
- Help the community by validating or contributing to crowdsourced data.

Meanwhile, public institutions can:

- Monitor accessibility stats via Power BI dashboards.
- Export data for analysis and reporting.
- Intervene faster in urban mobility issues.

It also has an mobile aplication for admins, where they can:
  - View reports uploaded by users
  - Approve/Reject the reports

## Features

- **Interactive Accessibility Map**  
  View streets, sidewalks, and public spaces tagged with accessibility information (ramps, elevators, inclines, obstacles, etc.).

- **Crowdsourced Data**  
  Users can contribute:  
  📸 Photos of locations  
  📝 Comments about accessibility  
  🏷️ Tags (e.g., “no ramp”, “stairs”)

- **Shortest Accessible Path (SAP) Algorithm**  
  Get directions optimized not just for distance, but also for accessibility, with color-coded visualizations based on an accessibility score.

- **Dynamic Update Algorithm** 
  Adapts routes based on live user reports and environmental changes.

- **Route Trajectory Visualization** 
  Smooth polylines for step-by-step navigation.

- **Haversine Formula** 
  Accurate distance calculation between GPS coordinates.
  
- **Levenshtein Distance** 
  Fuzzy matching of street names and tags for better querying.
  
- **Clustering of Reports** 
  Groups nearby reports to reduce clutter and optimize analysis.

- **Real-time Navigation**  
  Step-by-step navigation with compass orientation, off-route detection, and accessible turn-by-turn instructions with voice.

- **Geofencing-based Notifications**  
  Receive relevant alerts based on your location (e.g., "Obstacle report was just made near you").

- **Power BI Integration** 
  Real-time dashboards with charts, trends, and KPIs.

- **Photo & Tagging System** 
  Users can attach images, and comments to each location.

---
## ⚙️ Tech Stack

| Layer     | Tech                                      |
| --------- | ---------------------------------------- |
| Frontend  | Flutter (Dart), Bloc, Mapbox              |
| Backend   | Dart (Custom Microservices), Docker Swarm |
| Auth      | Firebase Authentication                   |
| Notifications | Firebase Cloud Messaging (FCM), Geofencing |
| Data & Reports | Cloud Storage + Power BI (for municipalities analytics) |

---

## 📦 Installation

**Firstly clone the repo**
```bash
git clone https://github.com/EleniKechrioti/ACCESS.git 
```
change in the following lines the IP
* In [search_service.dart](https://github.com/EleniKechrioti/ACCESS/blob/main/frontend/lib/services/search_service.dart) in line 42.
* In [notification_service.dart](https://github.com/EleniKechrioti/ACCESS/blob/main/frontend/lib/services/notification_service.dart) in line 60.
* In [map_service.dart](https://github.com/EleniKechrioti/ACCESS/blob/main/frontend/lib/services/map_service.dart) in line 31.

**To run backend:**

```bash
# You need to install docker hub and create an account
docker swarm init

# Take your keys from mapbox, google maps and firebase
echo "key" | docker secret create mapbox_token -
echo "key" | docker secret create google_maps_key -
docker secret create firebase_conf1.json services/update_service/your_firebase_conf.json
docker secret create firebase_conf2.json services/notification_service/your_firebase_conf.json
docker secret create firebase_conf3.json services/report_sync_service/your_firebase_conf.json
docker secret create firebase_conf4.json services/report_map_service/your_firebase_conf.json

# Build your containers
docker build -f gateway/Dockerfile -t your_dockerhubname/access_gateway:latest .
docker build -f services/notification_service/Dockerfile -t your_dockerhubname/access_notification_service:latest .
docker build -f services/report_sync_service_service/Dockerfile -t your_dockerhubname/access_report_sync_service:latest .
docker build -f services/search_service/Dockerfile -t your_dockerhubname/access_search_service:latest .
docker build -f services/update_service/Dockerfile -t your_dockerhubname/access_update_service:latest .
docker build -f services/map_service/Dockerfile -t your_dockerhubname/access_map_service:latest .

# Finally deploy them. Don't forget to change in stack.yml the images to your_dockerhubusername
docker stack deploy -c docker-compose.yml access_stack

```

**To run mobile frontend:**
```bash
# Install Flutter dependencies
flutter pub get

# Select your mobile phone / emulator and run the app
flutter run --dart-define=token=mapbox_token
```

**To run web frontend:**
```bash
# Install Flutter dependencies
flutter pub get

# Select your browser and run the app
flutter run --dart-define=token=public_mapbox_token
```

**To close backend:**
```bash
docker stack rm access_stack
docker swarm leave --force
# Optional/ removes all images, volumes, networks, containers
docker system prune -a
```


# Contributors
- [Anthippi Fatsea](https://github.com/Anthippi)
- [Maria Schoinaki](https://github.com/MariaSchoinaki)
- [Eleni Kechrioti](https://github.com/EleniKechrioti)
