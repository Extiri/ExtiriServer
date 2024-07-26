import App
import Vapor

#warning("Increase version number on every update.")
print("[Extiri Server] 1.0.14")

var env = try Environment.detect()

try LoggingSystem.bootstrap(from: &env)

let app = Application(env)

print("Environment: \(app.environment.name)")

defer { app.shutdown() }

try configure(app)
try app.run()
