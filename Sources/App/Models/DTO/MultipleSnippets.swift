import Vapor
import Fluent

struct MultipleSnippets: Content {
	var page: Page<Snippet>
	var totalNumberOfResults: Int
	
	init(page: Page<Snippet>, totalNumberOfResults: Int) {
		self.page = page
		self.totalNumberOfResults = totalNumberOfResults
	}
}
