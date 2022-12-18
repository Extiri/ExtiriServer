import Vapor
import Fluent

struct UsersController: RouteCollection {
	func boot(routes: RoutesBuilder) throws {
		routes.group("api", "1", "users") { users in
			users.get("get", ":id", use: getUser)
			users.post("signup", use: signIn)
			users.post("login", use: logIn)
			users.get("confirm", ":token", use: confirmWebsite)
			users.delete("delete", use: delete)
			users.get("valid", use: isValid)
			users.get("logout", use: logOut)
			users.get("me", use: aboutAccount)
			users.get("password", "request", use: requestPasswordChange)
			users.get("password", "page", ":token", use: showPasswordChangePage)
			users.post("password", "change", ":token", use: changePassword)
		}
	}
	
	func isValid(req: Request) async throws -> HTTPStatus {
		let tokensManager = TokensManager(request: req)
		let token = try await tokensManager.extractToken()
		
		do {
			try await tokensManager.isValidSessionToken(token.uuidString)
			return .ok
		} catch {
			return .unauthorized
		}
	}
	
	func delete(req: Request) async throws -> HTTPStatus {
		let accountsManager = AccountsManager(request: req)
		let login = try accountsManager.getLoginUser()
		let tokensManager = TokensManager(request: req)
		let _ = try await tokensManager.login(loginUser: LoginUser(email: login.email, password: login.password))
		
		let user = try await User.query(on: req.db)
			.filter(\.$email == login.email)
			.first()!
		
		let mailManager = MailManager(to: user.email, request: req)
		
		let body = """
  Hello \(user.name),
  
  Your account will be deleted within 30 days.
  I'm sad that you are leaving us. You can still
  recover your account by logging in your account.
  """
		
		try await req.queue.dispatch(
			AccountDeletionJob.self,
			user,
			maxRetryCount: 5,
			delayUntil: Lifetimes.getDate(for: Lifetimes.accountDeletionTime)
		)
		
		let error = await mailManager.send(subject: "Your account has been deleted - Extiri", body: body)
		
		if let error = error {
			req.logger.report(error: error)
		}
		
		try await user.delete(on: req.db)
		
		return .ok
	}
	
	func confirmWebsite(req: Request) async throws -> View {
		let token = req.parameters.get("token")!
		let tokensManager = TokensManager(request: req)
		let user = try await tokensManager.getUser(forToken: token)
		
		user.confirmed = true
		
		try await user.update(on: req.db)
		
		return try await req.view.render("confirmation", ["email": user.email])
	}
	
	func changePassword(req: Request) async throws -> View {
		let token = req.parameters.get("token")!
		let tokensManager = TokensManager(request: req)
		
		try await tokensManager.isNotExpired(token, ofType: .passwordChange)
		
		guard let tokenID = UUID(uuidString: token) else {
			throw Abort(.badRequest, reason: "Token is invalid.")
		}
		
		let tokenModel = try await Token.query(on: req.db)
			.filter(\.$id == tokenID)
			.first()
		
		guard let tokenModel = tokenModel else {
			throw Abort(.badRequest, reason: "Token is invalid.")
		}

		let user = try await User.query(on: req.db)
			.filter(\.$id == tokenModel.userID)
			.first()
		
		guard let user = user else {
			throw Abort(.badRequest, reason: "Token is invalid.")
		}
		
		let passwordChangeData = try req.content.decode(PasswordChangeData.self)
		
		guard passwordChangeData.email == user.email else {
			throw Abort(.unauthorized, reason: "Token is invalid.")
		}
		
		try user.changePassword(password: passwordChangeData.password)
		
		let mailManager = MailManager(to: user.email, request: req)
		
		let body = """
Hello \(user.name),
  
Your password has been succesfully changed.
"""
		
		let error = await mailManager.send(subject: "Password change - Extiri", body: body)
		
		if let error = error {
			req.logger.report(error: error)
			throw Abort(.internalServerError, reason: "Failed to send a password change notification mail due to a server error. Try signing up later.")
		}
		
		try await user.save(on: req.db)
		try await tokenModel.delete(on: req.db)
		
		return try await req.view.render("passwordChangeConfirmation", ["email": user.email])
	}
	
	func showPasswordChangePage(req: Request) async throws -> View {
		let token = req.parameters.get("token")!
		let tokensManager = TokensManager(request: req)
		
		try await tokensManager.isNotExpired(token, ofType: .passwordChangeRequest)
		
		guard let tokenID = UUID(uuidString: token) else {
			throw Abort(.badRequest, reason: "Token has invalid format.")
		}
		
		let requestToken = try await Token.query(on: req.db)
			.filter(\.$id == tokenID)
			.first()
		
		guard let requestToken = requestToken else {
			throw Abort(.badRequest, reason: "Token doesn't exist.")
		}
		
		let user = try await User.query(on: req.db)
			.filter(\.$id == requestToken.userID)
			.first()
		
		guard let user = user else {
			throw Abort(.badRequest, reason: "Token has invalid user assigned.")
		}
		
		try await requestToken.delete(on: req.db)
		
		let changeToken = Token(userID: user.id!, type: .passwordChange)
		
		try await changeToken.create(on: req.db)
		
		try await req.queue.dispatch(
			TokenDeletionJob.self,
			changeToken,
			maxRetryCount: 5,
			delayUntil: Lifetimes.getDate(for: Lifetimes.passwordChangeTime)
		)
	
		return try await req.view.render("passwordChange", ["token": changeToken.id?.uuidString ?? ""])
	}
	
	func requestPasswordChange(req: Request) async throws -> HTTPStatus {
		let accountsManager = AccountsManager(request: req)
		let login = try accountsManager.getLoginUser()
		let user = try await accountsManager.getForCredentials(user: LoginUser(email: login.email, password: login.password))
		
		guard let userID = user.id else {
			throw Abort(.internalServerError, reason: "User doesn't have ID.")
		}
		
		let token = Token(userID: userID, type: .passwordChangeRequest)
		
		try await token.create(on: req.db)
		
		let link = "\(EnvironmentVariables.server.domain)api/1/users/password/page/\(token.id!)"
		
		let mailManager = MailManager(to: user.email, request: req)
		
		let body = """
Hello \(user.name),
  
You requested a password change of your account. Go to this link to finish changing your password:

\(link)

The link will expire within 24 hours.

If it is not you who requested the password change, change the password yourself.
"""
		
		let error = await mailManager.send(subject: "Password change request - Extiri", body: body)
		
		if let error = error {
			req.logger.report(error: error)
			throw Abort(.internalServerError, reason: "Failed to send a request mail due to a server error. Try signing up later.")
		}
		
		try await req.queue.dispatch(
			TokenDeletionJob.self,
			token,
			maxRetryCount: 5,
			delayUntil: Lifetimes.getDate(for: Lifetimes.passwordChangeTime)
		)
		
		return HTTPStatus.ok
	}
	
	func signIn(req: Request) async throws -> String {
		try SignUpUser.validate(content: req)
		let userDefinition = try req.content.decode(SignUpUser.self)
		
		if !userDefinition.email.contains("@") {
			throw Abort(.badRequest, reason: "Email is invalid.")
		}
		
		if userDefinition.password.count > 100 || userDefinition.name.count > 100 || userDefinition.email.count > 100 {
			throw Abort(.badRequest, reason: "Password, username and email must not be longer than 100 characters.")
		}
		
		let newUser = try User(name: userDefinition.name, email: userDefinition.email, password: userDefinition.password)
		
		let lowercaseLetters = "qwertyuiopasdfghjklzxcvbnm"
		let uppercaseLetters = "QWERTYUIOPASDFGHJKLZXCVBNM"
		
		var hasLowercaseCharacter = false
		var hasUppercaseCharacter = false

		for character in userDefinition.password {
			if lowercaseLetters.contains(character) {
				hasLowercaseCharacter = true
			}
			
			if uppercaseLetters.contains(character) {
				hasUppercaseCharacter = true
			}
			
			if hasUppercaseCharacter && hasLowercaseCharacter {
				break
			}
		}
		
		if userDefinition.password.count < 8 || userDefinition.password == userDefinition.email || userDefinition.password == userDefinition.name || !hasLowercaseCharacter || !hasUppercaseCharacter {
			throw Abort(.badRequest, reason: "Password must be at least 8 characters long, contain at least 1 lowercase character, 1 uppercase character, 1 digit and must not be equal to either your email or username.")
		}
		 
		let users = try await User.query(on: req.db)
			.filter(\.$email == newUser.email)
			.all()
		
		if !users.isEmpty {
			throw Abort(.badRequest, reason: "User with this e-mail already exists.")
		} else {
			try await newUser.create(on: req.db)
		}
		
		let token = Token(userID: newUser.id!, type: .confirmation)
		
		try await token.create(on: req.db)
		
		let link = "\(EnvironmentVariables.server.domain)api/1/users/confirm/\(token.id!)"
		
		let mailManager = MailManager(to: newUser.email, request: req)
		
		let body = """
Hello \(newUser.name),
  
Your account in Extiri has been succesfully created.
You now need to confirm this e-mail address. To do this, click
the link below:

\(link)

If you don't confirm this e-mail within 24 hours, your account
will be deleted.

Enjoy Extiri's products!
"""
		
		try await req.queue.dispatch(
			AccountDeletionJob.self,
			newUser,
			maxRetryCount: 5,
			delayUntil: Lifetimes.getDate(for: Lifetimes.confirmationTime)
		)
		
		let error = await mailManager.send(subject: "Account created - Extiri", body: body)
		
		if let error = error {
			req.logger.report(error: error)
			throw Abort(.internalServerError, reason: "Failed to send a confirmation mail due to a server error. Try signing up later.")
		}
		
		return "Account has been succesfully registered. You will need to confirm it using link in e-mail sent to you. If you don't see it, check Spam folder."
	}
	
	func getUser(req: Request) async throws -> PublicUser {
		guard let id = UUID(uuidString: req.parameters.get("id")!) else {
			throw Abort(.badRequest, reason: "ID is not a valid UUID.")
		}
		
		let user = try await User.query(on: req.db)
			.filter(\.$id == id)
			.first()
		
		if let user = user {
			return PublicUser(id: user.id!, name: user.name)
		} else {
			throw Abort(.notFound)
		}
	}
	
	func logIn(req: Request) async throws -> TokenRepresentable {
		let accountsManager = AccountsManager(request: req)
		let login = try accountsManager.getLoginUser()
		let tokensManager = TokensManager(request: req)
		let id = try await tokensManager.login(loginUser: LoginUser(email: login.email, password: login.password))
		
		return TokenRepresentable(id: id)
	}
	
	func logOut(req: Request) async throws -> HTTPStatus {
		let tokensManager = TokensManager(request: req)
		let tokenUUID = try await tokensManager.extractToken()
		try await tokensManager.isValidSessionToken(tokenUUID.uuidString)
				
		let token = try await Token.query(on: req.db)
			.filter(\.$id == tokenUUID)
			.first()
		
		if let token = token {
			try await token.delete(on: req.db)
			return .ok
		} else {
			return .internalServerError
		}
	}
	
	func aboutAccount(req: Request) async throws -> InfoUser {
		let tokensManager = TokensManager(request: req)
		
		try await tokensManager.authorize()
		
		let user = try await tokensManager.getUser()
		
		guard let userID = user.id else {
			throw Abort(.internalServerError, reason: "User doesn't have ID.")
		}
		
		let infoUser = InfoUser(id: userID, name: user.name, email: user.email)
		
		return infoUser
	}
}
