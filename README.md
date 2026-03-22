# ChallengeMod_FS25 - Rebuilt for Farming Simulator 25

Challenge mod for the FS25 game. This is a complete rebuild from the FS22 version with improved architecture and FS25 compatibility.

## Status

This mod has been rebuilt with the following components:

### Implemented Features
- [x] Core mod framework and initialization
- [x] Global managers (PointTypeManager, ChallengeFarmManager)
- [x] Farm and point system
- [x] Point composition and calculation system
- [x] Configuration loading from XML
- [x] Save/Load functionality
- [x] GUI Menu structure (TabbedMenu based)
- [x] Input binding (Alt+C to open menu)
- [x] Farm overview and settings frames
- [x] Logging system
- [x] Multi-language support

### Point Types

#### General
- [ ] Farmland area
- [ ] Field area
- [ ] Owned building value
- [ ] Owned vehicle value

#### Money
- [ ] Current money
- [ ] Loan

#### Storage
- [ ] Fill types (storage system)
- [ ] Bales owned
- [ ] Pallets owned

#### Animals
- [ ] Animals (structure and functionality)

### Planned Features for Future Releases
- [ ] Integration of the Limited Daily Income Mod rules
- [ ] Complete animal system support
- [ ] Mission system integration
- [ ] Helper and vehicle rental limits
- [ ] Admin point management UI
- [ ] Challenge duration system
- [ ] Team visibility options
- [ ] Challenge completion system

## Installation

1. Download the mod
2. Extract to your Farming Simulator 25 mods folder
3. Enable the mod in the game
4. Load a save game to start using the Challenge Mode
5. Press Alt+C to open the Challenge Menu

## Configuration

The base configuration is stored in `config/ChallengeConfig.xml`. This file defines:
- Available point types
- Point calculation and composition methods
- Categories for organizing points

## Recent Changes (Version 2.0.0.0)

### Fixes and Improvements
- Complete rebuild for FS25 compatibility
- Fixed global initialization system
- Improved error handling and logging
- Added proper class inheritance for GUI system
- Fixed point calculation and composition system
- Enhanced XML state management
- Added better support for dynamic point types
- Improved farm management system
- Added input action handlers
- Fixed category and point streaming

### Migration Notes
If you're upgrading from FS22:
1. Saved challenge data from FS22 is not compatible
2. Configuration file format remains the same
3. GUI layout has been updated for FS25 standards

## Debugging

Enable detailed logging by setting these Logger levels in code:
```lua
local logger = Logger("ComponentName")
logger:setLevel(Logger.level.trace)  -- Most verbose
logger:setLevel(Logger.level.debug)  -- Standard debug
logger:setLevel(Logger.level.warning) -- Only warnings and errors
```

## For Developers

The mod uses a custom CpObject class system for OOP support:
```lua
MyClass = CpObject()

function MyClass:init(param1, param2)
    self.param1 = param1
    self.param2 = param2
end

function MyClass:myMethod()
    -- implementation
end

local instance = MyClass(value1, value2)
```

## Support & Issues

For issues, feature requests, or to contribute, visit:
https://github.com/Courseplay/ChallengeMode_FS25

## License

See LICENSE file for details.

