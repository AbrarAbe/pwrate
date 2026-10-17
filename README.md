# PipeWire Sample Rate Manager

This script provides a simple command-line interface to manage the sample rate of your PipeWire audio system.  It allows you to set custom sample rates, choose from common presets (44.1kHz, 48kHz, 96kHz, 192kHz, 384kHz), reset to the default, and view current PipeWire settings.

## Requirements

* **Linux:** This script is designed for Linux systems. It may not work on other operating systems.
* **PipeWire:** This script requires PipeWire to be installed and running.
* **`bc` command:**  Basic Calculator for arithmetic operations.

## Installation

1. Clone the repository and go into it:
```sh
git clone https://github.com/AbrarAbe/pwrate.git
cd pwrate
```

2. Make the script executable (if it's not):
```sh
chmod +x pwrate
```

3. Link it into your `$PATH` so you can run it from anywhere:
```sh
sudo ln -s "$PWD/pwrate" /usr/local/bin/pwrate
```

4. Install the required PipeWire config:
```sh
mkdir -p ~/.config/pipewire/pipewire.conf.d
cp .config/pipewire/pipewire.conf.d/*.conf ~/.config/pipewire/pipewire.conf.d/
```

5. *Optional:* for a system-wide config, copy to `/etc/pipewire/pipewire.conf.d/` instead (requires root):
```sh
sudo cp .config/pipewire/pipewire.conf.d/*.conf /etc/pipewire/pipewire.conf.d/
```

6. Restart PipeWire :
```sh
systemctl --user restart pipewire
```

Forced rates (what this script sets) bypass `clock.allowed-rates`, so the script works either way. The config fixes the *default* behavior: when no rate is forced, PipeWire picks the rate dynamically from `clock.allowed-rates`, and audio at rates missing from that list gets resampled to an allowed one. You can confirm the current settings with menu option 8 (Show current settings). To change the allowed rates later, edit the installed `.conf` file and restart PipeWire.

## Usage

Run the script from your terminal: `pwrate`

The script will present a menu with the following options:

1. **Set custom sample rate:** Allows you to enter a custom sample rate in kHz.
2. **Set sample rate to 44.1kHz:** Sets the sample rate to 44.1 kHz.
3. **Set sample rate to 48kHz:** Sets the sample rate to 48 kHz.
4. **Set sample rate to 96kHz:** Sets the sample rate to 96 kHz.
5. **Set sample rate to 192kHz:** Sets the sample rate to 192 kHz.
6. **Set sample rate to 384kHz:** Sets the sample rate to 384 kHz.
7. **Reset sample rate to default:** Resets the sample rate to PipeWire's default setting.
8. **Show current settings:** Displays the current PipeWire clock settings, including the sample rate.
9. **Show pactl info:** Displays PulseAudio/PipeWire server information (`pactl info` and `pactl stat`).
10. **Show current PipeWire processes:** Displays the current PipeWire processes (`pw-top` output).

After making a selection, the script will display the current sample rate and provide an options menu with the following:

1. Back to main menu
2. Show current settings
3. Exit

## How it Works

The script interacts with PipeWire using the `pw-metadata` command to get and set the `clock.force-rate` setting. If `clock.force-rate` is 0, it defaults to using the `clock.rate` setting to display the current rate. A forced rate applies immediately and bypasses `clock.allowed-rates`; the allowed list only governs rate selection when nothing is forced. Error handling is included to gracefully handle situations where Pipewire is not installed or if the sample rate cannot be determined.

## Troubleshooting

* **PipeWire not installed:** Ensure PipeWire is installed on your system.
* **Permission errors:** You may need administrator privileges to run the script, especially when setting the sample rate.  Try running with `sudo`.
* **Unexpected output:** If the script produces unexpected output, try running `pw-metadata -n settings` directly from the command line to see the raw PipeWire settings. This can help you diagnose issues.
* **Wrong rate when nothing is forced:** with `clock.force-rate` at 0 (after a reset or reboot), PipeWire picks the rate from `clock.allowed-rates`, and rates missing from that list are resampled. Fix the list — see [Installation](#installation).

## License

See the `LICENSE` file for details.