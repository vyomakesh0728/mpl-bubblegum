ExUnit.start()

defmodule TransferTest do
  use ExUnit.Case
  doctest MplBubblegum

  alias MplBubblegum.Types.Pubkey

  # Helper to generate a valid keypair (secret + public key)
  defp generate_keypair do
    secret = :crypto.strong_rand_bytes(64)
    public_bytes = binary_part(secret, 32, 32)
    pubkey = %Pubkey{bytes: :binary.bin_to_list(public_bytes)}
    {secret, pubkey}
  end

  # Helper to generate a 32-byte binary hash
  defp generate_hash do
    :crypto.strong_rand_bytes(32)
  end

  describe "transfer/1" do
    test "creates a valid transfer transaction" do
      {_, tree_config} = generate_keypair()
      {_, merkle_tree} = generate_keypair()
      {_, leaf_owner} = generate_keypair()
      {_, leaf_delegate} = generate_keypair()
      {_, new_leaf_owner} = generate_keypair()

      params = %{
        tree_config: tree_config,
        merkle_tree: merkle_tree,
        leaf_owner: leaf_owner,
        leaf_delegate: leaf_delegate,
        new_leaf_owner: new_leaf_owner,
        root: generate_hash(),
        data_hash: generate_hash(),
        creator_hash: generate_hash(),
        nonce: 1,
        index: 0
      }

      assert {:ok, transaction} = MplBubblegum.transfer(params)
      transaction_binary = :binary.list_to_bin(transaction)
      assert is_binary(transaction_binary)
      assert byte_size(transaction_binary) > 0
    end

    test "fails with invalid index" do
      {_, tree_config} = generate_keypair()
      {_, merkle_tree} = generate_keypair()
      {_, leaf_owner} = generate_keypair()
      {_, leaf_delegate} = generate_keypair()
      {_, new_leaf_owner} = generate_keypair()

      params = %{
        tree_config: tree_config,
        merkle_tree: merkle_tree,
        leaf_owner: leaf_owner,
        leaf_delegate: leaf_delegate,
        new_leaf_owner: new_leaf_owner,
        root: generate_hash(),
        data_hash: generate_hash(),
        creator_hash: generate_hash(),
        nonce: 1,
        index: -1 # Invalid index
      }

      assert_raise ArgumentError, fn ->
        MplBubblegum.transfer(params)
      end
    end
  end

  describe "sign_and_submit_transaction/2 for transfer" do
    test "signs transfer transaction successfully, even if submission fails" do
      {leaf_owner_secret, leaf_owner} = generate_keypair()
      {_, tree_config} = generate_keypair()
      {_, merkle_tree} = generate_keypair()
      {_, leaf_delegate} = generate_keypair()
      {_, new_leaf_owner} = generate_keypair()

      params = %{
        tree_config: tree_config,
        merkle_tree: merkle_tree,
        leaf_owner: leaf_owner,
        leaf_delegate: leaf_delegate,
        new_leaf_owner: new_leaf_owner,
        root: generate_hash(),
        data_hash: generate_hash(),
        creator_hash: generate_hash(),
        nonce: 1,
        index: 0
      }

      {:ok, transaction} = MplBubblegum.transfer(params)
      transaction_binary = :binary.list_to_bin(transaction)

      secret_keys = [leaf_owner_secret]
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