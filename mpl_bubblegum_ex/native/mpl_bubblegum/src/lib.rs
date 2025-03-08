mod types;
mod instructions;
mod utils;
mod error;

use rustler::{Encoder, Env, NifResult, Term, Binary};
use rustler::types::atom;
use rustler::error::Error;
use types::{ElixirMetadata, ElixirPubkey, ElixirHash};
use solana_sdk::{
    pubkey::Pubkey as SolanaPubkey,
    signature::{Keypair, Signer},
    transaction::Transaction,
};
use solana_client::rpc_client::RpcClient;
use std::str::FromStr;
use tokio::runtime::Runtime;

#[rustler::nif]
fn create_tree_config<'a>(
    env: Env<'a>,
    tree_config: ElixirPubkey,
    merkle_tree: ElixirPubkey,
    payer: ElixirPubkey,
    tree_creator: ElixirPubkey,
    max_depth: u32,
    max_buffer_size: u32,
    public: Option<bool>,
) -> NifResult<Term<'a>> {
    match instructions::create_tree_config(
        tree_config.into(),
        merkle_tree.into(),
        payer.into(),
        tree_creator.into(),
        max_depth,
        max_buffer_size,
        public,
    ) {
        Ok(transaction) => Ok((atom::ok(), transaction).encode(env)),
        Err(err) => Ok((atom::error(), err.to_string()).encode(env)),
    }
}

#[rustler::nif]
fn mint_v1<'a>(
    env: Env<'a>,
    tree_config: ElixirPubkey,
    leaf_owner: ElixirPubkey,
    leaf_delegate: ElixirPubkey,
    merkle_tree: ElixirPubkey,
    payer: ElixirPubkey,
    tree_creator_or_delegate: ElixirPubkey,
    metadata: ElixirMetadata,
) -> NifResult<Term<'a>> {
    match instructions::mint_v1(
        tree_config.into(),
        leaf_owner.into(),
        leaf_delegate.into(),
        merkle_tree.into(),
        payer.into(),
        tree_creator_or_delegate.into(),
        metadata.try_into()?,
    ) {
        Ok(transaction) => Ok((atom::ok(), transaction).encode(env)),
        Err(err) => Ok((atom::error(), err.to_string()).encode(env)),
    }
}

#[rustler::nif]
fn transfer<'a>(
    env: Env<'a>,
    tree_config: ElixirPubkey,
    leaf_owner: ElixirPubkey,
    leaf_delegate: ElixirPubkey,
    new_leaf_owner: ElixirPubkey,
    merkle_tree: ElixirPubkey,
    root: ElixirHash,
    data_hash: ElixirHash,
    creator_hash: ElixirHash,
    nonce: u64,
    index: u32,
) -> NifResult<Term<'a>> {
    match instructions::transfer(
        tree_config.into(),
        leaf_owner.into(),
        leaf_delegate.into(),
        new_leaf_owner.into(),
        merkle_tree.into(),
        root.into(),
        data_hash.into(),
        creator_hash.into(),
        nonce,
        index,
    ) {
        Ok(transaction) => Ok((atom::ok(), transaction).encode(env)),
        Err(err) => Ok((atom::error(), err.to_string()).encode(env)),
    }
}

#[rustler::nif]
fn hash_metadata<'a>(env: Env<'a>, metadata: ElixirMetadata) -> NifResult<Term<'a>> {
    match utils::hash_metadata(metadata.try_into()?) {
        Ok(hash) => Ok((atom::ok(), ElixirHash::from(hash)).encode(env)),
        Err(err) => Ok((atom::error(), err.to_string()).encode(env)),
    }
}

#[rustler::nif]
fn hash_creators<'a>(env: Env<'a>, creators: Vec<types::ElixirCreator>) -> NifResult<Term<'a>> {
    match utils::hash_creators(creators) {
        Ok(hash) => Ok((atom::ok(), ElixirHash::from(hash)).encode(env)),
        Err(err) => Ok((atom::error(), err.to_string()).encode(env)),
    }
}

#[rustler::nif]
fn get_asset_id<'a>(env: Env<'a>, tree: ElixirPubkey, nonce: u64) -> NifResult<Term<'a>> {
    match utils::get_asset_id(tree.into(), nonce) {
        Ok(asset_id) => Ok((atom::ok(), ElixirPubkey::from(asset_id)).encode(env)),
        Err(err) => Ok((atom::error(), err.to_string()).encode(env)),
    }
}

#[rustler::nif]
fn derive_pubkey_from_secret<'a>(env: Env<'a>, secret_key: Binary<'a>) -> NifResult<Term<'a>> {
    let secret_key_bytes = secret_key.as_slice();
    let keypair = Keypair::from_bytes(secret_key_bytes)
        .map_err(|e| Error::Term(Box::new(format!("Invalid secret key: {}", e))))?;
    let pubkey = keypair.pubkey();
    Ok((atom::ok(), ElixirPubkey::from(pubkey)).encode(env))
}

#[rustler::nif]
fn sign_and_submit_transaction<'a>(
    env: Env<'a>,
    transaction_binary: Binary<'a>,  // Serialized transaction from Elixir
    payer_secret_key: Binary<'a>,    // Payer's secret key
) -> NifResult<Term<'a>> {
    // Create a runtime for async operations
    let rt = Runtime::new()
        .map_err(|e| Error::Term(Box::new(format!("Failed to create tokio runtime: {}", e))))?;
    
    let result = rt.block_on(async {
        // Step 1: Deserialize the transaction from binary input
        let transaction_bytes = transaction_binary.as_slice();
        let mut transaction: Transaction = bincode::deserialize(transaction_bytes)
            .map_err(|e| format!("Failed to deserialize transaction: {}", e))?;

        // Step 2: Construct a keypair from the payer's secret key
        let secret_key_bytes = payer_secret_key.as_slice();
        let payer_keypair = Keypair::from_bytes(secret_key_bytes)
            .map_err(|e| format!("Failed to create keypair: {}", e))?;

        // Step 3: Fetch a recent blockhash from the Devnet RPC endpoint
        let client = RpcClient::new("https://api.devnet.solana.com".to_string());
        let recent_blockhash = client.get_latest_blockhash()
            .map_err(|e| format!("Failed to get blockhash: {}", e))?;

        // Step 4: Sign the transaction with the keypair and blockhash
        transaction.sign(&[&payer_keypair], recent_blockhash);

        // Step 5: Submit the signed transaction to Devnet and return the signature
        let signature = client.send_and_confirm_transaction(&transaction)
            .map_err(|e| format!("Failed to submit transaction: {}", e))?;

        Ok::<String, String>(signature.to_string())
    });

    match result {
        Ok(signature) => Ok((atom::ok(), signature).encode(env)),
        Err(err) => Ok((atom::error(), err).encode(env)),
    }
}

#[rustler::nif]
fn get_transaction_status<'a>(env: Env<'a>, signature: String) -> NifResult<Term<'a>> {
    // Create a runtime for async operations
    let rt = Runtime::new()
        .map_err(|e| Error::Term(Box::new(format!("Failed to create tokio runtime: {}", e))))?;
    
    let result = rt.block_on(async {
        // Connect to Solana Devnet to check the transaction status
        let client = RpcClient::new("https://api.devnet.solana.com".to_string());
        
        // Parse the signature string
        let signature = match solana_sdk::signature::Signature::from_str(&signature) {
            Ok(sig) => sig,
            Err(e) => return Err(format!("Invalid signature format: {}", e)),
        };
        
        // Get the transaction status
        match client.get_signature_status(&signature) {
            Ok(status) => {
                match status {
                    Some(Ok(_)) => Ok("confirmed".to_string()),
                    Some(Err(e)) => Ok(format!("failed: {}", e)),
                    None => Ok("not_found".to_string()),
                }
            },
            Err(e) => Err(format!("Failed to get transaction status: {}", e)),
        }
    });
    
    match result {
        Ok(status) => Ok((atom::ok(), status).encode(env)),
        Err(err) => Ok((atom::error(), err).encode(env)),
    }
}

#[rustler::nif]
fn get_account_info<'a>(env: Env<'a>, pubkey: ElixirPubkey) -> NifResult<Term<'a>> {
    // Create a runtime for async operations
    let rt = Runtime::new()
        .map_err(|e| Error::Term(Box::new(format!("Failed to create tokio runtime: {}", e))))?;
    
    let result = rt.block_on(async {
        // Connect to Solana Devnet to fetch account info
        let client = RpcClient::new("https://api.devnet.solana.com".to_string());
        
        // Convert ElixirPubkey to Solana Pubkey
        let pubkey: SolanaPubkey = pubkey.into();
        
        // Get the account info
        match client.get_account(&pubkey) {
            Ok(account) => {
                let account_data = {
                    let mut map = std::collections::HashMap::new();
                    map.insert("lamports", account.lamports.to_string());
                    map.insert("owner", account.owner.to_string());
                    map.insert("executable", account.executable.to_string());
                    map.insert("rent_epoch", account.rent_epoch.to_string());
                    map.insert("data_len", account.data.len().to_string());
                    map
                };
                
                Ok(account_data)
            },
            Err(e) => Err(format!("Failed to get account info: {}", e)),
        }
    });
    
    match result {
        Ok(account_data) => Ok((atom::ok(), account_data).encode(env)),
        Err(err) => Ok((atom::error(), err).encode(env)),
    }
}

rustler::init!(
    "Elixir.MplBubblegum.Native",
    [
        create_tree_config,
        mint_v1,
        transfer,
        hash_metadata,
        hash_creators,
        get_asset_id,
        sign_and_submit_transaction,
        get_transaction_status,
        get_account_info,
        derive_pubkey_from_secret
    ]
);
