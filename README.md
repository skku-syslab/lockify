# Lockify  
[USENIX FAST 2026] **Lockify: Understanding Linux Distributed Lock Management Overheads in Shared Storage**

---

**Lockify** is a novel distributed lock manager (DLM) for shared-disk file systems that reduces lock acquisition latency in the Linux kernel.  
It avoids unnecessary remote communication through **self-owner notifications** and **asynchronous ownership management**.

Implemented as a patch to the Linux kernel and evaluated on **GFS2** and **OCFS2**, Lockify achieves up to **6.4× higher throughput** than the default DLM, even under low-contention workloads.

---

## Installation and Benchmark Setup

Lockify is implemented as a modification to the DLM module in **Linux kernel 6.6.23**.

> ⚠️ This repository provides **only the modified DLM-related source files**, not the entire kernel tree.  
> Please copy the contents of this repository into a clean Linux 6.6.23 kernel source before building.

### 1. Clone the Repository

```bash
git clone https://github.com/skku-syslab/lockify.git
```

### 2. Integrate with Linux Kernel

- Download a clean Linux 6.6.23 kernel source.
- Copy the Lockify files (e.g., `dlm/`, relevant headers) into the kernel tree, overwriting existing files.
- Ensure the following kernel config options are enabled:
  - `CONFIG_NVME_TARGET_TCP`
  - `CONFIG_NVME_TCP`

### 3. Build and Install the Kernel

```bash
make menuconfig     # or reuse an existing .config
make -j$(nproc)
sudo make modules_install
sudo make install
reboot
```

### 4. Set Up the Evaluation Cluster

- Configure a shared-disk cluster using **GFS2** or **OCFS2**.
- Set up **NVMe-over-TCP** between the nodes.

### 5. Benchmarking Tools

Install the following tools to run evaluations:

- **mdtest (via IOR)**  
  https://github.com/hpc/ior

- **Postmark**  
  ```bash
  sudo apt install postmark
  ```

- **Filebench**  
  https://github.com/filebench/filebench

---

## Authors

- **Taeyoung Park** (Sungkyunkwan University) — <pty3595@g.skku.edu>  
- **Yunjae Jo** (Sungkyunkwan University) — <jack3319@g.skku.edu>  
- **Daegyu Han** (Sungkyunkwan University) — <hdg9400@skku.edu>  
- **Beomseok Nam** (Sungkyunkwan University) — <bnam@skku.edu>  
- **Jaehyun Hwang** (Sungkyunkwan University) — <jh.hwang@skku.edu>

---

## GitHub Repository

For more information and updates, please visit the official repository:

🔗 https://github.com/skku-syslab/lockify
