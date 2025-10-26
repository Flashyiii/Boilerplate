local dataTemplate = {

	Group = "Guest", -- Used for admin Permissions!
	Information = {
		FirstJoined = 0,
		LastJoined = 0,
		TimesSeen = 1,
		PlayTime = 0,
	},
}

export type DataTemplate = typeof(dataTemplate)

return dataTemplate
