defmodule MplBubblegum do
  @moduledoc """
  Elixir interface for the Metaplex Bubblegum program.
  
  This module provides functions to interact with the Solana blockchain
  for creating and managing compressed NFTs using the Metaplex Bubblegum program.
  """

  alias MplBubblegum.Native
  alias MplBubblegum.Types.Pubkey
  alias MplBubblegum.Native.Pubkey, as: RustPubkey

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
  def create_tree_config(%{
        tree_config: tree_config,
        merkle_tree: merkle_tree,
        payer: payer,
        tree_creator: tree_creator,
        max_depth: max_depth,
        max_buffer_size: max_buffer_size,
        public: public
      }) do
    # Call the Rust NIF function
    Native.create_tree_config(
      tree_config,
      merkle_tree,
      payer,
      tree_creator,
      max_depth,
      max_buffer_size,
      public
    )
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
  def mint_v1(%{
        tree_config: tree_config,
        leaf_owner: leaf_owner,
        leaf_delegate: leaf_delegate,
        merkle_tree: merkle_tree,
        payer: payer,
        tree_creator_or_delegate: tree_creator_or_delegate,
        metadata: metadata
      }) do
    # Call the Rust NIF function
    Native.mint_v1(
      tree_config,
      leaf_owner,
      leaf_delegate,
      merkle_tree,
      payer,
      tree_creator_or_delegate,
      metadata
    )
  end

  @doc """
  Transfers a compressed NFT.

  ## Parameters

  * `tree_config` - The public key for the tree configuration account
  * `leaf_owner` - The public key of the leaf owner
  * `leaf_delegate` - The public key of the leaf delegate
  * `new_leaf_owner` - The public key of the new leaf owner
  * `merkle_tree` - The public key for the merkle tree account
  * `root` - The root hash of the merkle tree
  * `data_hash` - The data hash of the leaf
  * `creator_hash` - The creator hash of the leaf
  * `nonce` - The nonce of the leaf
  * `index` - The index of the leaf

  ## Returns

  * `{:ok, transaction}` - The serialized transaction
  * `{:error, reason}` - If an error occurs
  """
  def transfer(%{
        tree_config: tree_config,
        leaf_owner: leaf_owner,
        leaf_delegate: leaf_delegate,
        new_leaf_owner: new_leaf_owner,
        merkle_tree: merkle_tree,
        root: root,
        data_hash: data_hash,
        creator_hash: creator_hash,
        nonce: nonce,
        index: index
      }) do
    # Call the Rust NIF function
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
  end

  @doc """
  Hashes the metadata of an NFT.

  ## Parameters

  * `metadata` - The metadata to hash

  ## Returns

  * `{:ok, hash}` - The hash of the metadata
  * `{:error, reason}` - If an error occurs
  """
  def hash_metadata(metadata) do
    Native.hash_metadata(metadata)
  end

  @doc """
  Hashes the creators of an NFT.

  ## Parameters

  * `creators` - The creators to hash

  ## Returns

  * `{:ok, hash}` - The hash of the creators
  * `{:error, reason}` - If an error occurs
  """
  def hash_creators(creators) do
    Native.hash_creators(creators)
  end

  @doc """
  Gets the asset ID for a leaf.

  ## Parameters

  * `tree` - The public key of the merkle tree
  * `nonce` - The nonce of the leaf

  ## Returns

  * `{:ok, asset_id}` - The asset ID
  * `{:error, reason}` - If an error occurs
  """
  def get_asset_id(tree, nonce) do
    Native.get_asset_id(tree, nonce)
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

  defp get_metadata(params, key) do
    case Map.get(params, key) do
      nil -> {:error, "Missing required parameter: #{key}"}
      value -> validate_metadata(value)
    end
  end

  defp validate_metadata(%MplBubblegum.Types.Metadata{} = metadata) do
    {:ok, metadata}
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
