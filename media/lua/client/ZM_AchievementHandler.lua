ZMAchievements = ZMAchievements or {}

ZMAchievements.CheckPlayerProgress = function(player, achievementID)
    if not player or not achievementID then return false end

    local fitnessFreak = "fitness_freak"

    return progress or 1
end

local function checkPlayerStats(player)
    if not player then return end

    local stats = player:GetStats() or {}
    local progress = {}
    for _, stat in ipairs(stats) do
        if stat.id == "fitness_freak" then
            progress.fitnessFreak = stat.value or 0
        elseif stat.id == "speedster" then
            progress.speedster = stat.value or 0
        elseif stat.id == "team_player" then
            progress.teamPlayer = stat.value or 0
        end
    end

    return progress
end
