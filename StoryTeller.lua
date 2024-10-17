Parser = require 'StoryTellerParser'
local Constants = require 'StoryTellerConstants'
local TextEffects = require 'TextEffects'

local StoryTeller = {}

function StoryTeller:init(config)
    local conf = {
        lines = {},
        characters = {},
        currentLine = 1,
        isActive = false,
        font = love.graphics.newFont(config.fontSize or Constants.DEFAULT_FONT_SIZE),
        nameFont = love.graphics.newFont(config.nameFontSize or Constants.DEFAULT_NAME_FONT_SIZE),
        boxColor = config.boxColor or Constants.BOX_COLOR,
        textColor = config.textColor or Constants.TEXT_COLOR,
        nameColor = config.nameColor or Constants.NAME_COLOR,
        padding = config.padding or Constants.PADDING,
        boxHeight = config.boxHeight or Constants.BOX_HEIGHT,
        typingSpeed = config.typingSpeed or Constants.TYPING_SPEED,
        typewriterTimer = 0,
        displayedText = "",
        currentCharacter = "",
        boxOpacity = 0,
        fadeInDuration = config.fadeInDuration or Constants.FADE_IN_DURATION,
        fadeOutDuration = config.fadeOutDuration or Constants.FADE_OUT_DURATION,
        animationTimer = 0,
        state = "inactive", -- Can be "inactive", "fading_in", "active", "fading_out"
        enableFadeIn = config.enableFadeIn or true,
        enableFadeOut = config.enableFadeOut or true,
        effects = {},
        waitTimer = 0,
        autoLayoutEnabled = config.autoLayoutEnabled or true,
        subjects = {},
        subjectNumber = 0,
        currentSubject = {},
        currentSubjectBox = {},
        subjectBoxes = {},
    }
    setmetatable(conf, self)
    self.__index = self
    return conf
end

function StoryTeller:continue()
    if self.state == 'active' then
        if self.displayedText ~= self.lines[self.currentLine].text then
            self.displayedText = self.lines[self.currentLine].text
        elseif self.lines[self.currentLine].isEnd then
            self:endDialogue()
        else
            self.currentLine = self.currentLine + 1
            self:setCurrentDialogue()
        end
    elseif self.state == 'fading_in' then
        self.state = 'active'
        self.boxOpacity = 1
    end
end

function StoryTeller:complete()
    
end

function StoryTeller:loadFromFile(filePath)
    self.lines, self.characters = Parser.parseFile(filePath)
end

function StoryTeller:start()
    love.window.setFullscreen(true)
    self.isActive = true
    self.currentLine = 1
    self.state = self.enableFadeIn and "fading_in" or "active"
    self.animationTimer = 0
    self.boxOpacity = self.enableFadeIn and 0 or 1
    self:setCurrentDialogue()
end

function StoryTeller:setCurrentDialogue()
    local currentDialogue = self.lines[self.currentLine]
    if currentDialogue then
        self.currentCharacter = currentDialogue.character
        self.displayedText = ""
        self.typewriterTimer = 0
        self.effects = {}
        self.waitTimer = 0
        self.currentSubject = {}
        self.subjects = {}
        self.subjectNumber = 0
        self.subjectBoxes = {}

        if currentDialogue.subjects then
            for _, subject in ipairs(currentDialogue.subjects) do
                table.insert(self.subjects, subject)
                self.subjectNumber = self.subjectNumber + 1
            end
            self.currentSubject = table.remove(self.subjects, 1)
        end

        if currentDialogue.effects then
            for _, effect in ipairs(currentDialogue.effects) do
                table.insert(self.effects, {
                    type = effect.type,
                    content = effect.content,
                    startIndex = effect.startIndex,
                    endIndex = effect.endIndex,
                    timer = 0,
                })
            end
        end
    else
        self:endDialogue()
    end
end

function StoryTeller:endDialogue()
    self.state = self.enableFadeOut and "fading_out" or "inactive"
    self.animationTimer = 0
    if not self.enableFadeOut then
        self.isActive = false
    end
end

function StoryTeller:jumpDialogue(subjectText)
end

function StoryTeller:update(dt)
    if not self.isActive then return end

    if self.state == "fading_in" then
        self.animationTimer = self.animationTimer + dt
        self.boxOpacity = math.min(self.animationTimer / self.fadeInDuration, 1)
        if self.animationTimer >= self.fadeInDuration then
            self.state = "active"
        end
    elseif self.state == "active" then
        local currentFullText = self.lines[self.currentLine].text
        if self.displayedText ~= currentFullText then
            if self.waitTimer > 0 then
                self.waitTimer = self.waitTimer - dt
            else
                self.typewriterTimer = self.typewriterTimer + dt
                if self.typewriterTimer >= self.typingSpeed then
                    self.typewriterTimer = 0
                    local nextCharIndex = #self.displayedText + 1
                    local nextChar = string.sub(currentFullText, nextCharIndex, nextCharIndex)
                    self.displayedText = self.displayedText .. nextChar

                    -- Check for wait effect
                    for _, effect in ipairs(self.effects) do
                        if effect.type == 'wait' and effect.startIndex == nextCharIndex then
                            self.waitTimer = tonumber(effect.content) or 0
                            break
                        end
                    end
                end
            end
        end
    elseif self.state == "fading_out" then
        self.animationTimer = self.animationTimer + dt
        self.boxOpacity = 1 - math.min(self.animationTimer / self.fadeOutDuration, 1)
        if self.animationTimer >= self.fadeOutDuration then
            self.isActive = false
            self.state = "inactive"
        end
    end

    -- Update effect timers
    for _, effect in ipairs(self.effects) do
        effect.timer = effect.timer + dt
    end

    -- Auto layout adjustment
    if self.autoLayoutEnabled then
        self:adjustLayout()
    end
end

function StoryTeller:adjustLayout()
    local windowWidth, windowHeight = love.graphics.getDimensions()
    self.boxHeight = math.floor(windowHeight * 0.25)
    self.padding = math.floor(windowWidth * 0.02)
    self.font = love.graphics.newFont(math.floor(windowHeight * 0.025))
    self.nameFont = love.graphics.newFont(math.floor(windowHeight * 0.025))

    -- Adjust subjectBoxes if found in current line
    local next = next
    if next(self.currentSubjectBox) == nil then
    end
end

function StoryTeller:draw()
    if not self.isActive then return end

    local windowWidth, windowHeight = love.graphics.getDimensions()
    local boxWidth = windowWidth - 2 * self.padding

    -- Draw dialogue box
    love.graphics.setColor(self.boxColor[1], self.boxColor[2], self.boxColor[3], self.boxColor[4]*self.boxOpacity)
    love.graphics.rectangle("fill", self.padding, windowHeight - self.boxHeight - self.padding, boxWidth, self.boxHeight)

    -- Draw character name
    love.graphics.setFont(self.nameFont)
    local nameColor = self.characters[self.currentCharacter]
    love.graphics.setColor(nameColor.r, nameColor.g, nameColor.b, nameColor.boxObacity)
    love.graphics.print(self.currentCharacter, self.padding * 2, windowHeight - self.boxHeight - self.padding + 10)

    -- Reset color
    love.graphics.setColor(1, 1, 1, 1)

    -- Draw text
    love.graphics.setFont(self.font)
    local x = self.padding * 2
    local y = windowHeight - self.boxHeight + self.padding + 20
    local limit = boxWidth - self.padding * 2

    for i = 1, #self.displayedText do
        local char = self.displayedText:sub(i, i)
        local charWidth = self.font:getWidth(char)
        local charHeight = self.font:getHeight()
        local color = {unpack(self.textColor)}
        local offset = {x = 0, y = 0}
        local scale = 1

        for _, effect in ipairs(self.effects) do
            if i >= effect.startIndex and i <= effect.endIndex then
                local effectFunc = TextEffects[effect.type]
                if effectFunc then
                    local effectColor, effectOffset = effectFunc(effect, char, i, effect.timer)
                    if effectColor then color = effectColor end
                    offset.x = offset.x + effectOffset.x
                    offset.y = offset.y + effectOffset.y
                    scale = scale * (effectOffset.scale or 1)
                end
            end
        end

        -- Check for subjects in current line
        if self.subjectNumber ~= 0 then
            local next = next
            if next(self.currentSubjectBox) == nil then
                if self.currentSubject.startIndex == i then
                    local textWidth = self.font:getWidth(self.currentSubject.text)
                    local endX = x + textWidth * scale
                    local endY = y + charHeight * scale
                    if endX > limit then
                        local tempX = endX
                        local text = self.currentSubject.text
                        local textIndex = #self.currentSubject.text
                        while tempX > limit do
                            textIndex = textIndex - 1
                            text = text.sub(1, textIndex)
                            tempX = x + self.font:getWidth(text) * scale
                        end

                        -- First subject box to be inserted
                        table.insert(self.subjectBoxes, {
                            text = self.currentSubject.text,
                            startX = x,
                            startY = y,
                            endX = tempX,
                            endY = endY,
                        })

                        -- Second part of subject box to be inserted
                        local startX = self.padding * scale
                        local startY = endY
                        endX = startX + endX - tempX
                        endY = startY + charHeight * scale
                        table.insert(self.subjectBoxes, {
                            text = self.currentSubject.text,
                            startX = startX,
                            startY = startY,
                            endX = endX,
                            endY = endY,
                        })

                        -- Loading of next subject to be generated
                        self.currentSubject = table.remove(self.subjects, 1)
                        self.subjectNumber = self.subjectNumber - 1
                    else
                        table.insert(self.subjectBoxes, {
                            text = self.currentSubject.text,
                            startX = x,
                            startY = y,
                            endX = endX,
                            endY = endY,
                        })

                        self.currentSubject = table.remove(self.subjects, 1)
                        self.subjectNumber = self.subjectNumber - 1
                    end
                end
            end
        end

        love.graphics.setColor(color[1], color[2], color[3], self.boxOpacity)
        love.graphics.print(char, x + offset.x, y + offset.y, 0, scale, scale)
        x = x + charWidth * scale

        if x > limit then
            x = self.padding * 2
            y = y + charHeight * scale
        end
    end
end

function StoryTeller:printSubjectBoxes()
    if not self.isActive then return end
    print("PRINTING SUBJECT BOXES")
    for index, subjectBox in ipairs(self.subjectBoxes) do
        print("Index: "..index)
        print("Text: "..subjectBox.text)
        print("StartX: "..subjectBox.startX)
        print("StartY: "..subjectBox.startY)
        print("EndX: "..subjectBox.endX)
        print("EndY: "..subjectBox.endY)
        print("")
    end
end

function StoryTeller:mousepressed(x, y)
    if not self.isActive then return end
    print("Mouse X: "..x)
    print("Mouse Y: "..y)
    print("")
    for index, subjectBox in ipairs(self.subjectBoxes) do
        if x >= subjectBox.startX and x <= subjectBox.endX and y >= subjectBox.startY and y <= subjectBox.endY then
            print("Subject Box Pressed")
            print(index)
            print(subjectBox.text)
            print(subjectBox.startX)
            print(subjectBox.startY)
            print(subjectBox.endX)
            print(subjectBox.endY)
            print("")
        end
    end
end

function StoryTeller:keypressed(key)
    if key == 'return' or key == 'space' then
        self:continue()
    end
    if key == 't' then
        self:printSubjectBoxes()
    end
    if key == 'y' then
        print("Testing")
    end
end

function StoryTeller.play(filePath, config)
    local dialogue = StoryTeller:init(config or {})
    dialogue:loadFromFile(filePath)
    dialogue:start()
    return dialogue
end

return StoryTeller
