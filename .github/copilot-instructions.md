# Copilot Instructions for NoBlock SourceMod Plugin

## Repository Overview

This repository contains the **NoBlock** SourceMod plugin for Counter-Strike: Source and Counter-Strike: Global Offensive. The plugin manipulates player and grenade collision properties to prevent blocking, allowing players to walk through each other while maintaining tactical gameplay options.

### Plugin Functionality
- **Player Collision Control**: Removes player-vs-player collisions by default
- **Grenade NoBlock**: Prevents grenades from being blocked by players
- **Temporary Blocking**: Players can use `!block` command to temporarily become solid
- **Configuration System**: Multiple ConVars for customizing behavior
- **Translation Support**: Multi-language support via phrase files

## Technical Environment

### Core Technologies
- **Language**: SourcePawn (.sp files)
- **Platform**: SourceMod 1.11+ (dependency defined in sourceknight.yaml)
- **Build System**: SourceKnight (modern SourcePawn build tool)
- **Game Compatibility**: Counter-Strike: Source and Counter-Strike: Global Offensive only

### Dependencies
- **SourceMod**: 1.11.0-git6934 (defined in sourceknight.yaml)
- **MultiColors**: For colored chat messages (GitHub: srcdslab/sm-plugin-MultiColors)
- **Standard Includes**: sourcemod, sdktools, sdkhooks

### Build Process
```bash
# SourceKnight handles compilation automatically
# Build configuration in sourceknight.yaml
# CI/CD via GitHub Actions (.github/workflows/ci.yml)
```

## Code Architecture & Patterns

### File Structure
```
/addons/sourcemod/
├── scripting/
│   └── NoBlock.sp              # Main plugin source
└── translations/
    └── noblock.phrases.txt     # Translation phrases
```

### Key Components

#### Global Variables
- `g_CollisionOffset`: Entity collision group offset for manipulation
- `g_cv*`: ConVar handles for all configuration options

#### Core Functions
- `EnableNoBlock(client)`: Sets player collision to pass-through mode
- `EnableBlock(client)`: Makes player solid (blocking)
- `Event_PlayerSpawn()`: Applies noblock on spawn
- `OnEntityCreated()`: Handles grenade noblock
- `Command_NoBlock()`: Handles !block command with timer

#### ConVar System
- `sm_noblock_grenades`: Enable/disable grenade noblock
- `sm_noblock_players`: Enable/disable player noblock
- `sm_noblock_allow_block`: Allow !block command usage
- `sm_noblock_allow_block_time`: Duration for temporary blocking
- `sm_noblock_notify`: Enable/disable chat notifications

## Development Guidelines

### Code Style (Project-Specific)
- **Current Convention**: Mixed case (some inconsistencies exist)
- **Indentation**: Tabs (4 spaces)
- **Variable Naming**: 
  - Globals: `g_` prefix (e.g., `g_CollisionOffset`)
  - ConVars: `g_cv` prefix (e.g., `g_cvPlayers`)
- **Function Naming**: Mix of camelCase and PascalCase (follow existing patterns)

### SourcePawn Best Practices for This Plugin
- **Collision Manipulation**: Uses `SetEntData()` with collision group offsets
  - Group 2: Pass-through (noblock active)
  - Group 5: Solid (blocking active)
- **Event Handling**: Uses EventHookMode_Post for player_spawn
- **Timer Management**: CreateTimer for temporary blocking with client as data
- **Chat Messages**: Uses MultiColors library with MESSAGE macro

### Memory Management
- ConVar handles are automatically managed by SourceMod
- Timers auto-clean when plugin unloads
- No manual memory allocation in this plugin

## Testing & Validation

### Build Validation
```bash
# SourceKnight automatically validates:
# - Syntax errors
# - Include dependencies
# - Compilation success
```

### Functional Testing Checklist
1. **Player Spawning**: Verify noblock activates on spawn
2. **Command Testing**: Test `!block` command functionality
3. **Timer System**: Verify temporary blocking expires correctly
4. **Grenade Interaction**: Test grenade pass-through behavior
5. **ConVar Changes**: Test dynamic configuration changes
6. **Translation System**: Verify phrase file loading

### Game Testing Environment
- **Required**: Counter-Strike server with SourceMod
- **Test Scenarios**:
  - Multiple players spawning
  - Player movement through each other
  - Grenade throwing and collision
  - Command usage and timer expiration
  - ConVar modifications via server console

## Plugin-Specific Implementation Details

### Collision System
The plugin manipulates the `m_CollisionGroup` property of entities:
- **Normal State**: Collision group 5 (solid/blocking)
- **NoBlock State**: Collision group 2 (pass-through)
- **Detection**: Uses `FindSendPropInfo("CBaseEntity", "m_CollisionGroup")`

### Event Flow
1. **OnPluginStart**: Initialize ConVars, hook events, find collision offset
2. **Player Spawn**: Apply noblock if enabled via ConVar
3. **!block Command**: Temporarily enable blocking with timer
4. **Entity Creation**: Apply noblock to grenades if enabled
5. **ConVar Changes**: Dynamically apply to all players

### Translation Integration
- **File**: `addons/sourcemod/translations/noblock.phrases.txt`
- **Keys Used**:
  - `now solid`: Blocking enabled message
  - `noblock enabled`: NoBlock activated message  
  - `block for solid`: Usage instruction
  - `noblock disabled`: Plugin disabled message

## CI/CD & Release Process

### GitHub Actions Workflow
- **Trigger**: Push to main/master, PRs, tags
- **Build**: SourceKnight compilation via maxime1907/action-sourceknight
- **Package**: Creates deployment-ready structure
- **Release**: Automatic releases on tags and latest builds

### Release Artifacts
- **Structure**: Standard SourceMod plugin layout
- **Contents**: 
  - Compiled .smx file
  - Translation files
  - Installation-ready directory structure

## Common Development Tasks

### Adding New Features
1. Update ConVars in `OnPluginStart()` if configuration needed
2. Add new functions following existing naming patterns
3. Update translation file if user-facing messages added
4. Test on Counter-Strike server before committing

### Modifying Collision Behavior
- Work with `g_CollisionOffset` and `SetEntData()`
- Test collision group values (2=pass-through, 5=solid)
- Consider impact on both players and grenades

### Updating Dependencies
- Modify `sourceknight.yaml` for SourceMod/MultiColors versions
- Ensure compatibility with minimum SourceMod version
- Test build process after dependency changes

## Troubleshooting

### Common Issues
- **Game Compatibility**: Plugin only works on CS:S and CS:GO
- **Collision Offset**: May change with game updates
- **Timer Cleanup**: Ensure clients are valid before timer operations
- **ConVar Synchronization**: Some functions use deprecated GetConVarInt()

### Debug Approach
1. Check SourceMod error logs
2. Verify collision offset is found correctly
3. Test with minimal ConVar configuration
4. Use developer console for runtime debugging

---

**Note**: This plugin modifies core game mechanics. Always test thoroughly on development servers before production deployment.