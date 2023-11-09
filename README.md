# MantraChain-Testnet


## Mode Setup

- Create a user account to use
```
useradd -U -m -d /home/mantra -s /bin/bash mantra
usermod -G sudo,sys,adm mantra 
passwd
su mantra
```

- Edit the settings at top of the setup file as needed then run the setup.sh script
```
cd ~
wget https://raw.githubusercontent.com/ImStaked/MantraChain-Testnet/main/setup.sh
chmod +x setup.sh
./setup.sh
```

- Start the node and Check the status or follow the system journal to see if it is connecting
```
systemctl status mantrad

sudo journalctl -f 
```
