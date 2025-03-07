# Example usage of the MplBubblegum library
# This example demonstrates creating, signing, and submitting a compressed NFT tree configuration transaction

alias MplBubblegum.Types.Pubkey
alias Solana.Key
alias Solana.RPC
alias Solana.Transaction

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

# Connect to Solana devnet
IO.puts("\nConnecting to Solana devnet...")
client = Solana.RPC.client(network: "devnet")

# Example: Create a compressed merkle tree config
IO.puts("\nCreating a compressed merkle tree config transaction...")

# Generate random pubkeys for tree_config and merkle_tree
tree_config_keypair = Key.pair()
merkle_tree_keypair = Key.pair()

{_, tree_config_public_key} = tree_config_keypair
{_, merkle_tree_public_key} = merkle_tree_keypair

# Create Pubkey structs
tree_config = Pubkey.from_bytes(tree_config_public_key)
merkle_tree = Pubkey.from_bytes(merkle_tree_public_key)
payer = Pubkey.from_bytes(payer_public_key)
tree_creator = Pubkey.from_bytes(tree_creator_public_key)

IO.puts("Tree config pubkey: #{Pubkey.to_base58(tree_config)}")
IO.puts("Merkle tree pubkey: #{Pubkey.to_base58(merkle_tree)}")

# Create the parameters map for create_tree_config
# Pass the bytes directly, not the Pubkey structs
create_tree_config_params = %{
  tree_config: tree_config.bytes,
  merkle_tree: merkle_tree.bytes,
  payer: payer.bytes,
  tree_creator: tree_creator.bytes,
  max_depth: 14,
  max_buffer_size: 64,
  public: true
}

# Add this before creating the params map
IO.inspect(byte_size(tree_config.bytes), label: "Tree config bytes size")
IO.inspect(tree_config.bytes, label: "Tree config raw bytes")
IO.inspect(byte_size(merkle_tree.bytes), label: "Merkle tree bytes size")
IO.inspect(byte_size(payer.bytes), label: "Payer bytes size")
IO.inspect(byte_size(tree_creator.bytes), label: "Tree creator bytes size")

case MplBubblegum.create_tree_config(create_tree_config_params) do
  {:ok, transaction} ->
    IO.puts("Successfully created tree config transaction")
    
    # Convert the transaction from a list of integers to a binary if needed
    transaction_binary = if is_list(transaction), do: :binary.list_to_bin(transaction), else: transaction
    
    IO.puts("Transaction size: #{byte_size(transaction_binary)} bytes")
    
    # For demonstration purposes, we'll print the first 20 bytes of the transaction
    first_20_bytes = transaction_binary |> binary_part(0, min(20, byte_size(transaction_binary)))
    IO.puts("First 20 bytes of transaction: #{inspect(first_20_bytes)}")
    
    # Get a recent blockhash from the Solana network - FIXED VERSION
    IO.puts("\nGetting recent blockhash...")
    case Solana.RPC.get_latest_blockhash(client) do
      {:ok, %{blockhash: blockhash}} ->
        IO.puts("Got recent blockhash: #{blockhash}")
        
        IO.puts("\nPreparing to sign and submit transaction...")
        
        # Transaction is already in binary format from the Rust NIF
        IO.puts("\nSubmitting transaction to Solana devnet...")
        
        # Encode the transaction in base64 for logging purposes
        transaction_base64 = Base.encode64(transaction_binary)
        
        # Submit the transaction using the Solana RPC client with send_transaction
        send_tx_request = Solana.RPC.Request.send_transaction(transaction_binary, encoding: "base58")
        case Solana.RPC.send(send_tx_request, client) do
          {:ok, signature} ->
            IO.puts("Transaction submitted with signature: #{signature}")
            
            # Wait for confirmation
            IO.puts("\nWaiting for confirmation...")
            
            # Poll for confirmation using Transaction.check
            confirmed = Enum.reduce_while(1..10, false, fn attempt, _ ->
              IO.puts("Checking confirmation (attempt #{attempt}/10)...")
              Process.sleep(1000)  # Wait 1 second between checks
              
              case Transaction.check(signature, client: client) do
                {:ok, ^signature} ->
                  IO.puts("Transaction confirmed!")
                  {:halt, true}
                {:error, :not_found} ->
                  IO.puts("Transaction still processing...")
                  {:cont, false}
                {:error, error} ->
                  IO.puts("Error checking transaction: #{inspect(error)}")
                  {:cont, false}
              end
            end)
            
            if confirmed do
              IO.puts("\nTransaction confirmed successfully!")
              IO.puts("Transaction address: #{signature}")
              
              # Get transaction details
              IO.puts("\nGetting transaction details...")
              
              # Use the Solana RPC client to get transaction details
              tx_details_request = Solana.RPC.Request.get_transaction(signature, encoding: "json")
              tx_details_result = Solana.RPC.send(tx_details_request, client)
              
              # Print transaction details
              case tx_details_result do
                {:ok, tx_details} when not is_nil(tx_details) ->
                  IO.puts("Transaction details:")
                  IO.puts("  Block time: #{tx_details["blockTime"]}")
                  IO.puts("  Slot: #{tx_details["slot"]}")
                  IO.puts("  Fee: #{tx_details["meta"]["fee"]}")
                {:error, error} ->
                  IO.puts("Error getting transaction details: #{inspect(error)}")
                _ ->
                  IO.puts("Transaction details not available")
              end
            else
              IO.puts("\nTransaction confirmation timed out")
              IO.puts("You can check the status later using:")
              IO.puts("Transaction.check(\"#{signature}\", client: client)")
            end
            
          {:error, error} ->
            IO.puts("Error sending transaction: #{inspect(error)}")
        end
        
      {:error, error} ->
        IO.puts("Error getting recent blockhash: #{inspect(error)}")
    end
    
  {:error, reason} ->
    IO.puts("Error creating tree config: #{reason}")
end

IO.puts("\nExample completed.")
IO.puts("This example demonstrates the complete process of creating and submitting a transaction to Solana devnet.")
IO.puts("The transaction was created using the Rust NIFs and submitted using the Solana Elixir library.")
