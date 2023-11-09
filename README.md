# MantraChain-Testnet

## Node Setup

- Create a user account to use
  ```
  useradd -U -m -d /home/mantra -s /bin/bash mantra
  usermod -G sudo,sys,adm mantra 
  passwd
  su mantra
  ```

- Install required packages
  ```
  sudo apt update && sudo apt upgrade -y
  sudo apt install lz4 unzip jq -y
  sudo wget -O /usr/lib/libwasmvm.x86_64.so https://github.com/CosmWasm/wasmvm/releases/download/v1.3.0/libwasmvm.x86_64.so
  ```
- Install the binary
  ```
  wget $BINARY_URL
  unzip mantrachaind-linux-amd64.zip
  rm mantrachaind-linux-amd64.zip
  sudo mv mantrachaind /usr/local/bin/mantrad
  ```
- Initialize the node
  ```
  mantrad init $MONIKER --chain-id $CHAIN_ID --home $HOME/.mantrad
  wget -O $HOME/.mantrad/config/genesis.json $GENESIS_URL 
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
  s|^(external_address[[:space:]]+=[[:space:]]+).*$|\1\"$MANTRA_EXTERNAL_ADDR\"| ; \
  s|^(laddr[[:space:]]+=[[:space:]]+).*$|\1\"$MANTRA_ADDR\"| ; \
  s|^(prometheus_listen_addr[[:space:]]+=[[:space:]]+).*$|\1\"$PROMETHEUS_ADDR\"| ; \
  s|^(persistent_peers[[:space:]]+=[[:space:]]+).*$|\1\"$PEERS\"| ; \
  s|^(seeds[[:space:]]+=[[:space:]]+).*$|\1\"$SEEDS\"|" $CONFIG_TOML
  ```
- Configure state sync
  ```
  STATE_SYNC_RPC="https://mantra-testnet-rpc.itrocket.net"
  SYNC_BLOCK_HASH="68C1A657AE776DF75348EE11C15547051CF651CB8A7DC3F040AD795874161F23"
  SYNC_BLOCK_HEIGHT="23000"
  SYNC_TRUST_PERIOD="168h"
  sed -i.bak -E "s|^(enable[[:space:]]+=[[:space:]]+).*$|\1true| ; \
  s|^(rpc_servers[[:space:]]+=[[:space:]]+).*$|\1\"$STATE_SYNC_RPC,$STATE_SYNC_RPC1\"| ; \
  s|^(trust_height[[:space:]]+=[[:space:]]+).*$|\1$SYNC_BLOCK_HEIGHT| ; \
  s|^(trust_period[[:space:]]+=[[:space:]]+).*$|\1$SYNC_TRUST_PERIOD| ; \
  s|^(trust_hash[[:space:]]+=[[:space:]]+).*$|\1\"$SYNC_BLOCK_HASH\"|" $CONFIG_TOML
  ```
- Reset data and download snapshot from itrocket.net
  ```
  mantrachaind tendermint unsafe-reset-all --home $HOME/.mantrachain
  if curl -s --head curl https://testnet-files.itrocket.net/mantra/snap_mantra.tar.lz4 | head -n 1 | grep "200" > /dev/null; then
    curl https://testnet-files.itrocket.net/mantra/snap_mantra.tar.lz4 | lz4 -dc - | tar -xf - -C $HOME/.mantrachain
      else
    echo no have snap
  fi
  ```

- Install the systemd service
  ```
  sudo cat <<EOF >> /etc/systemd/system/mantrad.service
  [Unit]
  Description=Mantra Node
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
