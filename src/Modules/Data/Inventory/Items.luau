local ReplicatedStorage = game:GetService("ReplicatedStorage")

return {
	["ArrowT1"] = {
		["Name"] = "Mystical Arrow",
		["Description"] = "This arrow looks kinda dirty... maybe it has some magic to it?",
		["Model"] = ReplicatedStorage.Assets.Items:FindFirstChild("ArrowT1"),
		["Moveset"] = "Arrow",
		["Rarity"] = "Common",
		["Tier"] = 1, --E Tier is Required to use and trade.

		["MaxStack"] = 1, --Max amount of items that can be stacked in the same slot.
		["MaxAmount"] = 3, --Max amount of Stacks that can be in the inventory.
		["MaxAmountOf"] = { "ArrowT1", "ArrowT2", "ArrowT3" }, -- Items that are considered the same item.
	},

	["ArrowT2"] = {
		["Name"] = "Mystical Arrow",
		["Description"] = "This arrow looks kinda dirty... maybe it has some magic to it?",
		["Model"] = ReplicatedStorage.Assets.Items:FindFirstChild("ArrowT1"),
		["Moveset"] = "Arrow",
		["Rarity"] = "Rare",
		["Tier"] = 2, --D Tier

		["MaxStack"] = 1,
		["MaxAmount"] = 3,
		["MaxAmountOf"] = { "ArrowT1", "ArrowT2", "ArrowT3" },
	},

	["ArrowT3"] = {
		["Name"] = "Mystical Arrow",
		["Description"] = "This arrow looks kinda dirty... maybe it has some magic to it?",
		["Model"] = ReplicatedStorage.Assets.Items:FindFirstChild("ArrowT1"),
		["Moveset"] = "Arrow",
		["Rarity"] = "Epic",
		["Tier"] = 3, --B Tier

		["MaxStack"] = 1,
		["MaxAmount"] = 3,
		["MaxAmountOf"] = { "ArrowT1", "ArrowT2", "ArrowT3" },
	},

	["Anubis"] = {
		["Name"] = "Anubis",
		["Description"] = "Hold up.. This sword looks kinda cool",
		["Model"] = ReplicatedStorage.Assets.Items:FindFirstChild("Anubis"),
		["Moveset"] = "Anubis",
		["Rarity"] = "Legendary",
		["Tier"] = 4, --A Tier

		["MaxStack"] = 1,
		["MaxAmount"] = 1,
		["MaxAmountOf"] = { "Anubis" },
	},

	["HealthPotion"] = {
		["Name"] = "Health Potion",
		["Description"] = "This potion will restore your health",
		["Model"] = ReplicatedStorage.Assets.Items:FindFirstChild("HealthPotion"),
		["Moveset"] = "Potion",
		["Rarity"] = "Common",
		["Tier"] = 1,

		["MaxStack"] = 10,
		["MaxAmount"] = 1,
		["MaxAmountOf"] = { "HealthPotion" },

		["Effect"] = function(character: Model)
			print("Health Potion Effect")
		end,
	},
}
