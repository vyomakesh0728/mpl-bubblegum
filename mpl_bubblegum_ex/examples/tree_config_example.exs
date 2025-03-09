# Example: Creating a compressed Merkle tree config and submitting it to Solana Devnet

alias MplBubblegum.Types.Pubkey
alias MplBubblegum.KeypairLoader

# Load payer keypair
{:ok, payer_json} = KeypairLoader.load_keypair("payer.json")
payer_secret = payer_json["secret"]
{:ok, payer} = Pubkey.from_base58(payer_json["public"])

# Load tree creator keypair
{:ok, tree_creator_json} = KeypairLoader.load_keypair("tree_creator.json")
{:ok, tree_creator} = Pubkey.from_base58(tree_creator_json["public"])

# Load tree config keypair
{:ok, tree_config_json} = KeypairLoader.load_keypair("tree_config.json")
{:ok, tree_config} = Pubkey.from_base58(tree_config_json["public"])

# Load merkle tree keypair
{:ok, merkle_tree_json} = KeypairLoader.load_keypair("merkle_tree.json")
{:ok, merkle_tree} = Pubkey.from_base58(merkle_tree_json["public"])

# Create tree config transaction
params = %{
  tree_config: tree_config,
  merkle_tree: merkle_tree,
  payer: payer,
  tree_creator: tree_creator,
  max_depth: 14,
  max_buffer_size: 64,
  public: true
}

IO.puts("Creating tree config with pubkeys:")
IO.puts("- Payer: #{payer_json["public"]}")
IO.puts("- Tree Creator: #{tree_creator_json["public"]}")
IO.puts("- Tree Config: #{tree_config_json["public"]}")
IO.puts("- Merkle Tree: #{merkle_tree_json["public"]}")

# Create and sign the transaction
case MplBubblegum.create_tree_config(params) do
  {:ok, transaction} ->
    transaction_binary = :binary.list_to_bin(transaction)
    IO.puts("Transaction created (size: #{byte_size(transaction_binary)} bytes). Signing and submitting...")
    case MplBubblegum.sign_and_submit_transaction(transaction_binary, payer_secret) do
      {:ok, signature} ->
        IO.puts("Transaction submitted with signature: #{signature}")
        Process.sleep(2000) # Wait for confirmation
        case MplBubblegum.get_transaction_status(signature) do
          {:ok, "confirmed"} -> IO.puts("Transaction confirmed!")
          {:ok, status} -> IO.puts("Transaction status: #{status}")
          {:error, reason} -> IO.puts("Failed to check status: #{reason}")
        end
      {:error, reason} ->
        IO.puts("Failed to submit transaction: #{reason}")
    end
  {:error, reason} ->
    IO.puts("Failed to create transaction: #{reason}")
end