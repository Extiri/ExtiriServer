import Fluent

struct TokensMigration: AsyncMigration {
	func prepare(on database: Database) async throws {
		try await database.schema("tokens")
			.id()
			.field("user_id", .uuid, .required)
			.field("creation_date", .date)
			.field("type", .string, .required)
			.create()
	}
	
	func revert(on database: Database) async throws {
		try await database.schema("tokens")
			.delete()
	}
}
