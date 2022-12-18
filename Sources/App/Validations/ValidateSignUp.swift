import Vapor

extension SignUpUser: Validatable {
	static func validations(_ validations: inout Validations) {
		validations.add("name", as: String.self, is: !.empty)
		validations.add("email", as: String.self, is: .email)
	}
}
