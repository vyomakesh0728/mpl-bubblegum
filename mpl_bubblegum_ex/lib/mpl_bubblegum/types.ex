defmodule MplBubblegum.Types do
  @moduledoc """
  Types used by the MplBubblegum module.
  """

  defmodule Pubkey do
    @moduledoc """
    Represents a Solana public key.
    """
    @enforce_keys [:bytes]
    defstruct [:bytes]

    @type t :: %__MODULE__{
            bytes: binary()
          }

    @doc """
    Creates a new Pubkey from a base58 string.
    """
    @spec from_base58(String.t()) :: {:ok, t()} | {:error, atom() | String.t()}
    def from_base58(base58) do
      case B58.decode58(base58) do
        {:ok, bytes} when byte_size(bytes) == 32 -> {:ok, %__MODULE__{bytes: bytes}}
        {:ok, _} -> {:error, :invalid_length}
        {:error, reason} -> {:error, reason}
      end
    end

    @doc """
    Converts a Pubkey to a base58 string.
    """
    @spec to_base58(t()) :: String.t()
    def to_base58(%__MODULE__{bytes: bytes}) do
      B58.encode58(bytes)
    end
  end

  defmodule Hash do
    @moduledoc """
    Represents a 32-byte hash.
    """
    @enforce_keys [:bytes]
    defstruct [:bytes]

    @type t :: %__MODULE__{
            bytes: binary()
          }

    @doc """
    Creates a new Hash from a hex string.
    """
    @spec from_hex(String.t()) :: {:ok, t()} | {:error, String.t()}
    def from_hex(hex) do
      case Base.decode16(hex, case: :mixed) do
        {:ok, bytes} when byte_size(bytes) == 32 ->
          {:ok, %__MODULE__{bytes: bytes}}

        {:ok, _} ->
          {:error, "Invalid hash length"}

        :error ->
          {:error, "Invalid hex encoding"}
      end
    end

    @doc """
    Converts a Hash to a hex string.
    """
    @spec to_hex(t()) :: String.t()
    def to_hex(%__MODULE__{bytes: bytes}) do
      Base.encode16(bytes, case: :lower)
    end
  end

  defmodule Creator do
    @moduledoc """
    Represents a creator of an NFT.
    """
    @enforce_keys [:address, :verified, :share]
    defstruct [:address, :verified, :share]

    @type t :: %__MODULE__{
            address: Pubkey.t(),
            verified: boolean(),
            share: integer()
          }
  end

  defmodule Collection do
    @moduledoc """
    Represents a collection of NFTs.
    """
    @enforce_keys [:verified, :key]
    defstruct [:verified, :key]

    @type t :: %__MODULE__{
            verified: boolean(),
            key: Pubkey.t()
          }
  end

  defmodule Uses do
    @moduledoc """
    Represents the uses of an NFT.
    """
    @enforce_keys [:use_method, :remaining, :total]
    defstruct [:use_method, :remaining, :total]

    @type t :: %__MODULE__{
            use_method: integer(),
            remaining: integer(),
            total: integer()
          }

    @doc """
    Use method constants.
    """
    def burn, do: 0
    def multiple, do: 1
    def single, do: 2
  end

  defmodule Metadata do
    @moduledoc """
    Represents the metadata of an NFT.
    """
    @enforce_keys [
      :name,
      :symbol,
      :uri,
      :seller_fee_basis_points,
      :primary_sale_happened,
      :is_mutable,
      :token_program_version,
      :creators
    ]
    defstruct [
      :name,
      :symbol,
      :uri,
      :seller_fee_basis_points,
      :primary_sale_happened,
      :is_mutable,
      :edition_nonce,
      :token_standard,
      :collection,
      :uses,
      :token_program_version,
      :creators
    ]

    @type t :: %__MODULE__{
            name: String.t(),
            symbol: String.t(),
            uri: String.t(),
            seller_fee_basis_points: integer(),
            primary_sale_happened: boolean(),
            is_mutable: boolean(),
            edition_nonce: integer() | nil,
            token_standard: integer() | nil,
            collection: Collection.t() | nil,
            uses: Uses.t() | nil,
            token_program_version: integer(),
            creators: [Creator.t()]
          }

    @doc """
    Token program version constants.
    """
    def original, do: 0
    def token2022, do: 1

    @doc """
    Token standard constants.
    """
    def non_fungible, do: 0
    def fungible_asset, do: 1
    def fungible, do: 2
    def non_fungible_edition, do: 3
  end
end
