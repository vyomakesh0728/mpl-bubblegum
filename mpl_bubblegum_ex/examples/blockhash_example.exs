alias Solana.RPC

# Connect to Solana devnet
IO.puts("Connecting to Solana devnet...")
client = RPC.client(network: "devnet")

# Get latest blockhash
IO.puts("\nGetting latest blockhash...")
request = {"getLatestBlockhash", []}

case RPC.send(client, request) do
  {:ok, %{"blockhash" => blockhash}} ->
    IO.puts("Got latest blockhash: #{blockhash}")

  {:error, error} ->
    IO.puts("Error getting latest blockhash: #{inspect(error)}")
end

IO.puts("\nExample completed.")