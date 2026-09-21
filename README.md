# home-assistant

Personal HomeAssistant Config

## Installed versions (`ha-lock.json`)

`ha-lock.json` is a generated inventory of the HA core version, every installed
HACS repository (integrations + Lovelace cards) and every Supervisor add-on, so
version bumps show up in `git log` without committing `.storage/` or vendoring
`custom_components/`.

Regenerate it from the Terminal & SSH / Advanced SSH & Web Terminal add-on
(needs the `ha` CLI for add-on data; `jq` is already there):

    /config/ha-lock.sh

The output is sorted and timestamp-free, so a re-run with nothing changed is a
no-op. Run it before committing, or from a cron in the SSH add-on.
