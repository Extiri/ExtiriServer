import Foundation
import Vapor
import Fluent

/// AccountsManager is responsible for managing accounts.
final class AccountsManager {
  let application: Application
  let request: Request?
  
  var db: Database {
    application.db
  }
  
  var logger: Logger {
    application.logger
  }
  
  /// Extracts user login credentials from the Basic header.
  func getLoginUser() throws -> LoginUser {
    guard let request = request else {
      logger.error("Request is nil and function using it is being run in AccountsManager.")
      throw Abort(.internalServerError, reason: "Server is experiencing an error.")
    }
    
    
    guard let basic = request.headers.basicAuthorization else {
      throw Abort(.unauthorized, reason: "A Basic Authorization HTTP header with email and plain-text password concatenated using : (e.g. email:password) encoded using Base-64 is required.")
    }
    
    return LoginUser(email: basic.username, password: basic.password)
  }
  
  
  func getForCredentials(user loginUser: LoginUser) async throws -> User {
    let user = try await User.query(on: db)
      .withDeleted()
      .filter(\.$email == loginUser.email)
      .first()
    
    guard let user = user else {
      waitRandomTime()
      throw Abort(.unauthorized, reason: TokensManager.WONG_CREDENTIALS_ERROR_MESSAGE)
    }
    
    if try user.check(loginUser.password) {
      if Lifetimes.hasTimePassed(for: user.creationDate!, with: Lifetimes.confirmationTime) && !user.confirmed {
        throw Abort(.unauthorized, reason: "Time for confirmation has passed. This account will be soon deleted.")
      }
      
      if !user.confirmed {
        throw Abort(.unauthorized, reason: "This account has not beed confirmed yet.")
      }
    } else {
      waitRandomTime()
      throw Abort(.unauthorized, reason: TokensManager.WONG_CREDENTIALS_ERROR_MESSAGE)
    }
    
    return user
  }
  
  func delete(user: User) async throws {
    let tokens = try await Token.query(on: db)
      .filter(\.$userID == user.id ?? UUID())
      .all()
    
    for token in tokens {
      try await token.delete(on: db)
    }
    
    let snippets = try await Snippet.query(on: db)
      .filter(\.$creator == user.id ?? UUID())
      .all()
    
    for snippet in snippets {
      try await snippet.delete(on: db)
    }
    
    try await user.delete(force: true, on: db)
  }
  
  init(application: Application) {
    self.application = application
    self.request = nil
  }
  
  init(req: Request) {
    self.request = req
    self.application = req.application
  }
}
