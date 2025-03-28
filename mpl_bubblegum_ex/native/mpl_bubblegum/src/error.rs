use thiserror::Error;
use rustler::Error as NifError;
use solana_sdk::program_error::ProgramError;

#[derive(Error, Debug)]
pub enum Error {
    #[error("Solana SDK error: {0}")]
    SolanaProgram(#[from] solana_sdk::program_error::ProgramError),

    #[error("Borsh serialization error: {0}")]
    Borsh(#[from] borsh::maybestd::io::Error),

    #[error("Bubblegum error: {0}")]
    Bubblegum(String),

    #[error("Invalid parameter: {0}")]
    InvalidParameter(String),

    #[error("Conversion error: {0}")]
    Conversion(String),
}

impl From<Error> for NifError {
    fn from(error: Error) -> Self {
        NifError::Term(Box::new(error.to_string()))
    }
}
