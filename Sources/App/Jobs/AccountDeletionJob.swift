import Vapor
import Queues
import Foundation

struct AccountDeletionJob: AsyncJob {
	typealias Payload = User
	
	func dequeue(_ context: QueueContext, _ payload: Payload) async throws {
		if !payload.confirmed || (payload.deletionDate != nil) {
			let accountManagers = AccountsManager(application: context.application)
			
			try await accountManagers.delete(user: payload)
		}
	}
	
	func error(_ context: QueueContext, _ error: Error, _ payload: Payload) async throws {
		context.logger.report(error: error)
	}
}
