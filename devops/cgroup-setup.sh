
#!/bin/bash
PROJECT_NAME=$1
CPU_LIMIT=$2          # e.g., "200000 100000"
MEMORY_LIMIT=$3       # e.g., "2147483648" (2GB)
STORAGE_LIMIT_GB=$4   # e.g., 20 (for 20GB)
STORAGE_DEVICE=$5     # e.g., "259:0" (from lsblk)


# Enable controllers in root cgroup (required for nested cgroups)
echo "+cpu +memory +io" | sudo tee /sys/fs/cgroup/cgroup.subtree_control
# Create cgroup
sudo mkdir -p /sys/fs/cgroup/$PROJECT_NAME

# CPU limits
echo "$CPU_LIMIT" | sudo tee /sys/fs/cgroup/$PROJECT_NAME/cpu.max

# Memory limits
echo "$MEMORY_LIMIT" | sudo tee /sys/fs/cgroup/$PROJECT_NAME/memory.max

# Storage I/O limits (convert GB to bytes)
STORAGE_BYTES=$(( STORAGE_LIMIT_GB * 1024 * 1024 * 1024 ))
THROTTLE_BPS=$(( STORAGE_LIMIT_GB * 75 * 1024 * 1024 ))  # 75% of limit as throttle

