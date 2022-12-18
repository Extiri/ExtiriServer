import Fluent

struct SnippetsMigration: AsyncMigration {
    func prepare(on database: Database) async throws {
        try await database.schema("snippets")
            .id()
            .field("title", .string, .required)
			.field("description", .string, .required)
			.field("code", .string, .required)
			.field("creator", .uuid, .required)
			.field("creation_date", .date, .required)
			.field("is_hidden", .bool, .required)
            .create()
    }

    func revert(on database: Database) async throws {
        try await database
			.schema("snippets")
			.delete()
    }
}

struct LanguageMigration: AsyncMigration {
	func prepare(on database: Database) async throws {
		try await database.schema("snippets")
			.field("language", .string, .required)
			.update()
	}
	
	func revert(on database: Database) async throws {
		try await database.schema("snippets")
			.deleteField("language")
			.update()
	}
}

struct CategoryMigration: AsyncMigration {
	func prepare(on database: Database) async throws {
		try await database.schema("snippets")
			.field("category", .string, .required)
			.update()
	}
	
	func revert(on database: Database) async throws {
		try await database.schema("snippets")
			.deleteField("category")
			.update()
	}
}

struct DateTimeMigration: AsyncMigration {
	func prepare(on database: Database) async throws {
		try await database.schema("snippets")
			.updateField("creation_date", .datetime)
			.update()
	}
	
	func revert(on database: Database) async throws {
		try await database.schema("snippets")
			.updateField("creation_date", .date)
			.update()
	}
}
