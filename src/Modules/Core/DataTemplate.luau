local dataTemplate = {

	Group = "Guest", -- Used for admin Permissions!
	Information = {
		FirstJoined = 0,
		LastJoined = 0,
		TimesSeen = 0,
		PlayTime = 0,
	},

	Skills = {
		Mining = 1,
		Foraging = 1,
		Combat = 1,
	}
}

export type DataTemplate = typeof(dataTemplate)

return dataTemplate
