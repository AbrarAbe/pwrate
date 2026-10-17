# PipeWire Sample Rate Manager

This script provides a simple command-line interface to manage the sample rate of your PipeWire audio system.  It allows you to set custom sample rates, choose from common presets (44.1kHz, 48kHz, 96kHz, 192kHz, 384kHz), reset to the default, and view current PipeWire settings.

## Requirements

* **Linux:** This script is designed for Linux systems. It may not work on other operating systems.
* [**PipeWire:**](https://pipewire.org/) This script requires PipeWire to be installed and running.
* **`gum`:** Charm's interactive CLI tool for the arrow-key menus and styled prompts. `install.sh` installs it automatically via your package manager; manual instructions are in [charmbracelet/gum](https://github.com/charmbracelet/gum#installation).

## Installation

1. Clone the repository and run the installer:
```sh
git clone https://github.com/AbrarAbe/pwrate.git
cd pwrate
./install.sh
```

The installer:

* installs `gum` if it's missing (via `pacman`, `dnf`, `yum`, `apt`, `zypper`, `brew`, `nix`, or `go`),
* links `pwrate` into your `$PATH` (`~/.local/bin` if it's on your PATH, otherwise `/usr/local/bin`),
* installs the required PipeWire config to `~/.config/pipewire/pipewire.conf.d/` (backing up any differing existing file as `.bak`),
* asks before restarting PipeWire so the config takes effect.

Re-running `./install.sh` is safe — everything is idempotent. Optional flags: `--system` installs the config to `/etc/pipewire/pipewire.conf.d/` instead (requires root), and `--no-restart` skips the restart prompt.

### Manual installation

<details>
<summary>Expand for the step-by-step version</summary>

1. Clone the repository and go into it:
```sh
git clone https://github.com/AbrarAbe/pwrate.git
cd pwrate
```

2. Install gum via your package manager (see [gum's installation section](https://github.com/charmbracelet/gum#installation)).

3. Make the script executable (if it's not):
```sh
chmod +x pwrate
```

4. Link it into your `$PATH` so you can run it from anywhere:
```sh
sudo ln -s "$PWD/pwrate" /usr/local/bin/pwrate
```

5. Install the required PipeWire config:
```sh
mkdir -p ~/.config/pipewire/pipewire.conf.d
cp .config/pipewire/pipewire.conf.d/*.conf ~/.config/pipewire/pipewire.conf.d/
```

6. *Optional:* for a system-wide config, copy to `/etc/pipewire/pipewire.conf.d/` instead (requires root):
```sh
sudo cp .config/pipewire/pipewire.conf.d/*.conf /etc/pipewire/pipewire.conf.d/
```

7. Restart PipeWire :
```sh
systemctl --user restart pipewire
```

</details>

Forced rates (what this script sets) bypass `clock.allowed-rates`, so the script works either way. The config fixes the *default* behavior: when no rate is forced, PipeWire picks the rate dynamically from `clock.allowed-rates`, and audio at rates missing from that list gets resampled to an allowed one. The `pwrate` header always shows the current state (active rate, default rate, allowed rates, quantum). To change the allowed rates later, edit the installed `.conf` file and restart PipeWire.

## Usage

Run the script from your terminal: `pwrate`

pwrate is a single screen: a status panel on top and an arrow-key menu (powered by `gum`) below it:

* **Active rate** — what your audio is running at now: `96000 (forced)` when a rate is forced, or `auto (default 192000)` when nothing is forced (in that case PipeWire picks from the allowed list per stream).
* **Default rate** — the `clock.rate` value used when nothing is forced.
* **Allowed rates / Quantum** — the configured `clock.allowed-rates` and `clock.quantum`.

Menu options:

1. **Set custom sample rate:** Prompts for a rate in kHz (e.g. `48` or `44.1`).
2. **Set sample rate to 44.1kHz:** Sets the sample rate to 44.1 kHz.
3. **Set sample rate to 48kHz:** Sets the sample rate to 48 kHz.
4. **Set sample rate to 96kHz:** Sets the sample rate to 96 kHz.
5. **Set sample rate to 192kHz:** Sets the sample rate to 192 kHz.
6. **Set sample rate to 384kHz:** Sets the sample rate to 384 kHz.
7. **Reset sample rate to default:** Unforces the rate so PipeWire uses its default again.
8. **Show pactl info:** PulseAudio/PipeWire server information (`pactl info` and `pactl stat`) in a scrollable pager.
9. **Show current PipeWire processes:** `pw-top`.
10. **Exit:** Quit the script.

After any action the menu redraws with the updated status — the confirmation line ("Sample rate set to: …") is followed immediately by the panel showing the new active rate.

## How it Works

The script drives its menus and prompts with `gum` and interacts with PipeWire using the `pw-metadata` command to get and set the `clock.force-rate` setting. The status panel reads `clock.force-rate`, `clock.rate`, `clock.allowed-rates`, and `clock.quantum` in one pass: a non-zero `clock.force-rate` is shown as the active (forced) rate, while `clock.rate` is only displayed as the active rate when nothing is forced. A forced rate applies immediately and bypasses `clock.allowed-rates`; the allowed list only governs rate selection when nothing is forced. Error handling is included for missing `pw-metadata`/`gum` and invalid rate input.

## Troubleshooting

* **PipeWire not installed:** Ensure PipeWire is installed on your system.
* **Permission errors:** You may need administrator privileges to run the script, especially when setting the sample rate.  Try running with `sudo`.
* **Unexpected output:** If the script produces unexpected output, try running `pw-metadata -n settings` directly from the command line to see the raw PipeWire settings. This can help you diagnose issues.
* **Wrong rate when nothing is forced:** with `clock.force-rate` at 0 (after a reset or reboot), PipeWire picks the rate from `clock.allowed-rates`, and rates missing from that list are resampled. Fix the list — see [Installation](#installation).

## License

See the `LICENSE` file for details.