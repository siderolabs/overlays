# Talos Linux Overlays

This repo servers a central place for the list of all official Talos Linux overlays.
Overlays are a way to extend the installation procedure of Talos to support SBC's.

## Using Overlays

Overlays referenced in this repo are published as container images.
These images can be added to the the Talos Linux boot asset to produce a final [boot asset](https://www.talos.dev/latest/talos-guides/install/boot-assets/) containing that supports the specific overlay implementation.

The overlays image is composed of a `overlays.yaml` file that provides the list of published overlays and the corresponding container image.

In order to find a container reference for an overlay you can use the following commands:

```bash
crane export ghcr.io/siderolabs/extensions:v<talos-version> | tar x -O overlays.yaml | yq '.overlays[] | select(.name == "<overlay-name>") | .image + "@" + .digest'
```

Please always use the pinned digest when referencing an overlay image.

All overlays and the overlay catalogue image are signed with Google Accounts OIDC issuer matching @siderolabs.com domain, so the image signatures can be verified, for example:

```bash
cosign verify --certificate-identity-regexp '@siderolabs\.com$' --certificate-oidc-issuer https://accounts.google.com ghcr.io/siderolabs/overlays:v1.7.0
cosign verify --certificate-identity-regexp '@siderolabs\.com$' --certificate-oidc-issuer https://accounts.google.com ghcr.io/siderolabs/sbc-raspberry-pi:v0.1.0
```

The list of available overlays can be found in the [Overlays Catalog](#overlays-catalog) section below.

## Overlays Catalog

| Overlay Name           | Board                           | Repository                                                       |
| ---------------------- | ------------------------------- | ---------------------------------------------------------------- |
| rpi_generic            | Raspberry Pi 4/Compute Module 4 | [sbc-raspberrypi](https://github.com/siderolabs/sbc-raspberrypi) |
| nanopi-r4s             | NanoPi R4S                      | [sbc-rockchip](https://github.com/siderolabs/sbc-rockchip)       |
| rock64                 | Pine64 Rock64                   | [sbc-rockchip](https://github.com/siderolabs/sbc-rockchip)       |
| rockpi4                | Rock Pi 4A,Rock Pi 4B           | [sbc-rockchip](https://github.com/siderolabs/sbc-rockchip)       |
| rockpi4c               | Rock Pi 4C                      | [sbc-rockchip](https://github.com/siderolabs/sbc-rockchip)       |
| rock4cplus             | Radxa ROCK 4C+                  | [sbc-rockchip](https://github.com/siderolabs/sbc-rockchip)       |
| rock4se                | Radxa ROCK 4SE                  | [sbc-rockchip](https://github.com/siderolabs/sbc-rockchip)       |
| jetson_nano            | Jetson Nano                     | [sbc-jetson](https://github.com/siderolabs/sbc-jetson)           |
| bananapi_m64           | BananaPi M64                    | [sbc-allwinner](https://github.com/siderolabs/sbc-allwinner)     |
| libretech_all_h3_cc_h5 | LibreTech H3 CC H5              | [sbc-allwinner](https://github.com/siderolabs/sbc-allwinner)     |
| pine64                 | Pine64 A64                      | [sbc-allwinner](https://github.com/siderolabs/sbc-allwinner)     |

## Building Overlays

A new overlay can be created using the [SBC Template](https://github.com/siderolabs/sbc-template) repository as a starting point and
replacing all references of `board` with  your SBC name.

Then followed by running `make rekres` to automatically generate/update all the required files.
Then the user can run `make help` on instructions on how to setting up `docker buildx`.

> Note: Run `make rekres` after any changes to the `.kres.yaml` file or before committing any changes.

It is highly recommended to take a look at an existing overlays from the [catalog](#overlays-catalog) as a template for building your own.


### Folder Structure

An overlay container image should have the following folder structure:

```text
.
├── artifacts
│   └── arm64
│       ├── dtb
│       │   └── rpi_4
│       ├── firmware
│       │   └── rpi4
│       │       └── firmware_20240302.bin
│       └── u-boot
│           └── rpi4.uboot.img
├── installers
│   └── rpi_generic
└── profiles
    ├── rpi_4.yaml
    └── rpi_5.yaml

12 directories, 3 files
```

An overlay can provide multiple `installers` and `profiles` for a group of SBC's.

The `artifacts` folder contains the files that will be copied to the Talos boot and installer assets.
This is an optional folder, if the overlay does not require any artifacts to be copied to the boot asset, it can be omitted.

The `installers` folder contains statically linked binaries named after the profile names.
If an overlay provides only a single profile it can be named `default`.

The `profiles` folder contains the list of profiles that the overlay supports.
Talos Imager will register profiles based on the file names in this folder.

### Installer implementation

The installer is a statically linked binary that is responsible for providing the logic Talos Imager will consume to generate a boot asset.

Installer can be any statically linked binary and has to be provided for both `amd64` and `arm64` architectures.

Sidero Labs will provide an official Go wrapper to handle the communication between the installer and Talos Imager.

Sidero Labs provides an [`adapter`](https://pkg.go.dev/github.com/siderolabs/talos/pkg/machinery/overlay/adapter#Execute) package than can used as the entrypoint of the Go program.

The Go code should implement the [`overlay.Installer`](https://pkg.go.dev/github.com/siderolabs/talos/pkg/machinery/overlay#Installer) interface.

An example of a simple installer can be found in the [sbc-template](https://github.com/siderolabs/sbc-template/blob/main/installers/board/src/main.go).

Refer to using [Custom installers](#custom-installers) for more information on how to use custom installers.

#### Custom Installers

Custom Installers can be written in any language as long as they follow the conditions below:

* The binary has to accept stdin as yaml input and output yaml to stdout.
* The binary should exit with a non-zero status code if an error occurs.
* The binary should implement `install` and `get-options` as `argv[1]`.

`get-options` accepts a yaml input of arbitrary `extraOptions` passed from the imager and should output a yaml to `stdout` conforming to the [`overlay.Options`](https://pkg.go.dev/github.com/siderolabs/talos/pkg/machinery/overlay#Options).

`install` accepts a yaml input conforming to [`overlay.InstallOptions`](https://pkg.go.dev/github.com/siderolabs/talos/pkg/machinery/overlay#InstallOptions) and outputs an empty yaml to `stdout`.

The installer `get-options` and `install` commands can use the provided inputs to perform any necessary operations to install the overlay on the target device.

### Profiles

Profiles define the output image format and base metal image size for an overlay.
This would rarely change and the default profile generated from `sbc-template` should be sufficient for most cases.
