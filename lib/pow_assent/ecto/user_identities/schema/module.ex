defmodule PowAssent.Ecto.UserIdentities.Schema.Module do
  @moduledoc """
  Generates schema module content.

  ## Configuration options

    * `:binary_id` - if the schema module should use binary id, default nil.
  """
  alias Pow.Config

  @template """
  defmodule <%= inspect schema.module %> do
    use Ecto.Schema
    use PowAssent.Ecto.UserIdentities.Schema

  <%= if schema.binary_id do %>
    @primary_key {:id, :binary_id, autogenerate: true}
    @foreign_key_type :binary_id<% end %>
    schema <%= inspect schema.table %> do
      pow_assent_user_identity_fields()

      timestamps(updated_at: false)
    end
  end
  """

  @doc """
  Generates schema module file content.
  """
  @spec gen(map()) :: binary()
  def gen(schema) do
    EEx.eval_string(unquote(@template), schema: schema)
  end

  @doc """
  Generates a schema module map.
  """
  @spec new(atom(), binary(), binary(), Config.t()) :: map()
  def new(context_base, schema_name, schema_plural, config \\ []) do
    module    = Module.concat([context_base, schema_name])
    binary_id = config[:binary_id]

    %{
      schema_name: schema_name,
      module: module,
      table: schema_plural,
      binary_id: binary_id
    }
  end
end
