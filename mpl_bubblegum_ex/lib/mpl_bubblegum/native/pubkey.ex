defmodule MplBubblegum.Native.Pubkey do
  @moduledoc """
  A module for interfacing with the Rust code's Pubkey type.
  """

  @doc """
  Converts a MplBubblegum.Types.Pubkey to a format that the Rust code can understand.
  """
  def to_rust_pubkey(%MplBubblegum.Types.Pubkey{bytes: bytes}) when is_binary(bytes) do
    # Convert the binary to a list of integers, which is what Rust expects for Vec<u8>
    %MplBubblegum.Types.Pubkey{bytes: :binary.bin_to_list(bytes)}
  end

  def to_rust_pubkey(%MplBubblegum.Types.Pubkey{bytes: bytes}) when is_list(bytes) do
    # If the bytes are already a list, just return the struct as is
    %MplBubblegum.Types.Pubkey{bytes: bytes}
  end
end 