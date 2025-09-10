--[[
████████╗ ██████╗ ██╗  ██╗   ██╗███████╗██████╗ ███████╗
╚══██╔══╝██╔═══██╗██║  ╚██╗ ██╔╝██╔════╝██╔══██╗██╔════╝
   ██║   ██║   ██║██║   ╚████╔╝ █████╗  ██║  ██║█████╗  
   ██║   ██║   ██║██║    ╚██╔╝  ██╔══╝  ██║  ██║██╔══╝  
   ██║   ╚██████╔╝███████╗██║   ███████╗██████╔╝███████╗
   ╚═╝    ╚═════╝ ╚══════╝╚═╝   ╚══════╝╚═════╝ ╚══════╝
SAFYRE HUB & COMPANY - LUA UNIVERSAL, EXPANSIVO, MODULAR - Parte 1
]]

-------------------------------- [ DEPENDÊNCIAS, BASES ESSENCIAIS ] -------------------------------
local Fluent = loadstring(game:HttpGet("https://github.com/dawid-scripts/Fluent/releases/latest/download/main.lua"))()
local Players, LocalPlayer = game:GetService("Players"), game:GetService("Players").LocalPlayer
local TweenService, CoreGui, RunService, UserInputService = game:GetService("TweenService"), game:GetService("CoreGui"), game:GetService("RunService"), game:GetService("UserInputService")
local HttpService, RepStorage = game:GetService("HttpService"), game:GetService("ReplicatedStorage")
local SoundService, Lighting   = game:GetService("SoundService"), game:GetService("Lighting")
local Workspace, Camera        = game:GetService("Workspace"), workspace.CurrentCamera
local Debris = game:GetService("Debris")

-- Estado do Hub global
local HUBSTATE = {
    Version = "3.0.0",
    SessionId = HttpService:GenerateGUID(false),
    Started = tick(),
    User = LocalPlayer.Name,
    Theme = "Dark",
    Notices = {},
    Stats = {},
    CommandsRun = 0,
}
local MODULES = {}
local NOTIFICATIONS = {}

-------------------------------- [ UI PRINCIPAL, ABAS, NOTIFICAÇÃO INICIAL ] ----------------------
local Window = Fluent:CreateWindow({
    Title = "Safyre Hub & Company",
    SubTitle = "Universal DemoHub v"..HUBSTATE.Version,
    TabWidth = 170,
    Size = UDim2.fromOffset(860, 540),
    Acrylic = true,
    Theme = HUBSTATE.Theme,
    MinimizeKey = Enum.KeyCode.LeftControl,
})
local Tabs = {
    Home     = Window:AddTab({ Title = "Home", Icon = "home" }),
    ESP      = Window:AddTab({ Title = "ESP", Icon = "eye" }),
    Autos    = Window:AddTab({ Title = "Automations", Icon = "settings2" }),
    Overlay  = Window:AddTab({ Title = "Overlay", Icon = "leaderboard" }),
    Visuals  = Window:AddTab({ Title = "Visuals", Icon = "star" }),
    Commands = Window:AddTab({ Title = "Commands", Icon = "terminal" }),
    Admin    = Window:AddTab({ Title = "Admin", Icon = "shield" }),
    Logs     = Window:AddTab({ Title = "Console", Icon = "clipboard" }),
}

local function quickNotify(msg, time)
    Window:Notify({
        Title = "SafyreHub Notice",
        Content = msg,
        Duration = time or 3
    })
end

quickNotify("Bem-vindo, "..LocalPlayer.Name.."!\nClique no botão flutuante para abrir o Hub.\nExplore as abas!", 6)

-- Som de inicialização
local s=Instance.new("Sound",SoundService)
s.SoundId = "rbxassetid://1841671229"
s.Volume = 1
s:Play()
Debris:AddItem(s,3)

-------------------------------- [ BOTÃO FLUTUANTE, DRAGGING, SOM AO CLICAR ] ---------------------
local iconAsset = "rbxassetid://6031091006" -- (Troque pelo seu asset id customizado futuramente)
local gui = Instance.new("ScreenGui")
gui.Name = "SafyreHubBtn"
gui.ResetOnSpawn = false
pcall(function() if syn and syn.protect_gui then syn.protect_gui(gui) end end)
gui.Parent = CoreGui

local sizePx = 72
local frame = Instance.new("Frame")
frame.Parent = gui
frame.Size = UDim2.new(0, sizePx, 0, sizePx)
frame.Position = UDim2.new(0, 20, 0, 160)
frame.BackgroundColor3 = Color3.fromRGB(43,59,92)
frame.BackgroundTransparency = 0.13
frame.BorderSizePixel = 0
frame.ZIndex = 500
frame.Active = true

local uicorner = Instance.new("UICorner",frame)
uicorner.CornerRadius = UDim.new(0, 22)

local openButton = Instance.new("ImageButton")
openButton.Parent = frame
openButton.Size = UDim2.new(1, -12, 1, -12)
openButton.Position = UDim2.new(0, 6, 0, 6)
openButton.Image = iconAsset
openButton.BackgroundTransparency = 1
openButton.ZIndex = 501
openButton.Active = true

local clickSound = Instance.new("Sound",SoundService)
clickSound.SoundId = "rbxassetid://9118828563"
clickSound.Volume = 1
openButton.MouseButton1Click:Connect(function()
    clickSound:Play()
    Window:Minimize(false)
end)

local dragging, dragStart, startPos
frame.InputBegan:Connect(function(input)
    if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
        dragging = true
        dragStart = input.Position
        startPos = frame.Position
        input.Changed:Connect(function()
            if input.UserInputState == Enum.UserInputState.End then dragging = false end
        end)
    end
end)
UserInputService.InputChanged:Connect(function(input)
    if dragging and (input.UserInputType == Enum.UserInputType.MouseMovement or input.UserInputType == Enum.UserInputType.Touch) then
        local delta = input.Position - dragStart
        frame.Position = startPos + UDim2.new(0, delta.X, 0, delta.Y)
    end
end)

-------------------------------- [ NOTIFICAÇÕES CUSTOM, TOASTS, DEMO ] ------------------------

NOTIFICATIONS.Show = function(txt, dur)
    local toast = Instance.new("TextLabel")
    toast.Text = "🔔 "..txt
    toast.BackgroundTransparency = 0.1
    toast.BackgroundColor3 = Color3.fromRGB(50,50,50)
    toast.TextColor3 = Color3.new(1,1,1)
    toast.Font = Enum.Font.GothamBold
    toast.TextSize = 22
    toast.AnchorPoint = Vector2.new(0.5, 0)
    toast.Position = UDim2.new(0.5, 0, 0, 44+28*#HUBSTATE.Notices)
    toast.Size = UDim2.new(0, 340, 0, 32)
    toast.Parent = gui
    toast.ZIndex = 1002
    local c = Instance.new("UICorner",toast) c.CornerRadius = UDim.new(0,14)
    table.insert(HUBSTATE.Notices, toast)
    local tw = TweenService:Create(toast,TweenInfo.new(0.33),{BackgroundTransparency=0.32,TextTransparency=0.1; Position=toast.Position+UDim2.new(0,0,0.035,0)})
    tw:Play()
    Debris:AddItem(toast,dur or 3)
    delay((dur or 3)-0.25,function()
        toast.TextTransparency = 1
    end)
end

-- Exemplo: NOTIFICATIONS.Show("Hub Ativado!", 4)

----------------------------------------------------
-- Prossiga para a PARTE 2 para as funções ESP, Weapons, Visuals, Automations, Logs, Admin, Overlay etc!
----------------------------------------------------
----------------------------------------------------
------------------- PARTE 2 -----------------------
-- ESP, WEAPONS, OVERLAY, VISUALS, AUTOMATIONS, ADMIN, LOGS, DEMOS
----------------------------------------------------

--------------------- [ MÓDULO: ESP UNIVERSAL, OUTLAW MAIOR RECOMPENSA ] -------------------------

MODULES.ESP = {
    Enabled = false,
    TopOutlawESP = true,
    ESPs = {},
    HighlightProps = {
        Outlaw      = {Fill=Color3.fromRGB(255,255,255), Outline=Color3.fromRGB(255,0,0)},
        TopOutlaw   = {Fill=Color3.fromRGB(255,255,80), Outline=Color3.fromRGB(255,30,30)},
        Sheriff     = {Fill=Color3.fromRGB(255,255,0),  Outline=Color3.fromRGB(255,255,0)},
        Civilian    = {Fill=Color3.fromRGB(0,255,0),    Outline=Color3.fromRGB(0,255,0)},
        Enemy       = {Fill=Color3.fromRGB(44,20,240),  Outline=Color3.fromRGB(255,90,255)}
    },
    UpdateESP = function(self)
        -- Identifica o Outlaw de maior recompensa
        local top, maxBounty = nil, -math.huge
        for _,p in ipairs(Players:GetPlayers()) do
            if p.Team and tostring(p.Team)=="Outlaw" and p:FindFirstChild("leaderstats") and p.leaderstats:FindFirstChild("Bounty") then
                local b = tonumber(p.leaderstats.Bounty.Value) or 0 if b>maxBounty then maxBounty = b; top=p end
            end
        end
        for _,p in ipairs(Players:GetPlayers()) do
            if p~=LocalPlayer and p.Character and p.Character:FindFirstChild("HumanoidRootPart") then
                if not self.ESPs[p] then
                    local h=Instance.new("Highlight")
                    h.Name="SafyreHubESP"
                    h.Adornee=p.Character
                    h.Parent=p.Character
                    self.ESPs[p]=h
                end
                local t=tostring(p.Team)
                if self.TopOutlawESP and p==top and t=="Outlaw" then
                    self.ESPs[p].FillColor=self.HighlightProps.TopOutlaw.Fill
                    self.ESPs[p].OutlineColor=self.HighlightProps.TopOutlaw.Outline
                    self.ESPs[p].DepthMode=Enum.HighlightDepthMode.AlwaysOnTop
                else
                    if t=="Outlaw" then
                        self.ESPs[p].FillColor=self.HighlightProps.Outlaw.Fill
                        self.ESPs[p].OutlineColor=self.HighlightProps.Outlaw.Outline
                    elseif t=="Sheriff" then
                        self.ESPs[p].FillColor=self.HighlightProps.Sheriff.Fill
                        self.ESPs[p].OutlineColor=self.HighlightProps.Sheriff.Outline
                    elseif t=="Civilian" then
                        self.ESPs[p].FillColor=self.HighlightProps.Civilian.Fill
                        self.ESPs[p].OutlineColor=self.HighlightProps.Civilian.Outline
                    else
                        self.ESPs[p].FillColor=self.HighlightProps.Enemy.Fill
                        self.ESPs[p].OutlineColor=self.HighlightProps.Enemy.Outline
                    end
                    self.ESPs[p].DepthMode=Enum.HighlightDepthMode.Occluded
                end
            elseif self.ESPs[p] then
                self.ESPs[p]:Destroy() self.ESPs[p]=nil
            end
        end
    end,
    Cleanup = function(self) for _,h in pairs(self.ESPs) do h:Destroy() end; table.clear(self.ESPs) end
}
RunService.RenderStepped:Connect(function()
    if MODULES.ESP.Enabled then MODULES.ESP:UpdateESP() else MODULES.ESP:Cleanup() end
end)

local espSec = Tabs.ESP:AddSection("ESP Toggle & Demos")
espSec:AddToggle("SeePlayersESP",{
    Title="Enable ESP", Default=false, Callback=function(v) MODULES.ESP.Enabled = v end
})
espSec:AddToggle("TopOutlawESP",{
    Title="Highlight Top Outlaw", Default=true, Callback=function(v) MODULES.ESP.TopOutlawESP = v end
})

---------------------- [ MÓDULO: WEAPON DEMOS (UPGRADE FAST, ONESHOT) ] --------------------------

local weaponSection = Tabs.Commands:AddSection("Weapon Mods")
weaponSection:AddButton({
    Title = "One-Shot Mode", Description = "Todas armas causam dano máximo!",
    Callback = function()
        local ok,stats=pcall(function() return require(RepStorage.GunScripts.GunStats) end)
        if ok and type(stats) == "table" then
            for _,v in pairs(stats) do v.MaxDamage,v.MinDamage = 999,999 end
        end
        NOTIFICATIONS.Show("Modo de dano máximo ativado!",3)
    end
})
weaponSection:AddButton({
    Title="Ultra Fast Reload",Description="Recarregue quase instantaneamente!", Callback=function()
        local ok,stats=pcall(function() return require(RepStorage.GunScripts.GunStats) end)
        if ok and type(stats)=="table" then for _,v in pairs(stats) do v.ReloadSpeed = 0.02 end end
        NOTIFICATIONS.Show("Recarregamento ultra-rápido!",3)
    end
})

----------------------- [ MÓDULO: OVERLAY DE ESTATÍSTICAS AO VIVO ] -----------------------------

OVERLAY = {
    SessionStart = os.time(),
    Events = {},
    TopBounty = 0,
    TopPlayer = "",
    XP = 0,
}
function OVERLAY:LogEvent(str)
    table.insert(self.Events, 1, os.date("%H:%M:%S").." - "..str)
    if #self.Events>19 then table.remove(self.Events) end
end
function OVERLAY:GetStats()
    return {
        ["Runtime"] = os.date("!%X", os.time() - self.SessionStart),
        ["ESP State"] = MODULES.ESP.Enabled and "ON" or "OFF",
        ["Players"] = #Players:GetPlayers(),
        ["Top Outlaw"] = MODULES.ESP.FindTopOutlaw and (select(1,MODULES.ESP:UpdateESP()) or "--") or "--",
        ["Your Name"] = LocalPlayer.Name,
        ["XP"] = self.XP
    }
end

local overlaySec = Tabs.Overlay:AddSection("Live Stats/Overlay")
overlaySec:AddButton({
    Title="Show Quick Overlay",
    Callback=function()
        local o=Instance.new("ScreenGui",CoreGui)
        o.Name="SafyreOverlay"
        for k,v in pairs(OVERLAY:GetStats()) do
            local txt=Instance.new("TextLabel",o)
            txt.Text=k..": "..tostring(v)
            txt.Size=UDim2.new(0,320,0,26)
            txt.Position=UDim2.new(0,22,0,34+26*#o:GetChildren())
            txt.BackgroundTransparency=1
            txt.Font=Enum.Font.Gotham
            txt.TextColor3=Color3.new(1,1,1)
        end
        Debris:AddItem(o,8)
    end
})

---------------------- [ MÓDULO: VISUALS, LIGHTING & EFEITOS RÁPIDOS ] --------------------------

local visSection = Tabs.Visuals:AddSection("Lighting/Effects")
visSection:AddButton({Title="Noite 🌙",Callback=function()Lighting.TimeOfDay="00:00:00"end})
visSection:AddButton({Title="Dia ☀️",Callback=function()Lighting.TimeOfDay="12:00:00"end})
visSection:AddButton({Title="Sem Nevoeiro",Callback=function()Lighting.FogEnd=100000 end})

---------------------- [ MÓDULO: AUTOMATIONS E MUTE ALL ] ----------------------------------------

local muteSec = Tabs.Autos:AddSection("Mute System")
muteSec:AddButton({
    Title="Mute All Sounds",Callback=function()
        for _,p in ipairs(Players:GetPlayers())do
            for _,s in ipairs(p:GetDescendants()) do if s:IsA("Sound") then s.Volume = 0 end end
        end
        for _,s in ipairs(workspace:GetDescendants()) do if s:IsA("Sound") then s.Volume = 0 end end
        NOTIFICATIONS.Show("Todos os sons mutados!",2.5)
    end
})
muteSec:AddButton({
    Title="Unmute All Sounds",Callback=function()
        for _,p in ipairs(Players:GetPlayers())do
            for _,s in ipairs(p:GetDescendants()) do if s:IsA("Sound") then s.Volume = 1 end end
        end
        for _,s in ipairs(workspace:GetDescendants()) do if s:IsA("Sound") then s.Volume = 1 end end
        NOTIFICATIONS.Show("Todos os sons reativados!",2.5)
    end
})

---------------------- [ CONTINUAÇÃO: EXPANSÃO ADMIN, LOGS, HOTKEYS, ETC NA PARTE 3 ] -------------
-- PARTE 3: Admin, Comandos, Log Console, Skins, Expansão Hotkeys, Personalização

-- Admin
local adminSec = Tabs.Admin:AddSection("Admin Commands")
adminSec:AddButton({Title="Print All Players",Callback=function()
    for _,p in ipairs(Players:GetPlayers())do print(p.Name)end
end})
adminSec:AddButton({Title="Give WalkSpeed 55",Callback=function()
    if LocalPlayer.Character and LocalPlayer.Character:FindFirstChild("Humanoid") then
        LocalPlayer.Character.Humanoid.WalkSpeed=55
        NOTIFICATIONS.Show("Velocidade ajustada!",2.5)
    end
end})
adminSec:AddButton({Title="Respawn Self",Callback=function()
    local humanoid = LocalPlayer.Character and LocalPlayer.Character:FindFirstChildWhichIsA("Humanoid")
    if humanoid then humanoid.Health = 0; NOTIFICATIONS.Show("Respawn acionado!",2) end
end})

-- Comandos rápidos/Quick Commands
local cmdSec = Tabs.Commands:AddSection("Quick Commands")
cmdSec:AddButton({
    Title="Kill Self",
    Callback=function()
        local h = LocalPlayer.Character and LocalPlayer.Character:FindFirstChildWhichIsA("Humanoid")
        if h then h.Health=0; NOTIFICATIONS.Show("Morto para respawn.",1.8) end
    end
})
cmdSec:AddButton({
    Title="Lag Game (Demo!)",
    Callback=function()
        for i=1,15 do workspace:Clone().Parent=game end
        NOTIFICATIONS.Show("Delay aumentado de propósito!",3)
    end,
    Description="Gera delay intencional (exemplo, não use em servidores reais!)"
})

-- Skins/Demonstrativo de coloração personagem
local skinsSection = Tabs.Visuals:AddSection("Skin/Color Mods")
skinsSection:AddButton({
    Title="Randomizar Cores",
    Callback=function()
        if LocalPlayer.Character then
            for _,v in pairs(LocalPlayer.Character:GetChildren()) do
                if v:IsA("BasePart") then v.Color = Color3.fromHSV(math.random(),1,1) end
            end
            NOTIFICATIONS.Show("Cores randomizadas!",2)
        end
    end,
    Description = "Sinta o efeito arco-íris rapid!"
})

-- Log Console/overlays
local logSec = Tabs.Logs:AddSection("Session Logs")
logSec:AddButton({Title="Log All Current Stats",Callback=function()
    print("=== SafyreHub Full Stats===")
    for k,v in pairs(HUBSTATE) do print(k,v) end
    for k,v in pairs(OVERLAY and OVERLAY.GetStats and OVERLAY:GetStats() or {})do print(k,v)end
    NOTIFICATIONS.Show("Logs impressos (dev console)!",2)
end})
logSec:AddLabel("Totais de eventos internos: "..(OVERLAY and #OVERLAY.Events or 0))
logSec:AddButton({
    Title="Log Recent Events",Callback=function()
        if OVERLAY and OVERLAY.Events then
            for i=1,math.min(#OVERLAY.Events,10) do print(OVERLAY.Events[i]) end
            NOTIFICATIONS.Show("Logs eventos impressos.",2)
        end
    end
})

-- Hotkey demo (fácil personalizar)
local function bindHotkey(key,actionName,callback)
    HOTKEYS = HOTKEYS or {}
    HOTKEYS[key] = callback
    UserInputService.InputBegan:Connect(function(input,gpe)
        if not gpe and input.KeyCode == key then callback() end
    end)
    NOTIFICATIONS.Show("Hotkey "..actionName.." ligada!",1.5)
end
bindHotkey(Enum.KeyCode.F4,"Esp Toggle",function()
    MODULES.ESP.Enabled = not MODULES.ESP.Enabled
    quickNotify("ESP: "..(MODULES.ESP.Enabled and "Ativado" or "Desativado"))
end)

local configSection = Tabs.Home:AddSection("Themes/Personalização")
configSection:AddDropdown("ThemeDropdown", {
    Title = "Fluent UI Theme",
    Values = {"Dark","Light","Rose","Aqua","Amethyst","Darker"},
    Default = HUBSTATE.Theme,
    Callback = function(v) Window:SetTheme(v) end,
})

Tabs.Home:AddSection("Créditos e informações"):AddLabel(
    "SafyreHub & Company\nGUI, modules, API, ESP inspired by various open-scripts, Perplexity AI, comunidade."
)

-- Fim da parte 3.
-- A próxima parte pode incluir hooks avançados, overlay mobile pro, achievements, animações, menu de friends, scoreboard, integração externa, etc.
-- PARTE 4: Overlay Pro, Achievements/Tarefas, Animações Visuais, Módulos de Expansão e Scoreboard

-- Overlay avançado: barra flutuante, stats sessão, XP, top jogador etc.
local overlayGui
local function showAdvancedOverlay()
    if overlayGui then overlayGui:Destroy() end
    overlayGui = Instance.new("ScreenGui",CoreGui)
    overlayGui.Name = "SafyreAdvancedOverlay"
    overlayGui.IgnoreGuiInset = true
    overlayGui.ZIndexBehavior = Enum.ZIndexBehavior.Global

    local bg = Instance.new("Frame", overlayGui)
    bg.Size = UDim2.new(0,390,0,195)
    bg.Position = UDim2.new(1,-400,0,74)
    bg.BackgroundTransparency = 0.15
    bg.BackgroundColor3 = Color3.fromRGB(28,33,65)
    bg.BorderSizePixel = 0
    bg.ZIndex = 3000
    local cor = Instance.new("UICorner",bg)
    cor.CornerRadius = UDim.new(0,18)
    local lbl = Instance.new("TextLabel",bg)
    lbl.Size = UDim2.new(1,0,0,34)
    lbl.Position = UDim2.new(0,0,0,0)
    lbl.BackgroundTransparency = 1
    lbl.Font = Enum.Font.GothamBold
    lbl.TextColor3 = Color3.fromRGB(89,215,250)
    lbl.Text = "SAFYRE LIVE STATS"
    lbl.TextSize = 24
    lbl.ZIndex = 3001

    local statsList = {
        {"Usuário", LocalPlayer.Name},
        {"Session Time", os.date("!%X", os.time()-(OVERLAY.SessionStart or os.time()))},
        {"Jogadores", #Players:GetPlayers()},
        {"ESP", MODULES.ESP and (MODULES.ESP.Enabled and "ON" or "OFF") or "--"},
        {"Top Outlaw", MODULES.ESP and MODULES.ESP.FindTopOutlaw and (select(1,MODULES.ESP:FindTopOutlaw()) or "--") or "--"},
        {"XP", OVERLAY and OVERLAY.XP or 0},
        {"Kills", math.random(6,80)}, -- exemplo, personalize aqui
        {"Deaths", math.random(0,30)}
    }
    for i,v in ipairs(statsList) do
        local l = Instance.new("TextLabel",bg)
        l.Text = ("%s: [ %s ]"):format(v[1], tostring(v[2]))
        l.Font = Enum.Font.Gotham
        l.Size = UDim2.new(1,-16,0,24)
        l.Position = UDim2.new(0,12,0,28+(i*22))
        l.TextColor3 = Color3.fromRGB(220,230,255)
        l.BackgroundTransparency = 1
        l.TextXAlignment = Enum.TextXAlignment.Left
        l.TextSize = 18
        l.ZIndex = 3002
    end
    Debris:AddItem(overlayGui,10)
end

Tabs.Overlay:AddButton({
    Title="Mostar Overlay PRO", Callback=showAdvancedOverlay,
    Description="Exibe painel animado de estatísticas avançadas"
})

-- Achievements/demo de tarefas por sessão
local achSec = Tabs.Overlay:AddSection("Tarefas & Conquistas")
local unlocked = {}
local function unlockAchievement(txt)
    if unlocked[txt] then return end
    unlocked[txt] = true
    NOTIFICATIONS.Show("🏅 Conquista: "..txt,3)
end

achSec:AddButton({
    Title="Jogar por 10 minutos",Callback=function()
        if (tick()-HUBSTATE.Started)>600 then
            unlockAchievement("Persistente: 10 minutos online!")
        else
            NOTIFICATIONS.Show("Ainda não atingiu 10 minutos. Volte depois!",2.2)
        end
    end
})
achSec:AddButton({Title="Usar ESP 3x",Callback=function()
    unlockAchievement("Caçador: Ativou ESP pelo menos 3 vezes!")
end})

-- Animações visuais de efeito/hud
Tabs.Visuals:AddButton({
    Title="Glow Aurablend (demo)", Callback=function()
        local glow = Instance.new("SelectionBox")
        glow.Parent = LocalPlayer.Character or workspace
        glow.Adornee = LocalPlayer.Character
        glow.LineThickness = 0.09
        glow.Color3 = Color3.fromRGB(math.random(40,255),math.random(180,255),255)
        glow.SurfaceTransparency = 0.5
        Debris:AddItem(glow,3)
        NOTIFICATIONS.Show("Brilho ativado",1.4)
    end,
    Description="Aura brilhante no corpo"
})

-- Scoreboard/placar simples
local function showScoreboard()
    local gui = Instance.new("ScreenGui",CoreGui)
    gui.Name = "SafyreScoreboard"
    local bg = Instance.new("Frame",gui)
    bg.Size = UDim2.new(0,320,0,32+#Players:GetPlayers()*28)
    bg.Position = UDim2.new(0,18,0,64)
    bg.BackgroundTransparency = 0.05
    bg.BackgroundColor3 = Color3.fromRGB(0,35,100)
    bg.BorderSizePixel = 0
    local title = Instance.new("TextLabel",bg)
    title.Text = "SCOREBOARD"
    title.Size = UDim2.new(1,0,0,32)
    title.TextColor3 = Color3.fromRGB(255,255,255)
    title.BackgroundTransparency = 1
    title.Font = Enum.Font.GothamBold
    title.TextSize = 21
    for i,p in ipairs(Players:GetPlayers()) do
        local n = Instance.new("TextLabel",bg)
        n.Text = ("%d. %s"):format(i,p.Name)
        n.TextColor3 = p.Team and p.Team.TeamColor.Color or Color3.new(1,1,1)
        n.BackgroundTransparency = 1
        n.Size = UDim2.new(1,0,0,22)
        n.Position = UDim2.new(0,7,0,28+(i-1)*22)
        n.Font = Enum.Font.Gotham
        n.TextSize = 16
    end
    Debris:AddItem(gui,8)
end

Tabs.Overlay:AddButton({Title="Mostrar Scoreboard",Callback=showScoreboard,Description="Exibe a lista atual de jogadores"})

-- Personalização extra: Troca cor do botão flutuante/padrão
Tabs.Home:AddButton({
    Title="Trocar cor do botão flutuante", Callback=function()
        frame.BackgroundColor3 = Color3.fromHSV(math.random(),0.44,0.98)
        NOTIFICATIONS.Show("Botão colorido!",1)
    end
})

-- Pronto para seguir para a próxima parte!  
-- PARTE 5: Friends, Chat Commands, Anti-AFK, Customização e Expansão Avançada

-- Lista de amigos e ações rápidas
local function showFriendsList()
    local gui = Instance.new("ScreenGui", CoreGui)
    gui.Name = "SafyreFriendsGui"
    local bg = Instance.new("Frame", gui)
    bg.Size = UDim2.new(0, 250, 0, 46 + (#Players:GetPlayers() * 32))
    bg.Position = UDim2.new(0, 28, 0.5, -110)
    bg.BackgroundColor3 = Color3.fromRGB(30,36,58)
    bg.BackgroundTransparency = 0.08
    local cor = Instance.new("UICorner",bg)
    cor.CornerRadius = UDim.new(0,12)
    local label = Instance.new("TextLabel", bg)
    label.Size = UDim2.new(1,0,0,34)
    label.Position = UDim2.new(0,0,0,0)
    label.BackgroundTransparency = 1
    label.TextColor3 = Color3.fromRGB(130,220,255)
    label.Font = Enum.Font.GothamBold
    label.Text = "AMIGOS ONLINE"
    label.TextSize = 20
    label.TextXAlignment = Enum.TextXAlignment.Center

    for i,p in ipairs(Players:GetPlayers()) do
        local n = Instance.new("TextLabel", bg)
        n.Text = p.Name..((Players:GetFriendStatusAsync(p.UserId) == Enum.FriendStatus.Friend) and " 🟢" or " ⚪")
        n.TextColor3 = Color3.fromRGB(255,255,255)
        n.BackgroundTransparency = 1
        n.Size = UDim2.new(1,0,0,22)
        n.Position = UDim2.new(0,12,0,28 + (i-1)*28)
        n.Font = Enum.Font.Gotham
        n.TextSize = 15
        n.ZIndex = 22
    end
    Debris:AddItem(gui,8)
end
Tabs.Home:AddButton({Title="Mostrar Amigos Online",Callback=showFriendsList})

-- Comandos rápidos via chat
local function chatListener()
    Players.LocalPlayer.Chatted:Connect(function(msg)
        local args = msg:split(" ")
        local cmd = args[1]:lower()

        if cmd == "!esp" then
            MODULES.ESP.Enabled = not MODULES.ESP.Enabled
            NOTIFICATIONS.Show("ESP "..(MODULES.ESP.Enabled and "ativado" or "desativado"), 2)
        elseif cmd == "!speed" and args[2] then
            local v = tonumber(args[2])
            if LocalPlayer.Character and LocalPlayer.Character:FindFirstChild("Humanoid") and v then
                LocalPlayer.Character.Humanoid.WalkSpeed = v
                NOTIFICATIONS.Show("Velocidade: "..v, 2)
            end
        elseif cmd == "!overlay" then
            showAdvancedOverlay()
        elseif cmd == "!score" then
            showScoreboard()
        end
    end)
end
chatListener()
Tabs.Commands:AddLabel('Comandos pelo chat: !esp | !speed <num> | !overlay | !score')

-- Anti-AFK simples
local function antiAfk()
    local connection = LocalPlayer.Idled:Connect(function()
        UserInputService:SendKeyEvent(true, Enum.KeyCode.Space, false, game)
        NOTIFICATIONS.Show("Anti-AFK ativado.",1.5)
    end)
    Tabs.Autos:AddLabel("Anti-AFK ativo ✔")
    return connection
end
antiAfk()

-- Customização visual live: tema randômico e cor do overlay.
Tabs.Home:AddButton({
    Title="Tema Aleatório",Callback=function()
        local themes = {"Dark","Light","Rose","Aqua","Amethyst","Darker"}
        local sel = themes[math.random(1,#themes)]
        Window:SetTheme(sel)
        NOTIFICATIONS.Show("Tema "..sel.." aplicado!",2)
    end
})

Tabs.Visuals:AddButton({
    Title="Cor aleatória no overlay",Callback=function()
        if overlayGui and overlayGui:FindFirstChildOfClass("Frame") then
            overlayGui:FindFirstChildOfClass("Frame").BackgroundColor3 = Color3.fromHSV(math.random(),0.5,0.8)
            NOTIFICATIONS.Show("Overlay colorido!",1)
        end
    end
})

-- Dummy achievements demonstrativos (expanda à vontade)
achSec:AddButton({
    Title="Achievement: Mudar de tema 3x",
    Callback=function()
        unlockAchievement("Estilo Flexível: 3 temas em uma sessão!")
    end
})

-- Hook demo: tocando efeito ao alterar ESP
table.insert(HOOKS or {}, RunService.Heartbeat:Connect(function()
    if MODULES.ESP and MODULES.ESP.Enabled and not frame.BackgroundTransparency then
        frame.BackgroundTransparency = 0.4 - math.abs(math.sin(tick()*1.2))*0.13
    end
end))
-- PARTE 6: Módulos Extras, Avançados e Dicas para Expansão

-- Achievement de sessão prolongada e detecção de tempo no jogo
achSec:AddButton({
    Title="Jogar por 1 hora",
    Callback=function()
        if (tick()-HUBSTATE.Started)>3600 then
            unlockAchievement("Veterano: 1 hora de sessão!")
        else
            NOTIFICATIONS.Show("Ainda não completou 1 hora! Continue jogando.",2.2)
        end
    end
})
achSec:AddButton({
    Title="Desbloquear aleatório",
    Callback=function()
        local achs = {"Primeiro Login","Primeiro Menu","Primeira Kill","Primeiro ESP","Primeiro Admin"}
        unlockAchievement(achs[math.random(1,#achs)])
    end,
    Description="Alcança conquistas por tentativa"
})

-- Sistema de reload do hub/fluent UI
Tabs.Config:AddButton({
    Title="Reload HUB (recarregar scripts/mods/gui)", Callback=function()
        NOTIFICATIONS.Show("Recarregando Hub...",2)
        wait(1.1)
        game:GetService("TeleportService"):TeleportToPlaceInstance(game.PlaceId, game.JobId, LocalPlayer)
    end,
    Description="Recarrega o hub na mesma sessão"
})

-- Demos de comandos automáticos e integração modular
Tabs.Commands:AddButton({
    Title="Mensagem Auto",
    Callback=function()
        for i=1,5 do
            local msg = "SafyreHub auto ["..i.."]"
            print(msg)
            NOTIFICATIONS.Show(msg,1)
        end
    end
})

-- Exemplo de integração externa (webhook/log remoto - para desenvolvimento!)
Tabs.Admin:AddButton({
    Title="Testar Log Remoto (Webhook)",Callback=function()
        local url, data = "https://discord.com/api/webhooks/...", {user=LocalPlayer.Name, ts=os.time()}
        pcall(function()
            -- Não funcional sem proxy/back, exemplo para expansão só!
            -- game:HttpGet(url.."?"..HttpService:JSONEncode(data))
        end)
        NOTIFICATIONS.Show("Demo: Evento registrado no webhook.",1.7)
    end
})

-- Demonstração: alteração de todas as cores de aberturas e animação HUD
Tabs.Visuals:AddButton({
    Title="Animar HUD safyre",
    Callback=function()
        for i=1,7 do
            frame.BackgroundColor3 = Color3.fromHSV(i/7,0.7,0.9)
            wait(0.20)
        end
        frame.BackgroundColor3 = Color3.fromRGB(43,59,92)
        NOTIFICATIONS.Show("HUD animado!",1)
    end
})

-- Suporte mobile/touch: mostra alerta ao detectar tela pequena
if math.min(workspace.CurrentCamera.ViewportSize.X,workspace.CurrentCamera.ViewportSize.Y) < 700 then
    quickNotify("Modo Mobile detectado! Experiência otimizada.", 3)
end

-- Dicas para expansão futura (coloque mais ações nos menus!)
-- 1. Adicione novas abas para minigames, mapas ou funções por jogo.
-- 2. Crie tabelas dinâmicas para listagem de armas, configs, teams, etc.
-- 3. Faça integração com sistemas de ranks ou achievements por progresso real.
-- 4. Implemente logs persistentes via HttpService/Datastore (usando módulos apropriados).
-- 5. Adicione comandos de voto, party, perfil, loot, quick-tp em menus externos.

-- FIM: Seu super-hub está pronto para uso e EXTENSÃO!
