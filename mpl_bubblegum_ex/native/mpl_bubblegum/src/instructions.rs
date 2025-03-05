use borsh::BorshSerialize;
use solana_program::pubkey::Pubkey;
use mpl_bubblegum::{
    instructions::{
        CreateTreeConfigBuilder, MintV1Builder, TransferBuilder,
        CreateTreeConfigInstructionArgs, MintV1InstructionArgs, TransferInstructionArgs,
    },
    types::MetadataArgs,
};
use crate::error::Error;

/// Creates a transaction for initializing a compressed merkle tree config.
pub fn create_tree_config(
    tree_config: Pubkey,
    merkle_tree: Pubkey,
    payer: Pubkey,
    tree_creator: Pubkey,
    max_depth: u32,
    max_buffer_size: u32,
    public: Option<bool>,
) -> Result<Vec<u8>, Error> {
    let args = CreateTreeConfigInstructionArgs {
        max_depth,
        max_buffer_size,
        public,
    };

    let mut builder = CreateTreeConfigBuilder::new()
        .tree_config(tree_config)
        .merkle_tree(merkle_tree)
        .payer(payer)
        .tree_creator(tree_creator)
        .max_depth(max_depth)
        .max_buffer_size(max_buffer_size);

    if let Some(public_value) = public {
        builder = builder.public(public_value);
    }

    let instruction = builder.instruction();

    // Serialize the instruction
    let serialized = bincode::serialize(&instruction)
        .map_err(|e| Error::Conversion(format!("Failed to serialize instruction: {}", e)))?;

    Ok(serialized)
}

/// Creates a transaction for minting a compressed NFT.
pub fn mint_v1(
    tree_config: Pubkey,
    leaf_owner: Pubkey,
    leaf_delegate: Pubkey,
    merkle_tree: Pubkey,
    payer: Pubkey,
    tree_creator_or_delegate: Pubkey,
    metadata: MetadataArgs,
) -> Result<Vec<u8>, Error> {
    let args = MintV1InstructionArgs { metadata };

    let builder = MintV1Builder::new()
        .tree_config(tree_config)
        .leaf_owner(leaf_owner)
        .leaf_delegate(leaf_delegate)
        .merkle_tree(merkle_tree)
        .payer(payer)
        .tree_creator_or_delegate(tree_creator_or_delegate)
        .metadata(args.metadata);

    let instruction = builder.instruction();

    // Serialize the instruction
    let serialized = bincode::serialize(&instruction)
        .map_err(|e| Error::Conversion(format!("Failed to serialize instruction: {}", e)))?;

    Ok(serialized)
}

/// Creates a transaction for transferring a compressed NFT.
pub fn transfer(
    tree_config: Pubkey,
    leaf_owner: Pubkey,
    leaf_delegate: Pubkey,
    new_leaf_owner: Pubkey,
    merkle_tree: Pubkey,
    root: [u8; 32],
    data_hash: [u8; 32],
    creator_hash: [u8; 32],
    nonce: u64,
    index: u32,
) -> Result<Vec<u8>, Error> {
    let args = TransferInstructionArgs {
        root,
        data_hash,
        creator_hash,
        nonce,
        index,
    };

    let builder = TransferBuilder::new()
        .tree_config(tree_config)
        .leaf_owner(leaf_owner, true) // Assuming leaf_owner is a signer
        .leaf_delegate(leaf_delegate, false) // Assuming leaf_delegate is not a signer
        .new_leaf_owner(new_leaf_owner)
        .merkle_tree(merkle_tree)
        .root(root)
        .data_hash(data_hash)
        .creator_hash(creator_hash)
        .nonce(nonce)
        .index(index);

    let instruction = builder.instruction();

    // Serialize the instruction
    let serialized = bincode::serialize(&instruction)
        .map_err(|e| Error::Conversion(format!("Failed to serialize instruction: {}", e)))?;

    Ok(serialized)
}
