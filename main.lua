local StoryTeller = require 'StoryTeller'
local dialogue

function love.load()
    -- To keep convention, uses .st files for StoryTeller
    dialogue = StoryTeller.play("example.st", {
        enableFadeIn = true,
        enableFadeOut = true,
    })
--    Parser.printDebugInfo(dialogue.lines, dialogue.characters)

end

function love.update(dt)
    if dialogue then
        dialogue:update(dt)
    end
end

function love.draw()
    love.graphics.setColor(1, 1, 1)
    if dialogue then
        dialogue:draw()
    end
end

function love.keypressed(key)
    if key == 'space' or key == 'space' or key == 't' or key == 'y' or key == 'j' then
        if dialogue then
            dialogue:keypressed(key)
        end
    end
end

function love.mousepressed(x, y, button)
    if button == '1' or button == 1 then
        print("Mouse Pressed")
        if dialogue then
            print("Running Dialogue Function")
            dialogue:mousepressed(x, y)
        end
    end
end

