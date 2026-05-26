
--- @param category string
--- @param name string 
--- @return string
local function lookup(category, name)
    return "data.raw[" .. string.format("%q", category) .. "][" .. string.format("%q", name) .. "]"
end

--- @param recipe_name RecipeID | string
--- @param extra_error string | nil
--- @return RecipePrototype
local function get_recipe(recipe_name, extra)
    error_level = error_level or 3
    extra = extra or ''
    local recipe = data.raw.recipe[recipe_name]
    if recipe == nil then
        error(lookup('recipe', recipe_name) .. " does not exist" .. extra_error, 4)
    end
end

--- @param recipe_name TechnologyID | string
--- @param extra_error string | nil
--- @return TechnologyPrototype
local function get_technology(tech_name, extra_error)
    extra = extra or ''
    local tech = data.raw.technology[tech_name]
    if tech == nil then
        error(lookup("technology", tech_name) .. " does not exist" .. extra_error, 4)
    end
end

--- @param recipe RecipeID
--- @return ItemID | nil
local function main_product(recipe)
    -- internal function = no checks

    if type(recipe) == 'string' then
        recipe = data.raw.recipe[recipe]
    end

    if recipe.main_product then
        return recipe.main_product
    end

    if recipe.result then
        return recipe.result
    end

    if #recipe.results == 1 then
        return recipe.results[1].name
    end
end

--- @param recipe RecipeID
--- @return Order
local function ordering(recipe)
    -- internal function = no checks

    if type(recipe) == 'string' then
        recipe = data.raw.recipe[recipe]
    end

    if recipe.order then
        return recipe.order
    end

    local product = main_product(recipe)
    if not product then return nil end -- put it dead last

    local category

    for _, subtype in pairs(defines.prototypes.item) do
        if subtype[product] then
            category = subtype.name
            break 
        end
    end

    return data.raw[category][product].order
end

--- @param recipe1 RecipeID
--- @param recipe2 RecipeID
--- @return boolean
local function order_recipes(recipe1, recipe2)
    -- internal function = no checks

    local order1 = ordering(recipe1)
    local order2 = ordering(recipe2)

    if order1 == nil and order2 == nil then return true end
    if order1 == nil then return false end
    if order2 == nil then return true end

    return order1 < order2
end

--- @param to_delete { [RecipeID]: boolean }
local function remove_unlocks(to_delete)

    for _, tech in pairs(data.raw.technology) do
        if tech.effects do
        for i = #tech.effects, 1, -1 do
            -- iterate backwards because table.remove shortens the table

            if
                tech.effects[i].type == 'unlock-recipe'
                and to_delete[tech.effects[i].recipe] -- to_delete is a set
            then
                table.remove(tech.effects, i)
            end
        end
    end

end

---@param to_add { [TechnologyID]: RecipeID[] }
local function add_unlocks(to_add)
    for tech_name, recipes in pairs(to_add) do

        --- @type TechnologyPrototype
        local tech = data.raw.technology[tech_name]

        if #recipes == 0 then
            tech.enabled = true
        else
            tech.enabled = false
        end

        for _, name in ipairs(recipes) do
            table.insert(tech.effects, {
                type='unlock-recipe', recipe=name
            })
        end
    end
end

---@param to_add RecipeID[]
---@return RecipeID[], { [TechnologyID]: RecipeID[] }, RecipeID[]
local function identify_unlocks(recipe_names)

    if
        type(recipe_names) ~= "table"
        or table_size(recipe_names) ~= #recipe_names
    then
        error("argument #1 must be an array or a string", 3)
        -- this error message is for auto_unlock, below
    end

    --- @type RecipeID[]
    local to_delete = {} 
    --- @type { [TechnologyID]: RecipeID[] }
    local to_add = {}
    --- @type RecipeID[]
    local to_enable = {}

    for _, name in ipairs(recipe_names) do

        if type(name) ~= 'string' then
            error("argument #1 must be an array of strings", 3)
        end

        local the_recipe = get_recipe(name)

        if the_recipe.hidden or the_recipe.auto_unlocked_by == nil then goto skip end
        -- we don't work with hidden recipes, and ignore those without an auto_unlocked_by field

        if not ({string=true,table=true})[type(the_recipe.auto_unlocked_by)]  then
            error("data.raw.recipe['" .. name .. "'].auto_unlocked_by is not a table or string value", 3)
        end

        local the_unlocks = the_recipe.auto_unlocked_by

        if type(the_unlocks) == 'string' then

            -- check existence with a better error message than below
            get_technology(the_unlocks, " (data.raw.recipe[" .. string.format("%q", name) .. "'].auto_unlocked_by)")

            the_unlocks = { the_unlocks }
        end

        if table_size(the_unlocks) ~= #the_unlocks then
            error("data.raw.recipe['" .. name .. "'].auto_unlocked_by must be an array", 3)
        end

        if #the_unlocks == 0 then
            table.insert(to_enable, name)
        end

        for i, tech in ipairs(the_unlocks) do
            if type(tech) ~= 'string' then
                error("data.raw.recipe['" .. name .. "'].auto_unlocked_by must be an array of strings", 3)
            end

            -- check existence with a good error message
            get_technology(tech, " (data.raw.recipe['" .. name .. "'].auto_unlocked_by["..i.."])")

            to_add[tech] = to_add[tech] or {}
            table.insert(to_add[tech], name)
        end

        to_delete[name] == true

        ::skip::
    end

    for _, added in pairs(to_add) do
        table.sort(added, order_recipes)
    end

    return to_delete, to_add, to_enable
end

--- @param recipe_names RecipeID[]
local function auto_unlock(recipe_names)
    
    if type(recipe_names) == 'string' then
        recipe_names = { recipe_names }
    end

    local to_delete, to_add, to_enable = identify_unlocks(recipe_names)
    
    remove_unlocks(to_delete)

    add_unlocks(to_add)
end

return {
    auto_unlock = auto_unlock,
}