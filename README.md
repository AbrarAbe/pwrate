# PipeWire Sample Rate Manager

This script provides a simple command-line interface to manage the sample rate of your PipeWire audio system.  It allows you to set custom sample rates, choose from common presets (44.1kHz, 48kHz, 96kHz, 192kHz, 384kHz), reset to the default, and view current PipeWire settings.

## Requirements

* **Linux:** This script is designed for Linux systems. It may not work on other operating systems.
* **PipeWire:** This script requires PipeWire to be installed and running.
* **`bc` command:**  Basic Calculator for arithmetic operations.

## Installation

1. Save the script above as `pwrate`.
2. Make the script executable: `chmod +x pwrate`
3. Optionally save the script to a directory in your system's `$PATH` for easy access.

## Usage

Run the script from your terminal: `./pwrate`

The script will present a menu with the following options:

1. **Set custom sample rate:** Allows you to enter a custom sample rate in kHz.
2. **Set sample rate to 44.1kHz:** Sets the sample rate to 44.1 kHz.
3. **Set sample rate to 48kHz:** Sets the sample rate to 48 kHz.
4. **Set sample rate to 96kHz:** Sets the sample rate to 96 kHz.
5. **Set sample rate to 192kHz:** Sets the sample rate to 192 kHz.
6. **Set sample rate to 384kHz:** Sets the sample rate to 384 kHz.
7. **Reset sample rate to default:** Resets the sample rate to PipeWire's default setting.
8. **Show current settings:** Displays the current PipeWire clock settings, including the sample rate.
9. **Show current PipeWire processes:** Displays the current PipeWire processes (`pw-top` output).


After making a selection, the script will display the current sample rate and provide an options menu with the following:

1. Back to main menu
2. Show current settings
3. Exit

## How it Works

The script interacts with PipeWire using the `pw-metadata` command to get and set the `clock.force-rate` setting. If `clock.force-rate` is 0, it defaults to using the `clock.rate` setting to display the current rate. Error handling is included to gracefully handle situations where Pipewire is not installed or if the sample rate cannot be determined.

## Troubleshooting

* **PipeWire not installed:** Ensure PipeWire is installed on your system.
* **Permission errors:** You may need administrator privileges to run the script, especially when setting the sample rate.  Try running with `sudo`.
* **Unexpected output:** If the script produces unexpected output, try running `pw-metadata -n settings` directly from the command line to see the raw PipeWire settings. This can help you diagnose issues.
