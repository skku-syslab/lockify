## SSH Access Instructions

All *eternity* nodes share the same home directory via NFS.  
To separate environments, individual directories are created for each node under the home directory:

```
~# ls
eternity1  eternity2  eternity5  eternity6  eternity11
```

From this point onward, please execute all node-specific scripts from their corresponding directories, for example:

```
~/eternity1/
~/eternity2/
...
```

> **Note**:  
> Since `sudo` privileges have been granted, perform all operations in a root shell using `sudo -s`,  
> **except** when running `mdtest` (IOR).

---

## Kernel Module Compilation

We have prepared three kernel modules for evaluation:

- `dlm`
- `lockify`
- `o2cb`

Each module directory includes its own compilation script:

- `dlm_compile.sh`
- `lockify_compile.sh`
- `o2cb_compile.sh`

To compile and apply a kernel module, run the corresponding script **as root**:

```
sudo -s
./lockify_compile.sh
```

This script will:

1. Build the module  
2. Install it  
3. Reboot the node

> After reboot, the module will be automatically loaded.

> **Important**:  
> By default, the **lockify** module is already compiled and applied on the initial boot.
