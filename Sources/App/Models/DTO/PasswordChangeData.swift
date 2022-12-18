import Vapor

struct PasswordChangeData: Content {
	var email: String
	var password: String
}
