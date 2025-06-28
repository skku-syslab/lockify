# Artifact Evaluation Instructions

Hello!

Thank you for taking the time to review our artifact. This document provides step-by-step instructions to access the servers used during our experiments, ensuring full reproducibility in the same environment used for the paper.

> **Access Information**  
> To access the servers, please refer to the **separately submitted information** for:
> - VPN configuration  
> - Server SSH path  
> - User ID and password  
>
> These credentials are intentionally excluded from this document for security reasons.

We provide access to the same servers used in the experiments (named `eternity`) so that you can reproduce the results in an identical environment.

## Testbed Configuration

All scripts have been fully prepared in this directory.  
**You do not need to refer to the `readme.md` file in the parent directory.**

The setup consists of **five client nodes** connected via a **56 Gbps switch**.  
A **single storage server** hosts a **250 GB Samsung 970 EVO Plus NVMe SSD**, which is shared over **NVMe-over-TCP**.

Each client node is equipped with:

- Dual Intel Xeon Gold 5115 CPUs @ 2.40GHz (20 cores per socket, Hyper-Threading enabled)
- 64 GB RAM
- Ubuntu 18.04 with Linux kernel 6.6.23

Unless noted otherwise, all nodes use default system settings.

---

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

> ⚠️ **Note**:  
> Since `sudo` privileges have been granted, perform all operations in a root shell using `sudo -s`,  
> **except** when running `mdtest` (IOR).

---

## Kernel Module Compilation

We have prepared three kernel modules for evaluation:

- `dlm`
- `lockify`
- `o2cb`

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

> After reboot, the module will be automatically loaded.

> ⚠️ **Note**:  
> This process may take 10 minutes or more depending on system load and build state.
> By default, the **lockify** module is already compiled and applied on the initial boot.

## Shared Storage and Filesystem Setup

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

> ⚠️ **Note**: This must be repeated after **each reboot**.

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

---

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

## Experiment Execution

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

---

> ⚠️ **Note**: To minimize kernel module patching overhead, we strongly recommend to avoid running experiments figure-by-figure.  
> Instead, group experiments by currently loaded kernel module, mounted file system, and number of client nodes and organize results incrementally in an Excel sheet during evaluation.

#### **Fig. 2**

- **Scripts**: `ior.sh` (a), `mdtest_create.sh` (b)  
- **Location**: `eternity1/ior/scripts/`  
- **File system**: GFS2  
- **Kernel module**: dlm  
- **Method**: Vary the number of client nodes that mount the GFS2 file system  
- `ior.sh` performs:  
  ```
  sequential write → sequential read → random write → random read
  ```

---

#### **Fig. 4**

- **Script**: `mdtest_distribution.sh`  
- **Location**: `eternity1/ior/scripts/`  
- **File system**: GFS2  
- **Kernel module**: dlm  
- **Method**: Mount GFS2 on varying numbers of client nodes, then execute the script.

---

#### **Fig. 5**

- **Script**: `mdtest_create.sh`  
- **Location**: `eternity1/ior/scripts/`  
- **File system**: OCFS2  
- **Kernel modules**: `o2cb`, `dlm`  
- **Method**:  
  Recompile the appropriate kernel module, mount OCFS2 on varying numbers of client nodes, and execute the script.

---

#### **Fig. 7**

- **Script**: `mdtest_create.sh`  
- **Location**: `eternity1/ior/scripts/`  
- **File systems**: NFS, GFS2, OCFS2  
- **Kernel modules**: `dlm`, `lockify`  
- **Method**:  
  - **NFS**: No kernel module changes are needed. Mount via NFS and run the script.  
  - **GFS2 / OCFS2**:  
    Recompile and load the appropriate kernel module (`dlm` or `lockify`), then vary the number of client nodes (1 to 5) and run the script.

---

#### **Fig. 8**

- **Script**: `mdtest_multi.sh`  
- **Location**: `eternity1/ior/scripts/`  
- **File systems**: NFS, GFS2, OCFS2  
- **Kernel modules**: `dlm`, `lockify`  
- **Method**: Same as Fig. 7

---

#### **Fig. 9**

- **Script**: `mdtest_distribution.sh`  
- **Location**: `eternity1/ior/scripts/`  
- **File system**: GFS2  
- **Kernel modules**: `dlm`, `lockify`  
- **Method**: Mount GFS2 on varying numbers of client nodes and execute the script.

---

#### **Fig. 10**

- **(a)**
  - **Script**: `postmark.sh`  
  - **Location**: `eternity1/postmark/`  
  - **File systems**: NFS, GFS2, OCFS2  
  - **Kernel modules**: `dlm`, `lockify`  

- **(b), (c)**
  - **Scripts**:  
    - `fileserver.sh` (b)  
    - `webproxy.sh` (c)  
  - **Location**: `eternity1/filebench/scripts/`  
  - **File systems**: NFS, GFS2, OCFS2  
  - **Kernel modules**: `dlm`, `lockify`  

---

> **Note**:  
> Benchmark results can vary, especially with **Filebench**.  
> For more consistent measurements, it is recommended to:
> - Reboot the system before execution
> - Run multiple trials and average results

## Contact

If you encounter any issues, please contact: **pty3595@g.skku.edu**
