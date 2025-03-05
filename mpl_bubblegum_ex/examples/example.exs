# Example usage of the MplBubblegum library

alias MplBubblegum.Types.{Pubkey, Hash, Creator, Collection, Uses, Metadata}

# Helper function to create a Pubkey from a base58 string
defp pubkey_from_base58!(base58) do
  {:ok, pubkey} = Pubkey.from_base58(base58)
  pubkey
end

# Example 1: Create a compressed merkle tree config
IO.puts("Example 1: Create a compressed merkle tree config")

tree_config = pubkey_from_base58!("11111111111111111111111111111111")
merkle_tree = pubkey_from_base58!("22222222222222222222222222222222")
payer = pubkey_from_base58!("33333333333333333333333333333333")
tree_creator = pubkey_from_base58!("44444444444444444444444444444444")

create_tree_config_params = %{
  tree_config: tree_config,
  merkle_tree: merkle_tree,
  payer: payer,
  tree_creator: tree_creator,
  max_depth: 14,
  max_buffer_size: 64,
  public: true
}

case MplBubblegum.create_tree_config(create_tree_config_params) do
  {:ok, transaction} ->
    IO.puts("Successfully created tree config transaction")
    IO.puts("Transaction size: #{byte_size(transaction)} bytes")

  {:error, reason} ->
    IO.puts("Error creating tree config: #{reason}")
end

# Example 2: Mint a compressed NFT
IO.puts("\nExample 2: Mint a compressed NFT")

leaf_owner = pubkey_from_base58!("55555555555555555555555555555555")
leaf_delegate = pubkey_from_base58!("55555555555555555555555555555555")
tree_creator_or_delegate = pubkey_from_base58!("44444444444444444444444444444444")

creator = %Creator{
  address: pubkey_from_base58!("66666666666666666666666666666666"),
  verified: false,
  share: 100
}

metadata = %Metadata{
  name: "My Compressed NFT",
  symbol: "CNFT",
  uri: "https://example.com/metadata.json",
  seller_fee_basis_points: 500,
  primary_sale_happened: false,
  is_mutable: true,
  edition_nonce: nil,
  token_standard: Metadata.non_fungible(),
  collection: nil,
  uses: nil,
  token_program_version: Metadata.original(),
  creators: [creator]
}

mint_params = %{
  tree_config: tree_config,
  leaf_owner: leaf_owner,
  leaf_delegate: leaf_delegate,
  merkle_tree: merkle_tree,
  payer: payer,
  tree_creator_or_delegate: tree_creator_or_delegate,
  metadata: metadata
}

case MplBubblegum.mint_v1(mint_params) do
  {:ok, transaction} ->
    IO.puts("Successfully created mint transaction")
    IO.puts("Transaction size: #{byte_size(transaction)} bytes")

  {:error, reason} ->
    IO.puts("Error creating mint transaction: #{reason}")
end

# Example 3: Transfer a compressed NFT
IO.puts("\nExample 3: Transfer a compressed NFT")

new_leaf_owner = pubkey_from_base58!("77777777777777777777777777777777")

# These values would normally be obtained from the blockchain
root = :crypto.strong_rand_bytes(32)
data_hash = :crypto.strong_rand_bytes(32)
creator_hash = :crypto.strong_rand_bytes(32)
nonce = 0
index = 0

transfer_params = %{
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
}

case MplBubblegum.transfer(transfer_params) do
  {:ok, transaction} ->
    IO.puts("Successfully created transfer transaction")
    IO.puts("Transaction size: #{byte_size(transaction)} bytes")

  {:error, reason} ->
    IO.puts("Error creating transfer transaction: #{reason}")
end

# Example 4: Hash metadata
IO.puts("\nExample 4: Hash metadata")

case MplBubblegum.hash_metadata(metadata) do
  {:ok, hash} ->
    IO.puts("Metadata hash: #{Hash.to_hex(hash)}")

  {:error, reason} ->
    IO.puts("Error hashing metadata: #{reason}")
end

# Example 5: Hash creators
IO.puts("\nExample 5: Hash creators")

case MplBubblegum.hash_creators([creator]) do
  {:ok, hash} ->
    IO.puts("Creators hash: #{Hash.to_hex(hash)}")

  {:error, reason} ->
    IO.puts("Error hashing creators: #{reason}")
end

# Example 6: Get asset ID
IO.puts("\nExample 6: Get asset ID")

case MplBubblegum.get_asset_id(merkle_tree, nonce) do
  {:ok, asset_id} ->
    IO.puts("Asset ID: #{Pubkey.to_base58(asset_id)}")

  {:error, reason} ->
    IO.puts("Error getting asset ID: #{reason}")
end
