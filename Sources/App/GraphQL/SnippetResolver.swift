//
//  SnippetResolver.swift
//
//
//  Created by Wiktor Wójcik on 21/07/2022.
//

import Vapor
import GraphQLKit
import Fluent

final class SnippetResolver {
	struct FetchOneArguments: Codable {
		let id: UUID
	}
	
	func getSnippet(request: Request, arguments: FetchOneArguments) throws -> EventLoopFuture<Snippet> {
		return Snippet.query(on: request.db)
			.filter(\.$id == arguments.id)
			.first()
			.unwrap(or: Abort(.notFound))
	}
	
	struct QueryAllArguments: Codable {
		let pageNumber: Int
		let query: String?
		let category: String?
		let language: String?
		let creator: UUID?
		let isHidden: Bool?
	}
	
	func getAllSnippets(request: Request, arguments: QueryAllArguments) throws -> EventLoopFuture<[Snippet]> {
		if arguments.pageNumber < 1 {
			throw Abort(.forbidden, reason: "Page must be equal or greater than 1.")
		}
		
		let pageNumber = arguments.pageNumber
		let searchPhrase: String? = arguments.query
		let language: String? = arguments.language
		let category: String? = arguments.category
		let creator: UUID? = arguments.creator
		let isHidden: Bool = arguments.isHidden ?? false
		
		if pageNumber < 1 {
			throw Abort(.forbidden, reason: "Page must be equal or greater than 1.")
		}
		
		return try Snippet.query(on: request.db)
			.sort(\.$creationDate, .descending)
			.filter(\.$isHidden == isHidden)
			.if(category != nil) { query in
				query
					.filter(\.$category == category!)
			}
			.if(language != nil) { query in
				return query
					.filter(\.$language == language!)
			}
			.if(creator != nil) { query in
				query
					.filter(\.$creator == creator!)
			}
			.if(searchPhrase != nil) { query in
				query
					.group(.or) { query in
						query
							.filter(\.$title ~~ searchPhrase!)
							.filter(\.$desc ~~ searchPhrase!)
							.filter(\.$code ~~ searchPhrase!)
					}
			}
			.limit(Int(EnvironmentVariables.state.snippetsPerPage)!)
			.offset((arguments.pageNumber - 1) * Int(EnvironmentVariables.state.snippetsPerPage)!)
			.all()
	}
	
	struct CreateSnippetArguments: Codable {
		let token: String
		let title: String
		let description: String
		let category: String
		let language: String
		let code: String
	}
	
	func createSnippet(request: Request, arguments: CreateSnippetArguments) throws -> EventLoopFuture<Snippet> {
		let promise = request.eventLoop.makePromise(of: Snippet.self)
		
		promise.completeWithTask {
			let token = arguments.token
			
			let tokensManager = TokensManager(request: request)
			
			try await tokensManager.isValidSessionToken(token)
			
			let user = try await tokensManager.getUser()
			
			if !EnvironmentVariables.languages.contains(arguments.language) {
				throw Abort(.badRequest, reason: "Programming language is not supported. Remember that it needs to be lowercased.")
			}
			
			if !EnvironmentVariables.categories.contains(arguments.category) {
				throw Abort(.badRequest, reason: "There is no souch category. Valid categories are: \(EnvironmentVariables.categories.joined(separator: ", ").dropLast(2)).")
			}
			
			let snippet = Snippet(title: arguments.title, description: arguments.description, category: arguments.category, language: arguments.language, code: arguments.code, creator: user.id!)
			
			try await snippet.create(on: request.db)
			
			return snippet
		}
		
		return promise.futureResult
	}
	
	struct UpdateSnippetArguments: Codable {
		let token: String
		let title: String
		let description: String
		let category: String
		let language: String
		let code: String
	}
	
	func updateSnippet(request: Request, arguments: UpdateSnippetArguments) throws -> EventLoopFuture<Bool> {
		return request.eventLoop.makeFailedFuture(Abort(.notImplemented))
	}
	
	struct DeleteSnippetArguments: Codable {
		let token: String
		let id: UUID
	}
	
	func deleteSnippet(request: Request, arguments: DeleteSnippetArguments) -> EventLoopFuture<Bool> {
		let promise = request.eventLoop.makePromise(of: Bool.self)
		
		promise.completeWithTask {
			let token = arguments.token
			let snippetID = arguments.id
			
			let tokensManager = TokensManager(request: request)
			
			try await tokensManager.isValidSessionToken(token)
			
			let user = try await tokensManager.getUser()
			
			let snippet = try await Snippet.query(on: request.db)
				.filter(\.$id == snippetID)
				.filter(\.$creator == user.id!)
				.first()
			
			if let snippet = snippet {
				try await snippet.delete(on: request.db)
			} else {
				throw Abort(.notFound, reason: "No snippet with specified ID found.")
			}
			
			return true
		}
		
		return promise.futureResult
	}
}
