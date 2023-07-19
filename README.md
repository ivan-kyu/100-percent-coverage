## Installation

```
forge install
```

## Run tests

```
forge test
```

## Start local node

```
anvil
```

## Environment variables

Create an .env file in the main dir and fill the variables as shown in .env.example

## Deploy contracts to local node

In another terminal execute:

```
source .env && forge script script/Deploy.s.sol:DeployScript --rpc-url $RPC_URL --broadcast
```

## Deploy contracts to testnet and verify

```
source .env && forge create \
    --rpc-url $RPC_URL \
    --private-key $DEPLOYER_PK \
    --etherscan-api-key $ETHERSCAN_API_KEY \
    --verify \
    src/LimeToken.sol:LimeToken
```

## Verify existing contract

```
source .env && forge verify-contract \
    --chain-id 80001 \
    --watch \
    --etherscan-api-key $ETHERSCAN_API_KEY \
    --compiler-version v0.8.10+commit.fc410830 \
    0x35fB629E24faD1ECEF47F37d9ACdee5bd97fea73 \
    src/LimeToken.sol:LimeToken
```
