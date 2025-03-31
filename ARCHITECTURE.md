# FitFlow App Architecture Plan

This document outlines the planned architecture for the FitFlow Flutter application.

**Core Technologies:**

- **Frontend:** Flutter (Cross-platform UI framework)
- **Backend:** Firebase (Authentication, Firestore Database)
- **State Management:** Riverpod
- **Health Data:** Platform-specific Health APIs (Apple HealthKit / Google Fit) via `package:health`.
- **Nutrient Data:** FatSecret API (accessed via Firebase Cloud Functions for security).
- **Local Notifications:** `package:flutter_local_notifications`
- **Local Storage:** Hive or SQLite (via `sqflite`) for offline support
- **Localization:** `flutter_localizations` and `intl` packages
- **Theme Management:** ThemeData with Material 3 dynamic colors

**Proposed Architecture Diagram:**

```mermaid
graph LR
    subgraph Flutter App
        direction TB
        UI(UI Layer - Widgets/Screens) --> SM(State Management - Riverpod);
        SM --> BL(Business Logic / Controllers);
        BL --> Nav(Navigation);
        BL --> Repo(Repositories);
        BL --> NotifService(Notification Service);
        BL --> ErrorService(Error Handling Service); %% Added Error Service
        BL --> ThemeService(Theme Service); %% Added Theme Service
        BL --> ExportService(Data Export Service); %% Added Export Service
        UI --> A11yService(Accessibility Service); %% Added Accessibility Service
        UI --> Onboarding(Onboarding Flow); %% Added Onboarding Flow
    end

    subgraph Repositories [Data Layer]
        direction TB
        AuthRepo(Auth Repository) --> FirebaseSDK;
        UserDataRepo(User Data Repository) --> FirebaseSDK;
        HealthRepo(Health Data Repository) --> HealthPlugin;
        NutrientRepo(Nutrient Repository) --> CloudFunctions;
        LocalDataRepo(Local Data Repository) --> LocalStorageAPI; %% Added Local Data Repository
    end

    subgraph Backend & External Services
        direction TB
        FirebaseSDK(Firebase SDK - Auth, Firestore) --> Firebase;
        HealthPlugin(Health Plugin - 'health') --> PlatformHealthAPI;
        NotifPlugin(Notification Plugin - 'flutter_local_notifications') --> PlatformNotifAPI;
        CloudFunctions(Firebase Cloud Functions) --> FatSecretAPI;
        FatSecretAPI(FatSecret API Client) --> FatSecret;
        LocalStorageAPI(Local Storage - Hive/SQLite) --> DeviceStorage; %% Added Local Storage
        Firebase(Firebase Cloud);
        PlatformHealthAPI(iOS HealthKit / Android Google Fit);
        PlatformNotifAPI(iOS UNUserNotificationCenter / Android NotificationManager);
        FatSecret(FatSecret Service);
        DeviceStorage(Device Local Storage); %% Added Device Storage
    end

    UI -- Reads state from --> SM;
    UI -- Calls methods in --> BL;
    BL -- Updates state in --> SM;
    BL -- Uses --> Repo;
    BL -- Uses --> NotifService;
    BL -- Uses --> ErrorService; %% Added link
    BL -- Uses --> ThemeService; %% Added link
    BL -- Uses --> ExportService; %% Added link
    UI -- Uses --> A11yService; %% Added link
    NotifService -- Uses --> NotifPlugin;
    CloudFunctions -- Securely calls --> FatSecretAPI;
    Repo -- Reads/Writes --> LocalDataRepo; %% Added link for offline-first approach


    %% Style Adjustments for Readability
    style Flutter App fill:#f9f,stroke:#333,stroke-width:2px
    style Repositories fill:#ccf,stroke:#333,stroke-width:2px
    style Backend & External Services fill:#cfc,stroke:#333,stroke-width:2px
    style UI fill:#FFF,stroke:#000
    style SM fill:#FFF,stroke:#000
    style BL fill:#FFF,stroke:#000
    style Nav fill:#FFF,stroke:#000
    style Repo fill:#FFF,stroke:#000
    style NotifService fill:#FFF,stroke:#000
    style ErrorService fill:#FFF,stroke:#000 %% Added style
    style ThemeService fill:#FFF,stroke:#000 %% Added style
    style ExportService fill:#FFF,stroke:#000 %% Added style
    style A11yService fill:#FFF,stroke:#000 %% Added style
    style Onboarding fill:#FFF,stroke:#000 %% Added style
    style AuthRepo fill:#FFF,stroke:#000
    style UserDataRepo fill:#FFF,stroke:#000
    style HealthRepo fill:#FFF,stroke:#000
    style NutrientRepo fill:#FFF,stroke:#000
    style LocalDataRepo fill:#FFF,stroke:#000 %% Added style
    style FirebaseSDK fill:#FFF,stroke:#000
    style HealthPlugin fill:#FFF,stroke:#000
    style NotifPlugin fill:#FFF,stroke:#000
    style CloudFunctions fill:#FFF,stroke:#000
    style FatSecretAPI fill:#FFF,stroke:#000
    style LocalStorageAPI fill:#FFF,stroke:#000 %% Added style
    style Firebase fill:#FFCA28,stroke:#000
    style PlatformHealthAPI fill:#ADD8E6,stroke:#000
    style PlatformNotifAPI fill:#ADD8E6,stroke:#000
    style FatSecret fill:#90EE90,stroke:#000
    style DeviceStorage fill:#ADD8E6,stroke:#000 %% Added style
```

**Explanation of Components:**

1.  **Flutter App:**

    - **UI Layer:** Widgets and screens (`/lib/src/features/.../presentation`).
    - **State Management (Riverpod):** Manages application state using Riverpod providers (`/lib/src/features/.../application` or `/lib/src/features/.../presentation`). Providers connect UI to Business Logic/Repositories.
    - **Business Logic / Controllers:** Contains logic specific to features, orchestrating calls to repositories and services (`/lib/src/features/.../application`).
    - **Navigation:** Handles routing (`/lib/src/routing`). GoRouter is a common choice.
    - **Repositories (Interfaces):** Abstract definitions for data operations (`/lib/src/features/.../domain` or `/lib/src/data/repositories`).
    - **Notification Service:** Handles scheduling and displaying local notifications (`/lib/src/services` or within relevant features).
    - **Error Handling Service:** Centralized error handling and reporting (`/lib/src/services/error`).
    - **Theme Service:** Manages app theming, dark mode, and user preferences (`/lib/src/services/theme`).
    - **Data Export Service:** Manages export of user health and workout data (`/lib/src/services/export`).
    - **Accessibility Service:** Manages accessibility settings and features (`/lib/src/services/accessibility`).
    - **Onboarding Flow:** First-time user experience components (`/lib/src/features/onboarding`).

2.  **Data Layer (`/lib/src/data`):**

    - **Repository Implementations:** Concrete implementations of the repository interfaces.
      - `AuthRepository`: Uses `firebase_auth`.
      - `UserDataRepository`: Uses `cloud_firestore`.
      - `HealthRepository`: Uses `package:health`.
      - `NutrientRepository`: Makes HTTP calls to a Firebase Cloud Function.
      - `LocalDataRepository`: Manages local data persistence using Hive/SQLite.
    - **Data Sources:** Lower-level classes interacting directly with external sources (Firebase SDKs, HTTP client, Health Plugin).

3.  **Backend & External Services:**
    - **Firebase SDK:** Integrated libraries for Auth and Firestore.
    - **Health Plugin:** Bridge to native HealthKit/Google Fit.
    - **Notification Plugin:** Bridge to native notification APIs via `flutter_local_notifications`.
    - **Firebase Cloud Functions:** Serverless functions to securely interact with the FatSecret API (requires separate deployment).
    - **FatSecret API Client:** HTTP client within the Cloud Function.
    - **Local Storage API:** Interface to local database (Hive/SQLite) for offline functionality.
    - **Firebase Cloud:** Hosting for Auth, Firestore, and Cloud Functions.
    - **Platform Health API:** Native OS services (HealthKit/Google Fit).
    - **Platform Notification API:** Native OS services for notifications.
    - **FatSecret Service:** External nutrient database API.
    - **Device Storage:** Local device storage for offline data persistence.

**Directory Structure (`lib/src`):**

- `features/`: Contains modules for each app feature (e.g., `auth`, `dashboard`, `profile`, `nutrition_logging`, `exercise_logging`, `onboarding`). Each feature might follow sub-structure like `application` (logic/state), `domain` (models/interfaces), `presentation` (UI), `data` (feature-specific data handling if needed).
- `data/`: Contains core data repositories implementations and data source logic.
- `routing/`: App navigation configuration.
- `services/`: Contains application-wide services:
  - `notification/`: Notification management.
  - `error/`: Error handling and reporting.
  - `theme/`: Theme management and persistence.
  - `export/`: Data export functionality.
  - `accessibility/`: Accessibility configurations.
  - `connectivity/`: Network state monitoring for offline support.
- `common_widgets/`: Reusable UI components.
- `utils/`: Utility functions, constants, extensions.
- `domain/`: (Optional) Core domain models shared across features if not placed within feature folders.
- `localization/`: Localization resources and utilities.

**Offline Support Strategy:**

The app will implement an offline-first approach with the following components:

- **Local Data Cache:** All remote data will be cached locally using Hive or SQLite.
- **Synchronization Service:** Handles bidirectional sync between local and remote data.
- **Connectivity Monitoring:** Tracks network status to adapt app behavior accordingly.
- **Conflict Resolution:** Implements strategies to handle conflicting changes between local and remote data.

**Error Handling Strategy:**

A centralized error handling approach will:

- **Categorize Errors:** Network, authentication, validation, permission, etc.
- **User Feedback:** Provide appropriate, user-friendly error messages.
- **Graceful Degradation:** Allow app functionality to continue despite non-critical errors.
- **Logging:** Record errors for analytics and debugging purposes.
- **Recovery Mechanisms:** Implement retry logic and fallback options.

**Theming and Appearance:**

The app will support:

- **Multiple Themes:** Light and dark modes plus optional accent colors.
- **Dynamic Theming:** Support Material 3 dynamic color on compatible devices.
- **Persistent Preferences:** Save user theme preferences locally.
- **System Integration:** Follow system theme preferences.

**Accessibility Features:**

The app will implement:

- **Screen Reader Support:** Semantic labels and descriptions for UI elements.
- **Adjustable Text Sizing:** Support system font scaling.
- **Sufficient Contrast:** Ensure all UI elements meet WCAG guidelines.
- **Focus Navigation:** Support keyboard and switch device navigation.
- **Reduced Motion:** Option to minimize animations for users sensitive to motion.

**User Onboarding:**

A comprehensive onboarding experience will:

- **Introduce Key Features:** Guide users through core app functionality.
- **Permission Context:** Explain why permissions are needed before requesting.
- **Initial Setup:** Help users set personal goals and preferences.
- **Progressive Disclosure:** Reveal advanced features gradually.
- **Skip Option:** Allow experienced users to bypass onboarding.

**Data Export Capabilities:**

The app will enable users to:

- **Export Formats:** Generate CSV, JSON, or PDF exports of health and fitness data.
- **Custom Date Ranges:** Select specific time periods for export.
- **Selective Content:** Choose which data types to include in exports.
- **Sharing Options:** Share exports via standard platform share sheets.
- **Privacy Controls:** Clear explanations of what data is included in exports.

This plan provides a comprehensive, structured approach for building the FitFlow application with robust offline support, error handling, theming options, accessibility features, user onboarding, and data export capabilities.
