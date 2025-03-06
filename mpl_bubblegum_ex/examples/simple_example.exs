# Simple example usage of the MplBubblegum library

alias MplBubblegum.Types.{Pubkey, Hash, Creator, Collection, Uses, Metadata}

# Load keypairs from files
IO.puts("Loading keypairs from files...")

# Load payer keypair
payer_json = Jason.decode!(File.read!("./payer.json"))
IO.puts("Payer JSON: #{inspect(payer_json)}")
payer_secret = Base.decode64!(payer_json["secret"])
payer_public = Base.decode64!(payer_json["public"])
payer_keypair = {payer_secret, payer_public}

# Load tree creator keypair
tree_creator_json = Jason.decode!(File.read!("./tree_creator.json"))
IO.puts("Tree creator JSON: #{inspect(tree_creator_json)}")
tree_creator_secret = Base.decode64!(tree_creator_json["secret"])
tree_creator_public = Base.decode64!(tree_creator_json["public"])
tree_creator_keypair = {tree_creator_secret, tree_creator_public}

# Extract public keys from keypairs
{_, payer_public_key} = payer_keypair
{_, tree_creator_public_key} = tree_creator_keypair

# Print keypair public keys
IO.puts("Payer public key: #{inspect(payer_public_key)}")
IO.puts("Tree creator public key: #{inspect(tree_creator_public_key)}")

payer_pubkey = Pubkey.from_bytes(payer_public_key)
tree_creator_pubkey = Pubkey.from_bytes(tree_creator_public_key)

IO.puts("Payer pubkey: #{inspect(payer_pubkey)}")
IO.puts("Tree creator pubkey: #{inspect(tree_creator_pubkey)}")

IO.puts("Payer base58: #{Pubkey.to_base58(payer_pubkey)}")
IO.puts("Tree creator base58: #{Pubkey.to_base58(tree_creator_pubkey)}")

# Example 1: Create a compressed merkle tree config
IO.puts("\nExample 1: Create a compressed merkle tree config")

# Generate random pubkeys for tree_config and merkle_tree
tree_config_keypair = Solana.Key.pair()
merkle_tree_keypair = Solana.Key.pair()

{_, tree_config_public_key} = tree_config_keypair
{_, merkle_tree_public_key} = merkle_tree_keypair

tree_config = Pubkey.from_bytes(tree_config_public_key)
merkle_tree = Pubkey.from_bytes(merkle_tree_public_key)
payer = Pubkey.from_bytes(payer_public_key)
tree_creator = Pubkey.from_bytes(tree_creator_public_key)

IO.puts("Tree config: #{inspect(tree_config)}")
IO.puts("Merkle tree: #{inspect(merkle_tree)}")
IO.puts("Payer: #{inspect(payer)}")
IO.puts("Tree creator: #{inspect(tree_creator)}")

create_tree_config_params = %{
  tree_config: tree_config.bytes,
  merkle_tree: merkle_tree.bytes,
  payer: payer.bytes,
  tree_creator: tree_creator.bytes,
  max_depth: 14,
  max_buffer_size: 64,
  public: true
}

IO.puts("Create tree config params: #{inspect(create_tree_config_params)}")

case MplBubblegum.create_tree_config(create_tree_config_params) do
  {:ok, transaction} ->
    IO.puts("Successfully created tree config transaction")
    IO.puts("Transaction: #{inspect(transaction)}")
    
    # Convert the transaction from a list of integers to a binary
    transaction_binary = if is_list(transaction), do: :binary.list_to_bin(transaction), else: transaction
    
    IO.puts("Transaction size: #{byte_size(transaction_binary)} bytes")
    
  {:error, reason} ->
    IO.puts("Error creating tree config: #{reason}")
end 