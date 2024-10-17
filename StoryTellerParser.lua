local Parser = {}

local function loadLuaFile(filePath)
    local chunk, err = loadfile(filePath)
    if not chunk then
        print("Error loading file:", err)
        return nil
    end
    return chunk()
end

local function parseTextWithTags(text)
    local parsedText = ""
    local effectsStack = {}
    local openEffects = {}
    local currentIndex = 1

    while currentIndex <= #text do
        local startTag, endTag, tag, content = text:find("{([^:}]+):([^}]*)}", currentIndex)
        local closingStartTag, closingEndTag, closingTag = text:find("{/([^}]+)}", currentIndex)

        if not startTag and not closingStartTag then
            -- No more tags found, add the rest of the text
            parsedText = parsedText .. text:sub(currentIndex)
            break
        end

        -- If we find a closing tag before an opening tag, we should handle it first
        if closingStartTag and (not startTag or closingStartTag < startTag) then
            -- Add text before the closing tag
            parsedText = parsedText .. text:sub(currentIndex, closingStartTag - 1)

            -- Close the most recent effect that matches the closing tag
            local effect
            for i = #openEffects, 1, -1 do
                if openEffects[i].type == closingTag then
                    effect = table.remove(openEffects, i)
                    break
                end
            end

            if effect then
                effect.endIndex = #parsedText
                table.insert(effectsStack, effect)
            end

            -- Move index past the closing tag
            currentIndex = closingEndTag + 1
        else
            -- Add text before the opening tag
            parsedText = parsedText .. text:sub(currentIndex, startTag - 1)

            -- Push the opening tag to the stack 
            table.insert(openEffects, {type = tag, content = content, startIndex = #parsedText + 1})

            -- Move index past the opening tag
            currentIndex = endTag + 1
        end
    end

    -- Close remaining open tags
    for _, effect in ipairs(openEffects) do
        effect.endIndex = #parsedText
        table.insert(effectsStack, effect)
    end

    return parsedText, effectsStack
end

function Parser.parseFile(filePath)
    local lines = {}
    local characters = {}
    local currentLine = 1

    for line in love.filesystem.lines(filePath) do
        local character, text = line:match("^(%S+):%s*(.+)$")
        local parsedLine = {character = character, text = "", effects = {}}

        if character and text then
            -- Find any subjects in the line indicated with enclosed brackets
            for w in text:gmatch("%[(.-)%]") do
                if not parsedLine.subjects then
                    parsedLine.subjects = {}
                end

                text = text:gsub("%b[]", function (s)
                    return s:match("%[(.-)%]")
                end)

                local parsedSubjectText, subjectEffects = parseTextWithTags(w)

                local subject = {
                    text = parsedSubjectText,
                    effects = subjectEffects,
                }

                table.insert(parsedLine.subjects, subject)
            end

            parsedLine.text, parsedLine.effects = parseTextWithTags(text)

            -- Find indexes for subjects if they exist 
            if parsedLine.subjects then
                for index, subject in ipairs(parsedLine.subjects) do
                    local startIndex, endIndex = string.find(parsedLine.text, subject.text)
                    parsedLine.subjects[index].startIndex = startIndex
                    parsedLine.subjects[index].endIndex = endIndex
                end
            end

            lines[currentLine] = parsedLine

            if not characters[character] then
                characters[character] = {r = love.math.random(), g = love.math.random(), b = love.math.random()}
            end

            currentLine = currentLine + 1
        end
    end

    return lines, characters
end

function Parser.printDebugInfo(lines, characters)
    print("Parsed Lines:")
    for i, line in ipairs(lines) do
        print(string.format("Line %d:", i))
        print(string.format("  Character: %s", line.character))
        print(string.format("  Text: %s", line.text))
        print(string.format("  Is End: %s", tostring(line.isEnd)))

        print("  Effects:")
        for _, effect in ipairs(line.effects) do
            print(string.format("    Type: %s", effect.type))
            print(string.format("    Content: %s", effect.content))
            print(string.format("    Start Index: %d", effect.startIndex))
            print(string.format("    End Index: %d", effect.endIndex))
        end

        if line.subjects then
            for subjectsIndex, subject in ipairs(line.subjects) do
                print("    Subjects:")
                -- Check and print all subjects 
                print(string.format("      SubjectID: %s", subjectsIndex))
                print(string.format("      Text: %s", subject.text))
                print(string.format("      Start Index: %s", subject.startIndex))
                print(string.format("      End Index: %s", subject.endIndex))
                -- Check and print subject effects
                if subject.effects then
                    print("      Effects:")
                    for _, effect in ipairs(subject.effects) do
                        print(string.format("         Type: %s", effect.type))
                        print(string.format("         Content: %s", effect.content))
                        print(string.format("         Start Index: %d", effect.startIndex))
                        print(string.format("         End Index: %d", effect.endIndex))
                    end
                end
            end
        end
    end

    print("Characters:")
    for character, color in pairs(characters) do
        print(string.format("  Character: %s", character))
        print(string.format("    Color: R=%f, G=%f, B=%f", color.r, color.g, color.b))
    end
end

return Parser
