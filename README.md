# Solder Alert

An ESPHome-based attention device that supervises a soldering iron's power switch. It counts down the iron's on-time, warns you before the time runs out, lets you add more time from the device, and cuts power if nobody responds — so an iron never gets left on indefinitely.

It pairs with a Home Assistant blueprint that drives a real smart plug or switch and adds an offline safety net: if the device drops off the network or a deadline passes, Home Assistant turns the switch off on its own.

## Hardware

Two board variants build from one shared config:

- **ESP32-S3** — Waveshare ESP32-S3-Touch-LCD-1.47 (8 MB PSRAM). The recommended board.
- **ESP32-C6** — the original prototype board, still supported.

Both variants drive a 172x320 touch LCD and a WS2812 status LED strip, and control a switch or smart plug through Home Assistant.

### Bill of Materials

This is a blinking-lights project, so use whatever you have on hand that's in your junk box.

I wanted these units to look identical so I purchased Waveshare displays.

- [Adafruit Perma-Proto Quarter-sized Breadboard PCB](https://www.adafruit.com/product/1608)
- [ESP32-S3-Touch-LCD-1.47-M](https://www.waveshare.com/esp32-s3-touch-lcd-1.47.htm?sku=31199)
- [ESP32-C6-Touch-LCD-1.47-M](https://www.waveshare.com/esp32-c6-touch-lcd-1.47.htm?sku=31201)
- I used some leftover segments from [a BTF-Lighting WS2812B LED strip](https://www.amazon.com/dp/B0DKSV5TPS) (160 LEDs/meter FCOB, 10mm wide)
- Fine hookup wire (30 AWG)

[Assembly photos](assembly-photos.html) from the prototype and the first "production" units installed at [PDX Hackerspace](https://pdxhackerspace.org/).

A 3D-printable enclosure lives in [`enclosure/`](enclosure/) — OpenSCAD source plus ready-to-print STL and 3MF, sized for the Waveshare display and the quarter-size Adafruit perma-proto board.

## Build and flash

Built with [ESPHome](https://esphome.io/) through the `make` targets in `firmware/`:

```sh
cd firmware
cp secrets.yaml.example secrets.yaml   # then fill in your values
make run BOARD=s3                      # compile, flash, and tail logs (USB)
make run BOARD=c6                      # or the C6 board
```

Run `make` with no target to list everything. The first flash is over USB; later flashes go over WiFi (OTA) once the device is provisioned through its captive portal.

## Secrets

Copy `firmware/secrets.yaml.example` to `firmware/secrets.yaml` and set:

- `api_encryption_key` — generate with `esphome secrets generate-encryption-key`
- `ota_password` — any strong password
- `ap_password` — the captive-portal fallback AP password. The example ships a default (`solder-alert-setup`); change it for anything past a bench setup.

WiFi credentials are not stored in the repo. The device asks for them through its captive portal on first boot.

## Home Assistant

`blueprints/solder-alert-bridge.yaml` bridges the device to a real HA switch and adds the offline and deadline safety fallback.

HA's "Import Blueprint" dialog only accepts a URL — there's no file picker — so to install a local copy you have to place the file directly in your HA config, using the **File Editor** add-on or `scp`:

```text
<config>/blueprints/automation/solder-alert/solder-alert-bridge.yaml
```

HA doesn't watch the filesystem for new blueprints, so afterward reload it from **Developer Tools → YAML** (reload automations / blueprints), or restart HA.

Then create an automation from the blueprint and pick your device, the target switch, and the device's "On-period expires at" sensor. Set the smart plug's power-on state to **off** so it never restores to "on" after a power cut.

## Releases

When a [release](https://github.com/ctrlh/solder-alert/releases) includes prebuilt factory images, flash a `*.factory.bin` directly (with `esptool` or the ESPHome web flasher) — no build needed. Otherwise, build from source with
the steps above.

## License

MIT — see [LICENSE](LICENSE).
