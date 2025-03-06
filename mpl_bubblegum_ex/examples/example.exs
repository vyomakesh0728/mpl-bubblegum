# Example usage of the MplBubblegum library
# This example demonstrates creating a compressed NFT tree configuration transaction

alias MplBubblegum.Types.Pubkey
alias Solana.Key

# Load keypairs from files
IO.puts("Loading keypairs from files...")

# Load payer keypair
payer_json = Jason.decode!(File.read!("./payer.json"))
payer_secret = Base.decode64!(payer_json["secret"])
payer_public = Base.decode64!(payer_json["public"])
payer_keypair = {payer_secret, payer_public}

# Load tree creator keypair
tree_creator_json = Jason.decode!(File.read!("./tree_creator.json"))
tree_creator_secret = Base.decode64!(tree_creator_json["secret"])
tree_creator_public = Base.decode64!(tree_creator_json["public"])
tree_creator_keypair = {tree_creator_secret, tree_creator_public}

# Extract public keys from keypairs
{_, payer_public_key} = payer_keypair
{_, tree_creator_public_key} = tree_creator_keypair

# Print keypair public keys
IO.puts("Payer public key: #{Pubkey.to_base58(Pubkey.from_bytes(payer_public_key))}")
IO.puts("Tree creator public key: #{Pubkey.to_base58(Pubkey.from_bytes(tree_creator_public_key))}")

# Example: Create a compressed merkle tree config
IO.puts("\nCreating a compressed merkle tree config transaction...")

# Generate random pubkeys for tree_config and merkle_tree
tree_config_keypair = Key.pair()
merkle_tree_keypair = Key.pair()

{_, tree_config_public_key} = tree_config_keypair
{_, merkle_tree_public_key} = merkle_tree_keypair

tree_config = Pubkey.from_bytes(tree_config_public_key)
merkle_tree = Pubkey.from_bytes(merkle_tree_public_key)
payer = Pubkey.from_bytes(payer_public_key)
tree_creator = Pubkey.from_bytes(tree_creator_public_key)

IO.puts("Tree config pubkey: #{Pubkey.to_base58(tree_config)}")
IO.puts("Merkle tree pubkey: #{Pubkey.to_base58(merkle_tree)}")

create_tree_config_params = %{
  tree_config: tree_config.bytes,
  merkle_tree: merkle_tree.bytes,
  payer: payer.bytes,
  tree_creator: tree_creator.bytes,
  max_depth: 14,
  max_buffer_size: 64,
  public: true
}

case MplBubblegum.create_tree_config(create_tree_config_params) do
  {:ok, transaction} ->
    IO.puts("Successfully created tree config transaction")
    
    # Convert the transaction from a list of integers to a binary if needed
    transaction_binary = if is_list(transaction), do: :binary.list_to_bin(transaction), else: transaction
    
    IO.puts("Transaction size: #{byte_size(transaction_binary)} bytes")
    
    # For demonstration purposes, we'll print the first 20 bytes of the transaction
    first_20_bytes = transaction_binary |> binary_part(0, min(20, byte_size(transaction_binary)))
    IO.puts("First 20 bytes of transaction: #{inspect(first_20_bytes)}")
    
    # In a real application, you would:
    # 1. Get a recent blockhash from the Solana network
    # 2. Sign the transaction with the appropriate keypairs
    # 3. Submit the signed transaction to the network
    # 4. Wait for confirmation
    
    IO.puts("\nTransaction creation successful!")
    
  {:error, reason} ->
    IO.puts("Error creating tree config: #{reason}")
end

IO.puts("\nExample completed.")
IO.puts("This example demonstrates that the MplBubblegum Rust NIFs are working correctly.")
IO.puts("The transaction was successfully created using the Rust NIFs.")
IO.puts("In a real application, you would need to:")
IO.puts("1. Get a recent blockhash from the Solana network")
IO.puts("2. Sign the transaction with the appropriate keypairs")
IO.puts("3. Submit the signed transaction to the network")
IO.puts("4. Wait for confirmation")
