import Vapor
import Fluent

final class Token: Model, Codable {
	enum TokenType: String, Codable {
		case confirmation
		case session
		case apiKey
		case passwordChange
		case passwordChangeRequest
	}
	
	static let schema = "tokens"
	
	@ID(key: .id)
	var id: UUID?
	
	@Field(key: "user_id")
	var userID: UUID
	
	@Timestamp(key: "creation_date", on: .create)
	var creationDate: Date?
	
	@Field(key: "type")
	var type: TokenType
	
	init() { }
	
	init(userID: UUID, type: TokenType) {
		self.userID = userID
		self.type = type
	}
}
