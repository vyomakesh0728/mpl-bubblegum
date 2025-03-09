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
            bytes: list(integer()) | binary()
          }

    @doc """
    Creates a new Pubkey from a base58 string.
    """
    @spec from_base58(String.t()) :: {:ok, t()} | {:error, atom() | String.t()}
    def from_base58(base58) do
      case Base58.decode(base58) do
        bytes when byte_size(bytes) == 32 -> {:ok, %__MODULE__{bytes: :binary.bin_to_list(bytes)}}
        _ -> {:error, "Invalid base58 public key"}
      end
    end

    @doc """
    Converts a Pubkey to a base58 string.
    """
    @spec to_base58(t()) :: String.t()
    def to_base58(%__MODULE__{bytes: bytes}) when is_list(bytes) do
      Base58.encode(:binary.list_to_bin(bytes))
    end
    def to_base58(%__MODULE__{bytes: bytes}) when is_binary(bytes) do
      Base58.encode(bytes)
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
            address: binary(),
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

  defmodule AccountInfo do
    @moduledoc """
    Represents account information retrieved from the Solana network.
    """
    @enforce_keys [:lamports, :owner, :executable, :rent_epoch, :data_len]
    defstruct [:lamports, :owner, :executable, :rent_epoch, :data_len]

    @type t :: %__MODULE__{
            lamports: non_neg_integer(),
            owner: String.t(),
            executable: boolean(),
            rent_epoch: non_neg_integer(),
            data_len: non_neg_integer()
          }

    @doc """
    Creates an AccountInfo struct from a map returned by the native function.

    ## Parameters
    - map: A map with string keys "lamports", "owner", "executable", "rent_epoch", "data_len"

    ## Returns
    - {:ok, AccountInfo.t()} if successful
    - {:error, reason} if the map is invalid
    """
    @spec from_map(map()) :: {:ok, t()} | {:error, String.t()}
    def from_map(map) when is_map(map) do
      with {:ok, lamports} <- get_integer(map, "lamports"),
           {:ok, owner} <- get_string(map, "owner"),
           {:ok, executable} <- get_boolean(map, "executable"),
           {:ok, rent_epoch} <- get_integer(map, "rent_epoch"),
           {:ok, data_len} <- get_integer(map, "data_len") do
        {:ok, %__MODULE__{
          lamports: lamports,
          owner: owner,
          executable: executable,
          rent_epoch: rent_epoch,
          data_len: data_len
        }}
      else
        {:error, reason} -> {:error, reason}
      end
    end

    defp get_integer(map, key) do
      case Map.get(map, key) do
        nil -> {:error, "Missing #{key}"}
        value when is_binary(value) ->
          case Integer.parse(value) do
            {int, ""} -> {:ok, int}
            _ -> {:error, "Invalid integer for #{key}"}
          end
        value when is_integer(value) -> {:ok, value}
        _ -> {:error, "Invalid type for #{key}"}
      end
    end

    defp get_string(map, key) do
      case Map.get(map, key) do
        nil -> {:error, "Missing #{key}"}
        value when is_binary(value) -> {:ok, value}
        _ -> {:error, "Invalid type for #{key}"}
      end
    end

    defp get_boolean(map, key) do
      case Map.get(map, key) do
        nil -> {:error, "Missing #{key}"}
        value when is_boolean(value) -> {:ok, value}
        "true" -> {:ok, true}
        "false" -> {:ok, false}
        _ -> {:error, "Invalid type for #{key}"}
      end
    end
  end
end
