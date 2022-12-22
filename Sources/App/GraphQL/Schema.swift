//
//  Schema.swift
//  
//
//  Created by Wiktor Wójcik on 21/07/2022.
//

import Vapor
import GraphQLKit

enum Schemas {
  static let snippetSchema = try! Schema<SnippetResolver, Request> {
    Scalar(UUID.self)
    DateScalar(formatter: ISO8601DateFormatter())
    
    Type(Snippet.self) {
      Field("id", at: \.id)
      Field("title", at: \.title)
      Field("description", at: \.desc)
      Field("category", at: \.category)
      Field("language", at: \.language)
        .description("Language key describing language of code. It is not a human-readable form.")
      Field("code", at: \.code)
      Field("creator", at: \.creator)
        .description("ID of snippet's creator account.")
      Field("isHidden", at: \.isHidden)
        .description("Informs whether snippet has been made public yet. True of it is hidden and false, if not.")
      Field("creationDate", at: \.creationDate)
    }
    
    Query {
      Field("snippets", at: SnippetResolver.getAllSnippets) {
        Argument("pageNumber", at: \.pageNumber)
          .description("Page number must be 1 or greater. Each page has 20 snippets.")
        Argument("query", at: \.query)
          .description("Server will search for occurences of this query in descriptions, codes and titles of snippets.")
        Argument("category", at: \.category)
        Argument("language", at: \.language)
        Argument("creator", at: \.creator)
        Argument("isHidden", at: \.isHidden)
      }
      
      Field("snippet", at: SnippetResolver.getSnippet) {
        Argument("id", at: \.id)
      }
    }
    
    Mutation {
      Field("createSnippet", at: SnippetResolver.createSnippet) {
        Argument("token", at: \.token)
        Argument("title", at: \.title)
        Argument("description", at: \.description)
        Argument("category", at: \.category)
        Argument("language", at: \.language)
        Argument("code", at: \.code)
      }
      
      Field("deleteSnippet", at: SnippetResolver.deleteSnippet) {
        Argument("token", at: \.token)
        Argument("id", at: \.id)
      }
    }
  }
}
