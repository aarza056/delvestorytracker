-- DelveTracker.lua

local DelveTracker = {}

-- 📅 Base date for rotation
local baseDate = { year = 2025, month = 6, day = 6 }

-- 🔄 Custom rotation patterns by story count
local customRotationPatterns = {
    [4] = {1, 4, 2, 3},       -- for 4‑story delves
    [5] = {1, 5, 2, 3, 4},    -- for 5‑story delves
    [3] = {3, 1, 2}, -- for 3‑story delves
    [1] = {1}, -- for 1-story delves
}

-- 🌍 Delve data
DelveTracker.delves = {
    ["Isle of Dorn"] = {
        ["Earthcrawl Mines"] = {
            achievementId = 40527,
            stories = {
                "Kidnapped Earthen", "Precious Ores", "Fiery Grounds",
                "Looking for Treasure", "Bugs and Grubs"
            },
        },
        ["Fungal Folly"] = {
            achievementId = 40525,
            stories = {
                "Lost Miners", "Spreading Decay", "Explorer's Competition",
                "Oversparked Operation"
            },
        },
        ["Kriegval's Rest"] = {
            achievementId = 40526,
            stories = {
                "Lost Keepsakes", "Swarming Kobolds", "Dargran's Day Out",
                "Corrupted Candles"
            },
        },
    },
    ["The Ringing Deeps"] = {
        ["The Waterworks"] = {
            achievementId = 40528,
            stories = {
                "Captured Engineers", "Trust Issues",
                "Stomping Some Sense", "Put a Wrench on It!"
            },
        },
        ["The Dreadpit"] = {
            achievementId = 40529,
            stories = {
                "Lost Gems", "Smashing Skardyn",
                "Kobold Kidnapping", "Darkfuse Disruption"
            },
        },
        ["Excavation Site 9"] = {
            achievementId = 41098,
            stories = {
                "Lost Excavators", "Black Blood Profits", "Rowdy Rifts"
            },
        },
        
    },
    ["Hallowfall"] = {
        ["Skittering Breach"] = {
            achievementId = 40533,
            stories = {
                "Old Rituals", "Renilash Beckons",
                "Shadow Realm", "Relics of the Old Gods"
            },
        },
        ["The Sinkhole"] = {
            achievementId = 40532,
            stories = {
                "Illusory Rescue", "Raen's Gambit",
                "Lurking Terror", "Orphan's Holiday"
            },
        },
        ["Nightfall Sanctum"] = {
            achievementId = 40530,
            stories = {
                "Dark Ritual", "Kyron's Assault",
                "Signal Noise", "Aiming to get Even"
            },
        },
        ["Mycomancer Cavern"] = {
            achievementId = 40531,
            stories = {
                "Missing Pigs", "The Great Scavenger Hunt", "Mushroom Morsel"
            },
        },
    },
    ["Azj-Kahet"] = {
        ["The Spiral Weave"] = {
            achievementId = 40536,
            stories = {
                "Tortured Hostages", "From the Weaver with Love",
                "Strange Disturbances", "Down to Size"
            },
        },
        ["Tak-Rethan Abyss"] = {
            achievementId = 40535,
            stories = {
                "Goblin Mischief", "Niffen Napping",
                "Pheromone Fury", "Pump the Brakes"
            },
        },
        ["The Underkeep"] = {
            achievementId = 40534,
            stories = {
                "Torture Victims", "Weaver Rescue", "Evolved Research",
                "Runaway Evolution", "Third Party Operation"  
            },
        },
    },
    ["Undermine"] = {
        ["Sidestreet Sluice"] = {
            achievementId = 41099,
            stories = {
                "All That Glitters", "Mr. DELVER", "Teleporter Tantrums"
            },
        },
    }
}

-- 🏆 Achievement completion helper
function DelveTracker:GetStoryCompletion(achievementId, index)
    local _, _, completed = GetAchievementCriteriaInfo(achievementId, index)
    return completed
end

-- 🔥 Main update function (only one version!)
function DelveTracker:UpdateContent()
    if not (DelveTrackerZoneDropdown and DelveTrackerFrameZoneTitle and DelveTrackerFrameText) then
        return
    end

    local zone = UIDropDownMenu_GetSelectedValue(DelveTrackerZoneDropdown)
    if not zone then
        return
    end

    DelveTrackerFrameZoneTitle:SetText(zone)

    -- Use server time for consistency
    local nowSec = GetServerTime()
    local baseSec = time({
        year = baseDate.year,
        month = baseDate.month,
        day = baseDate.day,
        hour = 0
    })
    local daysPassed = math.floor((nowSec - baseSec) / 86400)
    --print("DEBUG: daysPassed =", daysPassed)

    local storyText = ""
    for delveName, data in pairs(self.delves[zone]) do
        local count = #data.stories
        local pattern = customRotationPatterns[count]
        local index
        if pattern then
            index = pattern[(daysPassed % count) + 1]
        else
            index = (daysPassed % count) + 1
        end

        local story = data.stories[index] or "UNKNOWN STORY"
        local color = self:GetStoryCompletion(data.achievementId, index)
            and "|cff00ff00" or "|cffff0000"
        storyText = storyText .. string.format("%s: %s%s|r\n", delveName, color, story)
    end

    DelveTrackerFrameText:SetText(storyText)
end

-- 🖥️ UI creation logic (unchanged)
function DelveTracker:CreateUI()
    if not DelveTrackerFrame then
        print("Frame not loaded.")
        return
    end

    self:UpdateContent()
    DelveTrackerFrame:Show()
end

function DelveTracker_ZoneDropdown_OnLoad(self)
    UIDropDownMenu_Initialize(self, function(_, level)
        for zone in pairs(DelveTracker.delves) do
            local info = UIDropDownMenu_CreateInfo()
            info.text = zone
            info.value = zone
            info.func = function()
                UIDropDownMenu_SetSelectedValue(DelveTrackerZoneDropdown, zone)
                DelveTracker:UpdateContent()
            end
            UIDropDownMenu_AddButton(info, level)
        end
    end)
    local defaultZone = next(DelveTracker.delves)
    if defaultZone then
        UIDropDownMenu_SetSelectedValue(self, defaultZone)
    end
end

-- ⏰ Event-handling & slash command
local f = CreateFrame("Frame")
f:RegisterEvent("ADDON_LOADED")
f:SetScript("OnEvent", function(_, event, addonName)
    if addonName == "DelveTracker" and DelveTrackerZoneDropdown then
        DelveTracker_ZoneDropdown_OnLoad(DelveTrackerZoneDropdown)
    end
end)

SLASH_DELVETRACKER1 = "/dst"
SlashCmdList["DELVETRACKER"] = function()
    DelveTracker:CreateUI()
end
