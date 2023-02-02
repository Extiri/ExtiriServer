import Fluent
import FluentPostgresDriver
import Vapor
import Leaf
import Queues
import QueuesFluentDriver
import JWT
import Gatekeeper
import GraphQLKit
import GraphiQLVapor

public func configure(_ app: Application) throws {
  print("Is hiding new snippets: \(EnvironmentVariables.state.shouldHideNewSnippets == "true")")
  
  app.databases.use(.postgres(
    hostname: EnvironmentVariables.database.hostname,
    port: Int(EnvironmentVariables.database.port)!,
    username: EnvironmentVariables.database.username,
    password: EnvironmentVariables.database.password,
    database: EnvironmentVariables.database.name
  ), as: .psql)
  
  app.queues.use(.fluent())
  app.caches.use(.memory)
  
  app.migrations.add(UsersMigration())
  app.migrations.add(SnippetsMigration())
  app.migrations.add(TokensMigration())
  app.migrations.add(JobModelMigrate())
  app.migrations.add(LanguageMigration())
  app.migrations.add(CategoryMigration())
  app.migrations.add(DateTimeMigration())
  
  try app.autoMigrate().wait()
  
  app.queues.add(AccountDeletionJob())
  app.queues.add(TokenDeletionJob())
  
  try app.queues.startInProcessJobs(on: .default)
  
  let corsConfiguration = CORSMiddleware.Configuration(
    allowedOrigin: .all,
    allowedMethods: [.DELETE, .GET, .POST],
    allowedHeaders: [.accept, .authorization, .contentType, .origin, .xRequestedWith, .userAgent, .accessControlAllowOrigin, .contentLanguage]
  )
  
  app.gatekeeper.config = .init(maxRequests: 16, per: .second)
  
  app.middleware.use(CORSMiddleware(configuration: corsConfiguration), at: .beginning)
  app.middleware.use(GatekeeperMiddleware())
  
  app.jwt.signers.use(.hs512(key: EnvironmentVariables.secrets.jwtKey))
  
  app.views.use(.leaf)
  
  app.register(graphQLSchema: Schemas.snippetSchema, withResolver: SnippetResolver())
  app.enableGraphiQL(on: "graphiql")
  
  app.http.server.configuration.responseCompression = .enabled
  app.http.server.configuration.requestDecompression = .enabled(limit: .size(31_457_280)) // 30 MB
  
  try app.register(collection: APIController())
  try app.register(collection: SnippetsController())
  try app.register(collection: UsersController())
  
  try routes(app)
}
