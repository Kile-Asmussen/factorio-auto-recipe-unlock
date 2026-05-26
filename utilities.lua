
local function auto_unlock(...)

    local args = { ... }

    if #args > 1 then error("too many arguments, expected up to 1", 2) end
    
    if #args == 1 and type(args) ~= 'table' then
        error("optional argument #1 must be a table, if present", 2)
    end

    if table_size(args[1]) ~= #(args[1]) then
        error("argument #1 must be a linear array, not an associative array")
    end

    local recipe_names = args[1]

    local to_delete = {}

    if type(recipe_names) == 'table' then
        for _, name in ipairs(recipe_names) do

            if not data.raw.recipe[name] then
                error("recipe " .. name .. " not found", 2)
            end

            if not {string=true,table=true}[type(data.raw.recipe[name].auto_unlocked_by)]  then
                error()
            end

            to_delete[name] == true
        end
    else

    end
    
end

return { auto_unlock = auto_unlock }