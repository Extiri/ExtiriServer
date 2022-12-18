import Vapor

final class TokenRepresentable: Content {
	var token: UUID
	
	init(id: UUID) {
		self.token = id
	}
}
