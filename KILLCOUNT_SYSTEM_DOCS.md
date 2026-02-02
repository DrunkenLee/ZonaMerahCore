# Kill Count Tracking System Documentation

This system provides a comprehensive kill count tracking and leaderboard system for Project Zomboid multiplayer servers.

## Overview

The system consists of four main components:

### 1. Client-Side Kill Tracking (`ZM_KillCountClient.lua`)
- **Location**: `media/lua/client/ZM_KillCountClient.lua`
- **Purpose**: Tracks player kills and reports them to the server every hour
- **Key Features**:
  - Uses the built-in `player:getZombieKills()` function
  - Automatically reports kills every hour via `Events.EveryHours`
  - Handles server communication for data requests

### 2. Server-Side Data Storage (`ZM_KillCountServer.lua`)
- **Location**: `media/lua/server/ZM_KillCountServer.lua`
- **Purpose**: Receives kill data from clients and stores it in `killcount.json`
- **Key Features**:
  - Saves all player kill data to `killcount.json` file
  - Handles client requests for kill count data
  - Includes JSON parsing and serialization functions
  - Periodic auto-save functionality

### 3. Kill Count UI (`ZM_KillCountUI.lua`)
- **Location**: `media/lua/client/ISUI/ZM_KillCountUI.lua`
- **Purpose**: Displays a leaderboard of player kill counts
- **Key Features**:
  - Scrollable list showing all players ranked by kills
  - Shows player name, kill count, and last update time
  - Real-time refresh capability
  - Clean, professional UI design

### 4. Menu Integration (`ZM_KillCountMenu.lua`)
- **Location**: `media/lua/client/ZM_KillCountMenu.lua`
- **Purpose**: Provides easy access to the kill count UI
- **Key Features**:
  - Right-click context menu option: "View Kill Count Leaderboard"
  - Keyboard shortcut: `Ctrl+K`
  - Single-instance management

## How It Works

### Data Flow:
1. **Every Hour**: Each client automatically reports their current kill count to the server
2. **Server Storage**: Server receives the data and saves it to `killcount.json`
3. **UI Access**: Players can open the leaderboard via right-click menu or `Ctrl+K`
4. **Data Display**: UI requests latest data from server and displays ranked leaderboard

### File Structure:
```
killcount.json format:
{
  "PlayerName1": {
    "killCount": 1250,
    "lastUpdated": 168.5,
    "timestamp": "2025-10-13 15:30:45"
  },
  "PlayerName2": {
    "killCount": 987,
    "lastUpdated": 167.2,
    "timestamp": "2025-10-13 14:45:22"
  }
}
```

## User Instructions

### For Players:
1. **Viewing Leaderboard**:
   - Right-click anywhere in the game world
   - Select "View Kill Count Leaderboard"
   - OR press `Ctrl+K`

2. **Understanding the Display**:
   - Players are ranked by total kill count (highest first)
   - Shows your current kills at the bottom
   - "Refresh Data" button gets latest information
   - Last update timestamp shows when data was last reported

### For Server Administrators:
1. **Data Location**: Kill count data is stored in `killcount.json` in your server directory
2. **Backup**: The system auto-saves every hour, but you can manually backup the JSON file
3. **Reset Data**: Delete `killcount.json` to start fresh (server restart required)

## Technical Details

### Events Used:
- `Events.EveryHours`: Client kill count reporting
- `Events.OnCreatePlayer`: Client initialization
- `Events.OnServerStarted`: Server initialization
- `Events.OnClientCommand`: Server receiving client data
- `Events.OnServerCommand`: Client receiving server responses
- `Events.OnFillWorldObjectContextMenu`: Context menu integration
- `Events.OnKeyPressed`: Keyboard shortcut handling

### Client-Server Commands:
- `ZM_KillCount.reportKills`: Client → Server (kill count data)
- `ZM_KillCount.requestKillData`: Client → Server (request leaderboard)
- `ZM_KillCount.killCountUpdated`: Server → Client (confirmation)
- `ZM_KillCount.killCountData`: Server → Client (leaderboard data)

### Dependencies:
- Requires Project Zomboid's built-in UI framework
- Uses standard PZ file I/O functions
- Compatible with existing mod structure

## Troubleshooting

### Common Issues:
1. **No data showing**: Check if `killcount.json` exists and has valid data
2. **Data not updating**: Ensure server has write permissions to create files
3. **UI not opening**: Check console for error messages, verify mod loading order
4. **Missing players**: Players must be online and have killed at least one zombie to appear

### Console Messages:
- Look for messages starting with `ZM_KillCountClient:` and `ZM_KillCountServer:`
- These provide debugging information about data flow and errors

## Future Enhancements

Possible additions for future versions:
- Kill count statistics (kills per hour, per day)
- Different kill types (zombie types, weapons used)
- Achievement system based on kill milestones
- Export functionality for external statistics tools

## Installation Notes

All files are integrated into the existing ZonaMerahCore mod structure. The system will automatically:
- Initialize when the mod loads
- Start tracking kills for all connected players
- Create the `killcount.json` file when first needed
- Handle new players joining the server

No additional configuration is required - the system works out of the box!