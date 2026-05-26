# Kashmira Qeel's Declarative Technology Effects Mod

This is a utility factorio mod that allows _fully declarative_ control of which technologies unlock which recipes, as well as other effects. It provides no content, only functionality useable to other mods.

## How to use it

This mod introduces a "fake" property to [`RecipePrototype`]:

- `auto_unlocked_by` <sub>optional</sub> :: [`TechnologyID`] or `array[` [`TechnologyID`] `]`

This functions similarly to [`FluidPrototype.auto_barrel`] as well as [`ItemPrototype.auto_recycle`] and [``RecipePrototype.auto_recycle``] in that it causes automatic behavior during the `data-updates` stage.

Add this mod as a dependency for your mod, add your recipe prototypes during the `data.lua` stage and on them, define a field `auto_unlocked_by` as either the name of a technology, or an array of names of technologies. You can also change existing recipes if you want to re-assign which technologies unlock them.

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

auto_unlock.auto_unlock(array_of_your_super_cool_recipe_names)
```

(That function is the same that the mod calls, just with the list of all mods.)

## Why not in `data-final-fixes.lua` ?

Because it is a race to the bottom. Just call it yourself in `data-updates.lua` if you need it. IME, the vast majority of mods do not need to generate recipes in `data-updates.lua`.

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

## Why make this?

For the same reason auto-barrelling and auto-recycling exists: to save time and effort on the part of mod developers.

Factorio's prototype system is specified according to ease of integration with the game engine, not cohesion or locality of behavior.

Adding a fluid prototype will make it available in the game, only to flow through pipes. The fact that fluids can be barrelled is a game mechanic implemented through recipes and items, completely unrelated to the fluid type itself. 

Imagine a world where if you wanted to be able to barrel and un-barrel a new type of fluid, you had to create all the barrelling and unbarrelling recipes and add them to fluid handling's technology effects list &mdash; that would be a worse world to mod in, even if there were utility functions provided for it.

Adding an item or recipe prototype will make it available in the game, to be manipulated and crafted. The fact that items additionally can be recycled is a game mechanic implemented through separate recipes, completely unrelated to the items and recipes that are recycled.

Imagine a world where you had to create all the recycling recipes for your items and recipes &mdash; that would be a worse world to mod in, even if there were utility functions provided for it.

This mod takes the same stance: a world wherein we have to keep track of which technologies unlock which recipes, is one where we as fallible human beings are prone to make mistakes. Especially if you want to move around existing recipes in the technology tree.

## Future work

Similar reasoning can be applied to other technology modifiers:

- `ammo-damage` and `gun-speed`: an ammo category ought to specify which technologies increases its shooting speed. An `auto_upgraded_by` field, perhaps.

- `give-item`: an item ought to specify which technologies gives it to the player. An `auto_given_by` field, perhaps.

- `turret-attack`: a turret ought to specify which technologies increases its damage output via the `turret-attack` modifier. Same semantics as `auto_upgraded_by`.

- `unlock-space-location`: a space location ought to specify which technologies unlock it.

Those are to my knowledge, the only other technology modifiers that have an ID of some other prototype associated with them. However, a general utility function could very well be provided that could be used to manipulate the remaining modifiers, perhaps something like:

```lua
local auto_unlock = require('__AutoUnlockedBy__/auto-unlock.lua')

auto_unlock.add_numeric_modifier('character-crafting-speed', {
  ['my-super-cool-character-crafting-speed-technology-1'] = 0.5, 
  ['my-super-cool-character-crafting-speed-technology-2'] = 1.0,
  ['my-super-cool-character-crafting-speed-technology-3'] = 1.5,
})

auto_unlock.add_boolean_modifier('create-ghost-on-entity-death', {
  'my_super-cool-earlygame-robots-technology'
})

-- make steel pickaxe useless, hah!
auto_unlock.remove_modifiers('character-mining-speed')

auto_unlock.add_nothing_modifier({
  { 'modifier-description.my-scripted-modifier' }
})
```