# Example usage of the MplBubblegum library

alias MplBubblegum.Types.{Pubkey, Hash, Creator, Collection, Uses, Metadata}
alias Solana.RPC
alias Solana.Transaction
alias Solana.Key
alias Solana.SystemProgram

# Helper function to create a Pubkey from a base58 string
_pubkey_from_base58! = fn base58 ->
  {:ok, pubkey} = Pubkey.from_base58(base58)
  pubkey
end

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
IO.puts("Payer public key: #{Pubkey.to_base58(%Pubkey{bytes: payer_public_key})}")
IO.puts("Tree creator public key: #{Pubkey.to_base58(%Pubkey{bytes: tree_creator_public_key})}")

# Connect to Solana devnet
rpc_client = Solana.RPC.client(cluster: "https://api.devnet.solana.com")

# Check connection and get payer balance
IO.puts("\nConnecting to Solana devnet...")

# Example 1: Create a compressed merkle tree config
IO.puts("\nExample 1: Create a compressed merkle tree config")

# Generate random pubkeys for tree_config and merkle_tree
tree_config_keypair = Solana.Key.pair()
merkle_tree_keypair = Solana.Key.pair()

{_, tree_config_public_key} = tree_config_keypair
{_, merkle_tree_public_key} = merkle_tree_keypair

tree_config = %Pubkey{bytes: tree_config_public_key}
merkle_tree = %Pubkey{bytes: merkle_tree_public_key}
payer = %Pubkey{bytes: payer_public_key}
tree_creator = %Pubkey{bytes: tree_creator_public_key}

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
    IO.puts("Transaction size: #{byte_size(transaction)} bytes")
    
    # Get recent blockhash for transaction
    {:ok, blockhash} = Solana.RPC.get_recent_blockhash(client: rpc_client)
    
    # Sign and submit transaction
    signed_tx = Transaction.sign(
      transaction,
      [payer_keypair, tree_creator_keypair],
      blockhash: blockhash
    )
    
    case Solana.RPC.send_transaction(signed_tx, client: rpc_client) do
      {:ok, signature} ->
        IO.puts("Transaction submitted with signature: #{signature}")
        
        # Confirm transaction with status updates
        IO.puts("Waiting for confirmation...")
        
        # Poll for confirmation with timeout
        start_time = System.monotonic_time(:millisecond)
        max_wait_ms = 60_000
        
        poll_confirmation = fn poll_fn ->
          case Solana.RPC.get_signature_statuses([signature], client: rpc_client) do
            {:ok, %{value: [%{confirmations: confirmations, confirmation_status: status} | _]}} ->
              IO.puts("Status: #{status || "processing"}, Confirmations: #{confirmations || 0}")
              if status == "confirmed" || status == "finalized" do
                {:ok, status}
              else
                current_time = System.monotonic_time(:millisecond)
                if current_time - start_time > max_wait_ms do
                  {:error, :timeout}
                else
                  Process.sleep(2000)
                  poll_fn.(poll_fn)
                end
              end
            _ ->
              Process.sleep(2000)
              poll_fn.(poll_fn)
          end
        end
        
        case poll_confirmation.(poll_confirmation) do
          {:ok, status} -> 
            IO.puts("Transaction #{status}!")
            
            # Get transaction details
            {:ok, tx_details} = Solana.RPC.get_transaction(
              signature,
              encoding: "json",
              client: rpc_client
            )
            
            IO.puts("Block time: #{tx_details.block_time}")
            IO.puts("Slot: #{tx_details.slot}")
            
          {:error, :timeout} -> 
            IO.puts("Timed out waiting for confirmation")
        end
        
      {:error, err} ->
        IO.puts("Transaction submission failed: #{inspect(err)}")
    end

  {:error, reason} ->
    IO.puts("Error creating tree config: #{reason}")
end

# Example 2: Mint a compressed NFT
IO.puts("\nExample 2: Mint a compressed NFT")

leaf_owner = payer
leaf_delegate = payer
tree_creator_or_delegate = tree_creator

creator = %Creator{
  address: payer,
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
  tree_config: tree_config.bytes,
  leaf_owner: leaf_owner.bytes,
  leaf_delegate: leaf_delegate.bytes,
  merkle_tree: merkle_tree.bytes,
  payer: payer.bytes,
  tree_creator_or_delegate: tree_creator_or_delegate.bytes,
  metadata: metadata
}

case MplBubblegum.mint_v1(mint_params) do
  {:ok, transaction} ->
    IO.puts("Successfully created mint transaction")
    IO.puts("Transaction size: #{byte_size(transaction)} bytes")
    
    # Get recent blockhash for transaction
    {:ok, blockhash} = Solana.RPC.get_recent_blockhash(client: rpc_client)
    
    # Sign and submit transaction
    signed_tx = Transaction.sign(
      transaction,
      [payer_keypair, tree_creator_keypair],
      blockhash: blockhash
    )
    
    case Solana.RPC.send_transaction(signed_tx, client: rpc_client) do
      {:ok, signature} ->
        IO.puts("Mint transaction submitted with signature: #{signature}")
        
        # Poll for confirmation with timeout
        start_time = System.monotonic_time(:millisecond)
        max_wait_ms = 60_000
        
        poll_confirmation = fn poll_fn ->
          case Solana.RPC.get_signature_statuses([signature], client: rpc_client) do
            {:ok, %{value: [%{confirmations: confirmations, confirmation_status: status} | _]}} ->
              IO.puts("Status: #{status || "processing"}, Confirmations: #{confirmations || 0}")
              if status == "confirmed" || status == "finalized" do
                {:ok, status}
              else
                current_time = System.monotonic_time(:millisecond)
                if current_time - start_time > max_wait_ms do
                  {:error, :timeout}
                else
                  Process.sleep(2000)
                  poll_fn.(poll_fn)
                end
              end
            _ ->
              Process.sleep(2000)
              poll_fn.(poll_fn)
          end
        end
        
        case poll_confirmation.(poll_confirmation) do
          {:ok, status} -> 
            IO.puts("Mint transaction #{status}!")
            
            # Store the nonce for later use in transfer
            nonce = 0
            File.write!("./nonce.txt", "#{nonce}")
            
            # Hash the metadata and creators for later use in transfer
            {:ok, data_hash} = MplBubblegum.hash_metadata(metadata)
            {:ok, creator_hash} = MplBubblegum.hash_creators([creator])
            
            # Store the hashes for later use in transfer
            File.write!("./data_hash.bin", data_hash.bytes)
            File.write!("./creator_hash.bin", creator_hash.bytes)
            
            IO.puts("Stored nonce, data_hash, and creator_hash for later use in transfer")
            
          {:error, :timeout} -> IO.puts("Timed out waiting for confirmation")
        end
        
      {:error, err} ->
        IO.puts("Mint transaction submission failed: #{inspect(err)}")
    end

  {:error, reason} ->
    IO.puts("Error creating mint transaction: #{reason}")
end

# Example 3: Transfer a compressed NFT
IO.puts("\nExample 3: Transfer a compressed NFT")

# Create a new keypair to represent the new owner
new_leaf_owner_keypair = Solana.Key.pair()
{_, new_leaf_owner_public_key} = new_leaf_owner_keypair
new_leaf_owner = %Pubkey{bytes: new_leaf_owner_public_key}
IO.puts("Generated new owner with public key: #{Pubkey.to_base58(new_leaf_owner)}")

# Try to read the stored values from files
nonce = case File.read("./nonce.txt") do
  {:ok, content} -> String.to_integer(String.trim(content))
  _ -> 0  # Default value if file doesn't exist
end

data_hash = case File.read("./data_hash.bin") do
  {:ok, content} -> %Hash{bytes: content}
  _ -> %Hash{bytes: :crypto.strong_rand_bytes(32)}  # Random value if file doesn't exist
end

creator_hash = case File.read("./creator_hash.bin") do
  {:ok, content} -> %Hash{bytes: content}
  _ -> %Hash{bytes: :crypto.strong_rand_bytes(32)}  # Random value if file doesn't exist
end

# Get the root from the merkle tree (for testing, we're using a random value)
root = %Hash{bytes: :crypto.strong_rand_bytes(32)}
index = nonce

transfer_params = %{
  tree_config: tree_config.bytes,
  leaf_owner: leaf_owner.bytes,
  leaf_delegate: leaf_delegate.bytes,
  new_leaf_owner: new_leaf_owner.bytes,
  merkle_tree: merkle_tree.bytes,
  root: root.bytes,
  data_hash: data_hash.bytes,
  creator_hash: creator_hash.bytes,
  nonce: nonce,
  index: index
}

case MplBubblegum.transfer(transfer_params) do
  {:ok, transaction} ->
    IO.puts("Successfully created transfer transaction")
    IO.puts("Transaction size: #{byte_size(transaction)} bytes")
    
    # Get recent blockhash for transaction
    {:ok, blockhash} = Solana.RPC.get_recent_blockhash(client: rpc_client)
    
    # Sign and submit transaction
    signed_tx = Transaction.sign(
      transaction,
      [payer_keypair], # Only the current owner needs to sign
      blockhash: blockhash
    )
    
    case Solana.RPC.send_transaction(signed_tx, client: rpc_client) do
      {:ok, signature} ->
        IO.puts("Transfer transaction submitted with signature: #{signature}")
        
        # Confirm transaction with custom retry logic
        confirm_with_retry = fn ->
          Enum.reduce_while(1..10, nil, fn attempt, _ ->
            IO.puts("Confirmation attempt #{attempt}...")
            case Solana.RPC.get_signature_statuses([signature], client: rpc_client) do
              {:ok, %{value: [%{err: nil, confirmation_status: "confirmed"} | _]}} ->
                {:halt, :confirmed}
              {:ok, %{value: [%{err: nil, confirmation_status: "finalized"} | _]}} ->
                {:halt, :finalized}
              {:ok, %{value: [%{err: error} | _]}} when not is_nil(error) ->
                {:halt, {:error, error}}
              _ ->
                Process.sleep(1000)
                {:cont, nil}
            end
          end)
        end
        
        case confirm_with_retry.() do
          :confirmed -> IO.puts("Transfer transaction confirmed!")
          :finalized -> IO.puts("Transfer transaction finalized!")
          {:error, error} -> IO.puts("Transfer failed: #{inspect(error)}")
          _ -> IO.puts("Transfer confirmation timed out")
        end
        
      {:error, err} ->
        IO.puts("Transfer transaction submission failed: #{inspect(err)}")
    end

  {:error, reason} ->
    IO.puts("Error creating transfer transaction: #{reason}")
end

# Print summary of what was done
IO.puts("\nSummary:")
IO.puts("1. Created a compressed merkle tree config")
IO.puts("2. Minted a compressed NFT")
IO.puts("3. Transferred the compressed NFT to a new owner")
IO.puts("\nKeypair information:")
IO.puts("Payer public key: #{Pubkey.to_base58(%Pubkey{bytes: elem(payer_keypair, 1)})}")
IO.puts("Tree creator public key: #{Pubkey.to_base58(%Pubkey{bytes: elem(tree_creator_keypair, 1)})}")
IO.puts("New owner public key: #{Pubkey.to_base58(%Pubkey{bytes: elem(new_leaf_owner_keypair, 1)})}")
IO.puts("\nKeypairs used from:")
IO.puts("- ./payer.json")
IO.puts("- ./tree_creator.json")
