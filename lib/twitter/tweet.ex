defmodule Twitter.Tweet do
  use Ecto.Schema
  import Ecto.Changeset

  schema "tweets" do
    field :content, :string
    field :username, :string
    field :likes_count, :integer

    timestamps(type: :utc_datetime)
  end

  @doc false
  def changeset(tweet, attrs) do
    tweet
    |> cast(attrs, [:content, :username, :likes_count])
    |> validate_required([:content, :username, :likes_count])
  end
end
