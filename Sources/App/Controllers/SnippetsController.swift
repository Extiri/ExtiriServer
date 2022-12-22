import Vapor
import Fluent

struct SnippetsController: RouteCollection {
  func boot(routes: RoutesBuilder) throws {
    routes.group("api", "1", "snippets") { snippets in
      snippets.get("get", ":snippet_id", use: getSnippet)
      snippets.post("create", use: createSnippet)
      snippets.get(use: getMultipleSnippets)
      snippets.delete("delete", ":snippet_id", use: deleteSnippet)
      snippets.get("categories", use: getCategories)
      snippets.get("languages", use: getLanguages)
    }
  }
  
  func getSnippet(req: Request) async throws -> Snippet {
    let id = UUID(uuidString: req.parameters.get("snippet_id")!)!
    
    let snippet = try await Snippet.query(on: req.db)
      .filter(\.$id == id)
      .first()
    
    if let snippet = snippet {
      return snippet
    } else {
      throw Abort(.notFound)
    }
  }
  
  func createSnippet(req: Request) async throws -> Snippet {
    let tokensManager = TokensManager(request: req)
    
    try await tokensManager.authorize()
    
    let user = try await tokensManager.getUser()
    
    let snippetContent = try req.content.decode(SnippetContent.self)
    
    if !EnvironmentVariables.languages.contains(snippetContent.language) {
      throw Abort(.badRequest, reason: "Programming language is not supported. Remember that it needs to be lowercased and in key form.")
    }
    
    if !EnvironmentVariables.categories.contains(snippetContent.category) {
      throw Abort(.badRequest, reason: "There is no such category. Valid categories are: \(EnvironmentVariables.categories.joined(separator: ", ").dropLast(2)).")
    }
    
    let snippet = Snippet(title: snippetContent.title, description: snippetContent.description, category: snippetContent.category, language: snippetContent.language, code: snippetContent.code, creator: user.id!)
    
    try await snippet.create(on: req.db)
    
    return snippet
  }
  
  func getMultipleSnippets(req: Request) async throws -> MultipleSnippets {
    let pageNumber = Int(req.query["page"] ?? "1") ?? 1
    let searchPhrase: String? = req.query["query"]
    let language: String? = req.query["language"]
    let category: String? = req.query["category"]
    let creator: String? = req.query["creator"]
    let isHidden = Bool(req.query["isHidden"] ?? "false") ?? false
    
    var creatorID: UUID? = nil
    
    if pageNumber < 1 {
      throw Abort(.forbidden, reason: "Page must be equal or greater than 1.")
    }
    
    if let creator = creator {
      if let id = UUID(uuidString: creator) {
        creatorID = id
      } else {
        throw Abort(.badRequest, reason: "Creator is invalid.")
      }
    }
    
    let page = try await Snippet.query(on: req.db)
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
      .if(creatorID != nil) { query in
        query
          .filter(\.$creator == creatorID!)
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
      .paginate(PageRequest(page: pageNumber, per: Int(EnvironmentVariables.state.snippetsPerPage)!))
    
    let count = try await Snippet.query(on: req.db)
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
      .if(creatorID != nil) { query in
        query
          .filter(\.$creator == creatorID!)
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
      .count()
    
    return MultipleSnippets(page: page, totalNumberOfResults: count)
  }
  
  func deleteSnippet(req: Request) async throws -> HTTPStatus {
    let tokensManager = TokensManager(request: req)
    
    try await tokensManager.authorize()
    
    let snippetID = req.parameters.get("snippet_id")!
    
    guard let snippetID = UUID(uuidString: snippetID) else {
      throw Abort(.badRequest, reason: "Snippet ID is invalid.")
    }
    
    let user = try await tokensManager.getUser()
    
    let snippet = try await Snippet.query(on: req.db)
      .filter(\.$id == snippetID)
      .filter(\.$creator == user.id!)
      .first()
    
    if let snippet = snippet {
      try await snippet.delete(on: req.db)
    } else {
      throw Abort(.notFound, reason: "No snippet with specified ID found.")
    }
    
    return .ok
  }
  
  func getCategories(req: Request) async throws -> [String] {
    return EnvironmentVariables.categories
  }
  
  func getLanguages(req: Request) async throws -> [String] {
    return EnvironmentVariables.languages
  }
}
