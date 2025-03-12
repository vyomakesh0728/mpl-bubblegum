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
    root: Vec<u8>,
    data_hash: Vec<u8>,
    creator_hash: Vec<u8>,
    nonce: u64,
    index: u32,
) -> NifResult<Term<'a>> {
    let root_array: [u8; 32] = root.try_into().map_err(|_| Error::Term(Box::new("root must be 32 bytes")))?;
    let data_hash_array: [u8; 32] = data_hash.try_into().map_err(|_| Error::Term(Box::new("data_hash must be 32 bytes")))?;
    let creator_hash_array: [u8; 32] = creator_hash.try_into().map_err(|_| Error::Term(Box::new("creator_hash must be 32 bytes")))?;

    match instructions::transfer(
        tree_config.into(),
        leaf_owner.into(),
        leaf_delegate.into(),
        new_leaf_owner.into(),
        merkle_tree.into(),
        root_array,
        data_hash_array,
        creator_hash_array,
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
    transaction_binary: Binary<'a>,
    secret_keys: Vec<Binary<'a>>, // Changed to accept a vector of secret keys
) -> NifResult<Term<'a>> {
    let rt = Runtime::new().map_err(|e| Error::Term(Box::new(format!("Failed to create runtime: {}", e))))?;
    let result = rt.block_on(async {
        let transaction_bytes = transaction_binary.as_slice();
        let mut transaction: Transaction = bincode::deserialize(transaction_bytes)
            .map_err(|e| format!("Failed to deserialize transaction: {}", e))?;

        // Convert each secret key binary to a Keypair
        let mut keypairs = Vec::new();
        for secret_key in secret_keys {
            let keypair = Keypair::from_bytes(secret_key.as_slice())
                .map_err(|e| format!("Failed to create keypair: {}", e))?;
            keypairs.push(keypair);
        }
        let keypair_refs: Vec<&Keypair> = keypairs.iter().collect();

        let client = RpcClient::new("http://127.0.0.1:8899".to_string());
        let recent_blockhash = client.get_latest_blockhash()
            .map_err(|e| format!("Failed to get blockhash: {}", e))?;
        transaction.sign(&keypair_refs, recent_blockhash);
        let signature = transaction.signatures[0].to_string(); // Log signature for demo
        println!("Transaction signed with signature: {}", signature);
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
        let client = RpcClient::new("http://127.0.0.1:8899".to_string());
        
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
        let client = RpcClient::new("http://127.0.0.1:8899".to_string());
        
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
