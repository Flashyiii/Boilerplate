local ExampleServiceServer = {}

function ExampleServiceServer.init(self: ExampleServiceServer)
	print("ExampleServiceServer initialized")
end

export type ExampleServiceServer = typeof(ExampleServiceServer) & {}

return ExampleServiceServer
