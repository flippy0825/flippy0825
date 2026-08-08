--[[
    罗布乐思图片生成器脚本
    功能：输入图片ID生成图片，在角色面前显示，调整位置后固定，可穿透
    适用：忍者注入器客户端执行
]]

-- 服务引用
local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")

local player = Players.LocalPlayer
local character = player.Character or player.CharacterAdded:Wait()
local rootPart = character:WaitForChild("HumanoidRootPart")

-- 生成图片的部件
local imagePart = nil
local isFixed = false
local offsetX = 0   -- 左右偏移
local offsetY = 0   -- 上下偏移
local offsetZ = -5  -- 前后偏移（负数在前面，默认前方5格）

-- 创建GUI
local screenGui = Instance.new("ScreenGui")
screenGui.Name = "ImageSpawner"
screenGui.ResetOnSpawn = false
screenGui.Parent = player:WaitForChild("PlayerGui")

-- 主框架
local mainFrame = Instance.new("Frame")
mainFrame.Size = UDim2.new(0, 250, 0, 200)
mainFrame.Position = UDim2.new(0, 10, 0, 10)
mainFrame.BackgroundColor3 = Color3.fromRGB(40, 40, 40)
mainFrame.BorderSizePixel = 2
mainFrame.Active = true
mainFrame.Draggable = true
mainFrame.Parent = screenGui

-- 标题
local title = Instance.new("TextLabel")
title.Size = UDim2.new(1, 0, 0, 30)
title.BackgroundColor3 = Color3.fromRGB(60, 60, 60)
title.Text = "图片生成器"
title.TextColor3 = Color3.new(1, 1, 1)
title.Font = Enum.Font.SourceSansBold
title.TextSize = 18
title.Parent = mainFrame

-- 输入框标签
local inputLabel = Instance.new("TextLabel")
inputLabel.Size = UDim2.new(1, -10, 0, 20)
inputLabel.Position = UDim2.new(0, 5, 0, 35)
inputLabel.BackgroundTransparency = 1
inputLabel.Text = "图片ID (rbxassetid://):"
inputLabel.TextColor3 = Color3.new(1, 1, 1)
inputLabel.TextXAlignment = Enum.TextXAlignment.Left
inputLabel.Font = Enum.Font.SourceSans
inputLabel.TextSize = 14
inputLabel.Parent = mainFrame

-- 图片ID输入框
local idBox = Instance.new("TextBox")
idBox.Size = UDim2.new(1, -10, 0, 25)
idBox.Position = UDim2.new(0, 5, 0, 60)
idBox.BackgroundColor3 = Color3.new(1, 1, 1)
idBox.TextColor3 = Color3.new(0, 0, 0)
idBox.PlaceholderText = "输入图片ID..."
idBox.Font = Enum.Font.SourceSans
idBox.TextSize = 14
idBox.Parent = mainFrame

-- 生成按钮
local spawnBtn = Instance.new("TextButton")
spawnBtn.Size = UDim2.new(1, -10, 0, 30)
spawnBtn.Position = UDim2.new(0, 5, 0, 95)
spawnBtn.BackgroundColor3 = Color3.fromRGB(80, 160, 80)
spawnBtn.Text = "生成图片"
spawnBtn.TextColor3 = Color3.new(1, 1, 1)
spawnBtn.Font = Enum.Font.SourceSansBold
spawnBtn.TextSize = 16
spawnBtn.Parent = mainFrame

-- 偏移滑块说明
local offsetLabel = Instance.new("TextLabel")
offsetLabel.Size = UDim2.new(1, -10, 0, 20)
offsetLabel.Position = UDim2.new(0, 5, 0, 135)
offsetLabel.BackgroundTransparency = 1
offsetLabel.Text = "前后距离 (Z): -5"
offsetLabel.TextColor3 = Color3.new(1, 1, 1)
offsetLabel.TextXAlignment = Enum.TextXAlignment.Left
offsetLabel.Font = Enum.Font.SourceSans
offsetLabel.TextSize = 12
offsetLabel.Parent = mainFrame

-- Z轴滑块容器
local zSliderFrame = Instance.new("Frame")
zSliderFrame.Size = UDim2.new(1, -10, 0, 15)
zSliderFrame.Position = UDim2.new(0, 5, 0, 158)
zSliderFrame.BackgroundColor3 = Color3.fromRGB(80, 80, 80)
zSliderFrame.Parent = mainFrame

local zSliderKnob = Instance.new("TextButton")
zSliderKnob.Size = UDim2.new(0, 20, 1, 0)
zSliderKnob.BackgroundColor3 = Color3.new(1, 1, 1)
zSliderKnob.Text = ""
zSliderKnob.Parent = zSliderFrame

-- 固定按钮
local fixBtn = Instance.new("TextButton")
fixBtn.Size = UDim2.new(1, -10, 0, 30)
fixBtn.Position = UDim2.new(0, 5, 0, 165)
fixBtn.BackgroundColor3 = Color3.fromRGB(180, 100, 40)
fixBtn.Text = "固定图片"
fixBtn.TextColor3 = Color3.new(1, 1, 1)
fixBtn.Font = Enum.Font.SourceSansBold
fixBtn.TextSize = 16
fixBtn.Parent = mainFrame

-- 滑块拖动功能
local isDragging = false
zSliderKnob.InputBegan:Connect(function(input)
    if input.UserInputType == Enum.UserInputType.MouseButton1 then
        isDragging = true
    end
end)
zSliderKnob.InputEnded:Connect(function(input)
    if input.UserInputType == Enum.UserInputType.MouseButton1 then
        isDragging = false
    end
end)
UserInputService.InputChanged:Connect(function(input)
    if isDragging and input.UserInputType == Enum.UserInputType.MouseMovement then
        local mousePos = UserInputService:GetMouseLocation()
        local sliderPos = zSliderFrame.AbsolutePosition.X
        local sliderWidth = zSliderFrame.AbsoluteSize.X
        local knobWidth = zSliderKnob.AbsoluteSize.X
        local clampPos = math.clamp(mousePos.X - sliderPos - knobWidth/2, 0, sliderWidth - knobWidth)
        zSliderKnob.Position = UDim2.new(0, clampPos, 0, 0)
        local percent = clampPos / (sliderWidth - knobWidth)
        offsetZ = -2 - percent * 13  -- 范围 -2 到 -15
        offsetLabel.Text = "前后距离 (Z): " .. math.floor(offsetZ * 10) / 10
    end
end)

-- 生成图片函数
local function createImagePart(textureId)
    if imagePart then
        imagePart:Destroy()
    end
    
    -- 创建透明方块
    imagePart = Instance.new("Part")
    imagePart.Name = "ImagePart"
    imagePart.Size = Vector3.new(5, 5, 0.2)
    imagePart.CanCollide = false
    imagePart.Anchored = true
    imagePart.Transparency = 1  -- 方块本身透明，只显示图片
    
    -- 前面表面贴图
    local decal = Instance.new("Decal")
    decal.Face = Enum.NormalId.Front
    decal.Texture = "rbxassetid://" .. textureId
    decal.Parent = imagePart
    
    -- 背面也贴图（方便从背后看到）
    local decalBack = Instance.new("Decal")
    decalBack.Face = Enum.NormalId.Back
    decalBack.Texture = "rbxassetid://" .. textureId
    decalBack.Parent = imagePart
    
    imagePart.Parent = workspace
end

-- 更新图片位置（角色前方）
local function updatePosition()
    if imagePart and not isFixed and rootPart then
        -- 根据角色的朝向计算前方偏移
        local lookDir = rootPart.CFrame.LookVector
        local rightDir = rootPart.CFrame.RightVector
        local upDir = rootPart.CFrame.UpVector
        
        imagePart.CFrame = rootPart.CFrame
            + lookDir * offsetZ          -- 前后
            + rightDir * offsetX         -- 左右
            + upDir * offsetY            -- 上下
        
        -- 让图片始终面向角色（或默认跟随世界朝向，可根据需要调整）
        -- 这里让图片面朝向角色来的方向
        imagePart.CFrame = CFrame.lookAt(imagePart.Position, rootPart.Position)
    end
end

-- 生成按钮事件
spawnBtn.MouseButton1Click:Connect(function()
    local id = idBox.Text:match("%d+")  -- 提取数字ID
    if id then
        createImagePart(id)
        isFixed = false
        fixBtn.Text = "固定图片"
    end
end)

-- 固定按钮事件
fixBtn.MouseButton1Click:Connect(function()
    if not imagePart then return end
    isFixed = not isFixed
    if isFixed then
        fixBtn.Text = "已固定 (点击解除)"
    else
        fixBtn.Text = "固定图片"
    end
end)

-- 每帧更新位置
RunService.RenderStepped:Connect(function()
    if imagePart and not isFixed then
        updatePosition()
    end
end)

-- 角色重生后重置跟随
player.CharacterAdded:Connect(function(newChar)
    character = newChar
    rootPart = newChar:WaitForChild("HumanoidRootPart")
    -- 保持旧图片部件存在，如果未固定会继续跟随新角色
end)