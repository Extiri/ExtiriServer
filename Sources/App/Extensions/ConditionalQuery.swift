import Vapor
import Fluent

extension QueryBuilder {
	func `if`(_ condition: @autoclosure () -> Bool, _ closure: (QueryBuilder<Model>) throws -> QueryBuilder<Model>) throws -> QueryBuilder<Model> {
		if condition() {
			let result = try closure(self)
			
			return result
		}
		
		return self
	}
}
