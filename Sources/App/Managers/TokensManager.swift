import Vapor
import Fluent

func waitRandomTime() {
  // Wait a random time, so attacker will have harder time cracking user's email using bruteforce.
  sleep(UInt32.random(in: 1...2))
  // Make it more efficient, so server won't be so prone DDOS.
}

/// TokensManager is responosible for actions on tokens.
final class TokensManager {
  static let WONG_CREDENTIALS_ERROR_MESSAGE = "Email or password is invalid."
  
  let request: Request
  
  var db: Database {
    request.db
  }
  
  var logger: Logger {
    request.logger
  }
  
  /// Checks if user credentials are valid and creates a session token which is returned.
  func login(loginUser: LoginUser) async throws -> UUID {
    let user = try await User.query(on: db)
      .withDeleted()
      .filter(\.$email == loginUser.email)
      .first()
    
    guard let user = user else {
      waitRandomTime()
      throw Abort(.unauthorized, reason: TokensManager.WONG_CREDENTIALS_ERROR_MESSAGE)
    }
    
    if !(try user.check(loginUser.password)) {
      let mailManager = MailManager(to: user.email, request: request)
      
      let body = """
Hello \(user.name),

Your account has been used to unsuccesfully login on Extiri.
If it's not you, change your password.
"""
      
      let error = await mailManager.send(subject: "New login from  your accout - Extiri", body: body)
      
      if let error = error {
        logger.report(error: error)
      }
      
      waitRandomTime()
      throw Abort(.unauthorized, reason: TokensManager.WONG_CREDENTIALS_ERROR_MESSAGE)
    }
    
    if Date().timeIntervalSince(user.creationDate!) > Lifetimes.confirmationTime && !user.confirmed {
      throw Abort(.unauthorized, reason: "Time for confirmation has passed. This account will be soon deleted.")
    }
    
    if !user.confirmed {
      throw Abort(.unauthorized, reason: "This account has not beed confirmed yet.")
    }
    
    /// Check if user's account was deleted so it can be recovered if it was deleted.
    if user.deletionDate != nil {
      try await user.restore(on: db)
      
      let mailManager = MailManager(to: user.email, request: request)
      
      let body = """
Hello \(user.name),

Your account has been used to succesfully login on Extiri.
If it's not you, change your password.

Your account has been restored by logging in.
"""
      
      let error = await mailManager.send(subject: "Your account has been recovered - Extiri", body: body)
      
      if let error = error {
        logger.report(error: error)
      }
    } else {
      let mailManager = MailManager(to: user.email, request: request)
      
      let body = """
Hello \(user.name),

Your account has been used to succesfully login on Extiri.
If it's not you, change your password.
"""
      
      let error = await mailManager.send(subject: "New login from  your accout - Extiri", body: body)
      
      if let error = error {
        logger.report(error: error)
      }
    }
    
    let token = Token(userID: user.id!, type: .session)
    
    try await token.create(on: db)
    
    try await request.queue.dispatch(
      TokenDeletionJob.self,
      token.id ?? UUID(),
      maxRetryCount: 5,
      delayUntil: Lifetimes.getDate(for: Lifetimes.tokenLifetime)
    )
    
    return token.id!
  }
  
  /// Checks if user credentials are valid.
  func check(user loginUser: LoginUser) async throws {
    let user = try await User.query(on: db)
      .withDeleted()
      .filter(\.$email == loginUser.email)
      .first()
    
    guard let user = user else {
      waitRandomTime()
      throw Abort(.unauthorized, reason: TokensManager.WONG_CREDENTIALS_ERROR_MESSAGE)
    }
    
    if try user.check(loginUser.password) {
      if Date().timeIntervalSince(user.creationDate!) > Lifetimes.confirmationTime && !user.confirmed {
        throw Abort(.unauthorized, reason: "Time for confirmation has passed. This account will be soon deleted.")
      }
      
      if !user.confirmed {
        throw Abort(.unauthorized, reason: "This account has not beed confirmed yet.")
      }
    } else {
      waitRandomTime()
      throw Abort(.unauthorized, reason: TokensManager.WONG_CREDENTIALS_ERROR_MESSAGE)
    }
  }
  
  /// Extracts a Bearer token from token and checks if its in a valid format.
  func extractToken() async throws -> UUID {
    guard let bearer = request.headers.bearerAuthorization else {
      throw Abort(.unauthorized, reason: "A Bearer Authorization HTTP header with token is required.")
    }
    
    if let uuid = UUID(uuidString: bearer.token) {
      return uuid
    } else {
      throw Abort(.badRequest, reason: "Token is invalid.")
    }
  }
  
  /// Checks if token is valid (not expired, non-existent, not a session token).
  func isValidSessionToken(_ token: String) async throws {
    guard let id = UUID(uuidString: token) else {
      waitRandomTime()
      throw Abort(.unauthorized, reason: TokensManager.WONG_CREDENTIALS_ERROR_MESSAGE)
    }
    
    let token = try await Token.query(on: db)
      .filter(\.$id == id)
      .first()
    
    guard let token = token else {
      waitRandomTime()
      throw Abort(.unauthorized, reason: TokensManager.WONG_CREDENTIALS_ERROR_MESSAGE)
    }
    
    let user = try await User.query(on: db)
      .filter(\.$id == token.userID)
      .first()
    
    if user == nil {
      waitRandomTime()
      throw Abort(.unauthorized, reason: TokensManager.WONG_CREDENTIALS_ERROR_MESSAGE)
    }
    
    if Lifetimes.hasTimePassed(for: token.creationDate!, with: Lifetimes.tokenLifetime) {
      if token.type != .session {
        waitRandomTime()
        throw Abort(.unauthorized, reason: TokensManager.WONG_CREDENTIALS_ERROR_MESSAGE)
      }
    } else {
      try await token.delete(on: db)
      waitRandomTime()
      throw Abort(.unauthorized, reason: TokensManager.WONG_CREDENTIALS_ERROR_MESSAGE)
    }
  }
  
  /// Checks whether a token is valid (whether it exists, is properly formated, has specified type) and not expired.
  func isNotExpired(_ token: String, ofType type: Token.TokenType) async throws {
    guard let id = UUID(uuidString: token) else {
      throw Abort(.badRequest, reason: "Token has invalid format.")
    }
    
    let token = try await Token.query(on: db)
      .filter(\.$id == id)
      .first()
    
    guard let token = token else {
      throw Abort(.badRequest, reason: "Token doesn't exist.")
    }
    
    guard token.type == type else {
      throw Abort(.badRequest, reason: "Token has invalid type.")
    }
    
    let lifetime: Double
    switch type {
    case .passwordChange: lifetime = Lifetimes.passwordChangeTime
    case .session: lifetime = Lifetimes.tokenLifetime
    case .confirmation: lifetime = Lifetimes.confirmationTime
    case .passwordChangeRequest: lifetime = Lifetimes.passwordChangeTime
    default: throw Abort(.internalServerError, reason: "Invalid token provided.")
    }
    
    if Lifetimes.hasTimePassed(for: token.creationDate!, with: lifetime) {
      try await token.delete(on: db)
      throw Abort(.badRequest, reason: "Token expired.")
    }
  }
  
  /// Extracts user login data from request when authorized using Bearer header.
  func getUser(forToken token: String? = nil) async throws -> User {
    var id: UUID! = nil
    
    if let token = token {
      if let uuid = UUID(uuidString: token) {
        id = uuid
      } else {
        throw Abort(.badRequest, reason: "Token is invalid.")
      }
    } else {
      guard let bearer = request.headers.bearerAuthorization else {
        throw Abort(.unauthorized, reason: "A Bearer Authorization HTTP header with token is required.")
      }
      
      if let uuid = UUID(uuidString: bearer.token) {
        id = uuid
      } else {
        throw Abort(.badRequest, reason: "Token is invalid.")
      }
    }
    
    let token = try await Token.query(on: db)
      .filter(\.$id == id)
      .first()
    
    if let token = token {
      let user = try await User.find(token.userID, on: db)
      
      if let user = user {
        return user
      } else {
        logger.error("There is no user for token.")
        throw Abort(.internalServerError, reason: "Internal server error.")
      }
    } else {
      throw Abort(.notFound, reason: "Token not found.")
    }
  }
  
  init(req: Request) {
    self.request = request
  }
}
