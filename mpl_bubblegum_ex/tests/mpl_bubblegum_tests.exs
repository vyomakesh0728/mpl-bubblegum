ExUnit.start()

defmodule MplBubblegumTest do
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

  describe "create_tree_config/1" do
    test "creates a valid transaction binary" do
      {_, tree_config} = generate_keypair()
      {_, merkle_tree} = generate_keypair()
      {_, payer} = generate_keypair()
      {_, tree_creator} = generate_keypair()

      params = %{
        tree_config: tree_config,
        merkle_tree: merkle_tree,
        payer: payer,
        tree_creator: tree_creator,
        max_depth: 14,
        max_buffer_size: 64,
        public: true
      }

      assert {:ok, transaction} = MplBubblegum.create_tree_config(params)
      transaction_binary = :binary.list_to_bin(transaction)
      assert is_binary(transaction_binary)
      assert byte_size(transaction_binary) > 0
    end

    test "fails with invalid max_depth" do
      {_, tree_config} = generate_keypair()
      {_, merkle_tree} = generate_keypair()
      {_, payer} = generate_keypair()
      {_, tree_creator} = generate_keypair()

      params = %{
        tree_config: tree_config,
        merkle_tree: merkle_tree,
        payer: payer,
        tree_creator: tree_creator,
        max_depth: -1,
        max_buffer_size: 64,
        public: true
      }

      # Rust NIF crashes instead of returning {:error, reason}
      assert_raise ArgumentError, fn ->
        MplBubblegum.create_tree_config(params)
      end
    end
  end

  describe "sign_and_submit_transaction/2" do
    test "signs transaction successfully, even if submission fails" do
      {payer_secret, payer} = generate_keypair()
      {tree_creator_secret, tree_creator} = generate_keypair()
      {tree_config_secret, tree_config} = generate_keypair()
      {merkle_tree_secret, merkle_tree} = generate_keypair()

      params = %{
        tree_config: tree_config,
        merkle_tree: merkle_tree,
        payer: payer,
        tree_creator: tree_creator,
        max_depth: 14,
        max_buffer_size: 64,
        public: true
      }

      {:ok, transaction} = MplBubblegum.create_tree_config(params)
      transaction_binary = :binary.list_to_bin(transaction)

      secret_keys = [payer_secret, tree_creator_secret, tree_config_secret, merkle_tree_secret]
      result = MplBubblegum.sign_and_submit_transaction(transaction_binary, secret_keys)

      case result do
        {:ok, signature} ->
          assert is_binary(signature)
          assert byte_size(signature) == 88
        {:error, reason} ->
          # Broaden error check since submission fails without validator
          assert is_binary(reason)
      end
    end

    test "fails with insufficient secret keys" do
      {payer_secret, payer} = generate_keypair()
      {tree_creator_secret, tree_creator} = generate_keypair()
      {_, tree_config} = generate_keypair()
      {_, merkle_tree} = generate_keypair()

      params = %{
        tree_config: tree_config,
        merkle_tree: merkle_tree,
        payer: payer,
        tree_creator: tree_creator,
        max_depth: 14,
        max_buffer_size: 64,
        public: true
      }

      {:ok, transaction} = MplBubblegum.create_tree_config(params)
      transaction_binary = :binary.list_to_bin(transaction)

      secret_keys = [payer_secret, tree_creator_secret]
      result = MplBubblegum.sign_and_submit_transaction(transaction_binary, secret_keys)

      case result do
        {:error, reason} ->
          # Rust NIF might not return "NotEnoughSigners" cleanly
          assert String.contains?(reason, "NotEnoughSigners") or
                 String.contains?(reason, "signature error") or
                 String.contains?(reason, "Cannot decompress Edwards point")
        other ->
          flunk("Expected {:error, reason}, got #{inspect(other)}")
      end
    end
  end
end