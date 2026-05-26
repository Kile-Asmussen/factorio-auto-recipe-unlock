# Recipe Auto-unlocker

This is a utility factorio mod that allows _fully declarative_ control of which technologies unlock which recipes. It provides no content, only functionality useable to other mods.

## How to use it

This mod introduces a "fake" property to [`RecipePrototype`]:

- `auto_unlocked_by` <sub>optional</sub> :: [`TechnologyID`] or `array[` [`TechnologyID`] `]`

This functions similarly to [`FluidPrototype.auto_barrel`] as well as [`ItemPrototype.auto_recycle`] and [``RecipePrototype.auto_recycle``] in that it causes automatic behavior during the `data-updates` stage.

Simply add this mod as a dependency for your mod, add your recipe prototypes during the `data.lua` stage and on them, define a field `auto_unlocked_by` as either the name of a technology, or an array of names of technologies. You can also change existing recipes if you want to re-assign them.

**Note:** the set of recipe unlocks will be _overridden_, not simply added. If existing technologies unlock some recipe that has this field set, those unlocks will be _removed._ Use with caution.


[`TechnologyID`]: https://lua-api.factorio.com/latest/types/TechnologyID.html
[`RecipePrototype`]: https://lua-api.factorio.com/latest/prototypes/RecipePrototype.html
[`FluidPrototype.auto_barrel`]: https://lua-api.factorio.com/latest/prototypes/FluidPrototype.html#auto_barrel
[`ItemPrototype.auto_recycle`]: https://lua-api.factorio.com/latest/prototypes/ItemPrototype.html#auto_recycle
[`RecipePrototype.auto_recycle`]: https://lua-api.factorio.com/latest/prototypes/RecipePrototype.html#auto_recycle

## How to use (advanced)

If you are automatically generating recipes during the `data-updates.lua` stage, then you can still use this mod!

A utility function is provided in the module `__AutoUnlockedBy__/auto-unlock.lua`:
```lua
--- @param recipe_names RecipeID[]
function auto_unlock.auto_unlock(recipe_names) end
```

Simply add the following to your `data-updates.lua` file:

```lua
local auto_unlock = require('__AutoUnlockedBy__/auto-unlock.lua')

auto_unlock.auto_unlock(array_of_your_recipe_names)
```

(That function is the same that the mod calls, just with the list of all mods.)

## Why not in `data-final-fixes.lua` ?

Because it is a race to the bottom. Just call it yourself in `data-updates.lua` if you need it.

## How it works

The behavior of this mod is the following algorithm:

- Identify each recipe that has `auto_unlocked_by` set (ignore hidden recipes.)
- If a recipe is auto-unlocked by _no_ recipes (i.e. an empty array is given,) then set `enabled = true`.
  - The logic here is that absent an unlocking technology, a recipe cannot be used otherwise, which is silly.
  - (If you do not want this, why are you defining `auto_unlocked_by` for a recipe?)
- For each recipe with auto-unlocks, remove from all technologies any effect that unlocks it.
- For each recipe with auto-unlocks, add an appropriate `unlock-recipe` to the technologies that should unlock it
  - The recipes added to these technologies are sorted by their `order` field.

(The actual algorithm has some optimizations over this naïve approach.)

## Notes on code quality

I do not use the Lua language server VSCode extension (and by extension, the ) on principle because the default configuration is completely insane, so I'd rather raw-dog it with unit-tests and an LLM  