# Evmos - Adding Feesplit module upgrade

## Authors

Daniel Burckhardt (evmos.org)

## Date

2022-10-12

## Brief Overview

- There is a bug in the Evmos `v8.1.0` upgrade. The upgrade registers an outdated upgrade name, so that the feesplit module is added without running the store upgrade. Without this store upgrade, new modules that are added to the chain don't work.
- Impact: Feesplit module queries and transactions are unsuccessful. Other modules are unaffected.

## Timeline

### August 17, 2022

Validators perfom a [scheduled Evmos Testnet](https://testnet.mintscan.io/evmos-testnet/proposals/66) Software upgrade at block [4,600,000](https://testnet.mintscan.io/evmos-testnet/blocks/4600000) from Evmos `v7.0.0` to `v8.0.0`. This upgrade registers the correct [upgrade handler](https://github.com/evmos/evmos/blob/v8.0.0/app/app.go#L1089) and the necessary [store upgrade](https://github.com/evmos/evmos/blob/v8.0.0/app/app.go#L1121) to introduce the new feesplit module. After the upgrade, we test the feesplit functionality successfully by registering contracts for feesplits on Testnet and confirming the fee destribution when interacting with registered contracts using the CLI.

### August 22, 2022

Based on successful testing on Testnet, we propose a [Mainnet Software upgrade](https://www.mintscan.io/evmos/proposals/50) from `v7.0.0` to `v8.0.0`.

### August 25, 2022

Our team reports that frontend applications cannot use the feesplit module on Testnet. It is discovered that `v8.0.0` does not support signing transactions with eip712 for feesplit messages and cannot be implemented in [evmosjs](https://github.com/evmos/evmosjs) due to the lack of registering the amino codec for these messages.

We decide that this is a blocker for upgrading Mainnet to `v8.0.0` and recommend to validators and the community to reject the active proposal.

Taken from Evmos Discord #mainnet-announcements:

> @Validators  @Future Validators Hey everyone, we discovered on Testnet that the feesplit registration does not support signing transactions with eip712 on version v8.0.0.
>
> We already implemented the required changes on Ethermint(https://github.com/evmos/ethermint/pull/1288) and Evmos(https://github.com/evmos/evmos/pull/859) (which we will create a new release for) and would like to delay the Mainnet upgrade to deliver the full experience to you on Mainnet.
>
> To delay the upgrade we need your action! Please vote "no" on the Mainnet upgrade proposal (https://www.mintscan.io/evmos/proposals/50) 🙏

### August 27, 2022

The voting time for the Mainnet [v8.0.0 upgrade proposal](https://www.mintscan.io/evmos/proposals/50) ends with a final status: "rejected".

### September 1, 2022

Validators perform a [scheduled Evmos Testnet](https://testnet.mintscan.io/evmos-testnet/proposals/72) Software upgrade at block [5,320,000](https://testnet.mintscan.io/evmos-testnet/blocks/5320000) from Evmos `v8.0.0` to `v8.1.0`. This upgrade adds a state machine breaking change to register the missing amino codec for the feesplit module.

After changing the evmosd version to `v8.1.0`, validators discovered that the node couldn't start because they were getting a database error. After debugging the issue with members of the SDK team, we found a quick fix changing the pruning settings to `nothing`. After applying that change the node started to work correctly. The `v8.0.0` also included some database changes so we didn't know if the problem was related to database changes or anything else.

### September 21, 2022

Validators perform a [scheduled Evmos Mainnet](https://www.mintscan.io/evmos/proposals/50) software upgrade at block [3,620,000](https://www.mintscan.io/evmos/blocks/3620000) from Evmos `v7.0.0` to `v8.1.0`.

This upgrade registers the correct [upgrade handler](https://github.com/evmos/evmos/blob/v8.1.0/app/app.go#L1097) but **does not** include the correct upgrade name for the necessary store upgrade to introduce the new feesplit module. Instead of `v8.1.0`, the upgrade name is set to [`v8.0.0`](https://github.com/evmos/evmos/blob/v8.1.0/app/app.go#L1130), so that the store upgrade logic is not performed on Mainnet. Before this upgrade, Mainnet was running on v7.0.0 and hadn't introduced the feesplit module yet. This means, a new module has been added to Mainnet without upgrading the store.

On the same day, the missing store upgrade is disclosed to the Evmos team within a telegram chat including Cosmos SDK contributors.

### September 23, 2022

After close evaluation on how to add the missing store upgrade on Mainnet, we discover that the cleanest solution is to rename the module on Mainnet by planning an upgrade that deletes the `feesplit` module and adds it as `revenue` module.

After running our upgrade tests locally, we release Evmos v8.2.0 which includes the [rename and the store upgrade](https://github.com/evmos/evmos/blob/v8.2.0/app/app.go#L1146). The testing precedure is extended to perform the planned upgrade locally and perform queries and transactions for the new module on the upgraded local node.

In order to fix the broken module on Mainnet we decide to perform an upgrade to v8.2.0 using a [Hard Fork procedure](https://docs.evmos.org/validators/upgrades/overview.html#hard-forks).

To schedule the hard fork, we release a non-breaking release `v.8.1.1` that sets the upgrade height for the v8.2.0 emergency Mainnet upgrade. This procedure automatically applies the changes from an upgrade plan at given block height without the need for a governance proposal.

### September 26, 2022

Validators perform a [scheduled hard fork on Evmos Mainnet](https://www.mintscan.io/evmos/proposals/50) at block [4,888,000](https://www.mintscan.io/evmos/blocks/4888000) from Evmos `v8.1.1` to `v8.2.0`. This release successfully registers the now renamed revenue module.

## Five Whys

> Use the [root cause identification technique](https://en.wikipedia.org/wiki/Five_whys). Start with the impact and ask why it happened and why it have the impact it did. Continue asking why until you arrive at the root cause. Document your "whys" as a list here or in a diagram attached to the issue.

### Problem: Feesplit module queries and transactions are unsuccessful after upgrading Mainnet to `v8.1.0`.

**Why did the new feesplit module not work on Mainnet?**

The upgrade was missing a store upgrade, because we registered the wrong update name.

**Why did we register the wrong store upgrade name?**

Because our upgrade testing process wasn't sufficient and the diversion of  upgrade history on Testnet and Mainnet made communication prone to errors.

**Why wasn't the upgrade tested sufficiently?**

Because our upgrade testing is run manually the testing expectation hadn't been adjusted to test the functionalities of a new module with an upgraded local node.

**Why wasn't the testing expectation adjusted?**

Because we added a new module for the first time after launch and there is no process in place for aligning on the exact testing expectation for upgrades.

## What went well/Where we got lucky

* Once the issue was disclosed to us, we reacted quickly investigate  the most straight*forward solution and confirmed with advisors to the team on how to proceed.
* Only the newly added module was affected. Everything else worked fine.

## What went poorly

* The upgrade handler Pull Request review could have caught the wrong store upgrade.
* We could have communicated better our expectations on how to test the upgrade.

## Remediation

### Testnet

* Upgrade Testnet v8.1.0 => 8.2.3 to rename the feesplit to revenue module. Currently there are no registered contracts on Testnet. Even if there are contracts registered, the upgrade works successfully.

### Release Versioning: Should we achieve parity between Testnet and Mainnet?

There are two options to consider:

* introduce release (e.g. `v8-rc1` or similar) candidates on Testnet until we are ready on Mainnet, but this wouldn't allow parity
* introduce release candidates on localnet and only move to Testnet once we are confident about it.