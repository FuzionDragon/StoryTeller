local sqlite3 = require "lsqlite3"
local characterChecker = 'SELECT character IF EXISTS, '
local wordChecker = ""

local db = assert(sqlite3.open('data/dialogue.db'), "Database not found")

db:exec[[
]]

for row in db:nrows("SELECT * FROM test3") do
    print(row.id, row.content, row.path)
end
