# Evmos Mainnet

## Instructions

### Genesis Validators

Follow the instructions on the ["Running as a genesis validator"](https://github.com/tharsis/mainnet/blob/main/run.md) guide.

### Full nodes and general participants

Follow the instructions on the official documentation to [join the mainnet](https://evmos.dev/mainnet/join.html).

## Genesis File

Download the minified genesis file [`genesis.json`](https://archive.evmos.org/genesis/genesis.json)

Verify the SHA256 checksum using:

```bash
sha256sum genesis.json
# 0d25dd7abf7325e518519ca2289775f611c0beaf1a2caf3a6b080e66168c2d6e  genesis.json
```

## Details

- Network Chain ID: `evmos_9001-2`
- EIP155 Chain ID: `9001`
- `evmosd` version: [`v2.0.1`](https://github.com/tharsis/evmos/releases)
- EVM explorer: [evm.evmos.org](https://evm.evmos.org)
- Cosmos explorer: [explorer.evmos.org](https://explorer.evmos.org)

## Schedule

### Application Period

Submissions open on February 26, 2022 18:00 UTC, participants are required to [submit gentx](./gentx.md).

Submissions close on February 27, 2022 12:00 UTC.

### Genesis Launch

March 2, 2022 18:00 UTC.
