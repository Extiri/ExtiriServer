import Vapor
import JWT

struct APIPayload: JWTPayload {
  enum CodingKeys: String, CodingKey {
    case subject = "sub"
    case creation = "nbf"
    case token = "tkn"
  }
  
  var subject: SubjectClaim
  var creation: NotBeforeClaim
  var token: UUID
  
  func verify(using signer: JWTSigner) throws {
    try self.creation.verifyNotBefore()
  }
}

