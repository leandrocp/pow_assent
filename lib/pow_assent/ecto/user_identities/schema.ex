defmodule PowAssent.Ecto.UserIdentities.Schema do
  @moduledoc """
  Handles the Ecto schema for user identity.

  A default `changeset/2` method is created, but can be overridden with a
  custom `changeset/2` method.

  ## Usage

  Configure `lib/my_project/user_identities/user_identity.ex` the following way:

      defmodule MyApp.UserIdentities.UserIdentity do
        use Ecto.Schema
        use PowAssent.Ecto.UserIdentities.Schema,
          user: MyApp.Users.User

        schema "user_identities" do
          pow_assent_user_identity_fields()

          timestamps()
        end

        def changeset(user_identity_or_changeset, attrs) do
          pow_assent_changeset(user_identity_or_changeset, attrs)
        end
      end

  ## Configuration options

    * `:user` - the user schema module to use in the `belongs_to` association.
  """
  alias Ecto.Changeset
  alias PowAssent.Config

  @callback changeset(Ecto.Schema.t() | Changeset.t(), map()) :: Changeset.t()

  @doc false
  defmacro __using__(config) do
    user_mod = Config.get(config, :user) || raise_no_user_error()

    quote do
      @behaviour unquote(__MODULE__)
      @pow_user_mod unquote(user_mod)
      @pow_assent_config unquote(config)

      @spec changeset(Ecto.Schema.t() | Changeset.t(), map()) :: Changeset.t()
      def changeset(user_identity_or_changeset, attrs), do: pow_assent_changeset(user_identity_or_changeset, attrs)

      defoverridable unquote(__MODULE__)

      unquote(__MODULE__).__pow_assent_methods__()
      unquote(__MODULE__).__register_fields__()
      unquote(__MODULE__).__register_assocs__()
    end
  end

  @doc """
  Macro for adding user identity schema fields.
  """
  @spec pow_assent_user_identity_fields :: Macro.t()
  defmacro pow_assent_user_identity_fields do
    quote do
      Enum.each(@pow_assent_assocs, fn
        {:belongs_to, name, :users} ->
          belongs_to(name, @pow_user_mod)
      end)

      Enum.each(@pow_assent_fields, fn
        {name, type} ->
          field(name, type)
      end)
    end
  end

  @doc false
  defmacro __pow_assent_methods__ do
    quote do
      import unquote(__MODULE__), only: [pow_assent_user_identity_fields: 0]

      @spec pow_assent_changeset(Ecto.Schema.t() | Changeset.t(), map()) :: Changeset.t()
      def pow_assent_changeset(user_identity_or_changeset, attrs) do
        unquote(__MODULE__).changeset(user_identity_or_changeset, attrs, @pow_assent_config)
      end
    end
  end

  @doc false
  defmacro __register_fields__ do
    quote do
      @pow_assent_fields unquote(__MODULE__).Fields.attrs(@pow_assent_config)
    end
  end

  @doc false
  defmacro __register_assocs__ do
    quote do
      @pow_assent_assocs unquote(__MODULE__).Fields.assocs(@pow_assent_config)
    end
  end

  @doc """
  Validates a user identity.
  """
  def changeset(user_identity_or_changeset, params, _config) do
    user_identity_or_changeset
    |> Changeset.cast(params, [:provider, :uid, :user_id])
    |> Changeset.validate_required([:provider, :uid])
    |> Changeset.assoc_constraint(:user)
    |> Changeset.unique_constraint(:uid_provider, name: :user_identities_uid_provider_index)
  end

  @spec raise_no_user_error :: no_return
  defp raise_no_user_error do
    Config.raise_error("No :user configuration option found for user identity schema module.")
  end
end
