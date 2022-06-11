# batch-reveal-token

`batch-reveal-token` is a flexible ERC721A token with the following features:

- AllowList support with Merkle Proofs
- Configurable `SaleState`s: `PAUSED`, `ALLOW_LIST`, and `PUBLIC`
- Configurable public and allow-list mint prices
- Configurable max mints allowed per wallet
- Pre-determined (at deploy time) maximum public-mintable supply and dev-mintable supply
- Pre-determined provenance hash for metadata fairness
- Configurable batch "Reveals" - before full reveal, `Owner` can reveal batches of tokens by specifying an exclusive `maxId` and unique `tokenURI` for a set of sequential tokens
- Configurable EIP-2981 support
- A TwoStepOwnable "Ownable" interface (where new owner must `claimOwnership`), alleviating risks of ownership transfer

# Installation

`forge install jameswenzel/batch-reveal-token`

# Testing

On initial setup:

`forge install`

Once dependencies are installed:

`forge test`
