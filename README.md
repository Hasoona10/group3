# PlayMate CS2 Companion

PlayMate is a modern iOS companion app for Counter-Strike 2 (CS2) players, designed to help track your gaming progress, analyze performance, and manage your CS2 experience.

## Features

- **Steam Integration**
  - Seamless Steam account authentication
  - Automatic profile synchronization
  - Real-time game status updates

- **CS2 Stats Tracking**
  - Total and recent playtime monitoring
  - Achievement progress tracking
  - Performance statistics analysis

- **Match History**
  - Detailed match history records
  - Performance metrics per match
  - Score and map statistics

- **User Experience**
  - Clean, modern interface
  - Dark mode support
  - Intuitive navigation
  - Real-time data updates

## Requirements

- iOS 15.0 or later
- Active Steam account
- Counter-Strike 2 game ownership
- Internet connection for Steam synchronization

## Setup

1. Clone the repository
2. Open the project in Xcode
3. Install dependencies using Swift Package Manager
4. Configure your Steam API key in `SteamViewModel.swift`
5. Build and run the application

## Steam API Configuration

To use the Steam API features:

1. Get a Steam Web API key from [Steam Community](https://steamcommunity.com/dev/apikey)
2. Replace the placeholder API key in `SteamViewModel.swift`
3. Ensure your Steam profile is public for data access

## Privacy & Security

- Steam authentication is handled securely
- No sensitive data is stored locally
- All API communications are encrypted
- User data is handled according to Steam's privacy policy


## License

This project is licensed under the MIT License - see the LICENSE file for details.

## Acknowledgments

- Steam Web API for game data
- Valve Corporation for CS2
- The CS2 community

---

**Note:** This app is not affiliated with or endorsed by Valve Corporation.
