# Node Metrics

Not working good yet.... 

- To enable metrics edit your nodes config.toml. 
  Change these settings in the last section.
  ```
  #######################################################
  ###       Instrumentation Configuration Options     ###
  #######################################################
  prometheus = true
  prometheus_listen_addr = "0.0.0.0:26660"
  namespace = "cometbft"
  ```
  when finished restart the node.

  
