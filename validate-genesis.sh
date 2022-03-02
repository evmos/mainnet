#!/bin/bash
EVMOS_HOME="/tmp/evmosd$(date +%s)"
RANDOM_KEY="randomevmosvalidatorkey"
MAXBOND="15901060070671400000" # 15.90106 EVMOS
GENACC_BALANCE="17000000000000000000" # 17 EVMOS

# NOTE: This script is designed to run in CI.

print() {
    echo "$1" | boxes -d stone
}

set -e
echo "Cloning the Evmos repo and building $BINARY_VERSION"

rm -rf evmos
apt install git-lfs -y
git clone "$GH_URL" > /dev/null 2>&1
cd evmos
git checkout tags/"$BINARY_VERSION" > /dev/null 2>&1
make build > /dev/null 2>&1
chmod +x "$DAEMON"

# Adding random validator key so that we can start the network ourselves
$DAEMON keys add $RANDOM_KEY --keyring-backend test --home "$EVMOS_HOME" > /dev/null 2>&1
$DAEMON init --chain-id $CHAIN_ID validator --home "$EVMOS_HOME" > /dev/null 2>&1

# Move the genesis to $EVMOS_HOME
cp "$PROJECT_DIR"/genesis.json "$EVMOS_HOME"/config/genesis.json

# Setting the genesis time earlier so that we can start the network in our test
sed -i '/genesis_time/c\   \"genesis_time\" : \"2021-03-29T00:00:00Z\",' "$EVMOS_HOME"/config/genesis.json

# Add genesis account
$DAEMON add-genesis-account $RANDOM_KEY $GENACC_BALANCE$DENOM --home "$EVMOS_HOME" \
    --keyring-backend test

$DAEMON gentx $RANDOM_KEY $MAXBOND$DENOM --home "$EVMOS_HOME" \
    --keyring-backend test --chain-id $CHAIN_ID

$DAEMON collect-gentxs --home "$EVMOS_HOME"

sed -i '/persistent_peers =/c\persistent_peers = ""' "$EVMOS_HOME"/config/config.toml
echo "Run validate-genesis on created genesis file"
$DAEMON validate-genesis --home "$EVMOS_HOME"

echo "Starting the node to get complete validation (module params, signatures, etc.)"
$DAEMON start --home "$EVMOS_HOME" &

sleep 10s

echo "Checking the status of the network"
$DAEMON status --node http://localhost:26657

echo "Killing the daemon"
pkill evmosd > /dev/null 2>&1

echo "Cleaning the files"
rm -rf "$EVMOS_HOME" >/dev/null 2>&1


echo "Done."
