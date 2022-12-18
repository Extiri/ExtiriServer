import Vapor
import JWT
import Fluent

/// In Development
final class APIManager {
	let request: Request
	
	static func verify(request: Request) async throws {
		let apiManager = APIManager(request: request)
		try await apiManager.verify()
	}
	
	func verify() async throws {
		let payload = try request.jwt.verify(as: APIPayload.self)
		
		let token = try await Token.query(on: request.db)
			.filter(\.$type == .apiKey)
			.filter(\.$id == payload.token)
			.first()
		
		if token == nil {
			throw Abort(.unauthorized, reason: "Specify API key in Authorization header.")
		}
	}
	
	func delete() async throws {
		let payload = try request.jwt.verify(as: APIPayload.self)
		
		let token = try await Token.query(on: request.db)
			.filter(\.$type == .apiKey)
			.filter(\.$id == payload.token)
			.first()
		
		if token == nil {
			throw Abort(.forbidden, reason: "Specify API key in Authorization header.")
		}
	}
	
	func create(forUser user: User) async throws -> String {
		let _ = try request.jwt.verify(as: APIPayload.self)
		
		let apiKeys = try await Token.query(on: request.db)
			.filter(\.$type == .apiKey)
			.filter(\.$userID == user.id!)
			.all()
		
		if 2 < apiKeys.count {
			throw Abort(.forbidden, reason: "Account can have max. 2 API keys.")
		}
		
		let token = Token(userID: user.id!, type: .apiKey)
		
		try await token.create(on: request.db)
		
		let apiPayload = APIPayload(subject: .init(value: user.email), creation: .init(value: Date()), token: token.id!)
		
		return try request.jwt.sign(apiPayload)
	}
	
	init(request: Request) {
		self.request = request
	}
}
