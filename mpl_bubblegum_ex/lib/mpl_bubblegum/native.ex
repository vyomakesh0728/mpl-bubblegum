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

end
