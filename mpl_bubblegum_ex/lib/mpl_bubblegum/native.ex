defmodule MplBubblegum.Native do
  @moduledoc """
  Native implemented functions for MplBubblegum.
  This module is responsible for loading the Rust NIF functions.
  """
  # This module contains the native implemented functions (NIFs) for the MplBubblegum module.
  # It should not be used directly, but rather through the MplBubblegum module.

  use Rustler, otp_app: :mpl_bubblegum, crate: "mpl_bubblegum"

  # When your NIF is loaded, it will override these functions.
  # These function stubs are here to provide documentation and to prevent compile-time warnings.

  @doc false
  def create_tree_config(_tree_config, _merkle_tree, _payer, _tree_creator, _max_depth, _max_buffer_size, _public),
    do: :erlang.nif_error(:nif_not_loaded)

  @doc false
  def mint_v1(_tree_config, _leaf_owner, _leaf_delegate, _merkle_tree, _payer, _tree_creator_or_delegate, _metadata),
    do: :erlang.nif_error(:nif_not_loaded)

  @doc false
  def transfer(_tree_config, _leaf_owner, _leaf_delegate, _new_leaf_owner, _merkle_tree, _root, _data_hash, _creator_hash, _nonce, _index),
    do: :erlang.nif_error(:nif_not_loaded)

  @doc false
  def hash_metadata(_metadata),
    do: :erlang.nif_error(:nif_not_loaded)

  @doc false
  def hash_creators(_creators),
    do: :erlang.nif_error(:nif_not_loaded)

  @doc false
  def get_asset_id(_tree, _nonce),
    do: :erlang.nif_error(:nif_not_loaded)

  @doc """
  Derives a public key from a secret key.

  Args:
    - secret_key: Binary secret key (64 bytes)

  Returns:
    - {:ok, pubkey} where pubkey is an ElixirPubkey struct
    - {:error, reason} if an error occurs
  """
  def derive_pubkey_from_secret(_secret_key),
    do: :erlang.nif_error(:nif_not_loaded)

  @doc """
  Signs and submits a transaction to the Solana network.

  Args:
    - transaction_binary: Binary serialized transaction
    - payer_secret_key: Binary secret key of the payer (64 bytes)

  Returns:
    - {:ok, signature} if successful
    - {:error, reason} if an error occurs
  """
  def sign_and_submit_transaction(_transaction_binary, _payer_secret_key),
    do: :erlang.nif_error(:nif_not_loaded)

  @doc """
  Retrieves the status of a transaction from the Solana network.

  Args:
    - signature: String representing the transaction signature

  Returns:
    - {:ok, status} where status is "confirmed", "failed: <reason>", or "not_found"
    - {:error, reason} if an error occurs
  """
  def get_transaction_status(_signature),
    do: :erlang.nif_error(:nif_not_loaded)

  @doc """
  Retrieves account information from the Solana network.

  Args:
    - pubkey: ElixirPubkey struct representing the account's public key

  Returns:
    - {:ok, account_info} where account_info is a map with lamports, owner, etc.
    - {:error, reason} if an error occurs
  """
  def get_account_info(_pubkey),
    do: :erlang.nif_error(:nif_not_loaded)
end
