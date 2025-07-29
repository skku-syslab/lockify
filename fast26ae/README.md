# FAST'26 Artifact Evaluation Instructions

> **Environment Notice**  
> The following scripts and configurations are tailored for the FAST’26 Artifact Evaluation
> environment in our lab. They assume:
> - Shared mount point:        /mnt/fast26ae  
> - Storage host IPs:          10.0.0.1, …  
> - Client NVMe devices:       /dev/nvme1n1, …  
> - And other parameters may also be hard‑coded.  
>
> To run these scripts in your own testbed, replace all occurrences of those values with the corresponding values in your environment.


All artifact evaluation scripts have been fully prepared in this directory. **You do not need to refer to the `README.md` file in the parent directory.**  

In our evaluation, we assume the following:

- There are **five client nodes**: `eternity1`, `eternity2`, `eternity5`, `eternity6`, and `eternity11`.
- All client nodes have the Lockify kernel installed. ([Build Lockify Kernel](https://github.com/skku-syslab/lockify?tab=readme-ov-file#build-lockify-kernel))
- All client nodes have the required software packages installed. ([Configure shared-disk file systems](https://github.com/skku-syslab/lockify?tab=readme-ov-file#2-configure-shared-disk-file-system))
- The node `eternity6` hosts a shared storage device, `/dev/nvme0n1`, which is accessed by all five client nodes. Except for `eternity6` itself, the other four client nodes access this device via NVMe-over-TCP, where it appears locally as `/dev/nvme1n1`.

<!-- **(Please adapt this configuration to match your testbed environment.)** -->

## Testbed Configurations

Each client node is equipped with:

- Dual Intel Xeon Gold 5115 CPUs @ 2.40GHz (20 cores per socket, Hyper-Threading enabled)
- 64 GB RAM
- Ubuntu 18.04 with Linux kernel 6.6.23

All client nodes are connected via a 56 Gbps switch. A 250 GB Samsung 970 EVO Plus NVMe SSD is used for the shared storage.  
Unless noted otherwise, all nodes use default system settings.

## Preliminaries

**⚠️ [NOTE]**: Since client nodes access the shared storage under different device names (`/dev/nvme0n1` or `/dev/nvme1n1`) and use different sets of scripts, we provide the node-specific scripts located in each node's directory. For example, if you're on `eternity1`, use the `~/fast26ae/eternity1/` directory:

```
cd ~/fast26ae/eternity1/
```

For simplicity, we use the notation `eternity[n]`, where `n` can be 1, 2, 5, 6, and 11.

---

<!--
All *eternity* nodes share the same home directory via NFS.  
To separate environments, individual directories are created for each node under the home directory:

```
~# ls
eternity1  eternity2  eternity5  eternity6  eternity11
```

From this point onward, please execute all node-specific scripts from their corresponding directories, for example:

```
~/fast26ae/eternity1/
~/fast26ae/eternity2/
...
```

> ⚠️ **Note**:  
> Since `sudo` privileges have been granted, perform all operations in a root shell using `sudo -s`,  
> **except** when running `mdtest` (IOR).
-->

Before running the evaluation scripts, make sure that **each client node** is correctly configured with (1) the target DLM kernel module, (2) the NVMe-over-TCP setup, and (3) the target file system.

### 1. Configure DLM kernel module

We provide three DLM kernel modules: `dlm`, `o2cb`, and `lockify`. These modules operate in a mutually exclusive manner in our current setup, meaning that switching between DLM configurations requires reinstalling the desired kernel module followed by a system reboot, which takes ~10 minutes. After reboot, the target DLM module is automatically loaded.

Move to the module directory:

```
sudo -s
cd ~/fast26ae/eternity[n]/module/
```

Then, compile and install the target DLM module:

- For `dlm`: run `./dlm_compile.sh`
- For `o2cb`: run `./o2cb_compile.sh`
- For `lockify`: run `./lockify_compile.sh`

<!--
Each module directory includes its own compilation script:

- `module/dlm_compile.sh`
- `module/lockify_compile.sh`
- `module/o2cb_compile.sh`

To compile and apply a kernel module, run the corresponding script **as root**:

```
module/lockify_compile.sh
```

This script will:

1. Build the module  
2. Install it  
3. Reboot the node

After reboot, the module will be automatically loaded.

> ⚠️ **Note**:  
> This process may take 10 minutes or more depending on system load and build state.
> By default, the **lockify** module is already compiled and applied on the initial boot.
> This process must be performed on each node individually.
-->

### 2. Configure the shared storage (NVMe-over-TCP)

After reboot, configure the shared storage using NVMe-over-TCP. The node `eternity6`, which hosts the shared storage device, must be configured first.

On `eternity6`:

```
sudo -s
cd ~/fast26ae/eternity6/
./nvmeof_storage.sh
```

On the other client nodes:

```
sudo -s
cd ~/fast26ae/eternity[n]/
./nvmeof.sh
```

### 3. Configure the shared-disk file system

We evaluate three file systems: **GFS2**, **OCFS2**, and **NFS**. The shared storage on `eternity6` is first formatted with the target file system and then mounted on all client nodes.

On `eternity6`, create the target file system (format):

```
sudo -s
cd ~/fast26ae/eternity6/
```

- For **GFS2**: run `./gfs2/mkfs_gfs2.sh`
- For **OCFS2**: run `./ocfs2/mkfs_ocfs2.sh`
- For **NFS**: run `./nfs/nfs_storage.sh`

On all client nodes, mount the target file system:

```
sudo -s
cd ~/fast26ae/eternity[n]/
```

- For **GFS2**: run `./gfs2/mount_gfs2.sh`
- For **OCFS2**: run `./ocfs2/mount_ocfs2.sh`
- For **NFS**: run `./nfs/mount_nfs.sh`

### (Optional) 4. Verifying the file system

To verify that the file system is correctly shared:

1. On any node, create a file in the mounted directory:

    ```
    touch /mnt/fast26ae/testfile
    ```

2. On another node, verify that the file appears:

    ```
    ls /mnt/fast26ae
    ```

If the file is visible, the shared file system setup is successful.

> ⚠️ **Note**:  
> Before switching to a different file system (e.g., from GFS2 to OCFS2) without rebooting, make sure that `/mnt/fast26ae` is unmounted on all client nodes:

```
sudo -s
cd ~/fast26ae/eternity[n]/
```

- For **GFS2**: run `./gfs2/umount.sh`
- For **OCFS2**: run `./ocfs2/umount.sh`
- For **NFS**: run `./nfs/umount.sh`

<!--
We evaluate the following file systems:

- **GFS2** and **OCFS2**: These require shared storage.
- **NFS**: Uses file-level shared access via network.

---

### Shared NVMe Storage (for GFS2 and OCFS2)

The shared NVMe device is located on `eternity6`:

```
/dev/nvme0n1
```

To enable access from other nodes, we use **NVMe over TCP**.

#### Step 1: Export NVMe from eternity6

```
eternity6/nvmeof_storage.sh
```

#### Step 2: Connect from other nodes (eternity1, eternity2, eternity5, eternity11)

```
eternity[n]/nvmeof.sh
```

> ⚠️ **Note**:
> This must be repeated after **each reboot**.

#### Step 3: Create and Mount File System

For **GFS2**:

##### On `eternity6`, create the file system:

```
eternity6/gfs2/mkfs_gfs2.sh
```

> ⚠️ **Note**:  
> The `mkfs` process may ask for confirmation
> In such cases, please type `y` and press Enter.

##### On all nodes, mount the file system:

```
eternity[n]/gfs2/mount_gfs2.sh
```

For **OCFS2**:

##### On `eternity6`, create the file system:

```
eternity6/ocfs2/mkfs_ocfs2.sh
```

##### On all nodes, mount the file system:

```
eternity[n]/ocfs2/mount_ocfs2.sh
```

For **NFS**:

No NVMe setup is needed for NFS.

##### On `eternity6`, start the NFS server:

```
eternity6/nfs/nfs_storage.sh
```

##### Then, on the other nodes, mount the shared directory:

```
eternity[n]/nfs/nfs.sh
```

#### Verifying File System

To verify that the file system is correctly shared:

1. On any node, create a file in the mount directory:

    ```
    touch /mnt/fast26ae/testfile
    ```

2. On another node, check if the file appears:

    ```
    ls /mnt/fast26ae
    ```

If the file is visible, the setup is successful.

> ⚠️ **Note**:  
> Before switching file systems (e.g., from GFS2 to OCFS2), make sure to unmount `/mnt/fast26ae` on all nodes:

```
eternity[n]/[fs]/umount.sh
```

-->

## Lockify Evaluation

### 1. How to run evaluation scripts?

All evaluation scripts are assumed to run on **eternity1** and are located in the following directories:

- IOR/mdtest: `~/fast26ae/eternity1/ior/scripts/`
- Postmark: `~/fast26ae/eternity1/postmark/`
- Filebench: `~/fast26ae/eternity1/filebench/scripts/`

### 2. How to read the results?

Check the benchmark results using the following metrics:

- IOR: **Bandwidth** reported in the Results section  
- mdtest: **Directory/File creation** shown in the SUMMARY rate section  
- Postmark: **Transactions per second** shown in the Time section  
- Filebench: **ops/s** shown in the IO Summary section

### 3. How to vary the number of clients?

In our evaluation, we vary the number of clients, which refers to the number of nodes that currently have the target file system mounted. Before mounting, please make sure that the target file system is created on `eternity6`.

- For 1 client: mount the target file system on **`eternity1`**.
- For _n_ clients: mount the target file system on any _n_ client nodes, including `eternity1`.

---

<!--
All experiments are configured to be executed from **eternity1**.  
Number of clients refers to the number of nodes that currently have the file system mounted.
For single-client benchmarks, ensure that **only eternity1** mounts the target file system (except for NFS, where eternity6 (the server) must also mount the directory for proper operation.)
If any part of the setup becomes inconsistent or misconfigured, the simplest and most reliable way to recover is to **reboot the nodes** and retry the setup step.

Benchmark scripts are located in the following directories:

```
eternity1/ior/scripts/
eternity1/postmark/
eternity1/filebench/scripts/
```

Check the benchmark results using the following metrics:

- IOR: Bandwidth in the Results section  
- mdtest: Directory/File creation in the SUMMARY rate section  
- Postmark: Transactions per second in the Time section  
- Filebench: ops/s in the IO Summary section
---

### Breakdown by Figure (from the paper)

> ⚠️ **Note**:
> To minimize kernel module patching overhead, we strongly recommend to avoid running experiments figure-by-figure.
> Instead, group experiments by currently loaded kernel module, mounted file system, and number of client nodes and organize results incrementally in an Excel sheet during evaluation.
--->

### Running Evaluation Scripts

Run the evaluation scripts for Postmark and Filebench in a root shell using `sudo -s`, **except** for the IOR and mdtest scripts.

**IMPORTANT:**
To minimize reboot and filesystem reformatting overhead during evaluation, we recommend grouping experiments by the  currently loaded kernel module and file system.

We suggest the following order:
- **Lockify with GFS2**: Fig. 7, Fig. 8, Fig. 9, Fig. 10  
- **Lockify with OCFS2**: Fig. 7, Fig. 8, Fig. 10  
- **DLM with GFS2**: Fig. 2, Fig. 4, Fig. 7, Fig. 8, Fig. 9, Fig. 10  
- **DLM with OCFS2**: Fig. 5, Fig. 7, Fig. 8, Fig. 10  
- **O2CB with OCFS2**: Fig. 5  
- **NFS**: Fig. 7, Fig. 8, Fig. 10  

Once a (kernel module, file system) combination is set up, execute all corresponding figure scripts consecutively before moving on to the next configuration. This helps reduce repetitive kernel module switching and mkfs/mount operations.

> ⚠️ **Note**: If any part of the setup becomes inconsistent or misconfigured, the simplest and most reliable way to recover is to **reboot the nodes** and retry the setup step.

#### **Fig. 2:**
Vary the number of client nodes with GFS2 mounted, then run the script.

On all client nodes:
- **DLM module**: dlm
- **File system**: GFS2  
- **Number of clients**: 1 to 5

On `eternity1`:  
**(a)** 
```
cd ~/fast26ae/eternity1/ior/scripts/
./ior.sh
```
`ior.sh` performs sequential write → sequential read → random write → random read.  
**(b)**
```
cd ~/fast26ae/eternity1/ior/scripts/
./mdtest_create.sh
```

---

#### **Fig. 4:**
Vary the number of client nodes with GFS2 mounted, then run the script.

On all client nodes:
- **DLM module**: dlm
- **File system**: GFS2  
- **Number of clients**: 1 to 5

On `eternity1`:
```
cd ~/fast26ae/eternity1/ior/scripts/
./mdtest_distribution.sh
```

---

#### **Fig. 5:**
Configure the target DLM module (o2cb or dlm), vary the number of client nodes with OCFS2 mounted, and run the script.

On all client nodes:
- **DLM module**: o2cb, dlm
- **File system**: OCFS2  
- **Number of clients**: 1 or 5

On `eternity1`:
```
cd ~/fast26ae/eternity1/ior/scripts/
./mdtest_create.sh
```

---

#### **Fig. 7:**
For NFS, no DLM module configuration is needed, vary the number of client nodes with NFS mounted, and run the script.  
For GFS2 and OCFS2, configure the target DLM module (dlm or lockify), vary the number of client nodes with GFS2 or OCFS2 mounted, and run the script.

On all client nodes:
- **DLM module**: dlm, lockify
- **File system**: NFS, GFS2, OCFS2  
- **Number of clients**: 1 or 5

On `eternity1`:
```
cd ~/fast26ae/eternity1/ior/scripts/
./mdtest_create.sh
```

---

#### **Fig. 8:**
Same as Fig. 7, but using the `mdtest_multi.sh` script.

On all client nodes:
- **DLM module**: dlm, lockify
- **File system**: NFS, GFS2, OCFS2  
- **Number of clients**: 5

On `eternity1`:
```
cd ~/fast26ae/eternity1/ior/scripts/
./mdtest_multi.sh
```

---

#### **Fig. 9:**
Vary the number of client nodes with GFS2 mounted, then run the script.

On all client nodes:
- **DLM module**: dlm, lockify
- **File system**: GFS2
- **Number of clients**: 1 or 5

On `eternity1`:
```
cd ~/fast26ae/eternity1/ior/scripts/
./mdtest_distribution.sh
```

---

#### **Fig. 10:**
For NFS, no DLM module configuration is needed, vary the number of client nodes with NFS mounted, and run the script.  
For GFS2 and OCFS2, configure the target DLM module (dlm or lockify), vary the number of client nodes with GFS2 or OCFS2 mounted, and run the script.

On all client nodes:  
- **DLM module**: dlm, lockify
- **File system**: NFS, GFS2, OCFS2  
- **Number of clients**: 1 or 5

On `eternity1`:  
**(a)**
```
sudo -s
cd ~/fast26ae/eternity1/postmark/
./postmark.sh
```
**(b)**
```
sudo -s
cd ~/fast26ae/eternity1/filebench/scripts/
./fileserver.sh
```
**(c)**
```
sudo -s
cd ~/fast26ae/eternity1/filebench/scripts/
./webproxy.sh
```

---

> ⚠️ **Note**:  
> Benchmark results can vary, especially with **Filebench**.  
> For more consistent measurements, it is recommended to:
> - Reboot the system before execution
> - Run multiple trials and average results

## Contact

If you encounter any issues, please contact: **pty3595@g.skku.edu**
