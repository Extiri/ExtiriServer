# Extiri Server
Extiri Server is the server for all Extiri services.

It is made using Vapor in Swift. It uses Postgres as a database for all data, including jobs. By default, SendGrid is used as the middleware for sending mails.

It currently includes management of snippets in Snippets Store and accounts.

# Documentation
Official documentation can be found at https://docs.extiri.com.

# Development
To develop the server you will need a local Postgres database. Check https://www.postgresql.org for help. If you use macOS, you can use https://postgresapp.com.

Clone this repo into a directory using:
```
git clone https://github.com/Extiri/ExtiriServer.git
```
Enter ExtiriServer directory and run:
```
swift run ExtiriServer --env development
```

The server uses a .env and .env.development files as a source of some values. Here are all required variables:
- HIDE_NEW_SNIPPETS - Can be either true or false as a string ("true", "false"). Indicates whether the server should hide new snippets so they can be, for example, moderated and checked before they become public.
- SNIPPETS_PER_PAGE - An integer number. Indicates how many snippets can maximally appear on one page.
- DATABASE_HOSTNAME - Database's hostname.
- DATABASE_PORT - The database's port.
- DATABASE_NAME - The database's name.
- DATABASE_USERNAME - Username used to login to the database.
- DATABASE_PASSWORD - Password used to login to the database.
- MAIL_API_KEY - API key from SendGrid.
- DOMAIN - Domain where the server is hosted with no trailing /.
- SALT - Salt used for password hashing.
- JWT_KEY - Key for JWT tokens.

This variaibles can be placed in either .env or .env.development file.

# Security 
If you find a vulnerability, please, contact me at wiktor.wojcik+security@extiri.com. Include as much of informations about the vulnerability as you can.
