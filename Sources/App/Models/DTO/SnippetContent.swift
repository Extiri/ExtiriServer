import Fluent
import Vapor

struct SnippetContent: Content {
	var title: String
	var description: String
	var category: String
	var language: String
	var code: String
	
	init(title: String, description: String, category: String, language: String, code: String) {
		self.title = title
		self.description = description
		self.category = category
		self.language = language
		self.code = code
	}
}
