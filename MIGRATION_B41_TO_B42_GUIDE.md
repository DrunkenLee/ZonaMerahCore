# Project Zomboid Migration Guide: B41 to B42

## Overview
This guide covers the breaking changes and migration requirements when updating mods from Build 41 to Build 42 (version 42.13+).

## Registry System Changes

### New Registry Requirement
In version 42.13, certain identifiers must be registered using Lua before they can be used in scripts and recipes.

### Identifiers Requiring Registration
The following types must be registered in a `registries.lua` file:

- **CharacterTrait**
- **CharacterProfession**
- **ItemTag**
- **Brochure**
- **Flier**
- **ItemBodyLocation**
- **ItemType**
- **MoodleType** ⚠️ **IMPORTANT FOR THIS MOD**
- **WeaponCategory**
- **Newspaper**
- **AmmoType**

### Registry File Requirements

**File Location:** `media/registries.lua`

**CRITICAL:** 
- The file MUST be named exactly `registries.lua`
- It MUST be stored in the `media` folder
- It is loaded BEFORE scripts and BEFORE any other Lua files

### Registration Examples

```lua
-- Character Traits
CharacterTrait.register("testmod:nimblefingers")

-- Character Professions
CharacterProfession.register("testmod:thief")

-- Item Tags
ItemTag.register("testmod:bobbypin")

-- Brochures
Brochure.register("testmod:Village")

-- Fliers
Flier.register("testmod:BirdMilk")

-- Item Body Locations
ItemBodyLocation.register("testmod:MiddleFinger")

-- Item Types
ItemType.register("testmod:gamedev")

-- Moodles (IMPORTANT!)
MoodleType.register("testmod:Happy")

-- Weapon Categories
WeaponCategory.register("testmod:birb")

-- Newspapers
Newspaper.register("testmod:BirdNews", List.of("BirdKnews_July30", "BirdKnews_July2"))

-- Ammo Types
local item_key = ItemKey.new("bullets_666", ItemType.NORMAL)
AmmoType.register("testmod:duck_bullets", item_key)
```

## Script Changes

### Character Trait Definition

**B42 Format:**
```lua
character_trait_definition testmod:nimblefingers
{
    IsProfessionTrait = false,
    DisabledInMultiplayer = false,
    CharacterTrait = testmod:nimblefingers,
    Cost = 3,
    UIName = UI_trait_nimblefingers,
    UIDescription = UI_trait_nimblefingersDesc,
    XPBoosts = Lockpicking=2,
    GrantedRecipes = Lockpicking;AlarmCheck;CreateBobbyPin;CreateBobbyPin2,
}
```

### Craft Recipe Example

**B42 Format:**
```lua
craftRecipe CreateBobbyPin
{
    timedAction = Making,
    Time = 40,
    Tags = InHandCraft;CanBeDoneInDark,
    needTobeLearn = true,
    inputs
    {
        item 1 tags[base:screwdriver] mode:keep flags[MayDegradeLight;Prop1],
        item 1 [Base.Paperclip],
    }
    outputs
    {
        item 1 TestMod.HandmadeBobbyPin,
    }
}
```

### Character Profession Definition

**B42 Format:**
```lua
character_profession_definition testmod:thief
{
    CharacterProfession = testmod:thief,
    Cost = 2,
    UIName = UI_prof_Thief,
    IconPathName = profession_burglar2,
    XPBoosts = Nimble=3;Sneak=2;Lightfoot=1;Lockpicking=2,
    GrantedTraits = testmod:nimblefingers,
}
```

## Item Script Changes

### DisplayName Removal
- **REMOVED:** `DisplayName` field in item scripts
- **NEW:** Translation is now taken only from `Module.ItemId`

### Type Renamed to ItemType
- **OLD:** `Type = Normal`
- **NEW:** `ItemType = base:normal` (requires ItemType registry)

### Tags Require Registry
- All custom tags now require registration via `ItemTag.register()`

**Example:**
```lua
item HandmadeBobbyPin
{
    Weight = 0.01,
    ItemType = base:normal,
    Icon = HandmadeBobbyPin,
    Tags = testmod:bobbypin,  // Must be registered first!
    Tooltip = Tooltip_TestMod_BobbyPin,
    WorldStaticModel = Paperclip,
}
```

## API Changes

### Lua API Modifications
- Some Lua API functions have been modified
- Check decompiled Java code if something stops working
- More API changes expected in upcoming unstable patches

### Script Examples
- Base game script examples are now generated from Java code
- Study these examples in the game files for reference

## ZonaMerahCore Specific Requirements

### Moodle Registration
All custom moodles in this mod must be registered in `registries.lua`:

```lua
-- Example for ZonaMerahCore moodles
MoodleType.register("zonamerah:Pumped")
MoodleType.register("zonamerah:AnotherMoodle")
-- Add all custom moodles here
```

## Migration Checklist

- [ ] Create `media/registries.lua` file
- [ ] Register all custom MoodleTypes
- [ ] Register all custom ItemTags
- [ ] Register all custom CharacterTraits
- [ ] Register all custom CharacterProfessions
- [ ] Update item scripts: Remove DisplayName fields
- [ ] Update item scripts: Change Type to ItemType
- [ ] Verify all registered IDs match usage in scripts
- [ ] Test mod in B42.13+

## Notes

- Future content patches will include more modding changes
- New API documentation will gradually become available
- Report issues and requests to the development team

## Last Updated
December 18, 2025
