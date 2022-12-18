import Vapor

class NotFoundErrorMiddleware: AsyncMiddleware {
	func respond(to request: Request, chainingTo next: AsyncResponder) async throws -> Response {
		do {
			let response = try await next.respond(to: request)

			if response.status == .notFound {
				return request.redirect(to: "/404.html", type: .normal)
			} else {
				return try await response.encodeResponse(for: request)
			}
		} catch {
			if let error = error as? AbortError {
				if error.status == .notFound {
					return request.redirect(to: "/404.html", type: .normal)
				} else {
					throw error
				}
			} else {
				throw error
			}
		}
	}
}
