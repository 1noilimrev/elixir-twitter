defmodule Twitter.Repo do
  use Ecto.Repo,
    otp_app: :twitter,
    adapter: Ecto.Adapters.SQLite3
end
