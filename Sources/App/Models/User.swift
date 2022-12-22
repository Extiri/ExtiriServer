import Fluent
import Vapor

final class User: Model, Codable {
  static let schema = "users"
  
  @ID(key: .id)
  var id: UUID?
  
  @Field(key: "name")
  var name: String
  
  @Field(key: "email")
  var email: String
  
  @Field(key: "hash")
  var hash: String
  
  @Field(key: "confirmed")
  var confirmed: Bool
  
  @Field(key: "strikes")
  var strikes: Int
  
  @Timestamp(key: "creation_date", on: .create)
  var creationDate: Date?
  
  @Timestamp(key: "deletion_date", on: .delete)
  var deletionDate: Date?
  
  func check(_ password: String) throws -> Bool {
    let result = try Bcrypt.verify(password + EnvironmentVariables.secrets.salt, created: hash)
    waitRandomTime()
    return result
  }
  
  func changePassword(password: String) throws {
    self.hash = try Bcrypt.hash(password + EnvironmentVariables.secrets.salt)
  }
  
  init() { }
  
  init(id: UUID? = nil, name: String, email: String, password: String) throws {
    self.id = id
    self.name = name
    self.email = email
    self.hash = try Bcrypt.hash(password + EnvironmentVariables.secrets.salt)
    self.confirmed = false
    self.strikes = 0
  }
}
