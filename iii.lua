--[[
    罗布乐思 固定 GitHub 图片生成器（直链已内置）
    图片：1786207108827.png
    功能：面前生成图片 → 拖动滑块调节距离 → 一键固定 → 可穿透
]]

local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")

local player = Players.LocalPlayer
local character = player.Character or player.CharacterAdded:Wait()
local rootPart = character:WaitForChild("HumanoidRootPart")

-- ★ 你的 GitHub raw 图片链接（已修正为正确格式） ★
local IMAGE_URL = "https://raw.githubusercontent.com/flippy0825/flippy0825/main/1786207108827.png"

local imagePart = nil
local isFixed = false
local offsetZ = -5  -- 默认前方 5 格

-- ================= 创建控制界面 =================
local screenGui = Instance.new("ScreenGui")
screenGui.Name = "FixedGitHubImage"
screenGui.ResetOnSpawn = false
screenGui.Parent = player:WaitForChild("PlayerGui")

local mainFrame = Instance.new("Frame")
mainFrame.Size = UDim2.new(0, 220, 0, 100)
mainFrame.Position = UDim2.new(0, 10, 0, 10)
mainFrame.BackgroundColor3 = Color3.fromRGB(40, 40, 40)
mainFrame.BorderSizePixel = 2
mainFrame.Active = true
mainFrame.Draggable = true
mainFrame.Parent = screenGui

local title = Instance.new("TextLabel")
title.Size = UDim2.new(1, 0, 0, 22)
title.BackgroundColor3 = Color3.fromRGB(60, 60, 60)
title.Text = "图片控制器"
title.TextColor3 = Color3.new(1, 1, 1)
title.Font = Enum.Font.SourceSansBold
title.TextSize = 15
title.Parent = mainFrame

-- 距离显示
local distLabel = Instance.new("TextLabel")
distLabel.Size = UDim2.new(1, -10, 0, 18)
distLabel.Position = UDim2.new(0, 5, 0, 28)
distLabel.BackgroundTransparency = 1
distLabel.Text = "距离 (Z): -5"
distLabel.TextColor3 = Color3.new(1, 1, 1)
distLabel.Font = Enum.Font.SourceSans
distLabel.TextSize = 13
distLabel.Parent = mainFrame

-- 滑块背景
local sliderFrame = Instance.new("Frame")
sliderFrame.Size = UDim2.new(1, -10, 0, 12)
sliderFrame.Position = UDim2.new(0, 5, 0, 48)
sliderFrame.BackgroundColor3 = Color3.fromRGB(80, 80, 80)
sliderFrame.Parent = mainFrame

local sliderKnob = Instance.new("TextButton")
sliderKnob.Size = UDim2.new(0, 18, 1, 0)
sliderKnob.BackgroundColor3 = Color3.new(1, 1, 1)
sliderKnob.Text = ""
sliderKnob.Parent = sliderFrame

-- 固定按钮
local fixBtn = Instance.new("TextButton")
fixBtn.Size = UDim2.new(1, -10, 0, 28)
fixBtn.Position = UDim2.new(0, 5, 0, 65)
fixBtn.BackgroundColor3 = Color3.fromRGB(180, 100, 40)
fixBtn.Text = "固定图片"
fixBtn.TextColor3 = Color3.new(1, 1, 1)
fixBtn.Font = Enum.Font.SourceSansBold
fixBtn.TextSize = 16
fixBtn.Parent = mainFrame

-- ================= 滑块拖动逻辑 =================
local isDragging = false
sliderKnob.InputBegan:Connect(function(input)
    if input.UserInputType == Enum.UserInputType.MouseButton1 then
        isDragging = true
    end
end)
sliderKnob.InputEnded:Connect(function(input)
    if input.UserInputType == Enum.UserInputType.MouseButton1 then
        isDragging = false
    end
end)
UserInputService.InputChanged:Connect(function(input)
    if isDragging and input.UserInputType == Enum.UserInputType.MouseMovement then
        local mousePos = UserInputService:GetMouseLocation()
        local sliderX = sliderFrame.AbsolutePosition.X
        local sliderW = sliderFrame.AbsoluteSize.X
        local knobW = sliderKnob.AbsoluteSize.X
        local clampPos = math.clamp(mousePos.X - sliderX - knobW/2, 0, sliderW - knobW)
        sliderKnob.Position = UDim2.new(0, clampPos, 0, 0)
        local percent = clampPos / (sliderW - knobW)
        offsetZ = -2 - percent * 13
        distLabel.Text = "距离 (Z): " .. math.floor(offsetZ * 10) / 10
    end
end)

-- ================= 创建图片部件 =================
local function createImagePart(url)
    if imagePart then
        imagePart:Destroy()
    end

    -- 透明方块
    imagePart = Instance.new("Part")
    imagePart.Name = "GitHubImagePart"
    imagePart.Size = Vector3.new(5, 5, 0.2)
    imagePart.CanCollide = false
    imagePart.Anchored = true
    imagePart.Transparency = 1
    imagePart.Parent = workspace

    -- 前面贴图
    local surfaceFront = Instance.new("SurfaceGui")
    surfaceFront.Face = Enum.NormalId.Front
    surfaceFront.Adornee = imagePart
    surfaceFront.Parent = imagePart

    local imgFront = Instance.new("ImageLabel")
    imgFront.Size = UDim2.new(1, 0, 1, 0)
    imgFront.BackgroundTransparency = 1
    imgFront.Image = url
    imgFront.ScaleType = Enum.ScaleType.Stretch
    imgFront.Parent = surfaceFront

    -- 背面贴图
    local surfaceBack = Instance.new("SurfaceGui")
    surfaceBack.Face = Enum.NormalId.Back
    surfaceBack.Adornee = imagePart
    surfaceBack.Parent = imagePart

    local imgBack = Instance.new("ImageLabel")
    imgBack.Size = UDim2.new(1, 0, 1, 0)
    imgBack.BackgroundTransparency = 1
    imgBack.Image = url
    imgBack.ScaleType = Enum.ScaleType.Stretch
    imgBack.Parent = surfaceBack
end

-- ================= 位置跟随 =================
local function updatePosition()
    if imagePart and not isFixed and rootPart then
        local lookDir = rootPart.CFrame.LookVector
        imagePart.CFrame = rootPart.CFrame + lookDir * offsetZ
        imagePart.CFrame = CFrame.lookAt(imagePart.Position, rootPart.Position)
    end
end

RunService.RenderStepped:Connect(updatePosition)

-- ================= 固定按钮事件 =================
fixBtn.MouseButton1Click:Connect(function()
    if not imagePart then return end
    isFixed = not isFixed
    fixBtn.Text = isFixed and "已固定 (点击解除)" or "固定图片"
end)

-- ================= 角色重生处理 =================
player.CharacterAdded:Connect(function(newChar)
    character = newChar
    rootPart = newChar:WaitForChild("HumanoidRootPart")
end)

-- ================= 自动加载图片 =================
createImagePart(IMAGE_URL)