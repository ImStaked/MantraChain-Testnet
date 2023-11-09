# MantraChain-Testnet


## Mode Setup

- Create a user account to use
```
useradd -U -m -d /home/mantra -s /bin/bash mantra
usermod -G sudo,sys,adm mantra 
passwd
su mantra
```

- Run this setup script as the new user
```
setup.sh
```
