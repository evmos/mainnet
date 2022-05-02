# Evmos `9001-2`

## Overview

- Network Chain ID: `evmos_9001-2`
- EIP155 Chain ID: `9001`
- `evmosd` version: [`v3.0.0`](https://github.com/tharsis/evmos/releases)

## Schedule

- **Genesis Timestamp (UTC)**: `2022-04-27T16:00:00Z`
- **Airdrop Start Timestamp (UTC)**: `2022-04-29T16:00:00Z`

## Instructions

## Full nodes and general participants

Follow the instructions on the official documentation to [carry out a manual upgrade](https://docs.evmos.org/validators/upgrades/manual.html) with a [data reset](https://docs.evmos.org/validators/upgrades/manual.html#_3-data-reset).

> NOTE: for more info. Check the official Evmos [documentation](https://docs.evmos.org/validators/upgrades/upgrades.html) for the `evmos_9001-2` upgrade.

### Genesis File

1. Download the zipped genesis file [genesis.json.zip](https://github.com/tharsis/mainnet/raw/main/evmos_9001-2/genesis.json.zip)

2. Extract it with command:

    ```bash
      unzip genesis.json.zip
    ```

3. Verify the SHA256 checksum using:

    ```bash
      sha256sum genesis.json

      # 4aa13da5eb4b9705ae8a7c3e09d1c36b92d08247dad2a6ed1844d031fcfe296c  genesis.json
    ```

    or alternatively, from the `config/` directory:

    ```bash
      cd $HOME/.evmosd/config
      echo "<expected_hash>  genesis.json" | sha256sum -c
    ```

### Step-by-Step

These are abbreviated version of the instructions linked above.

1. Move the genesis file into your config:

    ```bash
    cp -f genesis.json $HOME/.evmosd/config
    ```

2. **BACK UP ALL PRIVATE KEYS, YOU WILL NEED THESE FOR MAINNET**
3. Remove any previous state

    ```bash
    rm $HOME/.evmosd/config/addrbook.json
    evmosd tendermint unsafe-reset-all --home=$HOME/.evmosd
    ```

4. Start the chain:

    ```bash
    evmosd start
    ```

## Seeds & Peers

You can find seeds & peers on the `seeds` channel on the [Evmos Discord](https://discord.gg/evmos)
