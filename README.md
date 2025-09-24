1. How to bind a systemd service to specific cpu(s), helpful in arm bit.little architecture
Add CPUAffinity under [Service] sections 
[Service] 
CPUAffinity=6 7

To run a process on specific cpu(s), use "taskset -c 6 7 python3 main.py"
