# 🧹 CleanSlate

**Smart Chore Management for Student Households**

CleanSlate is a Flutter-based mobile application designed specifically for students living in shared accommodations — dorms, apartments, or houses with roommates. It streamlines household chore distribution through intelligent scheduling that respects everyone's academic schedules, preferences, and availability.

![Flutter](https://img.shields.io/badge/Flutter-02569B?style=for-the-badge&logo=flutter&logoColor=white)
![Supabase](https://img.shields.io/badge/Supabase-3ECF8E?style=for-the-badge&logo=supabase&logoColor=white)
![Google Calendar](https://img.shields.io/badge/Google%20Calendar-4285F4?style=for-the-badge&logo=google-calendar&logoColor=white)

---

## 📖 Table of Contents

- [Overview](#-overview)
- [Key Features](#-key-features)
- [Screenshots](#-screenshots)
- [Tech Stack](#-tech-stack)
- [Architecture](#-architecture)
- [Getting Started](#-getting-started)
- [Configuration](#-configuration)
- [Database Schema](#-database-schema)
- [Project Structure](#-project-structure)
- [Roadmap](#-roadmap)
- [Contributing](#-contributing)
- [License](#-license)

---

## 🎯 Overview

Managing chores in a shared living space is challenging — especially for students juggling classes, assignments, and social lives. CleanSlate solves this by:

1. **Setting preferences once** — availability, chore likes/dislikes, weekend travel patterns
2. **Syncing with Google Calendar** — automatically avoids scheduling during classes
3. **Operating transparently** — chores appear on your calendar without constant app interaction
4. **Ensuring fairness** — distributes tasks based on preferences and workload balance

### Who is this for?

- 🎓 College/university students in dorms or shared apartments
- 🏠 Roommates who want a fair, automated chore system
- 👨‍👩‍👧‍👦 Any household seeking smart task distribution

---

## ✨ Key Features

### 🏠 Household Management
- Create households with unique 8-character invite codes
- Join existing households via code or QR scan
- Role-based permissions (Admin/Member)
- View all household members and their roles

### ✅ Chore Management
- Create chores with descriptions and to-do subtasks
- Set priority levels (Low, Medium, High)
- Configure recurrence patterns (Daily, Weekly, Monthly, Weekdays, Weekends)
- Assign chores to specific members with due dates
- Track completion status with one-tap marking

### 📅 Calendar Integration
- Connect Google Calendar with OAuth 2.0
- Automatically sync assigned chores to your calendar
- Respect class schedules when assigning tasks
- Background sync — no manual intervention needed

### ⚙️ Smart Preferences
- Set available days for chores
- Choose preferred time slots (Morning, Afternoon, Evening)
- Rate each chore type (1-5 scale) for preference-based assignment
- "I go home on weekends" toggle for commuter students
- Maximum chores per week limit

### 🔔 Notifications
- Real-time push notifications for new assignments
- In-app notification center with read/unread status
- Deadline approaching reminders
- Member joined/left household alerts

### 👤 User Profile
- Email/password or Google Sign-In authentication
- Profile picture upload (or sync from Google)
- Link Google account to existing email account
- Dark mode support
- Account deletion option

---

## 📱 Screenshots

> *Screenshots coming soon*

| Home Screen | Schedule View | Preferences |
|-------------|---------------|-------------|
| View your assigned chores | Week/month calendar view | Set availability & ratings |

---

## 🛠 Tech Stack

### Frontend
| Technology | Purpose |
|------------|---------|
| **Flutter 3.7+** | Cross-platform UI framework |
| **Provider** | State management |
| **flutter_svg** | SVG icon rendering |
| **table_calendar** | Calendar widget |
| **fl_chart** | Statistics charts |
| **mobile_scanner** | QR code scanning |

### Backend (Supabase)
| Service | Purpose |
|---------|---------|
| **Authentication** | Email/password, Google OAuth, Magic Links |
| **PostgreSQL Database** | All application data with RLS |
| **Storage** | Profile image uploads (`user-images` bucket) |
| **Realtime** | Live notification subscriptions |
| **Edge Functions** | Scheduled deadline checks |

### External APIs
| API | Purpose |
|-----|---------|
| **Google Calendar API** | Calendar sync and event creation |
| **Google Sign-In** | OAuth authentication |

---

## 🏗 Architecture

CleanSlate follows a **feature-first** architecture with clear separation of concerns:

```
┌─────────────────────────────────────────────────────────────┐
│                        UI Layer                              │
│  (Screens, Widgets, Providers)                              │
├─────────────────────────────────────────────────────────────┤
│                    Repository Layer                          │
│  (ChoreRepository, HouseholdRepository, etc.)               │
├─────────────────────────────────────────────────────────────┤
│                     Service Layer                            │
│  (SupabaseService, CalendarService, NotificationService)    │
├─────────────────────────────────────────────────────────────┤
│                     Data Layer                               │
│  (Models, Supabase Client)                                  │
└─────────────────────────────────────────────────────────────┘
```

### Data Flow
1. **UI** calls **Repository** methods
2. **Repository** uses **Services** for API calls
3. **Services** interact with **Supabase** and external APIs
4. **Models** define data structures for type safety

---

## 🚀 Getting Started

### Prerequisites

- [Flutter SDK](https://docs.flutter.dev/get-started/install) (3.7.0 or higher)
- [Supabase Account](https://supabase.com) (free tier works)
- [Google Cloud Console](https://console.cloud.google.com) project (for OAuth & Calendar API)
- Android Studio / Xcode (for platform-specific builds)

### Installation

1. **Clone the repository**
   ```bash
   git clone https://github.com/yourusername/cleanslate.git
   cd cleanslate
   ```

2. **Install dependencies**
   ```bash
   flutter pub get
   ```

3. **Set up environment variables**
   
   Create a `.env` file in the project root:
   ```env
   SUPABASE_URL=https://your-project.supabase.co
   SUPABASE_ANON_KEY=your-anon-key-here
   ```

4. **Configure Google Sign-In**
   
   - Create OAuth 2.0 credentials in Google Cloud Console
   - Add your SHA-1 fingerprint for Android
   - Update `android/app/google-services.json` (if using Firebase)
   - Update iOS `Info.plist` with your reversed client ID

5. **Run the app**
   ```bash
   # Debug mode (uses .env file)
   flutter run
   
   # Release mode (uses dart-define)
   flutter run --release \
     --dart-define=SUPABASE_URL=https://your-project.supabase.co \
     --dart-define=SUPABASE_ANON_KEY=your-anon-key
   ```

---

## ⚙️ Configuration

### Supabase Setup

1. Create a new Supabase project
2. Run the database migrations (SQL files in `/supabase/migrations/`)
3. Enable Google OAuth provider in Authentication settings
4. Create the `user-images` storage bucket with appropriate RLS policies
5. Deploy edge functions for deadline notifications

### Google Cloud Setup

1. Enable these APIs:
   - Google Calendar API
   - Google Sign-In API

2. Create OAuth 2.0 credentials:
   - **Android**: Web application client ID (for `serverClientId`)
   - **iOS**: iOS client ID

3. Configure consent screen with required scopes:
   - `email`
   - `profile`
   - `https://www.googleapis.com/auth/calendar`
   - `https://www.googleapis.com/auth/calendar.events`

### Environment Variables

| Variable | Description | Required |
|----------|-------------|----------|
| `SUPABASE_URL` | Your Supabase project URL | ✅ |
| `SUPABASE_ANON_KEY` | Supabase anonymous/public key | ✅ |

---

## 🗄 Database Schema

### Core Tables

```sql
-- User profiles (synced with Supabase Auth)
profiles (
  id UUID PRIMARY KEY,
  email TEXT,
  full_name TEXT,
  profile_image_url TEXT,
  auth_provider TEXT, -- 'email', 'google', 'email_and_google'
  created_at TIMESTAMP,
  updated_at TIMESTAMP
)

-- Households
households (
  id UUID PRIMARY KEY,
  name TEXT,
  code CHAR(8) UNIQUE, -- Invite code
  created_by UUID REFERENCES profiles(id),
  created_at TIMESTAMP,
  updated_at TIMESTAMP
)

-- Household membership
household_members (
  id UUID PRIMARY KEY,
  household_id UUID REFERENCES households(id),
  user_id UUID REFERENCES profiles(id),
  role TEXT, -- 'admin' or 'member'
  is_active BOOLEAN,
  joined_at TIMESTAMP
)

-- Chore definitions
chores (
  id UUID PRIMARY KEY,
  household_id UUID REFERENCES households(id),
  name TEXT,
  description TEXT,
  estimated_duration INTEGER, -- minutes
  frequency TEXT, -- 'once', 'daily', 'weekly', 'monthly'
  created_by UUID REFERENCES profiles(id),
  created_at TIMESTAMP
)

-- Chore assignments
chore_assignments (
  id UUID PRIMARY KEY,
  chore_id UUID REFERENCES chores(id),
  assigned_to UUID REFERENCES profiles(id),
  assigned_by UUID REFERENCES profiles(id),
  due_date TIMESTAMP,
  status TEXT, -- 'pending', 'completed'
  priority TEXT, -- 'low', 'medium', 'high'
  completed_at TIMESTAMP
)

-- User preferences for smart scheduling
user_preferences (
  user_id UUID PRIMARY KEY REFERENCES profiles(id),
  available_days TEXT[], -- ['monday', 'tuesday', ...]
  preferred_time_slots JSONB, -- {morning: true, afternoon: false, ...}
  preferred_chore_types TEXT[],
  disliked_chore_types TEXT[],
  max_chores_per_week INTEGER,
  go_home_weekends BOOLEAN,
  created_at TIMESTAMP,
  updated_at TIMESTAMP
)

-- Calendar integrations
calendar_integrations (
  id UUID PRIMARY KEY,
  user_id UUID REFERENCES profiles(id),
  provider TEXT, -- 'google'
  access_token TEXT,
  calendar_id TEXT,
  calendar_email TEXT,
  sync_enabled BOOLEAN,
  auto_add_chores BOOLEAN,
  token_expiry TIMESTAMP
)

-- Notifications
notifications (
  id UUID PRIMARY KEY,
  user_id UUID REFERENCES profiles(id),
  household_id UUID REFERENCES households(id),
  type TEXT, -- 'chore_assigned', 'member_joined', 'deadline_approaching'
  title TEXT,
  message TEXT,
  metadata JSONB,
  is_read BOOLEAN,
  created_at TIMESTAMP
)
```

---

## 📁 Project Structure

```
cleanslate/
├── lib/
│   ├── main.dart                 # App entry point
│   │
│   ├── core/                     # Shared utilities
│   │   ├── constants/            # App colors, strings
│   │   ├── providers/            # Theme provider
│   │   ├── theme/                # App theming
│   │   └── utils/                # Helper functions
│   │
│   ├── data/                     # Data layer
│   │   ├── models/               # Data models
│   │   ├── repositories/         # Data access layer
│   │   └── services/             # API services
│   │
│   ├── features/                 # Feature modules
│   │   ├── auth/                 # Authentication
│   │   │   └── screens/          # Login, Signup, etc.
│   │   │
│   │   ├── home/                 # Home screen
│   │   │   └── screens/
│   │   │
│   │   ├── chores/               # Chore management
│   │   │   └── screens/
│   │   │
│   │   ├── schedule/             # Calendar views
│   │   │   └── screens/
│   │   │
│   │   ├── members/              # Household members
│   │   │   └── screens/
│   │   │
│   │   ├── settings/             # App settings
│   │   │   ├── screens/
│   │   │   └── widgets/
│   │   │
│   │   ├── profile/              # User preferences
│   │   │   └── screens/
│   │   │
│   │   ├── calendar/             # Calendar integration
│   │   │   └── screens/
│   │   │
│   │   ├── notifications/        # Notification center
│   │   │   └── screens/
│   │   │
│   │   └── household/            # Household management
│   │       └── screens/
│   │
│   └── widgets/                  # Shared widgets
│
├── assets/
│   ├── images/
│   │   ├── icons/                # SVG icons
│   │   └── profile_pictures/     # Default avatars
│   └── fonts/                    # Custom fonts
│
├── android/                      # Android-specific config
├── ios/                          # iOS-specific config
├── web/                          # Web support
│
├── pubspec.yaml                  # Dependencies
├── .env.example                  # Environment template
└── README.md                     # This file
```

---

## 🗺 Roadmap

### ✅ Completed (v1.0)
- [x] User authentication (Email + Google)
- [x] Household creation and management
- [x] Basic chore CRUD operations
- [x] Manual chore assignment
- [x] Google Calendar integration
- [x] User preference collection
- [x] Push notifications
- [x] Dark mode

### 🚧 In Progress (v1.1)
- [ ] Automatic chore assignment algorithm
- [ ] Smart scheduling with conflict detection
- [ ] Fairness/rotation logic

### 📋 Planned (v2.0)
- [ ] Chore history and statistics dashboard
- [ ] Exam period handling
- [ ] Chore swap/trade between roommates
- [ ] Chore templates for common setups
- [ ] Apple Calendar integration
- [ ] Offline mode with local caching
- [ ] Multi-language support
- [ ] Onboarding flow for new users

---

## 🤝 Contributing

Contributions are welcome! Please follow these steps:

1. **Fork the repository**

2. **Create a feature branch**
   ```bash
   git checkout -b feature/amazing-feature
   ```

3. **Commit your changes**
   ```bash
   git commit -m "Add amazing feature"
   ```

4. **Push to your branch**
   ```bash
   git push origin feature/amazing-feature
   ```

5. **Open a Pull Request**

### Development Guidelines

- Follow Flutter's [style guide](https://dart.dev/guides/language/effective-dart/style)
- Write meaningful commit messages
- Add comments for complex logic
- Test on both Android and iOS before submitting PR
- Update documentation for new features

---

## 📄 License

This project is licensed under the MIT License. See the [LICENSE](LICENSE) file for details.

---

## 📬 Contact

For questions, feedback, or support:

- **Email**: imsounic@gmail.com
- **Issues**: [GitHub Issues](https://github.com/yourusername/cleanslate/issues)

---

<p align="center">
  Made with ❤️ for students everywhere
</p>
