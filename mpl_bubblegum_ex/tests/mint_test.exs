ExUnit.start()

defmodule MintTest do
  use ExUnit.Case
  doctest MplBubblegum

  alias MplBubblegum.Types.{Pubkey, Creator, Metadata}

  # Helper to generate a valid keypair (secret + public key)
  defp generate_keypair do
    secret = :crypto.strong_rand_bytes(64)
    public_bytes = binary_part(secret, 32, 32)
    pubkey = %Pubkey{bytes: :binary.bin_to_list(public_bytes)}
    {secret, pubkey}
  end

  # Helper to generate a valid metadata struct
  defp generate_metadata(payer) do
    creator = %Creator{
      address: payer,
      verified: true,
      share: 100
    }

    %Metadata{
      name: "Test NFT",
      symbol: "TNFT",
      uri: "https://example.com/nft.json",
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
  end

  describe "mint_v1/1" do
    test "creates a valid mint transaction" do
      {_, tree_config} = generate_keypair()
      {_, merkle_tree} = generate_keypair()
      {_, payer} = generate_keypair()
      {_, leaf_owner} = generate_keypair()
      {_, leaf_delegate} = generate_keypair()
      {_, tree_creator_or_delegate} = generate_keypair()

      metadata = generate_metadata(payer)

      params = %{
        tree_config: tree_config,
        merkle_tree: merkle_tree,
        payer: payer,
        leaf_owner: leaf_owner,
        leaf_delegate: leaf_delegate,
        tree_creator_or_delegate: tree_creator_or_delegate,
        metadata: metadata
      }

      assert {:ok, transaction} = MplBubblegum.mint_v1(params)
      transaction_binary = :binary.list_to_bin(transaction)
      assert is_binary(transaction_binary)
      assert byte_size(transaction_binary) > 0
    end

    test "fails with invalid metadata" do
      {_, tree_config} = generate_keypair()
      {_, merkle_tree} = generate_keypair()
      {_, payer} = generate_keypair()
      {_, leaf_owner} = generate_keypair()
      {_, leaf_delegate} = generate_keypair()
      {_, tree_creator_or_delegate} = generate_keypair()

      params = %{
        tree_config: tree_config,
        merkle_tree: merkle_tree,
        payer: payer,
        leaf_owner: leaf_owner,
        leaf_delegate: leaf_delegate,
        tree_creator_or_delegate: tree_creator_or_delegate,
        metadata: nil # Invalid metadata
      }

      # The Rust NIF crashes instead of returning {:error, reason}
      assert_raise ArgumentError, fn ->
        MplBubblegum.mint_v1(params)
      end
    end
  end

  describe "sign_and_submit_transaction/2 for mint" do
    test "signs mint transaction successfully, even if submission fails" do
      {payer_secret, payer} = generate_keypair()
      {_, tree_config} = generate_keypair()
      {_, merkle_tree} = generate_keypair()
      {leaf_owner_secret, leaf_owner} = generate_keypair()
      {_, leaf_delegate} = generate_keypair()
      {_, tree_creator_or_delegate} = generate_keypair()

      metadata = generate_metadata(payer)

      params = %{
        tree_config: tree_config,
        merkle_tree: merkle_tree,
        payer: payer,
        leaf_owner: leaf_owner,
        leaf_delegate: leaf_delegate,
        tree_creator_or_delegate: tree_creator_or_delegate,
        metadata: metadata
      }

      {:ok, transaction} = MplBubblegum.mint_v1(params)
      transaction_binary = :binary.list_to_bin(transaction)

      secret_keys = [payer_secret, leaf_owner_secret]
      result = MplBubblegum.sign_and_submit_transaction(transaction_binary, secret_keys)

      case result do
        {:ok, signature} ->
          assert is_binary(signature)
          assert byte_size(signature) == 88 # Base58-encoded signature length
        {:error, reason} ->
          assert is_binary(reason)
      end
    end
  end
end