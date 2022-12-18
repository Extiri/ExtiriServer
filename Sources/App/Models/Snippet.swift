import Fluent
import Vapor

final class Snippet: Model, Content {
    static let schema = "snippets"
    
    @ID(key: .id)
    var id: UUID?

    @Field(key: "title")
    var title: String
	
	@Field(key: "description")
	var desc: String
	
	@Field(key: "category")
	var category: String
	
	@Field(key: "language")
	var language: String
	
	@Field(key: "code")
	var code: String
	
	@Field(key: "creator")
	var creator: UUID
	
	@Field(key: "is_hidden")
	var isHidden: Bool
	
	@Timestamp(key: "creation_date", on: .create)
	var creationDate: Date?

    init() { }

	init(id: UUID? = nil, title: String, description: String, category: String, language: String, code: String, creator: UUID) {
        self.id = id
        self.title = title
		self.desc = description
		self.category = category
		self.language = language
		self.creator = creator
		self.code = code
		self.isHidden = EnvironmentVariables.state.shouldHideNewSnippets == "true"
    }
}
