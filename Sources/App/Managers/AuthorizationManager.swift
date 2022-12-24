//
//  AuthorizationManager.swift
//  
//
//  Created by Wiktor Wójcik on 22/12/2022.
//

import Vapor

/// AuthorizationManager contains common code for authorization of requests.
final class AuthorizationManager {
  /// Authorizes access using a Bearer token.
  static func assertUserIsLoggedIn(req: Request) async throws {
    guard let bearer = req.headers.bearerAuthorization else {
      throw Abort(.unauthorized, reason: "A Bearer Authorization HTTP header with token is required.")
    }
    
    try await TokensManager(req: req).isValidSessionToken(bearer.token)
  }
}
