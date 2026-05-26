
local auto_unlock = require 'auto-unlock'

local all_recipes = {}

for name, _ in pairs(data.raw.recipe) do
    table.insert(all_recipes, name)
end

auto_unlock.auto_unlock_recipes(all_recipes)