## Polygon zkEVM x RocketPool Investment Manger 

contract for staking  some of the underlying ETH in the bridge with RocketPool


## Get started

### Requirements

This repository is using foundry. You can install foundry via
[foundryup](https://book.getfoundry.sh/getting-started/installation).


### Setup

Clone the repository:

```sh
git clone https://github.com/0xKaizendev/zkevm-bridge-investment-manager.git
cd zkevm-wsteth/
```

Install the dependencies:

```sh
forge install
```


### Tests

Create `.env` with the following contents:

```
RPC_URL=""
```
Use the following command to run the test:

```sh
forge test
```