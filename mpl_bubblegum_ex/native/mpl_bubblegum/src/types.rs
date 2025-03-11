use rustler::{NifStruct, Error};
use solana_sdk::pubkey::Pubkey;
use mpl_bubblegum::types::{MetadataArgs, Creator, TokenProgramVersion, TokenStandard, Collection, Uses};
use std::convert::{TryFrom, TryInto};

#[derive(NifStruct, Debug, Clone)]
#[module = "MplBubblegum.Types.Pubkey"]
pub struct ElixirPubkey {
    pub bytes: Vec<u8>,
}

impl From<ElixirPubkey> for Pubkey {
    fn from(pubkey: ElixirPubkey) -> Self {
        let mut bytes = [0u8; 32];
        bytes.copy_from_slice(&pubkey.bytes);
        Pubkey::new_from_array(bytes)
    }
}

impl From<Pubkey> for ElixirPubkey {
    fn from(pubkey: Pubkey) -> Self {
        ElixirPubkey {
            bytes: pubkey.to_bytes().to_vec(),
        }
    }
}

#[derive(NifStruct, Debug, Clone)]
#[module = "MplBubblegum.Types.Hash"]
pub struct ElixirHash {
    pub bytes: Vec<u8>,
}

impl From<ElixirHash> for [u8; 32] {
    fn from(hash: ElixirHash) -> Self {
        let mut bytes = [0u8; 32];
        bytes.copy_from_slice(&hash.bytes);
        bytes
    }
}

impl From<[u8; 32]> for ElixirHash {
    fn from(hash: [u8; 32]) -> Self {
        ElixirHash {
            bytes: hash.to_vec(),
        }
    }
}

#[derive(NifStruct, Debug, Clone)]
#[module = "MplBubblegum.Types.Creator"]
pub struct ElixirCreator {
    pub address: ElixirPubkey,
    pub verified: bool,
    pub share: u8,
}

impl TryFrom<ElixirCreator> for Creator {
    type Error = Error;

    fn try_from(creator: ElixirCreator) -> Result<Self, Self::Error> {
        Ok(Creator {
            address: creator.address.into(),
            verified: creator.verified,
            share: creator.share,
        })
    }
}

impl From<Creator> for ElixirCreator {
    fn from(creator: Creator) -> Self {
        ElixirCreator {
            address: ElixirPubkey::from(creator.address),
            verified: creator.verified,
            share: creator.share,
        }
    }
}

#[derive(NifStruct, Debug, Clone)]
#[module = "MplBubblegum.Types.Collection"]
pub struct ElixirCollection {
    pub verified: bool,
    pub key: ElixirPubkey,
}

impl TryFrom<ElixirCollection> for Collection {
    type Error = Error;

    fn try_from(collection: ElixirCollection) -> Result<Self, Self::Error> {
        Ok(Collection {
            verified: collection.verified,
            key: collection.key.into(),
        })
    }
}

#[derive(NifStruct, Debug, Clone)]
#[module = "MplBubblegum.Types.Uses"]
pub struct ElixirUses {
    pub use_method: u8,
    pub remaining: u64,
    pub total: u64,
}

impl TryFrom<ElixirUses> for Uses {
    type Error = Error;

    fn try_from(uses: ElixirUses) -> Result<Self, Self::Error> {
        let use_method = match uses.use_method {
            0 => mpl_bubblegum::types::UseMethod::Burn,
            1 => mpl_bubblegum::types::UseMethod::Multiple,
            2 => mpl_bubblegum::types::UseMethod::Single,
            _ => return Err(Error::Term(Box::new(format!("Invalid use method: {}", uses.use_method)))),
        };

        Ok(Uses {
            use_method,
            remaining: uses.remaining,
            total: uses.total,
        })
    }
}

#[derive(NifStruct, Debug, Clone)]
#[module = "MplBubblegum.Types.Metadata"]
pub struct ElixirMetadata {
    pub name: String,
    pub symbol: String,
    pub uri: String,
    pub seller_fee_basis_points: u16,
    pub primary_sale_happened: bool,
    pub is_mutable: bool,
    pub edition_nonce: Option<u8>,
    pub token_standard: Option<u8>,
    pub collection: Option<ElixirCollection>,
    pub uses: Option<ElixirUses>,
    pub token_program_version: u8,
    pub creators: Vec<ElixirCreator>,
}

impl TryFrom<ElixirMetadata> for MetadataArgs {
    type Error = Error;

    fn try_from(metadata: ElixirMetadata) -> Result<Self, Self::Error> {
        let token_program_version = match metadata.token_program_version {
            0 => TokenProgramVersion::Original,
            1 => TokenProgramVersion::Token2022,
            _ => return Err(Error::Term(Box::new(format!("Invalid token program version: {}", metadata.token_program_version)))),
        };

        let token_standard = if let Some(ts) = metadata.token_standard {
            Some(match ts {
                0 => TokenStandard::NonFungible,
                1 => TokenStandard::FungibleAsset,
                2 => TokenStandard::Fungible,
                3 => TokenStandard::NonFungibleEdition,
                _ => return Err(Error::Term(Box::new(format!("Invalid token standard: {}", ts)))),
            })
        } else {
            None
        };

        let collection = if let Some(c) = metadata.collection {
            Some(c.try_into()?)
        } else {
            None
        };

        let uses = if let Some(u) = metadata.uses {
            Some(u.try_into()?)
        } else {
            None
        };

        let creators = metadata
            .creators
            .into_iter()
            .map(|c| c.try_into())
            .collect::<Result<Vec<_>, _>>()?;

        Ok(MetadataArgs {
            name: metadata.name,
            symbol: metadata.symbol,
            uri: metadata.uri,
            seller_fee_basis_points: metadata.seller_fee_basis_points,
            primary_sale_happened: metadata.primary_sale_happened,
            is_mutable: metadata.is_mutable,
            edition_nonce: metadata.edition_nonce,
            token_standard,
            collection,
            uses,
            token_program_version,
            creators,
        })
    }
}
