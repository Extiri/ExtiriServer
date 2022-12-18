import Vapor
import Queues
import Foundation

struct TokenDeletionJob: AsyncJob {
	typealias Payload = Token
	
	func dequeue(_ context: QueueContext, _ payload: Payload) async throws {
		try await payload.delete(on: context.application.db)
	}
	
	func error(_ context: QueueContext, _ error: Error, _ payload: Payload) async throws {
		context.logger.report(error: error)
	}
}
