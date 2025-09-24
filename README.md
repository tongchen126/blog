1. How to bind a systemd service to specific cpu(s), helpful in arm bit.little architecture
   
Add CPUAffinity under [Service] sections 

[Service] 

CPUAffinity=6 7
