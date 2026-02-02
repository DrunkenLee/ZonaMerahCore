-- ===================================================
-- ZonaMerahCore - B42.13 Registry File
-- ===================================================
-- This file MUST be named "registries.lua" and placed in the media folder
-- It is loaded BEFORE scripts and BEFORE any other Lua files
-- Required for Build 42.13+ (version migration from B41)
-- ===================================================

-- Register Custom MoodleTypes
-- These moodles are used throughout the ZonaMerahCore mod
print("[ZonaMerah] Registering custom MoodleTypes for B42.13...")

MoodleType.register("zonamerah:Pumped")
MoodleType.register("zonamerah:GiantOx")
MoodleType.register("zonamerah:OakRemedy")

print("[ZonaMerah] Successfully registered 3 custom MoodleTypes")

-- ===================================================
-- Registered Moodles:
-- 1. zonamerah:Pumped - Combat readiness and adrenaline system
-- 2. zonamerah:GiantOx - Increased carry capacity buff
-- 3. zonamerah:OakRemedy - Weight normalization effect
-- ===================================================
