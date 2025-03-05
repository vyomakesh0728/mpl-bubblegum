mod types;
mod instructions;
mod utils;
mod error;

use rustler::{Encoder, Env, NifResult, Term};
use rustler::types::atom;
use rustler::error::Error;
use types::{ElixirMetadata, ElixirPubkey, ElixirHash};

#[rustler::nif]
fn create_tree_config(
    env: Env,
    tree_config: ElixirPubkey,
    merkle_tree: ElixirPubkey,
    payer: ElixirPubkey,
    tree_creator: ElixirPubkey,
    max_depth: u32,
    max_buffer_size: u32,
    public: Option<bool>,
) -> NifResult<Term> {
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
fn mint_v1(
    env: Env,
    tree_config: ElixirPubkey,
    leaf_owner: ElixirPubkey,
    leaf_delegate: ElixirPubkey,
    merkle_tree: ElixirPubkey,
    payer: ElixirPubkey,
    tree_creator_or_delegate: ElixirPubkey,
    metadata: ElixirMetadata,
) -> NifResult<Term> {
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
fn transfer(
    env: Env,
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
) -> NifResult<Term> {
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
fn hash_metadata(env: Env, metadata: ElixirMetadata) -> NifResult<Term> {
    match utils::hash_metadata(metadata.try_into()?) {
        Ok(hash) => Ok((atom::ok(), ElixirHash::from(hash)).encode(env)),
        Err(err) => Ok((atom::error(), err.to_string()).encode(env)),
    }
}

#[rustler::nif]
fn hash_creators(env: Env, creators: Vec<types::ElixirCreator>) -> NifResult<Term> {
    match utils::hash_creators(creators) {
        Ok(hash) => Ok((atom::ok(), ElixirHash::from(hash)).encode(env)),
        Err(err) => Ok((atom::error(), err.to_string()).encode(env)),
    }
}

#[rustler::nif]
fn get_asset_id(env: Env, tree: ElixirPubkey, nonce: u64) -> NifResult<Term> {
    match utils::get_asset_id(tree.into(), nonce) {
        Ok(asset_id) => Ok((atom::ok(), ElixirPubkey::from(asset_id)).encode(env)),
        Err(err) => Ok((atom::error(), err.to_string()).encode(env)),
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
        get_asset_id
    ]
);
