import Vapor

struct EnvironmentVariables {
	struct state {
		@EnvironmentVariable(key: "HIDE_NEW_SNIPPETS") static var shouldHideNewSnippets
		@EnvironmentVariable(key: "SNIPPETS_PER_PAGE") static var snippetsPerPage
	}
	
	struct database {
		@EnvironmentVariable(key: "DATABASE_HOSTNAME") static var hostname
		@EnvironmentVariable(key: "DATABASE_PORT") static var port
		@EnvironmentVariable(key: "DATABASE_NAME") static var name
		@EnvironmentVariable(key: "DATABASE_USERNAME") static var username
		@EnvironmentVariable(key: "DATABASE_PASSWORD") static var password
	}
	
	struct mail {
		@EnvironmentVariable(key: "MAIL_API_KEY") static var apiKey
	}
	
	struct server {
		@EnvironmentVariable(key: "DOMAIN") static var domain
	}
	
	struct secrets {
		@EnvironmentVariable(key: "SALT") static var salt
		@EnvironmentVariable(key: "JWT_KEY") static var jwtKey
	}
	
	static let languages = ["apl", "pgp", "asn", "cmake", "c", "c++", "objective-c", "kotlin", "scala", "c#", "java", "cobol", "coffescript", "lisp", "css/scss", "django", "dart", "dockerfile", "erlang", "fortran", "go", "groovy", "haskell", "html", "http", "javascript", "typescript", "json", "ecma", "jinja", "lua", "markdown", "maths", "ntriples", "pascal", "perl", "php", "powershell", "properties", "protobuf", "python", "r", "ruby", "rust", "sass", "scheme", "shell", "sql", "sqlite", "sparql", "mysql", "latex", "swift", "text", "toml", "turtle", "vb", "vue", "xml", "yaml"]
	
	static let categories = ["None", "UI", "Math", "Algorithms", "Collections", "Automations", "Debugging"]
}

@propertyWrapper struct EnvironmentVariable {
	let key: String
	
	var wrappedValue: String {
		get {
			if let value = Environment.get(key) {
				return value
			} else {
				fatalError("Value for key \"\(key)\" not found.")
			}
		}
	}
	
	init(key: String) {
		self.key = key
	}
}
