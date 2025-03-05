use solana_program::pubkey::Pubkey;
use mpl_bubblegum::{
    hash::{hash_metadata as bubblegum_hash_metadata, hash_creators as bubblegum_hash_creators},
    utils::get_asset_id as bubblegum_get_asset_id,
    types::{MetadataArgs, Creator},
};
use crate::{error::Error, types::ElixirCreator};
use std::convert::TryInto;

/// Computes the hash of NFT metadata.
pub fn hash_metadata(metadata: MetadataArgs) -> Result<[u8; 32], Error> {
    bubblegum_hash_metadata(&metadata)
        .map_err(|e| Error::Bubblegum(format!("Failed to hash metadata: {}", e)))
}

/// Computes the hash of NFT creators.
pub fn hash_creators(creators: Vec<ElixirCreator>) -> Result<[u8; 32], Error> {
    let creators: Result<Vec<Creator>, _> = creators
        .into_iter()
        .map(|c| c.try_into())
        .collect();

    let creators = creators.map_err(|e| Error::Conversion(format!("Failed to convert creators: {:?}", e)))?;

    Ok(bubblegum_hash_creators(&creators))
}

/// Computes the asset ID of an asset given its tree and nonce values.
pub fn get_asset_id(tree: Pubkey, nonce: u64) -> Result<Pubkey, Error> {
    Ok(bubblegum_get_asset_id(&tree, nonce))
}
