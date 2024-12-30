-- Services
local HttpService = game:GetService("HttpService")
local TeleportService = game:GetService("TeleportService")
local Players = game:GetService("Players")
local player = Players.LocalPlayer

-- Variables
local PlaceId = game.PlaceId
local ServersAPI = "https://games.roblox.com/v1/games/" .. PlaceId .. "/servers/Public?sortOrder=Asc&limit=100"

-- Function to fetch available servers
local function getServers()
    local servers = {}
    local nextCursor = nil

    repeat
        local url = ServersAPI
        if nextCursor then
            url = url .. "&cursor=" .. nextCursor
        end

        local success, response = pcall(function()
            return HttpService:JSONDecode(game:HttpGet(url))
        end)

        if success and response and response.data then
            for _, server in ipairs(response.data) do
                -- Only include servers that aren't full (i.e., playing < maxPlayers)
                if server.playing < server.maxPlayers and server.id ~= game.JobId then
                    table.insert(servers, server)
                end
            end
            nextCursor = response.nextPageCursor
        else
            warn("Failed to retrieve servers or no servers found.")
            break
        end
    until not nextCursor

    return servers
end

-- Function to sort servers by the number of players (descending)
local function sortServersByPlayerCount(servers)
    table.sort(servers, function(a, b)
        return a.playing > b.playing -- Sort by most players first
    end)
end

-- Function to attempt hopping to a server
local function hopToNewServer()
    local servers = getServers()

    -- Sort servers by player count (most players first)
    sortServersByPlayerCount(servers)

    if #servers > 0 then
        for _, server in ipairs(servers) do
            -- Try joining a server with the highest player count first
            local serverId = server.id
            if server.playing < server.maxPlayers then
                TeleportService:TeleportToPlaceInstance(PlaceId, serverId, player)
                print("Hopping to server with " .. server.playing .. " players.")
                return -- Exit once we successfully try hopping
            end
        end
    else
        warn("No available servers to hop to!")
    end
end

-- Function to loop hop through servers continuously
local function loopHop()
    while true do
        local servers = getServers()
        
        -- Sort servers by player count (most players first)
        sortServersByPlayerCount(servers)
        
        if #servers > 0 then
            local joined = false
            for _, server in ipairs(servers) do
                -- Try joining a server
                local serverId = server.id
                if server.playing < server.maxPlayers then
                    -- Attempt to teleport to the server
                    local success, message = pcall(function()
                        TeleportService:TeleportToPlaceInstance(PlaceId, serverId, player)
                    end)
                    
                    -- Check if the teleportation was successful
                    if success then
                        print("Successfully hopped to server with " .. server.playing .. " players.")
                        return -- Exit the loop if teleportation is successful
                    else
                        print("Failed to join server, trying another one...")
                    end
                end
            end
            if not joined then
                wait(2) -- Wait for 2 seconds before retrying
            end
        else
            warn("No available servers to hop to!")
            wait(2) -- Wait before retrying
        end
    end
end

-- Create GUI for the button
local function createGUI()
    local ScreenGui = Instance.new("ScreenGui")
    ScreenGui.Name = "ServerHopGUI"
    ScreenGui.Parent = game.CoreGui  -- Parent it to CoreGui so it shows on the screen

    local DragFrame = Instance.new("Frame")
    DragFrame.Size = UDim2.new(0, 200, 0, 50) -- Size of the button container
    DragFrame.Position = UDim2.new(0, 10, 0, 10) -- Top-left corner with some padding
    DragFrame.BackgroundColor3 = Color3.new(0.2, 0.2, 0.2)
    DragFrame.BorderSizePixel = 0
    DragFrame.Active = true
    DragFrame.Draggable = true -- Make it draggable if needed
    DragFrame.Parent = ScreenGui

    local Button = Instance.new("TextButton")
    Button.Size = UDim2.new(1, -10, 1, -10) -- Slight padding within the frame
    Button.Position = UDim2.new(0, 5, 0, 5)
    Button.BackgroundColor3 = Color3.new(0.3, 0.6, 0.8)
    Button.Text = "Loop Hop Servers"
    Button.Font = Enum.Font.SourceSansBold
    Button.TextColor3 = Color3.new(1, 1, 1)
    Button.TextSize = 20
    Button.Parent = DragFrame

    -- Connect button click to server hop loop
    Button.MouseButton1Click:Connect(function()
        loopHop()
    end)
end

-- Create the GUI when the script runs
createGUI()
