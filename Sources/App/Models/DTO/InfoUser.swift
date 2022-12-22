import Vapor

struct InfoUser: Content {
  var id: UUID
  var name: String
  var email: String
  
  init(id: UUID, name: String, email: String) {
    self.id = id
    self.name = name
    self.email = email
  }
}
