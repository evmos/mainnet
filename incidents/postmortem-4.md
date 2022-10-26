# Postmortem - Airdrop Clawback Bug

Reference: https://github.com/evmos/mainnet/blob/main/incidents/postmortem-2.md

## Authors

- Guillermo Paoletti - [Hanchon.live](https://www.mintscan.io/evmos/validators/evmosvaloper1dgpv4leszpeg2jusx2xgyfnhdzghf3rf0qq22v)
- Federico Kunze Küllmer - Evmos

## Date

10/05/2022

## Brief Overview

- There was a bug in the claims' module clawback function.
- Accounts that had claims records, evmos balance different than 0 and didn't sent any transaction (i.e sequence 0) got their founds moved to the community pool account.
- The IBC module (ICS20) account had claims records incorrectly assigned to it on the genesis file, so that account was also affected.

### Impact

- 1,8k accounts got their EVMOS balance incorrectly moved to the community pool account, which is controlled via governance.
- The IBC module account being affected made some transactions from Osmosis chain to Evmos chain fail to be executed, because the IBC module account didn't have enough coins to make the transfer. Funds are safe, but IBC transactions may fail if they try to send more EVMOS than the current IBC module account balance.

## Timeline

### Sept 29

The claims' module clawback function was executed, it made some validators to run out of memory and halt the chain for 30min.

Validators affected were the ones running hardware with less than 64gbs of ram.

After setting up correctly the swap and improving the servers configuration the network started to create blocks every 2 seconds.

### Oct 2

We got a report about a user having 32 EVMOS dissapearing from their wallet. The user had received the founds from an exchange transaction that moved the Evmos using a EVM transfer. The balance from that account changed arround the clawback time.

We start to investigate the issue, making sure that the transaction that sent the EVMOS was a standard transaction and also that the EVM and Cosmos explorer were reporting the correct information and it wasn't an indexer bug.

We find that everything is looking good for the explorers and transaction, so we start investigating the claims' module clawback function.

Later that day we got a report that some IBC transfers were failing:
![IBC Failed tx](https://i.imgur.com/gfmvRYk.jpg)

We run the same evmosd calls to make sure that it was the same bug as the other user:

```sh
evmos@evmostest:~/evmos8.2.0/bin$ ./evmosd q bank balances evmos1a53udazy8ayufvy0s434pfwjcedzqv345dnt3x --height 5074186
balances:
- amount: "3167501226339726493675414"
  denom: aevmos
- amount: "100"
  denom: ibc/25813B5DF7C0AF9FB79A71EF8E67FE4E182A03BB4145D248DADFAF74006835B2
- amount: "11000"
  denom: ibc/5CC0E9B98B8C719E3378F941B40A4FAC9F750A155F3788E4C449144C08EA4537
- amount: "12274000"
  denom: ibc/693989F95CF3279ADC113A6EF21B02A51EC054C95A9083F2E290126668149433
- amount: "12000000000000000"
  denom: ibc/6B3FCE336C3465D3B72F7EFB4EB92FC521BC480FE9653F627A0BD0237DF213F3
- amount: "1000000"
  denom: ibc/7F0C2CB6E79CC36D29DA7592899F98E3BEFD2CF77A94340C317032A78812393D
- amount: "2310000"
  denom: ibc/A4DB47A9D3CF9A068D454513891B526702455D3EF08FB9EB558C561F9DC2B701
- amount: "100000000000000000"
  denom: ibc/D8921A62D207159A25FFEA0DB4E7DB623A095219B60D99768CCE9D3DF66122C7
pagination:
  next_key: null
  total: "0"
evmos@evmostest:~/evmos8.2.0/bin$ ./evmosd q bank balances evmos1a53udazy8ayufvy0s434pfwjcedzqv345dnt3x --height 5074187
balances:
- amount: "100"
  denom: ibc/25813B5DF7C0AF9FB79A71EF8E67FE4E182A03BB4145D248DADFAF74006835B2
- amount: "11000"
  denom: ibc/5CC0E9B98B8C719E3378F941B40A4FAC9F750A155F3788E4C449144C08EA4537
- amount: "12274000"
  denom: ibc/693989F95CF3279ADC113A6EF21B02A51EC054C95A9083F2E290126668149433
- amount: "12000000000000000"
  denom: ibc/6B3FCE336C3465D3B72F7EFB4EB92FC521BC480FE9653F627A0BD0237DF213F3
- amount: "1000000"
  denom: ibc/7F0C2CB6E79CC36D29DA7592899F98E3BEFD2CF77A94340C317032A78812393D
- amount: "2310000"
  denom: ibc/A4DB47A9D3CF9A068D454513891B526702455D3EF08FB9EB558C561F9DC2B701
- amount: "100000000000000000"
  denom: ibc/D8921A62D207159A25FFEA0DB4E7DB623A095219B60D99768CCE9D3DF66122C7
pagination:
  next_key: null
  total: "0"
```

That confirmed that the IBC module account was affected by the same issue, because the account had claims records incorrectly assigned to it:

```sh
evmos@evmostest:~/evmos8.2.0/bin$ ./evmosd q claims record evmos1a53udazy8ayufvy0s434pfwjcedzqv345dnt3x --height 5074186
claims:
- action: ACTION_VOTE
  claimable_amount: "-1555021112861182544"
  completed: false
- action: ACTION_DELEGATE
  claimable_amount: "-1555021112861182544"
  completed: false
- action: ACTION_EVM
  claimable_amount: "-1555021112861182544"
  completed: false
- action: ACTION_IBC_TRANSFER
  claimable_amount: "-1555021112861182544"
  completed: false
initial_claimable_amount: "167871611791302033408"
```

We found the issue on the clawback code, affecting these accounts:
https://github.com/evmos/evmos/blob/main/x/claims/keeper/abci.go#L124

```go
if seq != 0 {
    return false
}

clawbackCoin := k.bankKeeper.GetBalance(ctx, addr, claimsDenom)
```

The code assumed that if the account didn't sent any transaction (`seq == 0`), the account didn't complete any claims' mission, so we can clawback the dust assigned to that account back to the community account.

The issue here is that the code didn't consider the case where users with claims records that just moved coins to their accounts but didn't send any transaction. (They didn't stake, transfer nor claim any of the claims missions)

For example a user that bought coins from an exchange and send it to its wallet (that had claims records) just to hold Evmos will be incorrectly flagged and all their Evmos will be moved to the community account.

### Oct 3

We have the issue already detected so we start working on the chain analysis to get how many wallets were affected by this bug and if any other module account affected.

We start by getting all wallets from the genesis file and quering the balance at the block `5074186` (pre-clawback block) and their sequence number.
We start to store all the wallets that had Evmos balance different to the dust assigned on the genesis file and their sequence number was 0.

This first filter was applied to the 1.8M wallets and it returned ~15k wallets, of which 2,4k were affected.

```sh
sqlite> select count(*) from claims;
15744
sqlite> select count(*) from claims where balance != "0";
2433
```

Wallets with balance equal `0` were not affected by this because the code only moved Evmos coins.

That was a good first approach to get the damage done by the bug, for our second filter we removed all the accounts that didn't have any claims records but were picked up when parsing the complete genesis file, resulting on a total of `1812` wallets affected.

```sh
sqlite> select count(*) from claims;
1812
```

With this information we start to look for all the module account in the database to make sure that only the IBC module was affected. We found that was the case.

### Oct 4

We move all the data colected to a google sheets file so a desition can be made on how to solve the issue.

After reviewing all the data, it was decided to make a proposal to move the community founds back to the IBC module account to restore the module as soon as posible, and start working on a upgrade to refound all the other affected users in the upgrade handler.

## Five Whys

**Why did the some accounts got their Evmos dissapeared?**

Because there was a bug on the clawback function that made accounts with claims records and no transactions be incorrectly flagged. This included the IBC transfer (ICS20) module account.

**Why did the ICS20 module account get clawed back?**

Because the module account had claims records.

**Why did the module account have a claims record?**

Because the script that we used to generate the genesis file incorrectly added the module account to the claims' module rektdrop list

**Why was the genesis file generated incorrectly?**

There was a mismatched balance on the genesis file and we went with the fastest path to launch which was to create the module account with the standard account type, and it wasn't understood upfront that we needed to create a module specific account.

**Why was it not understood that we needed to create a module specific account?**

There wasn't a strong review process when it came to genesis file creation. Changes to the genesis file were not easy to review as it's a massive JSON blob. So any reviewable mutations have to be scripted and then the scripts have to be reviewed and sanity checked with tests. Few things in a genesis file can be manually reviewed. In this case, it had to do with the accounts, which is a massive list and reviewers of the JSON are unlikely to catch bad entries.

## What went well

- As soon as we got the report we created a private channel to investigate the issue and found the root cause pretty fast.

## What went poorly

- We were not monitorizing the evmosd nodes when the clawback was executed
- Took a while to figure out what accounts were affected
- We had no idea this was an issue until someone reported it (essentially IBC dead)
- Someone reported the issue Oct 2nd, but the clawback happened on September 30th, so there was a 2 day delay on beginning to address the issue of broken IBC

## Where we got lucky

- The prunning bug 2 upgrades ago allow us to have some "semi-archive" nodes available to run locally the script to analize the chain records. Without that bug, we probably needed to use the public infra and the scripts would take 50hours instead of just 1hour to run.
- The accounts that did the recovery/attestation were not actually deleted from the account module, so all the IBC balance on that accounts are safe

## Remediation

- [x] Write a script that checks what accounts were affected in the clawback. (https://github.com/evmos/claims_fixer)
- [x] Community pool spend proposal to send funds back to the module account.
- [x] Fix the code in the claims module to prevent clawing back from module accounts and from accounts that have a positive balance of other IBC denominations.
- [x] Make the script to get the founds to be sent back to the affected addresses public for the community to review it. (https://github.com/evmos/claims_fixer)
- [x] Test the upgrade handlers for the account migrations and the balances transfers.
- [ ] Check if the same bug affected testnet.
