import Vapor
import Queues
import Foundation
import Fluent

struct AccountDeletionJob: AsyncJob {
  typealias Payload = UUID
  
  func dequeue(_ context: QueueContext, _ payload: Payload) async throws {
    let account = try await User.query(on: context.application.db)
      .filter(\.$id == payload)
      .first()
    
    guard let account = account else {
      context.logger.error("Account doesn't exist.")
      return
    }
    
    if !account.confirmed || account.deletionDate != nil {
      let accountManagers = AccountsManager(application: context.application)
      
      try await accountManagers.delete(user: account)
      context.logger.info("Deleted account.")
      return
    }
    
    context.logger.error("Failed to delete an account.")
  }
  
  func error(_ context: QueueContext, _ error: Error, _ payload: Payload) async throws {
    context.logger.report(error: error)
  }
}
