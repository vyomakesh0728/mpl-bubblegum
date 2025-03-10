use solana_program::pubkey::Pubkey;
use solana_sdk::{
    instruction::{AccountMeta, Instruction},
    transaction::Transaction,
    message::Message,
    system_instruction,
    rent::Rent,
};
use mpl_bubblegum::{
    instructions::{
        CreateTreeConfigBuilder, MintV1Builder, TransferBuilder,
        MintV1InstructionArgs, TransferInstructionArgs,
    },
    types::MetadataArgs,
    ID as BUBBLEGUM_ID,
};
use spl_account_compression::ID as SPL_ACCOUNT_COMPRESSION_ID;
use spl_noop::ID as SPL_NOOP_ID;
use crate::error::Error;

pub fn create_tree_config(
    tree_config: Pubkey,
    merkle_tree: Pubkey,
    payer: Pubkey,
    tree_creator: Pubkey,
    max_depth: u32,
    max_buffer_size: u32,
    public: Option<bool>,
) -> Result<Vec<u8>, Error> {
    let rent = Rent::default();

    // Space and rent for tree_config
    let tree_config_space = 8 + 32 + 1; // Discriminator + pubkey + bool (simplified)
    let tree_config_lamports = rent.minimum_balance(tree_config_space);

    // Space and rent for merkle_tree
    let merkle_tree_space = get_merkle_tree_size(max_depth, max_buffer_size);
    let merkle_tree_lamports = rent.minimum_balance(merkle_tree_space);

    let mut instructions = vec![
        // Create tree_config account
        system_instruction::create_account(
            &payer,
            &tree_config,
            tree_config_lamports,
            tree_config_space as u64,
            &BUBBLEGUM_ID,
        ),
        // Create merkle_tree account
        system_instruction::create_account(
            &payer,
            &merkle_tree,
            merkle_tree_lamports,
            merkle_tree_space as u64,
            &SPL_ACCOUNT_COMPRESSION_ID,
        ),
    ];

    // Add the create_tree_config instruction
    let mut builder = CreateTreeConfigBuilder::new();
    builder
        .tree_config(tree_config)
        .merkle_tree(merkle_tree)
        .payer(payer)
        .tree_creator(tree_creator)
        .max_depth(max_depth)
        .max_buffer_size(max_buffer_size);

    if let Some(public_value) = public {
        builder.public(public_value);
    }

    let instruction = builder.instruction();
    instructions.push(instruction);

    // Create a Message from the Instructions
    let message = Message::new(&instructions, Some(&payer));
    let transaction = Transaction::new_unsigned(message);

    bincode::serialize(&transaction)
        .map_err(|e| Error::Conversion(format!("Failed to serialize transaction: {}", e)))
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

    let mut builder = MintV1Builder::new();
    builder
        .tree_config(tree_config)
        .leaf_owner(leaf_owner)
        .leaf_delegate(leaf_delegate)
        .merkle_tree(merkle_tree)
        .payer(payer)
        .tree_creator_or_delegate(tree_creator_or_delegate)
        .metadata(args.metadata);

    let instruction = builder.instruction();

    // Create a Message from the Instruction
    let message = Message::new(&[instruction], Some(&payer)); // Payer as fee payer

    // Create a Transaction
    let transaction = Transaction::new_unsigned(message);

    // Serialize the transaction
    bincode::serialize(&transaction)
        .map_err(|e| Error::Conversion(format!("Failed to serialize transaction: {}", e)))
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
    let _args = TransferInstructionArgs {
        root,
        data_hash,
        creator_hash,
        nonce,
        index,
    };

    let mut builder = TransferBuilder::new();
    builder
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

    // Create a Message from the Instruction
    let message = Message::new(&[instruction], Some(&leaf_owner)); // Leaf owner as fee payer

    // Create a Transaction
    let transaction = Transaction::new_unsigned(message);

    // Serialize the transaction
    bincode::serialize(&transaction)
        .map_err(|e| Error::Conversion(format!("Failed to serialize transaction: {}", e)))
}

/// Helper function to calculate the size needed for a merkle tree account
fn get_merkle_tree_size(max_depth: u32, max_buffer_size: u32) -> usize {
    let header_size = 8 + 32 + 32; // Discriminator + pubkey + misc
    let canopy_size = (1 << (max_depth - 1)) * 32; // Simplified canopy
    let tree_size = (1 << (max_depth + 1)) * 32; // Nodes
    let buffer_size = max_buffer_size as usize * 32;
    header_size + canopy_size + tree_size + buffer_size
}