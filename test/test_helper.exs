ExUnit.start()

{:ok, _} = EctoContext.Test.Repo.start_link()

Ecto.Adapters.SQL.query!(EctoContext.Test.Repo, """
  CREATE TABLE IF NOT EXISTS users (
    id INTEGER PRIMARY KEY AUTOINCREMENT,
    name TEXT NOT NULL,
    is_admin INTEGER NOT NULL DEFAULT 0,
    inserted_at TEXT NOT NULL,
    updated_at TEXT NOT NULL
  )
""")

Ecto.Adapters.SQL.query!(EctoContext.Test.Repo, """
  CREATE TABLE IF NOT EXISTS articles (
    id INTEGER PRIMARY KEY AUTOINCREMENT,
    title TEXT NOT NULL,
    body TEXT,
    published INTEGER NOT NULL DEFAULT 0,
    category_id TEXT,
    user_id INTEGER NOT NULL REFERENCES users(id),
    inserted_at TEXT NOT NULL,
    updated_at TEXT NOT NULL
  )
""")
