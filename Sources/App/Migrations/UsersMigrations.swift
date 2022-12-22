import Fluent

struct UsersMigration: AsyncMigration {
  func prepare(on database: Database) async throws {
    try await database.schema("users")
      .id()
      .field("name", .string, .required)
      .field("email", .string, .required)
      .field("hash", .string, .required)
      .field("confirmed", .bool)
      .field("creation_date", .date)
      .field("deletion_date", .date)
      .field("strikes", .int8, .required)
      .create()
  }
  
  func revert(on database: Database) async throws {
    try await database.schema("users")
      .delete()
  }
}
