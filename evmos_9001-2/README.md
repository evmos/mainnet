# Evmos Mainnet evmos_9001-2

## Instructions

## Full nodes and general participants

Follow the instructions on the official documentation to [carry out a manual upgrade](https://docs.evmos.org/validators/upgrades/manual.html) with a [data reset](https://docs.evmos.org/validators/upgrades/manual.html#_3-data-reset).

## Genesis File

Download the zipped genesis file [genesis.json.zip](./genesis.json.zip)

Extract it with command

```bash
unzip genesis.json.zip
mv genesis.json genesis.json
```

Verify the SHA256 checksum using:

```bash
sha256sum genesis.json
# 75dc34ff91afba87af0c68f3e96382909b8a979fd8df0897fc43b4da483bbeb1  genesis.json
```

## Step-by-Step

These are abbreviated version of the instructions linked above.

1. Move the genesis file into your config

```
cp -f genesis.json $HOME/.evmosd/config
```

2. **BACK UP ALL PRIVATE KEYS**

3. Remove any previous state

```
rm $HOME/.evmosd/config/addrbook.json
evmosd tendermint unsafe-reset-all --home=$HOME/.evmosd
```

4. Start the chain

```
evmosd start
```

## Details

- Network Chain ID: `evmos_9001-2`
- EIP155 Chain ID: `9001`
- `evmosd` version: [`v3.0.0`](https://github.com/tharsis/evmos/releases)

## Schedule

Genesis: `2022-04-27T16:00:00Z`

Airdrop: `2022-04-29T16:00:00Z`

## Seeds & Peers

You can find seeds & peers on the seeds.txt and peers.txt files, respectively. If you want to share your seed or peer, please fork this repo and and add it to the bottom of the corresponding .txt file.
