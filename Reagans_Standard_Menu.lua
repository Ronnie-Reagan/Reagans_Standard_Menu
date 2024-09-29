-- Reagans Standard Menu

util.require_natives("natives-3095a")
util.keep_running()

--#region Menu Creation (Tabs)
reagans = menu.my_root()
speedometer = reagans:list("Speedometer")
settingsMenu = reagans:list("Settings")
analogSettingsMenu = settingsMenu:list("Analog Speedometer")
digitalSettingsMenu = settingsMenu:list("Digital Speedometer")

--#endregion

--#region helper functions and variables

--#region Colour Stuff
local colours = {
    red = { 255, 0, 0 },
    green = { 0, 255, 0 },
    blue = { 0, 0, 255 },
    yellow = { 255, 255, 0 },
    cyan = { 0, 255, 255 },
    magenta = { 255, 0, 255 },
    orange = { 255, 165, 0 },
    violet = { 238, 130, 238 },
    indigo = { 75, 0, 130 },
    lightRed = { 255, 102, 102 },
    darkRed = { 139, 0, 0 },
    pink = { 255, 192, 203 },
    deepPink = { 255, 20, 147 },
    lightGreen = { 144, 238, 144 },
    darkGreen = { 0, 100, 0 },
    lime = { 0, 255, 0 },
    olive = { 128, 128, 0 },
    lightBlue = { 173, 216, 230 },
    darkBlue = { 0, 0, 139 },
    skyBlue = { 135, 206, 235 },
    navy = { 0, 0, 128 },
    lightYellow = { 255, 255, 224 },
    gold = { 255, 215, 0 },
    khaki = { 240, 230, 140 },
    lightCyan = { 224, 255, 255 },
    darkCyan = { 0, 139, 139 },
    teal = { 0, 128, 128 },
    lavender = { 230, 230, 250 },
    purple = { 128, 0, 128 },
    darkMagenta = { 139, 0, 139 },
    brown = { 165, 42, 42 },
    tan = { 210, 180, 140 },
    beige = { 245, 245, 220 },
    white = { 255, 255, 255 },
    gray = { 128, 128, 128 },
    black = { 0, 0, 0 }
}

opacityPercentage = {
    ten = 0.10,
    twenty = 0.20,
    thirty = 0.30,
    forty = 0.40,
    fifty = 0.50,
    sixty = 0.60,
    seventy = 0.70,
    eighty = 0.80,
    ninety = 0.90,
    hundred = 1.0
}


local colourOptions = {}
local colourIndex = 1

for colourName, rgb in pairs(colours) do
    table.insert(colourOptions, { colourIndex, colourName:gsub("^%l", string.upper), rgb })
    colourIndex = colourIndex + 1
end

--#endregion

local remoteUserSettingsPath = ""
local remoteUserSettings = {} -- Placeholder for Cloud Saved Data

local localUserSettings = {
    Speedometers = {

        Default_Analog = true,
        Default_Speed_Unit = KPH,

        Analog = {

            Position_And_Scale = {
                X = 0.5,
                Y = 0.5,
                Scale = 1,
            },

            Colouring = {
                Tachometer_Needle = colours.red,
                Speedometer_Needle = colours.red,
                Digital_Speed_Text = colours.black,
                Gear_Range_Display = colours.black,
                Main_Dash_Opacity = opacityPercentage.eighty,
                Car_View_Opacities = opacityPercentage.eighty
            },

            Digital = {

                Position_And_Scale = {
                    X = 0.75,
                    Y = 0.75,
                    Scale = 1
                },

                Colouring = {
                    Speedometer_Text = colours.black,
                    Speedometer_Text_Opacity = opacityPercentage.hundred,
                    Speedometer_Background = colours.white,
                    Speedometer_Background_Opacity = opacityPercentage.fifty,
                    Tachometer_Text = colours.black,
                    Tachometer_Text_Opacity = opacityPercentage.hundred,
                    Tachometer_Background = colours.white,
                    Tachometer_Background_Opacity = opacityPercentage.fifty
                }
            }
        }
    }
}


local pixelSize = 0.002
local dashboardTexture = nil    -- Placeholder for the dashboard texture ID
local sideViewCarTexture = nil  -- Placeholder for sideViewCar.png
local topViewCarTexture = nil   -- Placeholder for topViewCar.png
local frontViewCarTexture = nil -- Placeholder for frontViewCar.png
local updating = false

-- Speedometer variables
local currentSpeedMode = 3.6
local KPH = 3.6
local MPH = 2.23694
local analogMode = false
local rpmNeedleColour = colours.red
local speedometerNeedleColour = colours.red
local digitalSpeedometerColour = colours.black
local gearSelectorColour = colours.black
local carViewOpacities = 080
local mainDashOpacity = 080

-- Central scale and offsets for all speedometer components
local speedometerScale = 0.5    -- Adjust to scale the entire dash
local speedometerXOffset = 0.5  -- Center X position (0.5 is middle of screen)
local speedometerYOffset = 0.86 -- Center Y position for the entire dash

-- Helper function to check if player is in a vehicle
function isPlayerInVehicle(playerPed)
    return PED.IS_PED_IN_ANY_VEHICLE(playerPed)
end

-- Returns the player's current vehicle
function getCurrentVehicle(playerPed)
    return PED.GET_VEHICLE_PED_IS_IN(playerPed)
end

function fetchScript()
    local scriptsFolderAddress = filesystem.scripts_dir()
    local fileName = "Reagans_Standard_Menu.lua"
    local githubPath = "/Ronnie-Reagan/Reagans_Standard_Menu/" .. fileName
    local filePath = scriptsFolderAddress .. fileName
    if filesystem.exists(filePath) then
        util.toast("Downloading " .. fileName .. " from GitHub...")
        async_http.init("raw.githubusercontent.com", githubPath,
            function(body)
                local file = io.open(filePath, "wb")
                if file then
                    file:write(body)
                    file:close()
                    util.toast(fileName .. " saved successfully.")
                else
                    util.toast("Failed to save " .. fileName)
                end
            end,
            function()
                util.toast("Failed to download " .. fileName .. " from GitHub.")
            end
        )
        async_http.dispatch()
    else
        util.toast("Failed To Locate " .. fileName .. " @ " .. filePath)
    end
end

-- Function to check and download PNG files if not found
function fetchDashboardTexture()
    -- Ensure PNG_Files directory exists
    local pngDir = filesystem.resources_dir() .. "Reagans_Standard_Menu_Resources/PNG_Files/"
    filesystem.mkdirs(pngDir)

    -- List of files to download
    local pngFiles = {
        { "Main_Dash.png",      "/Ronnie-Reagan/Reagans_Standard_Menu/main/Main_Dash.png" },
        { "Side_View_Car.png",  "/Ronnie-Reagan/Reagans_Standard_Menu/main/Side_View_Car.png" },
        { "Top_View_Car.png",   "/Ronnie-Reagan/Reagans_Standard_Menu/main/Top_View_Car.png" },
        { "Front_View_Car.png", "/Ronnie-Reagan/Reagans_Standard_Menu/main/Front_View_Car.png" }
    }

    -- Download each PNG file if not present
    for _, fileData in ipairs(pngFiles) do
        local fileName, githubPath = fileData[1], fileData[2]
        local filePath = pngDir .. fileName
        if not filesystem.exists(filePath) or updating then
            util.toast("Downloading " .. fileName .. " from GitHub...")
            async_http.init("raw.githubusercontent.com", githubPath,
                function(body)
                    local file = io.open(filePath, "wb")
                    if file then
                        file:write(body)
                        file:close()
                        util.toast(fileName .. " saved successfully.")
                    else
                        util.toast("Failed to save " .. fileName)
                    end
                end,
                function()
                    util.toast("Failed to download " .. fileName .. " from GitHub.")
                end
            )
            async_http.dispatch()
        end
    end

    -- Load textures
    local mainDashPath = pngDir .. "Main_Dash.png"
    if filesystem.exists(mainDashPath) then
        dashboardTexture = directx.create_texture(mainDashPath)
    end

    local sideViewPath = pngDir .. "Side_View_Car.png"
    if filesystem.exists(sideViewPath) then
        sideViewCarTexture = directx.create_texture(sideViewPath)
    end

    local topViewPath = pngDir .. "Top_View_Car.png"
    if filesystem.exists(topViewPath) then
        topViewCarTexture = directx.create_texture(topViewPath)
    end

    local frontViewPath = pngDir .. "Front_View_Car.png"
    if filesystem.exists(frontViewPath) then
        frontViewCarTexture = directx.create_texture(frontViewPath)
    end
end

-- Manually parse simple version JSON (mock parser)
function parseVersionData(versionData)
    local parsedData = {}
    for line in versionData:gmatch("[^\r\n]+") do
        local key, value = line:match('"([^"]+)":%s*([%d%.]+)')
        if key and value then
            parsedData[key] = tonumber(value)
        end
    end
    return parsedData
end

-- Function to check if an update is available for the version files
function checkForUpdates()
    local localVersionPath = filesystem.resources_dir() ..
    "Reagans_Standard_Menu_Resources/JSON_Files/Version_Tracking.txt"
    local remoteVersionPath = "/Ronnie-Reagan/Reagans_Standard_Menu/main/Version_Tracking.txt"

    -- Ensure directory exists
    filesystem.mkdirs(filesystem.resources_dir() .. "Reagans_Standard_Menu_Resources/JSON_Files/")

    -- Read local version data
    local localVersionData = {}
    if filesystem.exists(localVersionPath) then
        local file = io.open(localVersionPath, "r")
        local data = file:read("*all")
        file:close()
        localVersionData = parseVersionData(data)
    end

    -- Fetch remote version data
    async_http.init("raw.githubusercontent.com", remoteVersionPath,
        function(body)
            local remoteVersionData = parseVersionData(body)
            local scriptUpdateAvailable = remoteVersionData.script_Version > (localVersionData.script_Version or 0)
            local pngUpdateAvailable = remoteVersionData.png_Version > (localVersionData.png_Version or 0)

            if scriptUpdateAvailable or pngUpdateAvailable then
                util.toast("Update available! Downloading new files...")
                updating = true
                if pngUpdateAvailable then
                    fetchDashboardTexture()
                elseif scriptUpdateAvailable then
                    fetchScript()
                else
                    util.toast("Something went wrong, error code 436549")
                end
                -- Save updated version tracking
                local file = io.open(localVersionPath, "w")
                file:write(body)
                file:close()
                util.toast("Version tracking updated.")
                updating = false
            else
                util.toast("No updates found.\nCurrent Versions: Script: " ..
                localVersionData.script_Version ..
                ", PNG : " ..
                localVersionData.png_Version ..
                "\nRemote Versions: Script: " ..
                remoteVersionData.script_Version .. ", PNG: " .. remoteVersionData.png_Version)
            end
        end,
        function()
            util.toast("Failed to fetch remote version tracking data.")
        end
    )
    async_http.dispatch()
end

-- Call this function at the start to check for updates
checkForUpdates()
fetchDashboardTexture()

-- Apply scaling and offsets to all elements
function applyScaleAndOffset(x, y)
    return speedometerXOffset + (x - 0.5) * speedometerScale, speedometerYOffset + (y - 0.5) * speedometerScale
end

-- Function to dynamically adjust the center based on rotation angle
function calculateRotationOffset(rotation, sizeX, sizeY)
    local offsetX = (sizeX / 2) * math.cos(rotation) - (sizeY / 2) * math.sin(rotation)
    local offsetY = (sizeX / 2) * math.sin(rotation) + (sizeY / 2) * math.cos(rotation)
    return offsetX, offsetY
end

--#region Draw Car Views (New Textures)

-- Function to draw additional textures with scaling and positioning
function drawCarViews()
    -- Draw side view texture
    if sideViewCarTexture and directx.has_texture_loaded(sideViewCarTexture) then
        local sideX, sideY = applyScaleAndOffset(0.396, 0.453)
        directx.draw_texture(sideViewCarTexture, 0.5 * speedometerScale, 0.5 * speedometerScale, 0.5, 0.5, sideX, sideY,
            0, 1, 1, 1, carViewOpacities / 100)
    else
        util.toast("Side view car texture not loaded.")
    end

    -- Draw top view texture
    if topViewCarTexture and directx.has_texture_loaded(topViewCarTexture) then
        local topX, topY = applyScaleAndOffset(0.4799, 0.8)
        directx.draw_texture(topViewCarTexture, 0.5 * speedometerScale, 0.5 * speedometerScale, 0.5, 0.5, topX, topY, 0,
            1, 1, 1, carViewOpacities / 100)
    else
        util.toast("Top view car texture not loaded.")
    end

    -- Draw front view texture
    if frontViewCarTexture and directx.has_texture_loaded(frontViewCarTexture) then
        local frontX, frontY = applyScaleAndOffset(0.562, 0.392 --[[upside down = - 0.086]])
        directx.draw_texture(frontViewCarTexture, 0.5 * speedometerScale, 0.5 * speedometerScale, 0.5, 0.5, frontX,
            frontY, 0 --[[rotation]], 0, 0, 0, carViewOpacities / 100)
    else
        util.toast("Front view car texture not loaded.")
    end
end

--#endregion

--#region Analog Tachometer and Speedometer Needles

-- Function to draw lines at each main increment
function drawSpeedometerIncrements(maxValue, increments)
    local centerX, centerY = applyScaleAndOffset(0.661, 0.663)
    local radius = 0.15 * speedometerScale

    for _, increment in ipairs(increments) do
        local angle = math.rad(((increment / 320) * 175 - -135)) + math.rad(63)

        local lineX2 = centerX + math.cos(angle) * (radius / 1.5)
        local lineY2 = centerY + math.sin(angle) * (radius * 1.25)

        local lineColour = { 1, 1, 1, 1 }

        directx.draw_line(centerX, centerY, lineX2, lineY2, table.unpack(lineColour))
    end
end

function drawAnalogNeedle(value, maxValue, isRPM)
    local centerX, centerY = applyScaleAndOffset(isRPM and 0.297 or 0.661, 0.663)

    local radius = 0.15 * speedometerScale

    local needleAngle = math.rad((value / maxValue) * 270 - 135) - math.rad(63) -- subtract 63 to line up with the 0 mark

    local needleX = centerX + math.cos(needleAngle) * (radius / 1.5 --[[adjust for screen ratio]])
    local needleY = centerY + math.sin(needleAngle) * (radius * 1.25 --[[adjust for screen ratio]])

    local colour = {}
    if isRPM then
        for i, v in ipairs(rpmNeedleColour) do
            table.insert(colour, v / 255.0)
        end
    else
        for i, v in ipairs(speedometerNeedleColour) do
            table.insert(colour, v / 255.0)
        end
    end
    table.insert(colour, 4, 1.0)
    local speedometerIncrements = { 40, 80, 120, 160, 200, 240, 280, 320 }
    --drawSpeedometerIncrements(maxValue, speedometerIncrements)
    directx.draw_line(centerX, centerY, needleX, needleY, table.unpack(colour))
end

function drawRPM()
    local playerPed = PLAYER.PLAYER_PED_ID()
    local vehicle = PED.GET_VEHICLE_PED_IS_IN(playerPed, false)

    if vehicle ~= 0 then
        local revRatio = VEHICLE._GET_VEHICLE_CURRENT_REV_RATIO(vehicle)
        local rpm = revRatio * 10000
        drawAnalogNeedle(rpm, 12000, true)
    end
end

function drawSpeedometer(speed)
    drawAnalogNeedle(speed, 320, false)
end

--#endregion

--#region Gear Display

-- this needs to be adjusted to scroll for higher gear counts than 6
function drawGearDisplay()
    local playerPed = PLAYER.PLAYER_PED_ID()
    local vehicle = PED.GET_VEHICLE_PED_IS_IN(playerPed, false)

    if vehicle ~= 0 then
        local gearX, gearY = applyScaleAndOffset(0.4, 0.482)
        local colour = {}
        for i, v in ipairs(gearSelectorColour) do
            table.insert(colour, v / 255.0)
        end
        table.insert(colour, 4, 1.0)
        directx.draw_text(gearX, gearY, getDigitalComponents(), ALIGN_CENTRE_LEFT, 1 * speedometerScale,
            table.unpack(colour))
    end
end

--#endregion

--#region Digital Speed Display

function drawSpeedText(speed)
    local speedX, speedY = applyScaleAndOffset(0.7, 0.736)
    local colour = {}
    for i, v in ipairs(digitalSpeedometerColour) do
        table.insert(colour, v / 255.0)
    end
    table.insert(colour, 4, 1.0)
    directx.draw_text(speedX, speedY, speed .. (currentSpeedMode == KPH and " KPH" or " MPH"), ALIGN_CENTRE_RIGHT,
        1.2 * speedometerScale, table.unpack(colour))
end

--#endregion

function inDrive()
    return getCurrentGear() ~= 0
end

function getMaxGears()
    local playerPed = PLAYER.PLAYER_PED_ID()
    local vehicle = PED.GET_VEHICLE_PED_IS_IN(playerPed, false)
    return VEHICLE._GET_VEHICLE_MAX_DRIVE_GEAR_COUNT(vehicle)
end

function getCurrentGear()
    local playerPed = PLAYER.PLAYER_PED_ID()
    local vehicle = PED.GET_VEHICLE_PED_IS_IN(playerPed, false)
    return VEHICLE._GET_VEHICLE_CURRENT_DRIVE_GEAR(vehicle)
end

function getCurrentGearForDisplay()
    local display = ""
    local numberGears = getMaxGears()
    local currentGear = getCurrentGear()

    for gear = 1, numberGears do
        if gear ~= currentGear then
            display = display .. " " .. tostring(gear)
        else
            display = display .. " |" .. tostring(gear) .. "|"
        end
    end

    return display .. " "
end

-- returns a string with padding on each end
function getDigitalComponents()
    local driveSelector = inDrive() and " P R N [D] " or " P [R] N D "
    return driveSelector .. getCurrentGearForDisplay()
end

--#region Main Display Function

function displaySpeedometer()
    local playerPed = PLAYER.PLAYER_PED_ID()
    if playerPed and isPlayerInVehicle(playerPed) then
        local currentVeh = getCurrentVehicle(playerPed)
        local speed = ENTITY.GET_ENTITY_SPEED(currentVeh)

        if currentSpeedMode == KPH then
            speed = math.floor(speed * 3.6)
        elseif currentSpeedMode == MPH then
            speed = math.floor(speed * 2.236936)
        end

        if dashboardTexture and directx.has_texture_loaded(dashboardTexture) then
            local dashX, dashY = applyScaleAndOffset(0.48, 0.35)
            directx.draw_texture(dashboardTexture, 0.7 * speedometerScale, 0.7 * speedometerScale, 0.5, 0.5, dashX, dashY,
                0, 1, 1, 1, mainDashOpacity / 100)
        else
            util.toast("Dashboard texture not loaded.")
        end

        drawCarViews()
        drawRPM()
        drawSpeedometer(speed)
        drawSpeedText(speed)
        drawGearDisplay()
    end
end

function profile()
    profiling.tick("speedometer", function() displaySpeedometer() end)
end

--#endregion

--#region Menu Items
speedometer:toggle_loop("Speedometer Profiling", {}, "Start profiling the current version of the speedometer", profile,
    function() return end)
speedometer:toggle_loop("Toggle Speedometer", {}, "Show speedometer", displaySpeedometer, function() return end)

speedometer:toggle("KPH/MPH", {}, "Switch speed unit",
    function() currentSpeedMode = (currentSpeedMode == KPH and MPH or KPH) end)
speedometer:toggle("Analog/Digital Mode", {}, "Switch between analog and digital speedometer",
    function() analogMode = not analogMode end)

-- Analog Settings
analogSettingsMenu:slider_float("Dash X Position", {}, "Move dash horizontally", 0, 100, speedometerXOffset * 100, 1,
    function(value) speedometerXOffset = value / 100 end)
analogSettingsMenu:slider_float("Dash Y Position", {}, "Move dash vertically", 0, 100, speedometerYOffset * 100, 1,
    function(value) speedometerYOffset = value / 100 end)
analogSettingsMenu:slider_float("Dash Scale", {}, "Scale the entire dash", 5, 200, speedometerScale * 100, 1,
    function(value) speedometerScale = value / 100 end)
-- Colours
analogSettingsMenu:list_select("Speedometer Needle Colour", {}, "Select the color for the Speedometer Needle",
    colourOptions, 2, function(value) speedometerNeedleColour = colourOptions[value][3] end)
analogSettingsMenu:list_select("Tachometer Needle Colour", {}, "Select the color for the Tachometer (RPM) Needle",
    colourOptions, 2, function(value) rpmNeedleColour = colourOptions[value][3] end)
analogSettingsMenu:list_select("Digital Speedometer Colour", {},
    "Select the color for the Digital Speedometer below the analog display", colourOptions, 2,
    function(value) digitalSpeedometerColour = colourOptions[value][3] end)
analogSettingsMenu:list_select("Gear Selection Colour", {},
    "Select the color for the Gear Selection Display between the guages", colourOptions, 2,
    function(value) gearSelectorColour = colourOptions[value][3] end)
-- Opacities
analogSettingsMenu:slider_float("Dash Opacity", {},
    "Select the opacity for the Main Dash. 0.01 is clear and 1.0 is fully coloured", 001, 100, mainDashOpacity, 1,
    function(value) mainDashOpacity = value end)
analogSettingsMenu:slider_float("Tilt/Roll/Compass Car Opacity", {},
    "Select the opacity for the little cars in the dash that show Tilt/Roll/Compass. 0.01 is clear and 1.0 is fully coloured",
    001, 100, carViewOpacities, 1, function(value) carViewOpacities = value end)

--#endregion
