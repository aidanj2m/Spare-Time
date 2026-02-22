# Spare Time

A bowling tracking app for iOS, built with SwiftUI. Spare Time lets you log every frame of a game — shots, pin results, ball path, and angle at the arrows — and reviews your session with a full match summary.

---

## Features

- **Phone auth** — sign in with your mobile number via Twilio Verify OTP
- **Frame-by-frame scoring** — keypad entry for each shot, with standard bowling rules (strikes, spares, 10th frame)
- **Pin selection** — tap the pins that are still standing after your first ball
- **Ball path tracking** — interactive bowling lane view showing the first 15 feet; position your release point and arrow crossing with sliders
- **Breakpoint placement** — tap to mark where your ball breaks on the last 20 feet of the lane, then dial in your entry angle
- **Running score** — live cumulative total recalculated across frames with proper strike/spare bonuses
- **Match summary** — full scorecard with frame-by-frame breakdown at the end of each game
- **Home screen** — shows your rolling average and recent games

---

## Stack

| Layer | Tech |
|---|---|
| iOS app | SwiftUI |
| Backend API | FastAPI (Python), deployed on Vercel |
| Database | Supabase (Postgres) |
| Auth / SMS | Twilio Verify |

---

## Project Structure

```
Spare Time/               # Xcode project
├── Spare Time/
│   ├── Views/
│   │   ├── HomeView.swift
│   │   ├── FrameView.swift
│   │   ├── MatchView.swift
│   │   ├── MatchSummaryView.swift
│   │   └── OnboardingView.swift
│   ├── Components/
│   │   ├── First15FeetLaneView.swift   # interactive release/arrows lane
│   │   ├── Last20FeetLaneView.swift    # breakpoint lane
│   │   ├── DrawingView.swift           # release + arrows sliders
│   │   ├── BreakpointView.swift        # breakpoint tap + entry angle
│   │   ├── PinLayoutView.swift
│   │   ├── KeypadView.swift
│   │   └── FrameScoreBoxView.swift
│   ├── Models/
│   │   ├── Frame.swift
│   │   ├── Pin.swift
│   │   └── BowlingSession.swift
│   ├── Services/
│   │   ├── APIService.swift
│   │   └── ScoreCalculator.swift
│   ├── Theme.swift
│   └── ContentView.swift

bowling-api/              # FastAPI backend
├── api/
│   ├── endpoints/
│   │   ├── auth.py       # OTP send/verify, user lookup
│   │   ├── matches.py    # match CRUD
│   │   └── crud.py       # frame CRUD
│   ├── models/
│   ├── services/
│   │   ├── supabase.py
│   │   └── twilio.py
│   └── main.py
└── migrations/
```

---

## Setup

### iOS App

1. Open `Spare Time/Spare Time.xcodeproj` in Xcode
2. The app reads `API_BASE_URL` from `Spare Time/Secrets.xcconfig` — this file is gitignored, create it locally:
   ```
   API_BASE_URL = https:/$()/your-api-url.vercel.app
   ```
3. Build and run on a simulator or device (iOS 17+)

### Backend

1. `cd bowling-api`
2. `pip install -r requirements.txt`
3. Create a `.env` file (gitignored):
   ```
   SUPABASE_URL=https://your-project.supabase.co
   SUPABASE_KEY=your-service-role-key
   TWILIO_ACCOUNT_SID=ACxxxxxxxx
   TWILIO_AUTH_TOKEN=xxxxxxxx
   TWILIO_VERIFY_SID=VAxxxxxxxx
   ```
4. Run locally: `uvicorn api.main:app --reload`
5. Deploy: push to Vercel — `vercel.json` is already configured

---

## API

Base URL: `https://bowling-api-eight.vercel.app`

| Method | Endpoint | Description |
|---|---|---|
| POST | `/auth/send-otp` | Send OTP to phone number |
| POST | `/auth/verify-otp` | Verify OTP, return/create user |
| GET | `/auth/user/{user_id}` | Get user profile |
| PUT | `/matches/` | Create or update a match |
| GET | `/matches/?user_id=` | List matches for a user |
| DELETE | `/matches/{match_id}` | Delete a match |
| PUT | `/frames/` | Upsert a frame |
| GET | `/frames/game/{game_id}` | Get all frames for a match |
