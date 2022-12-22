import SwiftSMTP
import Foundation
import Vapor

final class MailManager {
  private let recipient: String
  private let request: Request
  
  private let smtp = SMTP(
    hostname: "smtp.sendgrid.net",
    email: "apikey",
    password: EnvironmentVariables.mail.apiKey,
    port: 587
  )
  
  
  func send(subject: String, body: String) async -> Error? {
    let server = Mail.User(email: "server@extiri.com")
    let user = Mail.User(email: recipient)
    
    let mail = Mail(from: server, to: [user], subject: subject, text: body)
    
    return await send(mail)
  }
  
  private func send(_ mail: Mail) async -> Error? {
    return await  withCheckedContinuation { continuation in
      smtp.send(mail) { error in
        if let error = error {
          self.request.logger.error("Failed to send email: \(error.localizedDescription)")
          continuation.resume(returning: Abort(.internalServerError, reason: "Failed to send email."))
        } else {
          continuation.resume(returning: nil)
        }
      }
    }
  }
  
  
  init(to recipient: String, request: Request) {
    self.recipient = recipient
    self.request = request
  }
}
