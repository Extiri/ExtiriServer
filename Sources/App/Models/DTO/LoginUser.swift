import Vapor

struct LoginUser: Content {
	var email: String
	var password: String
	
	init(email: String, password: String) {
		self.email = email
		self.password = password
	}
}
