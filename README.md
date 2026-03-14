# YAAWG: Yet another AmneziaWG variation for OpenWrt

## FAQ & TL;DR

**Q: Where can I get the binaries?**  
A: [Check here](#how-to-use-the-new-workflow).

**Q: What is the latest supported version of the protocol?**  
A: YAAWG fully supports AmneziaWG v2.0, including S3-S4, I1-I5 and ranged H1-H4 parameters.

**Q: Should I use the kernel module or the Go implementation?**  
A: Use the kernel module by default. If it doesn't work for you, switch to the Go implementation. More info [here](#kmod-amneziawg-vs-amneziawg-go).

**Q: Why are no compiled binaries available?**  
A: There are several reasons:  
1. OpenWRT supports many architectures and targets (5-7 of which cover 80% of devices). Compiling binaries for all of them is impractical.  
2. It takes just a few clicks and about 20 minutes to compile binaries with your parameters.  
3. If you find compiling difficult, correctly setting up the protocol will be even harder.
4. You can review all the sources and make sure there are no unexpected issues or vulnerabilities before building or deploying.

**Q: How are versions named?**  
A: Versioning follows the pattern `x.y.z` where `x` and `y` represent the current AmneziaWG version, and `z` corresponds to the YAAWG version.

**Q: I get errors on steps `Download and prepare SDK`, `Checkout OpenWRT repository`, `Update feeds`. Any advice?**  
A: It looks like the OpenWRT repository went for a coffee break and is unavailable at the moment. Try restarting the workflow in 15-40 minutes.

## Project description

This project aims to update the sources of the initial AmneziaWG repository and align them as closely as possible with four upstream projects ([luci-proto-wireguard](https://github.com/openwrt/luci/tree/master/protocols/luci-proto-wireguard), [amneziawg-tools](https://github.com/amnezia-vpn/amneziawg-tools/), [amneziawg-linux-kernel-module](https://github.com/amnezia-vpn/amneziawg-linux-kernel-module), [amneziawg-go](https://github.com/amnezia-vpn/amneziawg-go)).

Why? Because it seems the original repository has been abandoned: over half a year has passed since the last commit, no bugs were fixed, and no new protocol versions were added, while the four upstream projects continue receiving regular updates (at least from the community).

The main differences and objectives are:
1. `luci-proto-amneziawg` has been aligned with [luci-proto-wireguard](https://github.com/openwrt/luci/tree/master/protocols/luci-proto-wireguard):
   - Based on the `luci-proto-wireguard` codebase.
   - The AmneziaWG settings tab now includes placeholders where available (default values, if chosen, mimic the Wireguard protocol).
   - Fixed a bug with QR code generation. The generated QR code now contains AmneziaWG-specific information.
   - Added checkboxes to enable/disable peers.
   - Added an icon for the interface.
   - Added support for ranged H1-H4 parameters (delimiter: `-`, e.g., `123456-123500`).
   - Added support for v2.0 protocol parameters: S3-S4, I1-I5.

2. `amneziawg-tools` has been aligned with the upstream repository [amneziawg-tools](https://github.com/amnezia-vpn/amneziawg-tools/):
   - The package is now compiled based on the upstream repository.
   - Fixed a bug with the non-existent `proto_amneziawg_check_installed` method.
   - Changed temporary folders and files to match the protocol name.
   - Refactored scripts to make them look more "amneziish".
   - Fixed a bug with an incorrect path when using `amneziawg-go`.
   - Added support for ranged H1-H4 parameters (with `-` delimiter, e.g., `123456-123500`).
   - Added support for v2.0 protocol parameters: S3-S4, I1-I5.

3. `kmod-amneziawg` is now compiled entirely based on the upstream [amneziawg-linux-kernel-module](https://github.com/amnezia-vpn/amneziawg-linux-kernel-module) repository plus fixes from the community.
   - Added support for v2.0 protocol parameters: S3-S4, I1-I5.

4. `amneziawg-go` acts as an alternative to `kmod-amneziawg`. Please refer to [this section](#kmod-amneziawg-vs-amneziawg-go) for more information. The Go implementation is fully based on the upstream project [amneziawg-go](https://github.com/amnezia-vpn/amneziawg-go).

## `kmod-amneziawg` vs `amneziawg-go`

When the AmneziaWG authors introduced the v1.5 protocol, it was supported only in the Go implementation. Thus the user namespace (Go) implementation was added to the repo in order to support the newer protocol version. Later, v2.0 protocol support was added to both the user namespace (Go) and kernel module implementations. To maintain backward compatibility, this repository will continue to support both packages.

Differences:
1. `kmod-amneziawg`: requires a less powerful device to run, consumes less space and provides a faster throughput. Recommended option.
2. `amneziawg-go`: requires a more powerful device and uses more space but provides a user namespace implementation of the protocol. Use it if kernel module doesn't work for you.

If both implementations are installed, `kmod-amneziawg` will be used by default.

## Results

Everything seems to work fine. No major problems have been detected or reported so far.

## How to build and use

### Build OpenWRT firmware with AmneziaWG packages included

This repository is intended primarily for compiling packages during the firmware build process. Follow these steps:

1. Clone the OpenWrt repo by running `git clone https://github.com/openwrt/openwrt.git`. You may choose any tag/commit hash by adding `-b {tag/commit hash}`.

2. Add the line `src-git awgopenwrt https://github.com/this-username-has-been-taken/amneziawg-openwrt.git` to the `feeds.conf.default` file.

3. Update package feeds by running: `{path to openwrt dir}/scripts/feeds update -a`

4. Shall you build the firmware with the `amneziawg-go` package, please make sure the included Go package version is higher than `1.24.4`. Most OpenWRT versions except `SNAPSHOT` have older Go versions. To upgrade:
   - Clone the latest OpenWRT Packages repository: `git clone https://github.com/openwrt/packages.git`.
   - Replace `{path to openwrt dir}/feeds/packages/lang/golang` with the one from the cloned repository at `{path to the cloned repository}/packages/lang/golang`.

5. Install packages by running: `{path to openwrt dir}/scripts/feeds install -a`

6. Configure firmware (choose target, settings, AmneziaWG packages: `amneziawg-go` or `kmod-amneziawg` + `amneziawg-tools` + `luci-proto-amneziawg` and others) using: `make -C {path to openwrt dir} menuconfig` and save.

7. Make the defconfig: `make -C {path to openwrt dir} defconfig`

8. Build the firmware: `make -C openwrt -j$(nproc) V=sc`

9. After building, firmware will be located at: `{path to openwrt dir}/bin/targets/{your target}/{your subtarget}` and compiled packages at: `{path to openwrt dir}/bin/targets/{your target}/{your subtarget}/packages` (kernel module) and `{path to openwrt dir}/bin/packages/{your architecture}/awgopenwrt` (other packages).

### Compile AmneziaWG Packages Without Building the Firmware

You can compile packages independently without building the full firmware. There are two workflows available: the **new workflow** and the **legacy workflow**. It is recommended to use the new workflow. The legacy workflow will continue to be supported to maintain backward compatibility.

#### New Workflow vs. Legacy Workflow

Key differences between the workflows:

1. The new workflow runs much faster (~20 minutes vs. 2.5 hours).
2. The new workflow uses the SDK instead of building the toolchain from scratch.
3. The new workflow consists of a single step instead of two.
4. The new workflow also compiles the localization package.
5. The new workflow does not calculate `vermagic` value (see below).

#### How to Use the New Workflow

The new workflow is a single step process: run it, and when complete, all compiled packages will be available in the run's artifacts section (at the bottom of the GitHub Actions page).

Steps to follow:

1. Obtain your router parameters:
   - **OpenWRT version:** `SNAPSHOT` or a stable release (e.g., `24.10.2`), found under `Status -> Overview` on the `Firmware Version` line.
   - **CPU/package architecture:** run `apk info kernel` or `opkg info kernel` to check the `Architecture` value (e.g., `aarch64_cortex-a53`), or consult the [OpenWRT router database](https://openwrt.org/toh/start).
   - **Target and Subtarget:** found under `Status -> Overview` on the `Target Platform` line (before and after the slash).

2. Fork this repository.

3. Enable GitHub Actions, if not already enabled.

4. Select the workflow `New - Build AmneziaWG from SDK`, enter your router parameters in the `Run workflow` form, and start the run.
   - Optionally, specify a different YAAWG version using the release tag or commit hash field.
   - Choose whether to compile the kernel module, Go implementation, or both.

5. Wait approximately 20 minutes until the build completes.

6. If you get an error in step `Download and prepare SDK`, it is more likely that the OpenWRT repository is unavailable. Please restart the process in 15-40 minutes.

7. Download the artifacts, extract them, and install the packages.

#### How to Use the Legacy Workflow

The legacy process involves two workflows (steps): building the OpenWRT toolchain cache (about 2.5 hours) and compiling AmneziaWG packages (under 20 minutes). The toolchain build needs to be completed once, after which the package compilation step can be repeated as needed.

Steps:

1. Obtain your router parameters following the same instructions as in the new workflow.

2. Fork this repository.

3. Enable GitHub Actions, if not already enabled.

4. Select the workflow `Legacy - step 1. Build OpenWrt toolchain cache`, enter your router parameters, and start the run.
   - Optionally set a different YAAWG version using the release tag or commit hash field.
   - Do **not** disable `Update Go` unless you understand the consequences; `amneziawg-go` requires Go version greater than 1.24.4.

5. Wait approximately 2 to 2.5 hours for the cache build to complete.

6. If you get an error in steps `Checkout OpenWRT repository`, `Update feeds`, it is more likely that the OpenWRT repository is unavailable. Please restart step 1 in 15-40 minutes.

7. Select the workflow `Legacy - step 2. Build AmneziaWG from cache`, input the parameters, and run it.
   - Choose whether to compile the kernel module, Go implementation, or both.
   
8. Again, errors in step `Checkout OpenWRT repository` show that the OpenWRT repository is unavailable. Please restart step 2 in 15-40 minutes.

9. Wait around 10–20 minutes for the packages to compile.

10. Download the artifacts, extract, and install.

### How to Install AmneziaWG

1. Choose your installation method:

   - **Via Web Interface (LuCI):**
     - Navigate to `System -> Software`.
     - Click `Upload Package...`.
     - Upload `kmod-amneziawg` or `amneziawg-go` `.ipk` or `.apk` files.
     - Confirm the installation.
     - Repeat for `amneziawg-tools` and `luci-proto-amneziawg`.

   - **Via Console:**
     - Transfer the package files to your router.
     - Run `apk install {path to kmod-amneziawg or amneziawg-go .apk}` or `opkg install {path to kmod-amneziawg or amneziawg-go .ipk}`.
     - Install `amneziawg-tools` and `luci-proto-amneziawg` similarly.

2. Reboot the router or restart the network service with: `/etc/init.d/network restart`

3. Congratulations! AmneziaWG is installed. Go to `Network -> Interfaces`, click `Add new interface...`, then select `AmneziaWG` as the protocol.

> **Note:** You may need to clear your browser cache to see the new protocol available in OpenWRT.

#### Vermagic control for `SNAPSHOT` versions
> **Note:** Vermagic is calculated only for the **old workflow**

Vermagic is a hash calculated for the OpenWRT kernel. When installing kernel-related packages, OpenWRT checks if the package's `vermagic` matches the kernel's. If not, installation won't succeed. Since `SNAPSHOT` versions update daily, `vermagic` values may differ. Check your firmware's `vermagic` by running `apk info kernel` or `opkg info kernel` and noting the hash after the kernel version in `Version`. For example, `6.6.52~f58afd3748410d3b1baa06a466d6682-r1` means `vermagic` is `f58afd3748410d3b1baa06a466d6682`. The compiled package's `vermagic` value is located in the `vermagic` file within the workflow artifacts. If these do not match, the kernel module cannot be installed.
