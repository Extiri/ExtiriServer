import Vapor

struct PublicUser: Content {
	var id: UUID
	var name: String
	
	init(id: UUID, name: String) {
		self.id = id
		self.name = name
	}
}
