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
