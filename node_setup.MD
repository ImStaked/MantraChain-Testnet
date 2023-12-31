# MantraChain-Testnet

## Node Setup

- Create a user account to use
  ```
  useradd -U -m -d /home/mantra -s /bin/bash mantra
  usermod -G sudo,sys,adm mantra 
  passwd mantra
  ```
  ```
  su mantra   
  cd /home/mantra
  ```
- Setup the environment variables. Fill in your moniker and edit the settings found below as needed  
  Then copy this block of text and paste into your terminal
  ```
  MONIKER=Testing
  # External Address should be domain:port but can be ip:port or blank. Using domain:port allows both ipv4 and ipv6 name resolution
  EXTERNAL_ADDR=""
  MINIMUM_GAS_PRICE="0.0001uaum"
  GENESIS_URL="https://testnet-files.itrocket.net/mantra/genesis.json"
  SEEDS="a9a71700397ce950a9396421877196ac19e7cde0@mantra-testnet-seed.itrocket.net:22656"
  PEERS="1a46b1db53d1ff3dbec56ec93269f6a0d15faeb4@mantra-testnet-peer.itrocket.net:22656,63763bfb78d296187754c367a9740e24730a7fc4@167.235.14.83:32656,64691a4202c1ad29a416b21ce21bfc9659783406@34.136.169.18:26656,d44eb6a1ea69263eb0a61bab354fb267396b27e1@34.70.189.2:26656,62cadc3da28e1a4785a2abf76c40f1c4e0eaeebd@34.123.40.240:26656,c4bec34390d2ab1004b9a25580c75e4743e033a1@65.108.72.253:22656,e6921a8a228e12ebab0ab70d9bcdb5364c5dece5@65.108.200.40:47656,2d2f8b62feee6b0fcbdec78d51d4ba9959e33c87@65.108.124.219:34656,4a22a9cbabe4313674d2058a964aef2863af9213@185.197.251.195:26656,c0828205f0dea4ef6feb61ee7a9e8f376be210f4@161.97.149.123:29656,30235fa097d100a14d2b534fdbf67e34e8d5f6cf@65.21.133.86:21656"
  ENABLE_METRICS=true
  METRICS_ADDR="0.0.0.0:26660"
  BINARY_URL="https://testnet-files.itrocket.net/mantra/mantrachaind-linux-amd64.zip"
  CHAIN_ID="mantrachain-testnet-1"
  INDEXER="null"
  APP_TOML="/home/mantra/.mantrad/config/app.toml"
  CONFIG_TOML="/home/mantra/.mantrad/config/config.toml"
  # Can be everything for a validator none for archive default or custom
  PRUNING="everything"
  ```
- Install required packages
  ```
  sudo apt update && sudo apt upgrade -y
  sudo apt install lz4 unzip jq -y
  sudo wget -O /usr/lib/libwasmvm.x86_64.so https://github.com/CosmWasm/wasmvm/releases/download/v1.3.0/libwasmvm.x86_64.so
  ```
- Install the binary
  ```
  cd /home/mantra
  wget $BINARY_URL
  unzip mantrachaind-linux-amd64.zip
  rm mantrachaind-linux-amd64.zip
  sudo mv mantrachaind /usr/local/bin/mantrad
  ```
- Initialize the node
  ```
  mantrad init $MONIKER --chain-id $CHAIN_ID --home /home/mantra/.mantrad
  wget -O /home/mantra/.mantrad/config/genesis.json $GENESIS_URL 
  ```
- Edit app.toml
  ```
  sed -i.bak -E "s|^(pruning[[:space:]]+=[[:space:]]+).*$|\1\"$PRUNING\"| ; \
  s|^(minimum-gas-prices[[:space:]]+=[[:space:]]+).*$|\1\"$MINIMUM_GAS_PRICE\"|" $APP_TOML
  ```
- Edit the config.toml file
  ```
  sed -i.bak -E "s|^(prometheus[[:space:]]+=[[:space:]]+).*$|\1\"$ENABLE_METRICS\"| ; \
  s|^(indexer[[:space:]]+=[[:space:]]+).*$|\1\"null\"| ; \
  s|^(prometheus_listen_addr[[:space:]]+=[[:space:]]+).*$|\1\"$METRICS_ADDR\"| ; \
  s|^(persistent_peers[[:space:]]+=[[:space:]]+).*$|\1\"$PEERS\"| ; \
  s|^(seeds[[:space:]]+=[[:space:]]+).*$|\1\"$SEEDS\"|" $CONFIG_TOML
  ```
- Configure state sync
  ```
  STATE_SYNC_RPC="https://mantra-testnet-rpc.itrocket.net:443,https://mantra-testnet-rpc.itrocket.net:443"
  SYNC_BLOCK_HASH="68C1A657AE776DF75348EE11C15547051CF651CB8A7DC3F040AD795874161F23"
  SYNC_BLOCK_HEIGHT="23000"
  SYNC_TRUST_PERIOD="168h"
  sed -i.bak -E "s|^(enable[[:space:]]+=[[:space:]]+).*$|\1true| ; \
  s|^(rpc_servers[[:space:]]+=[[:space:]]+).*$|\1\"$STATE_SYNC_RPC\"| ; \
  s|^(trust_height[[:space:]]+=[[:space:]]+).*$|\1$SYNC_BLOCK_HEIGHT| ; \
  s|^(trust_period[[:space:]]+=[[:space:]]+).*$|\1\"$SYNC_TRUST_PERIOD\"| ; \
  s|^(trust_hash[[:space:]]+=[[:space:]]+).*$|\1\"$SYNC_BLOCK_HASH\"|" $CONFIG_TOML
  ```
- Reset data and download snapshot from itrocket.net
  ```
  cp ~/.mantrad/data/priv_validator_state.json ~/priv_validator_state.json
  mantrachaind tendermint unsafe-reset-all --home /home/mantra/.mantrad --keep-addr-book
  if curl -s --head curl https://testnet-files.itrocket.net/mantra/snap_mantra.tar.lz4 | head -n 1 | grep "200" > /dev/null; then
    curl https://testnet-files.itrocket.net/mantra/snap_mantra.tar.lz4 | lz4 -dc - | tar -xf - -C /home/mantra/.mantrad
      else
    echo no have snap
  fi
  ```

- Install the systemd service
  ```
  sudo bash -c 'cat <<EOF >> /etc/systemd/system/mantrad.service
  [Unit]
  Description=Mantra Node
  After=network-online.target
  
  [Service]
  User=mantra
  WorkingDirectory=/home/mantra/.mantrad
  ExecStart=/usr/local/bin/mantrad start --home /home/mantra/.mantrad
  Restart=on-failure
  RestartSec=5
  LimitNOFILE=65535
  
  [Install]
  WantedBy=multi-user.target
  EOF'
  ```
- Enable and start the service
  ```
  sudo systemctl daemon-reload
  sudo systemctl enable mantrad
  sudo systemctl start mantrad
  ```
- Check logs for progress
  ```
  sudo journalctl -f -u mantrad.service
  ```
