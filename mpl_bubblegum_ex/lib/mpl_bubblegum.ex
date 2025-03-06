defmodule MplBubblegum do
  @moduledoc """
  Elixir interface for the Metaplex Bubblegum program.
  
  This module provides functions to interact with the Solana blockchain
  for creating and managing compressed NFTs using the Metaplex Bubblegum program.
  """

  alias MplBubblegum.Native
  alias MplBubblegum.Types.Pubkey

  @doc """
  Creates a new compressed NFT tree configuration.

  ## Parameters

  * `tree_config` - The public key for the tree configuration account
  * `merkle_tree` - The public key for the merkle tree account
  * `payer` - The public key of the payer
  * `tree_creator` - The public key of the tree creator
  * `max_depth` - The maximum depth of the merkle tree
  * `max_buffer_size` - The maximum buffer size of the merkle tree
  * `public` - Whether the tree is public or not (optional)

  ## Returns

  * `{:ok, transaction}` - The serialized transaction
  * `{:error, reason}` - If an error occurs
  """
  def create_tree_config(params) do
    with {:ok, tree_config} <- get_pubkey(params, :tree_config),
         {:ok, merkle_tree} <- get_pubkey(params, :merkle_tree),
         {:ok, payer} <- get_pubkey(params, :payer),
         {:ok, tree_creator} <- get_pubkey(params, :tree_creator),
         {:ok, max_depth} <- get_integer(params, :max_depth),
         {:ok, max_buffer_size} <- get_integer(params, :max_buffer_size),
         public = Map.get(params, :public) do
      Native.create_tree_config(
        tree_config,
        merkle_tree,
        payer,
        tree_creator,
        max_depth,
        max_buffer_size,
        public
      )
    else
      {:error, reason} -> {:error, reason}
    end
  end

  @doc """
  Mints a new compressed NFT.

  ## Parameters

  * `tree_config` - The public key for the tree configuration account
  * `leaf_owner` - The public key of the leaf owner
  * `leaf_delegate` - The public key of the leaf delegate
  * `merkle_tree` - The public key for the merkle tree account
  * `payer` - The public key of the payer
  * `tree_creator_or_delegate` - The public key of the tree creator or delegate
  * `metadata` - The metadata for the NFT

  ## Returns

  * `{:ok, transaction}` - The serialized transaction
  * `{:error, reason}` - If an error occurs
  """
  def mint_v1(params) do
    with {:ok, tree_config} <- get_pubkey(params, :tree_config),
         {:ok, leaf_owner} <- get_pubkey(params, :leaf_owner),
         {:ok, leaf_delegate} <- get_pubkey(params, :leaf_delegate),
         {:ok, merkle_tree} <- get_pubkey(params, :merkle_tree),
         {:ok, payer} <- get_pubkey(params, :payer),
         {:ok, tree_creator_or_delegate} <- get_pubkey(params, :tree_creator_or_delegate),
         {:ok, metadata} <- validate_metadata(params[:metadata]) do
      Native.mint_v1(
        tree_config,
        leaf_owner,
        leaf_delegate,
        merkle_tree,
        payer,
        tree_creator_or_delegate,
        metadata
      )
    else
      {:error, reason} -> {:error, reason}
    end
  end

  @doc """
  Transfers a compressed NFT to a new owner.

  ## Parameters

  * `tree_config` - The public key for the tree configuration account
  * `leaf_owner` - The public key of the current leaf owner
  * `leaf_delegate` - The public key of the current leaf delegate
  * `new_leaf_owner` - The public key of the new leaf owner
  * `merkle_tree` - The public key for the merkle tree account
  * `root` - The current root of the merkle tree
  * `data_hash` - The data hash of the leaf
  * `creator_hash` - The creator hash of the leaf
  * `nonce` - The nonce of the leaf
  * `index` - The index of the leaf

  ## Returns

  * `{:ok, transaction}` - The serialized transaction
  * `{:error, reason}` - If an error occurs
  """
  def transfer(params) do
    with {:ok, tree_config} <- get_pubkey(params, :tree_config),
         {:ok, leaf_owner} <- get_pubkey(params, :leaf_owner),
         {:ok, leaf_delegate} <- get_pubkey(params, :leaf_delegate),
         {:ok, new_leaf_owner} <- get_pubkey(params, :new_leaf_owner),
         {:ok, merkle_tree} <- get_pubkey(params, :merkle_tree),
         {:ok, root} <- get_hash(params, :root),
         {:ok, data_hash} <- get_hash(params, :data_hash),
         {:ok, creator_hash} <- get_hash(params, :creator_hash),
         {:ok, nonce} <- get_integer(params, :nonce),
         {:ok, index} <- get_integer(params, :index) do
      Native.transfer(
        tree_config,
        leaf_owner,
        leaf_delegate,
        new_leaf_owner,
        merkle_tree,
        root,
        data_hash,
        creator_hash,
        nonce,
        index
      )
    else
      {:error, reason} -> {:error, reason}
    end
  end

  @doc """
  Computes the hash of NFT metadata.

  ## Parameters

  * `metadata` - The metadata to hash

  ## Returns

  * `{:ok, hash}` - The hash of the metadata
  * `{:error, reason}` - If an error occurs
  """
  def hash_metadata(metadata) do
    with {:ok, metadata} <- validate_metadata(metadata) do
      Native.hash_metadata(metadata)
    else
      {:error, reason} -> {:error, reason}
    end
  end

  @doc """
  Computes the hash of NFT creators.

  ## Parameters

  * `creators` - The creators to hash

  ## Returns

  * `{:ok, hash}` - The hash of the creators
  * `{:error, reason}` - If an error occurs
  """
  def hash_creators(creators) do
    with {:ok, creators} <- validate_creators(creators) do
      Native.hash_creators(creators)
    else
      {:error, reason} -> {:error, reason}
    end
  end

  @doc """
  Computes the asset ID of an asset given its tree and nonce values.

  ## Parameters

  * `tree` - The public key of the tree
  * `nonce` - The nonce of the asset

  ## Returns

  * `{:ok, asset_id}` - The asset ID
  * `{:error, reason}` - If an error occurs
  """
  def get_asset_id(tree, nonce) do
    with {:ok, tree} <- validate_pubkey(tree),
         {:ok, nonce} <- validate_integer(nonce) do
      Native.get_asset_id(tree, nonce)
    else
      {:error, reason} -> {:error, reason}
    end
  end

  # Helper functions for parameter validation

  defp get_pubkey(params, key) do
    case Map.get(params, key) do
      nil -> {:error, "Missing required parameter: #{key}"}
      %MplBubblegum.Types.Pubkey{} = pubkey -> {:ok, pubkey}
      value -> validate_pubkey(value)
    end
  end

  defp validate_pubkey(%MplBubblegum.Types.Pubkey{} = pubkey) do
    {:ok, pubkey}
  end

  defp validate_pubkey(pubkey) when is_binary(pubkey) and byte_size(pubkey) == 32 do
    {:ok, %MplBubblegum.Types.Pubkey{bytes: pubkey}}
  end

  defp validate_pubkey(_) do
    {:error, "Invalid public key format"}
  end

  defp get_integer(params, key) do
    case Map.get(params, key) do
      nil -> {:error, "Missing required parameter: #{key}"}
      value -> validate_integer(value)
    end
  end

  defp validate_integer(value) when is_integer(value) do
    {:ok, value}
  end

  defp validate_integer(_) do
    {:error, "Invalid integer format"}
  end

  defp get_hash(params, key) do
    case Map.get(params, key) do
      nil -> {:error, "Missing required parameter: #{key}"}
      value -> validate_hash(value)
    end
  end

  defp validate_hash(hash) when is_binary(hash) and byte_size(hash) == 32 do
    {:ok, hash}
  end

  defp validate_hash(_) do
    {:error, "Invalid hash format"}
  end

  defp validate_metadata(metadata) when is_map(metadata) do
    required_fields = [:name, :symbol, :uri, :seller_fee_basis_points]

    with :ok <- validate_required_fields(metadata, required_fields),
         {:ok, creators} <- validate_creators(Map.get(metadata, :creators, [])) do
      # Convert metadata to a format that can be passed to Rust
      {:ok, Map.put(metadata, :creators, creators)}
    else
      {:error, reason} -> {:error, reason}
    end
  end

  defp validate_metadata(_) do
    {:error, "Invalid metadata format"}
  end

  defp validate_required_fields(map, fields) do
    missing = Enum.filter(fields, fn field -> !Map.has_key?(map, field) end)

    if Enum.empty?(missing) do
      :ok
    else
      {:error, "Missing required fields: #{Enum.join(missing, ", ")}"}
    end
  end

  defp validate_creators(creators) when is_list(creators) do
    results = Enum.map(creators, &validate_creator/1)
    errors = Enum.filter(results, fn {status, _} -> status == :error end)

    if Enum.empty?(errors) do
      {:ok, Enum.map(results, fn {:ok, creator} -> creator end)}
    else
      {:error, "Invalid creators: #{inspect(errors)}"}
    end
  end

  defp validate_creators(_) do
    {:error, "Invalid creators format"}
  end

  defp validate_creator(%{address: address, share: share, verified: verified})
       when is_binary(address) and byte_size(address) == 32 and
              is_integer(share) and share >= 0 and share <= 100 and
              is_boolean(verified) do
    {:ok, %{address: address, share: share, verified: verified}}
  end

  defp validate_creator(_) do
    {:error, "Invalid creator format"}
  end
end
