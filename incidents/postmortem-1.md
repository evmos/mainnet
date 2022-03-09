# Evmos V2 Upgrade Incident

## Authors

* Akash Khosla (evmos.org)
* Federico Kunze Küllmer (evmos.org)
* Joe Abbey (jabbey.io)
* Marko Barcevic (binary.holdings)
* Prajjwol Gautam (evmos.org)

### Date

2022-03-09

## Timeline

> *NOTE*: All times in UTC

### March 4th, 2022

*15:19* - IBC core team at Interchain GmbH notifies the Evmos core team of a potential security vulnerability
*15:25* - The Evmos teams responds to the notification and requests additional information of the component(s) affected, attack scenario(s), etc.

### March 5th, 2022

*10:58-11:38* - IBC Team replies with the attack scenario and suggests to avoid LP pool creation on the Osmosis chain and perform an upgrade to fix the vulnerability.

*11:55* - Discussion between teams about potential workarounds.

*12:50* - Evmos co-founder analyzes the full scope of the vulnerability score, and a new [critical security advisory](https://github.com/tharsis/evmos/security/advisories/GHSA-5jgq-x857-p8xw) is drafted.

*16:03* - A Telegram group is created to coordinate the Evmos Security Upgrade

*17:26* - Validators begin [collecting availability](https://docs.google.com/spreadsheets/d/1cTcZaGpsXUEN-WUg3wOeSnZmZ24Zz72u0zgVt6QzHzw/edit?usp=sharing), to gauge feasibilty of a manual emergency upgrade at height 46,000.

*20:17* - Upgrade plan restated, `v1.1.2` awaiting release due to testing

*21:27* - Insufficient network awareness achieved, determine best course of action is to delay for 20 hours at height 56,300.

*21:42 (March 5th) - 10:36 (March 6th)* - Core team consults with other Tendermint and Cosmos SDK core teams and experts regarding upgrade logic without governance upgrade to skip 5 day timeline for the emergency upgrade. Determined that safest way is to make a Cosmos SDK fork to call [`ScheduleUpgradeNoHeightCheck`](https://github.com/tharsis/evmos/pull/354/commits/e8b7fc6943cedecf404186d7449a2ddaa2cc179f) at upgrade height on `BeginBlocker` for both `v1.1.2` and `v2.0.0` in order to follow [Cosmovisor](https://docs.cosmos.network/master/run-node/cosmovisor.html) gov proposal upgrade path without having to reconstruct it entirely in Evmos codebase. Testing performed, upgrade works.

### March 6th, 2022

*12:35* - Upgrade logic for **`v1.1.2`** [is completed](https://github.com/tharsis/evmos/pull/354)

*12:44* - Upgrade logic merged, release being formed

*12:52* - [**`v1.1.2`**](https://github.com/tharsis/evmos/tree/v1.1.2) upgrade announced as needed immediately

*14:02* - Upgrade logic for **`v2.0.0`** [is completed](https://github.com/tharsis/evmos/pull/352/commits/08fce50bb725a23fbcb9d15cdb36684adc9b2e19) and is modified to support in-store migration logic within module instead of altering params outside of the module in the upgrade handler. After discussing with other Cosmos and Tendermint experts, it was made clear that migrations was a safer way to set new params and bump the consensus version of the module.

*14:54* - Code is peer reviewed for v2 upgrade logic

*14:58* - Code is merged for v2 upgrade logic

*15:00 - 17:37* - Rebase and review security advisory patch prior to merge with v2 release

*17:37* - Security advisory patch [merged](https://github.com/tharsis/evmos/commit/28870258d4ee9f1b8aeef5eba891681f89348f71) into [`release/v2.0.x`](https://github.com/tharsis/evmos/tree/release/v2.0.x) branch

*17:42* - [**`v2.0.0`**](https://github.com/tharsis/evmos/releases/tag/v2.0.0) released

*17:46* - [**`v2.0.0`**](https://github.com/tharsis/evmos/releases/tag/v2.0.0) upgrade announced, upgrade delayed to 58,700

*21:01* - Evmos core team runs another test, realizes that upgrade failed on the test, devs immediately start investigating and prepare for `v2.0.1`

*21:11* - As expected, people get a consensus failure for 58,700 to begin the upgrade process

*21:12* - [**`v2.0.0`**](https://github.com/tharsis/evmos/releases/tag/v2.0.0) Upgrade error reports begin, same error the core team found in *21:01*:

```shell
INF applying upgrade "v2" at height: 58700
INF migrating module claims from version 1 to version 2
panic: UnmarshalJSON cannot decode empty byte
```

*21:21* - Team announces to Discord that developers are working on a patch release

*21:27* - Core team and Cosmos developers understand that `GetParams` was breaking the migration and a [hotfix PR](https://github.com/tharsis/evmos/pull/363/commits/463992d65b2e999aa69f1df782315c167178e6b8) is merged

*21:33* - [**`v2.0.1`**](https://github.com/tharsis/evmos/releases/tag/v2.0.1) released, fixing the error

*21:35* - [**`v2.0.1`**](https://github.com/tharsis/evmos/releases/tag/v2.0.1) Upgrade begins

*21:40* - 67% consensus seems to have reached for 58700, but 58701 gets stuck in consensus rounds...

*21:41* - Reports of peer blocking / lost begin, possibly due to version discrepancies and people rebooting their nodes

*21:47* - Reports of `v2.0.0` being accidentally deployed on some validators

> no the problem is not git fetch, there is
an existing build in the directory and its
not getting replaced by new one

*21:50* - `consensus_state` hang reported

> I'm getting a hang when I run `curl -s localhost:26657/consensus_state`

*21:50* - Participants point out that rank #1 validator is missing pre-commit/pre-votes and the network not moving forward because not enough people correctly upgraded and are participating in the rounds now for 58701. Suggested that rank #1 and others such as #7 and #8 upgrade.

*21:50* - Further report of lost peers

*21:50 - 22:31* - Several validators restart their nodes due to peer issues while they try updating peer settings or try to get peers

*22:03* - Contact is made to rank #1 validator and other nodes to get online for 58701 and to participate in consensus rounds

*22:31* - Recommendations on peer settings appear, and peer gathering efforts begin by Evmos team in #validators-active

*22:44* - Report of resyncing

> Mystery, I think we had a db corruption with `2.0.0`, and he didn't want to vote for the next block. Resync the blockchain and upgrade it worked

*22:44* - Report of shutting down hanging, to address peering

> anyone notice that `v2.0.1` takes an incredibly long time to shut down?

*22:49* - Another validator begins to resync (`@jabbey`) the chain

> trying to resync the chain ... getting about 100 blocks / second (which felt like a bad idea.. but here we are)

*23:00* - Recommendations to use snapshot to have nodes participate in the consensus process again, if they are not seeing prevotes

*23:32* - Nodes reporting they are aggressively dropping in peers after starting the node, only 5/10 are online in prevoting stage

*23:41* - Advised that people remove their seeds as their old `addrbook.json` files and the fact they may not be updated is likely to cause nodes to have broken peers

*23:46* - Advised in step by step post that people should update peers, increase peering counts for inbound and outbound and delete their existing `addrbook.json`, and restart the node (note restarting the node likely meant the need to resync, didn't know it at the time)

### March 7th, 2022

*00:12* - New [peers list](https://hackmd.io/VTulVrhDQRmjhKRSu-Gv_A) to ensure upgraded peers and make more robust, due to concerns that GitHub `tharsis/mainnet` repository has an `addrbook.json` dump.

*00:39* - [Resync flow guide](https://hackmd.io/@y8_ti5SFRYSoiwFNMvJWtA/HJWeyCfWc) released.

*00:30 - 01:40* - Lots of double signing uncertainty. Core team reassured that, as long as the `priv_validator_state.json` file isn't deleted, people are going to be OK and won't double sign.

*01:17 - 01:50* - Coordinating with rank #1 validator to ensure they start their node as they were not in the latest consensus rounds. They were not willing to resume initially because of double signing fears, but after Evmos team member walked through steps to avoid double sign, they were online.

*01:50* - Block 58,701 produced

*01:52* - Reports of [byzantine behavior evidence](https://gist.github.com/joeabbey/4a15674aaab65945e0aa31ec3dbdbe83) (double sign) on 5 nodes:

| **Voting Power** |
| ---------------- |
| 7.62%            |
| 3.86%            |
| 3.03%            |
| 1.95%            |
| 0.57%            |
| **16.97% Total** |

After this happened, we had still not attained 67% of network voting power, and at the end of the struggle and seeing 5 double signs with ~17% of the voting power everyone seemed in agreement to halt the chain.

*02:00* - Participants show signs of fatigue (have been for awhile)

*02:25* - Agree amongst validators to turn off nodes because we'd have to wait again for the network to continue (it wasn't continuing after the double sign)

*02:52* - Published decision to delay official response 24 - 48 hours

## Five Whys

> Use the [root cause identification technique](https://en.wikipedia.org/wiki/Five_whys). Start with the impact and ask why it happened and why it have the impact it did. Continue asking why until you arrive at the root cause. Document your "whys" as a list here or in a diagram attached to the issue.

### Problem: the chain is halted

**Why is the chain halted?**

* Core Team released partially tested upgrade procedure code on mainnet
* Coordination of upgrade after consensus mistake was too high, team scheduled it for too soon, with only hours available to manage upgrading to new release
* Upgrade complexity went to an extreme (restarts, peers, resyncs/people moving to different machines)
* 5 validators double signed, causing them to be [tombstoned](https://docs.cosmos.network/master/modules/slashing/07_tombstone.html)
  * When validators are tombstoned, they cannot be unjailed
  * This is a serious fault. Tombstoning is essentially permanent jailing. Your validator is sunsetted forever. All the delegations are expected to manually unbond, which is a horrible scenario for delegators as well.
  * Considering the validators and users affected, it made sense not to continue the chain.
* After hours of trying to recover the network we witnessed multiple validators get tombstoned. The validator community & core team did not feel this was right and decided to halt the network until the upgrade was tested and ready to be used in production

**Why did 5 validators double sign?**

* They ran `unsafe-reset-all` during a consensus halt, causing them to destroy their `priv_validator_state.json`file.
  * Alternatively, some nodes migrated their validator node to another machine during this process and forgot to bring their `priv_validator_state.json`
* They didn't know that they had to back up and bring their `priv_validator_state.json` since it's typically not an issue when the chain is running normally, as most blocks will reach consensus in one round, and it wasn't explicit in an instructions manual to do so until it was too late.

**Why did so many validators run `unsafe-reset-all` and not keep their `priv_validator_state.json`?**

* Validators had to restore from snapshot because they were no longer contributing to consensus rounds if they restarted their node during the upgrade, so when doing this, they either deleted `$EVMOSD_HOME/data` entirely, or ran `unsafe-reset-all`. When doing this during a consensus halt, it is not safe (as the command points out in its title), and without backing up `priv_validator_state.json`, it's not fully understood how to recover.
* There were a lot of misunderstandings around `priv_validator_state.json`
* There was no clear answer regarding the impact of this file when it came to resyncing
  * There was lack of understanding that every round in consensus for the same block means a proposer change, and if the proposer came back and reran the rounds, which the 5 double signers did, they would throw two blocks.

**Why did validators have to restore from snapshots?**

* When the chain halted and people restarted their nodes during the halt, the node would not resume participating in consensus
  * When validators started `v2.0.1`, many thought there was a peering issue, as this is common in the cosmos ecosystem. After stopping their node to modify the peer list and/or increase the amount of connected peers, they restarted their node. We believe this caused a **limbo state** in Tendermint. This “limbo” state, as we refer to it, was a state in which Tendermint did not know if it should be in block sync mode or consensus mode thus **causing the node to sit idle**.
* Therefore the solution was to start from a fresh database using a snapshot
* During this time, many people overwhelmed the Polkachu endpoints, but operators managed to scramble and make mirrors of the Polkachu snapshot after downloading or synced the node from scratch
* Strong correlation between people who double signed and people who were proposer in the block
  * Examining the [proposer for each round in 58701](https://gist.github.com/joeabbey/315e072914b1cdc7872128b1f8235b6a) against the [byzantine behavior](https://gist.github.com/joeabbey/4a15674aaab65945e0aa31ec3dbdbe83).

    ```shell
    BF5FC06E32A4168817A16D69692F36C8F7A5DA37, proposed round 0, and double signed round 0.
    FF9F24A7DB626386EBA92D1E8D058474CEC40C26, proposed round 2, and double signed round 2.
    4F8EDD442959D0BB78F8CE0012BAD23AFEE6E08C, proposed round 4, and double signed round 4.
    76692115F93AE444FA857C7BA963F125D8C2E6C6, proposed round 8, and double signed round 8.
    9BA4035E5B58DAB71B6573791FDAA3D9E1C78A00, proposed round 10, and double signed round 10.
    ```

**Why did validators restart their nodes?**

* Some operators restarted because it "looked stuck"
* Other operators restarted because the no one could keep a solid set of peers
* Upgrade was more complex than any upgrade than most validators are used to

**Why could no one keep a solid set of peers?**

* We suspect that a lot of full nodes on the network (we had thousands) had not upgraded and people were querying invalid peers during the upgrade after some nodes initially restarted. The `addrbook.json` file of many nodes likely contained old version nodes that weren't compatible anymore and failed to peer.
* People were likely connected to seeds that didn't upgrade and were likely broadcasting their massive set of invalid `addrbook.json` peers.
* When people shut down during the upgrade, the fragility of the peering situation becomes worse.
* Several key nodes also didn't come to upgrade until later, meaning that a lot of key node operators were running old versions.
* We went and we ended up creating a peers list fresh out of the gate

**Why did we need an emergency `v1.1.2` release prior to the `v2.0.1`?**

* It required an upgrade handler to emergency upgrade the chain at height 58,700.
  * We didn't want to go through governance for the upgrade because it was a security vulnerability waiting to happen, and 5 days is too long to wait for patching a discoverable security vulnerability that breaks the claiming process and allows malicious actors to steal claims.

**Why did we not catch that `v2.0.0` would fail to upgrade earlier?**

* There was no automated test suite to catch the fault, so testing had to be either constructed from the ground up or manually done.
  * Manual testing was done up until the very last minute changes - however not all team members were up to speed on the need or ability to manually test during a migration.
* Because we changed the migration logic last minute to try and upgrade through the module migration (as this is safer practice than doing in upgrade handler), we tested this ~300 blocks before the upgrade.
  * We didn't have enough time to gather staff available and ready to test this hours before, because it was a manual test and required deep knowledge of the upgrade.
* When we used the old upgrade handler logic (setting new params in the upgrade handler), that was tested and working when upgrading with cosmovisor at a specified block height, but it wasn't inline with best practices because setting new params should be done in a migration handler in the module itself. When writing the migration handler, we were trying to fetch the existing params and setting it, but `GetParams` when you are running a migration will return empty bytes.
  * So the [fix was to set all the new params in the migration](https://github.com/tharsis/evmos/pull/363) without retrieving the old parameters from the store.
* When we did test the migration logic and caught the failure, it was 300 blocks behind as other Evmos engineers came back online. By then, it was too late, and Evmos had to accept the upgrade fate at 58,700.

**Why did this upgrade get so complex for validators?**

* Several errors were made by Evmos team when coordinating the emergency upgrade
  * Not testing `v2.0.0` prior to release, causing a second update
    * The upgrade should have been delayed / not been put out if not tested
  * Tight release timeline due to the severity of the vulnerability
    * Notice was given 24 hours at least and block heights got somewhat pushed back, but the releases were cut hours before the upgrade, meaning that validators had to be online to swap binaries
    * The upgrade was very aggressive.
    * Timeline was picked before the fix was made, which is not how security incidents should be handled
      * Even if user funds are at risk, a fix should be found before going public, even to wider validator group
  * Using cosmovisor for this on an infeasible timeline, when the original design was making the state machine compatible until fork height, requiring a manual upgrade
    * The team over estimated cosmovisor importance amongst node operators

**Why did it take so many rounds to try and upgrade?**

* Voting power wasn't there, we were 66% at some rounds, for 10 rounds, meaning for hours and hours.

**Why did people need to rely on snapshots and resync from `v1.1.2` to reapply the upgrade to `v2.0.1`?**

* When validators started `v2.0.1`, many thought there was a peering issue, as this is common in the cosmos ecosystem. After stopping their node to modify the peer list and/or increase the amount of connected peers, they restarted their node. We believe this caused a limbo state in tendermint. This "limbo" state, as we refer to it, was a state in which Tendermint did not know if it should be in block sync mode or consensus mode thus causing the node to sit idle. To recover from this limbo state, users were required to delete their databases and recover from a snapshot from before the upgrade and sync till the upgrade height, then change to `v2.0.1`.

## Remediation

### Documentation

* [x] Create documentation for validators to deploy and run a Key Management Service (KMS) for Tendermint (`tmkms`) or multi-party-computation signing service for nodes (`horcrux`).
* [ ] Clear instructions to **NEVER** `unsafe-reset-all` without saving a local copy of `priv_validator_state.json`, stating the importance of this file. A new command has been added to tendermint that does a [safe-reset](https://github.com/tendermint/tendermint/pull/8081).
* [ ] Manual Upgrade and Emergency Upgrade documents for Validators in case the automated upgrade fails to prevent FUD.
* [ ] Ensure that seed/peer operators know to upgrade their full nodes during this process
  * [ ] Figure out how to have a peer list that is tested for working peers by CI or a Discord bot.

### Chain Upgrade

* [ ] Genesis JSON file export at height 58,699 (i.e before validator double-signing) OR restart the chain at height 0.
* [ ] Restart the chain with a new release that includes additional fixes (TBA).

### Engineering

* [ ] Create How-to Guide for Cosmos SDK chain upgrades
* [ ] Create integration and E2E tests for upgrades, both for automated upgrades (Cosmovisor) and manual upgrades.
* [x] Open an improvement [PR](https://github.com/tendermint/tendermint/pull/8081) on Tendermint Core to to ONLY reset the db instead of also wiping the `priv_validator_state.json` when running `unsafe-reset-all`.
* [x] Post Mortem document of the incident and remediations
