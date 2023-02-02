import Vapor
import Queues
import Foundation

struct TokenDeletionJob: AsyncJob {
	typealias Payload = UUID
	
	func dequeue(_ context: QueueContext, _ payload: Payload) async throws {
    let token = Token.query(on: context.application.db)
      .filter(\.$id == payload)
      .first()
    
    guard let token = token else {
      context.logger.error("Token doesn't exist.")
      return
    }
    
    
		try await token.delete(on: context.application.db)
	}
	
	func error(_ context: QueueContext, _ error: Error, _ payload: Payload) async throws {
		context.logger.report(error: error)
	}
}
