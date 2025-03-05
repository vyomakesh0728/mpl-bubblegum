# MplBubblegum

Elixir NIFs for the Metaplex Bubblegum program, enabling Elixir developers to construct and send compressed NFT transactions on Solana.

## Features

- Create/initialize compressed merkle tree configurations
- Mint compressed NFTs
- Transfer compressed NFTs
- Utility functions for hashing metadata and creators
- Utility function for getting asset IDs

## Installation

The package can be installed by adding `mpl_bubblegum` to your list of dependencies in `mix.exs`:

```elixir
def deps do
  [
    {:mpl_bubblegum, "~> 0.1.0"}
  ]
end
```

## Usage

### Creating a Compressed Merkle Tree Config

```elixir
alias MplBubblegum.Types.Pubkey

# Create public keys from base58 strings
{:ok, tree_config} = Pubkey.from_base58("...")
{:ok, merkle_tree} = Pubkey.from_base58("...")
{:ok, payer} = Pubkey.from_base58("...")
{:ok, tree_creator} = Pubkey.from_base58("...")

# Create the tree config transaction
params = %{
  tree_config: tree_config,
  merkle_tree: merkle_tree,
  payer: payer,
  tree_creator: tree_creator,
  max_depth: 14,
  max_buffer_size: 64,
  public: true
}

case MplBubblegum.create_tree_config(params) do
  {:ok, transaction} ->
    # Send the transaction to the Solana network
    # ...

  {:error, reason} ->
    IO.puts("Error: #{reason}")
end
```

### Minting a Compressed NFT

```elixir
alias MplBubblegum.Types.{Pubkey, Creator, Metadata}

# Create the metadata for the NFT
creator = %Creator{
  address: payer,
  verified: true,
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

# Create the mint transaction
params = %{
  tree_config: tree_config,
  leaf_owner: owner,
  leaf_delegate: owner,
  merkle_tree: merkle_tree,
  payer: payer,
  tree_creator_or_delegate: tree_creator,
  metadata: metadata
}

case MplBubblegum.mint_v1(params) do
  {:ok, transaction} ->
    # Send the transaction to the Solana network
    # ...

  {:error, reason} ->
    IO.puts("Error: #{reason}")
end
```

### Transferring a Compressed NFT

```elixir
alias MplBubblegum.Types.Pubkey

{:ok, new_owner} = Pubkey.from_base58("...")

# These values would normally be obtained from the blockchain
root = ...
data_hash = ...
creator_hash = ...
nonce = ...
index = ...

# Create the transfer transaction
params = %{
  tree_config: tree_config,
  leaf_owner: owner,
  leaf_delegate: owner,
  new_leaf_owner: new_owner,
  merkle_tree: merkle_tree,
  root: root,
  data_hash: data_hash,
  creator_hash: creator_hash,
  nonce: nonce,
  index: index
}

case MplBubblegum.transfer(params) do
  {:ok, transaction} ->
    # Send the transaction to the Solana network
    # ...

  {:error, reason} ->
    IO.puts("Error: #{reason}")
end
```

### Utility Functions

```elixir
# Hash metadata
{:ok, metadata_hash} = MplBubblegum.hash_metadata(metadata)

# Hash creators
{:ok, creators_hash} = MplBubblegum.hash_creators([creator])

# Get asset ID
{:ok, asset_id} = MplBubblegum.get_asset_id(merkle_tree, nonce)
```

## Examples

See the [examples](examples) directory for more examples.

## License

This project is licensed under the MIT License - see the [LICENSE](LICENSE) file for details.
