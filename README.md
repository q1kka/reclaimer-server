# Halo 3 Tsavo Highway co-op server (Project Reclaimer)

**Branch `tsavo-legendary`.** One campaign co-op server, `Good times saturday - Tsavo Highway`:
Tsavo Highway on **Legendary** with the **Grunt Birthday Party** and **Cowbell** skulls, up to
16 players, everyone as their own Spartan/Elite. The Swords server is on `swords-only`, the
mixed FFA rotation on `main`.

## Quick start (Windows PC with MCC + Project Reclaimer installed)

Everyone who joins needs MCC with the Halo 3 campaign installed and the same Project Reclaimer
version. Admin PowerShell:

```powershell
git clone -b tsavo-legendary https://github.com/q1kka/reclaimer-server.git C:\reclaimer-config
cd C:\reclaimer-config
powershell -ExecutionPolicy Bypass -File .\setup-windows.ps1 -ExePath "C:\path\to\your\project-reclaimer.exe"
cd C:\reclaimer
.\project-reclaimer.exe dedicated
```

`setup-windows.ps1` copies the campaign missions (about 4 GB) the first time. Then start the game
normally and join **Good times saturday - Tsavo Highway** from the Server Browser (Campaign
filter). The mission starts as soon as one player is in; others join it while it runs.

Auto-kick offensive names: in a **second** PowerShell window, `cd C:\reclaimer-config; .\name-guard.ps1`
(see [Auto-kick offensive names](#auto-kick-offensive-names)).
After a `git pull`, re-run `setup-windows.ps1` to copy the new config into `C:\reclaimer`.

Already running the Swords server from `C:\reclaimer`? Switching branches and re-running setup
turns that same server into this one. Both at once would need one `dedicated.toml` with two
`[[server]]` blocks (they share the discovery port), so ask for that instead.

| File | What it is |
|---|---|
| `dedicated.toml` | Server config: the campaign setup, 16 players max |
| `name-guard.ps1` | Kicks players with offensive names, through RCON |
| `name-filter.txt` | The words `name-guard.ps1` kicks for; edit freely |
| `CONFIG-REFERENCE.md` | Every setting, its possible values and what changing it does |
| `setup-windows.ps1` | Builds the server folder, copies the config, opens the firewall, runs `dedicated check` |
| `docker/` | Experimental Docker setup (Mac/Linux) |
| `playlists/`, `game-modes/` | Swords/FFA rotations from the other branches (not used here) |

Docs: https://projectreclaimer.dev/host.html#campaign

## Campaign setup

In `dedicated.toml`:

```toml
campaign = { mission = 3030, insertion = 0, difficulty = "legendary", custom_characters = true, modifiers = { skulls = 6144 } }
```

| Setting | Ours | Options |
|---|---|---|
| `mission` | 3030 Tsavo Highway | 3010 Sierra 117, 3020 Crow's Nest, 3040 The Storm, 3050 Floodgate, 3070 The Ark, 3100 The Covenant, 3110 Cortana, 3120 Halo |
| `insertion` | 0 (mission start) | 1, 2, ... = later rally points, in the order the Campaign page lists them |
| `difficulty` | "legendary" | "easy", "normal", "heroic" |
| `custom_characters` | true | false = everyone plays as the Master Chief and the Arbiter |
| `modifiers.skulls` | 6144 | Sum of the skulls you want (table below) |

Other modifiers: `sprint = true` (with `sprint_speed_percent` 110-200, `sprint_stamina_seconds`
0-30), enemy `health_percent` / `damage_percent` 25-1000.

| Skull | Value | | Skull | Value |
|---|---|---|---|---|
| Iron | 1 | | Assassin | 512 |
| Black Eye | 2 | | Blind | 1024 |
| Tough Luck | 4 | | **Cowbell** | **2048** |
| Catch | 8 | | **Grunt Birthday Party** | **4096** |
| Fog | 16 | | IWHBYD | 8192 |
| Famine | 32 | | | |
| Thunderstorm | 64 | | | |
| Tilt | 128 | | | |
| Mythic | 256 | | | |

Avoid Iron with a full lobby: anyone dying sends everyone back to the checkpoint.

After Tsavo the server goes on to The Storm and through the campaign, then starts again from Tsavo.
Checkpoints live in the server's memory: restarting it starts Tsavo over.

## Auto-kick offensive names

Project Reclaimer has no server-side name filter (the in-game filter only masks names for the
player who turned it on), so `name-guard.ps1` does it through the remote console:

- Every 5 s it reads the player list and kicks anyone whose name matches `name-filter.txt`,
  with the reason "Offensive name. Change your name and rejoin." Admins are never kicked.
- A kick blocks them for 10 min (then 30/60/120 min for repeats that day); after renaming they can
  come back once it runs out.
- Matching sees through leetspeak (`n1gg3r`), spacing/symbols (`N i G g E r`), stretched letters,
  accents and Cyrillic lookalikes. Entries starting with `=` only match whole words, so `=spic`
  kicks "sp1c" but not "Spicy Taco", `=coon` not "Raccoon King".
- Edit `name-filter.txt` any time; it reloads by itself. Try names without kicking anyone:
  `.\name-guard.ps1 -Test "Some Name", "Other Name"`.
- Kicks are logged to `C:\reclaimer\name-guard.log`.

It needs RCON, which `setup-windows.ps1` turns on: it adds a random password to
`C:\reclaimer\dedicated.toml` (kept in `C:\reclaimer\rcon-password.txt`, never in this repo) and
RCON only listens on this PC (127.0.0.1). Restart the server after the first setup so RCON starts.
Windows only; the Docker setup doesn't run it.

## Before anything

- Steam MCC with Halo 3 Multiplayer installed on the Windows PC.
- Latest Project Reclaimer from https://github.com/ProjectReclaimer/project-reclaimer-releases/releases.
  **Server and client versions must match**, or nobody can join.
- Map and game type names must match what your copy reports. `setup-windows.ps1` prints
  them with `dedicated content`; `dedicated check` fails on any name in the playlist it
  doesn't know. Fix the playlist to match if needed (e.g. if FFA Slayer is called something else).

## Option A: host and play on the same Windows PC

1. Copy this folder to the Windows PC.
2. Admin PowerShell in that folder:
   ```powershell
   powershell -ExecutionPolicy Bypass -File .\setup-windows.ps1 -ExePath "C:\path\to\project-reclaimer.exe"
   ```
3. Start the server (leave this window open, Ctrl+C stops it):
   ```powershell
   cd C:\reclaimer; .\project-reclaimer.exe dedicated
   ```
4. Launch your normal client, open the Server Browser, join "Good times saturday - Tsavo Highway".
   To test alone, set `min_players = 1` in `C:\reclaimer\dedicated.toml` (it reloads live).

Friends outside your home network: forward **UDP 49176** and **TCP 49175** on your router
to the PC, or set `upnp = true`. Test from outside with
`project-reclaimer.exe server-status <your-public-ip>:49176`.

The server runs the Halo 3 engine headless, so it takes CPU/RAM from the game you're playing.
On a decent gaming PC with 8 players that should be fine; if you get frame drops, go to option B.

## Option A2: Docker on the Mac (experimental)

`docker/compose.yaml` runs the official image (x86-64 only) emulated on Apple Silicon. Not an
officially supported setup: the docs only list Docker Desktop on Intel Macs. Wine starts and the
server reads our config; real-game performance is untested.

1. Game files: on the Windows PC run
   `.\project-reclaimer.exe dedicated init C:\reclaimer-mac --from`, then copy the **contents** of
   `C:\reclaimer-mac\game` into `docker/server/game/` (keep the folders: `halo3/halo3.dll`,
   `halo3/maps/...`). ~5.5 GB, any way you like: USB stick, SMB share, `scp`.
2. Docker Desktop → Settings → General → turn on **Use Rosetta for x86_64/amd64 emulation on
   Apple Silicon**, Apply & restart. Much faster than the default QEMU emulation.
3. `cd docker && docker compose up -d && docker compose logs -f`
4. Copy `docker/.env.example` to `docker/.env` and set your machine's LAN IP (`ipconfig getifaddr en0` on a Mac).
5. On the Windows PC: Server Browser → join. Client version must match the image (latest = v0.9.23).

Config, playlist and Swords mode are mounted from this folder, so edits here apply live.

## Option B: AWS

Simplest path is a Windows Server EC2 instance, since that's an officially supported server OS
and the setup above works unchanged.

1. **Region**: closest to the players (e.g. `eu-north-1` Stockholm for Finland).
2. **Instance**: Windows Server 2022, compute-optimised, e.g. `c7i.large` (2 vCPU / 4 GB),
   go `c7i.xlarge` if `dedicated status` shows lag at 8 players. 40 GB gp3 disk.
3. **Security group inbound**: UDP 49176, TCP 49175 from 0.0.0.0/0; RDP 3389 from your IP only.
4. **Game files**: the server needs ~5.5 GB of Halo 3 files from *your own* install. On your PC run
   `project-reclaimer.exe dedicated init C:\reclaimer --from`, then zip `C:\reclaimer`, upload to S3,
   and download it on the instance (or copy via RDP drive sharing).
5. Copy this folder over, run `setup-windows.ps1` with `-ServerDir C:\reclaimer`, then
   `.\project-reclaimer.exe dedicated`. Use an Elastic IP if you want a stable address.
6. **Stop the instance when nobody's playing.** Windows instances bill by the hour including the licence.

Cheaper alternative: Ubuntu x86 instance + the official Docker image
`ghcr.io/projectreclaimer/project-reclaimer-dedicated` (`docker compose up -d`), using the compose
file from the release. Same ports, same `dedicated.toml`/playlist, same game-file copy.
