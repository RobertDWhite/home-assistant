# Circadian sleep mode

Configured 2026-10-16: 01:00 local time (America/New_York) until actual sunrise.
`binary_sensor.circadian_sleep_mode` recomputes after startup and never reactivates at sunset.

All 33 Circadian groups reference this helper, with sleep brightness 10%, RGB [255, 0, 0],
and fallback sleep_colortemp 1000 K. Color-capable bulbs receive pure RGB red, translated
into their supported gamut by Home Assistant/Hue. White-only bulbs clamp to their reported
minimum (2000 or 2202 K). Lights that are off stay off; disabled Circadian switches stay disabled.
Normal daytime CT and brightness settings resume at sunrise for enabled switches.
The existing midnight–07:30 master bathroom/hallway dim rules defer while sleep is active.

## Local integration extensions

The upstream integration supports sleep_entity, sleep_state, sleep_colortemp and
sleep_brightness, but no saturated RGB sleep color. `sleep_rgb_color` is an optional
extension to custom_components/circadian_lighting/switch.py. The component also waits for the
sleep helper to be available at startup.

Since 2026-10-22 HACS installs Circadian Lighting from the fork RobertDWhite/circadian_lighting
(release 2.1.7.1 = upstream claytonjn 2.1.7 + this extension, branch sleep-rgb) instead of
claytonjn/hass-circadian_lighting, so HACS updates keep it. To take a newer upstream release,
rebase sleep-rgb onto it and publish a new fork release. Installing the claytonjn repository
again would drop the extension and the YAML schema would reject every sleep_rgb_color switch.

Both saved Hue scene sync integrations follow the sleep helper: native bulb gamut red for
color bulbs, maximum supported mirek for white-only bulbs, 10% brightness. These update
saved Circadian scene actions, not recalls, so they do not turn lights on. Normal scene
settings return at sunrise. Retain these local changes when updating either scene integration.

Docs: https://github.com/claytonjn/hass-circadian_lighting/wiki/Advanced-Configuration#switch-configuration-variables
Backup of original files and exact code patch: `/config/backups/circadian-sleep-20261016T044203Z`.
To revert, restore original files from that backup, remove template/circadian_sleep.yaml
and this document, validate configuration and restart Home Assistant.

Sleep brightness raised to 10% on 2026-10-16. Prior 1% settings backed up at `/config/backups/circadian-sleep-10pct-20261016T044937Z`.


Reliability repair, 2026-10-18:
- Removed the obsolete circadian_lighting_bridge YAML loader and disabled both legacy
  config entries. Its global event listener was still running and failing with
  CERTIFICATE_VERIFY_FAILED even while its entries showed setup_error.
- circadian_hue_scene_sync/__init__.py now waits for HA startup and usable sleep /
  color-temperature / brightness values before its first full sync. It refreshes
  native values after startup, checks readiness for up to 60 seconds, and also
  responds to switch brightness changes with a two-second debounce. This prevents
  failed startup sync and copying brightness before switches publish new values.
- All 27 originally enabled native room switches were restored; six previously
  disabled switches remain disabled. Sleep remains 01:00 to sunrise, red at 10%.
- Source/config backups and pre-isolation switch states are in
  /config/.circadian-repair-backups/. These local source changes need preserving
  across HACS updates.
- Remaining bridge-reported Zigbee connectivity issues were NOT resolved by this
  repair. No physical-light success is assumed from reported on/off states.
