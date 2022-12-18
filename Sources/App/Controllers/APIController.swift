import Vapor
import Fluent

/// In Development
struct APIController: RouteCollection {
	func boot(routes: RoutesBuilder) throws {
		routes.group("api", "1", "manage") { api in
			api.get("request", ":token", use: requestKey)
			api.delete("delete", ":token", use: deleteKey)
		}
	}
	
	func deleteKey(req: Request) async throws -> HTTPStatus {
		let tokensManager = TokensManager(request: req)
		try await tokensManager.authorize()
		let apiManager = APIManager(request: req)
		try await apiManager.delete()
		return .ok
	}
	
	func requestKey(req: Request) async throws -> [String: String] {
		let tokensManager = TokensManager(request: req)
		
		try await tokensManager.authorize()
		
		let user = try await tokensManager.getUser()
		let apiManager = APIManager(request: req)
		let apiKey = try await apiManager.create(forUser: user)
		
		return [
			"key": apiKey
		]
	}
}
