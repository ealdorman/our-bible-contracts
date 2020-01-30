# Our Bible smart contracts

> Ethereum contracts for Our Bible

## Development

You'll need [Truffle](https://www.trufflesuite.com/truffle) installed:

`npm install truffle -g`

To compile contracts, run:

`truffle compile`

To migrate the contracts (i.e. deploy the contracts to a testnet), you'll need an instance of a testnet running locally. Ganache CLI is a useful tool for getting a local blockchain up and running.

First, install Ganache CLI:

`npm install -g ganache-cli`

Then, run the CLI:

`ganache-cli`

You can now migrate the contracts to the local blockchain:

`truffle migrate`

## Production

There are many ways to migrate a contract to the Ethereum mainnet.

You may be interested in [Truffle Teams](https://www.trufflesuite.com/teams) for pushing to the Ehtereum mainnet.

## Contribute

Find a bug? Want to make an improvement? Submit an issue or a pull request! 😃
