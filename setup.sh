#!/bin/bash
# Setup node on Testnet

# Configuration
MONIKER=ImStaked
APP_TOML="$HOME/.mantrad/config/app.toml"
CONFIG_TOML="$HOME/.mantrad/config/config.toml"
BINARY_URL="https://testnet-files.itrocket.net/mantra/mantrachaind-linux-amd64.zip"
GENISIS_URL="https://testnet-files.itrocket.net/mantra/genesis.json"
CHAIN_ID="mantrachain-testnet-1"
INDEXER="null"
MINIMUM_GAS_PRICE="0.0001uaum"
SEEDS="a9a71700397ce950a9396421877196ac19e7cde0@mantra-testnet-seed.itrocket.net:22656"
PEERS="1a46b1db53d1ff3dbec56ec93269f6a0d15faeb4@mantra-testnet-peer.itrocket.net:22656,63763bfb78d296187754c367a9740e24730a7fc4@167.235.14.83:32656,64691a4202c1ad29a416b21ce21bfc9659783406@34.136.169.18:26656,d44eb6a1ea69263eb0a61bab354fb267396b27e1@34.70.189.2:26656,62cadc3da28e1a4785a2abf76c40f1c4e0eaeebd@34.123.40.240:26656,c4bec34390d2ab1004b9a25580c75e4743e033a1@65.108.72.253:22656,e6921a8a228e12ebab0ab70d9bcdb5364c5dece5@65.108.200.40:47656,2d2f8b62feee6b0fcbdec78d51d4ba9959e33c87@65.108.124.219:34656,4a22a9cbabe4313674d2058a964aef2863af9213@185.197.251.195:26656,c0828205f0dea4ef6feb61ee7a9e8f376be210f4@161.97.149.123:29656,30235fa097d100a14d2b534fdbf67e34e8d5f6cf@65.21.133.86:21656"
# Can be everything for a validator
PRUNING="default"
# Address to listen for incoming connections 
MANTRA_ADDR="tcp://0.0.0.0:26656"
# Address to advertise to peers so they can connect
# Should be domain:port - "example.com:26656"
MANTRA_EXTERNAL_ADDR="example.com:26656"
# Enable Metrics
ENABLE_METRICS=true
METRICS_ADDR="0.0.0.0:26660"

# Install Prerequisites
sudo apt update && sudo apt upgrade -y
sudo apt install lz4 unzip jq
sudo wget -O /usr/lib/libwasmvm.x86_64.so https://github.com/CosmWasm/wasmvm/releases/download/v1.3.0/libwasmvm.x86_64.so

# Install the binary
wget $BINARY_URL
unzip mantrachaind-linux-amd64.zip
rm mantrachaind-linux-amd64.zip
sudo mv mantrachaind /usr/local/bin/mantrad

# Initialize the node
mantrad init $MONIKER --chain-id $CHAIN_ID --home $HOME/.mantrad
wget -O $HOME/.mantrad/config/genesis.json $GENESIS_URL 

# Edit the app.toml file
sed -i.bak -E "s|^(pruning[[:space:]]+=[[:space:]]+).*$|\1\"$PRUNING\"| ; \
s|^(minimum-gas-prices[[:space:]]+=[[:space:]]+).*$|\1\"$MINIMUM_GAS_PRICE\"|" $APP_TOML 

# Edit the config.toml file
sed -i.bak -E "s|^(prometheus[[:space:]]+=[[:space:]]+).*$|\1\"$ENABLE_METRICS\"| ; \
s|^(indexer[[:space:]]+=[[:space:]]+).*$|\1\"null\"| ; \
s|^(external_address[[:space:]]+=[[:space:]]+).*$|\1\"$MANTRA_EXTERNAL_ADDR\"| ; \
s|^(laddr[[:space:]]+=[[:space:]]+).*$|\1\"$MANTRA_ADDR\"| ; \
s|^(prometheus_listen_addr[[:space:]]+=[[:space:]]+).*$|\1\"$PROMETHEUS_ADDR\"| ; \
s|^(persistent_peers[[:space:]]+=[[:space:]]+).*$|\1\"$PEERS\"| ; \
s|^(seeds[[:space:]]+=[[:space:]]+).*$|\1\"$SEEDS\"|" $CONFIG_TOML


# Install the systemd service
sudo <<EOF >> /etc/systemd/system/mantrad.service
[Unit]
Description=Mantra Validator
After=network-online.target
[Service]
User=$USER
WorkingDirectory=$HOME/.mantrad
ExecStart=/usr/local/bin/mantrad start --home $HOME/.mantrad
Restart=on-failure
RestartSec=5
LimitNOFILE=65535
[Install]
WantedBy=multi-user.target
EOF
systemctl daemon-reload
systemctl enable mantrad

# reset and download snapshot from https://itrocket.net/services/testnet/mantra/installation/
mantrachaind tendermint unsafe-reset-all --home $HOME/.mantrachain
if curl -s --head curl https://testnet-files.itrocket.net/mantra/snap_mantra.tar.lz4 | head -n 1 | grep "200" > /dev/null; then
  curl https://testnet-files.itrocket.net/mantra/snap_mantra.tar.lz4 | lz4 -dc - | tar -xf - -C $HOME/.mantrachain
    else
  echo no have snap
fi

# Start the service
systemctl start mantrad
# Start the node