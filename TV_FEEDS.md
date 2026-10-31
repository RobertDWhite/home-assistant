# TV feeds

Four independently selectable streams:

- Summary Feed: existing information and kids-camera rotation, `/stream.m3u8`.
- Camera Feed: all 15 Protect views simultaneously, `/cameras/stream.m3u8`.
- Weather Feed: custom weather radar (30 seconds), forecasts and active alerts (15 seconds), `/weather/stream.m3u8`.
- Summary Only Feed: information layouts only, no cameras, `/summary/stream.m3u8`.

All paths use the existing private LAN streaming host `http://10.99.5.60`.
Each TV has four scripts and a restart-mode controller. Existing room-light and bathroom schedules still start the original Summary Feed. Stops recognize all four stream URLs. Bathroom power remains infrared with optimistic state.

Deployment order: merge/deploy the corresponding screen-renderer infrastructure changes, verify all four playlists, deploy these scripts and the HomeKit exclusion, validate HA configuration and reload scripts. Import the two dashboard JSON files via the Lovelace API (back up the existing TV Screens dashboard first). No `.storage` edits.

The new scripts are excluded from the existing crowded HomeKit bridge. Dedicated HomeKit pairing and Siri scene names are a separate activation step; they are not ready merely because the HA buttons work.
