# Halo 3 Swords server (Project Reclaimer)

**Branch `swords-only`.** One server, `Good times FFA - H3 originals`, 2-8 players, free-for-all
**Swords only**, voted rotation of 6 small maps. The mixed-mode rotation is on the `main` branch.

## Quick start (Windows PC with MCC + Project Reclaimer installed)

Admin PowerShell:

```powershell
git clone -b swords-only https://github.com/q1kka/reclaimer-server.git C:\reclaimer-config
cd C:\reclaimer-config
powershell -ExecutionPolicy Bypass -File .\setup-windows.ps1 -ExePath "C:\path\to\your\project-reclaimer.exe"
cd C:\reclaimer
.\project-reclaimer.exe dedicated
```

Then start the game normally and join **Good times FFA - H3 originals** from the Server Browser.
To test alone, set `min_players = 1` in `C:\reclaimer\dedicated.toml`.
After a `git pull`, re-run `setup-windows.ps1` to copy the new config into `C:\reclaimer`.

| File | What it is |
|---|---|
| `game-modes/swords.json` | Custom Swords mode |
| `docker/` | Experimental Docker setup (Mac/Linux) |
| `dedicated.toml` | Server config (8 players max, voting waits for 2) |
| `playlists/swords-small.playlist.json` | **Active**: Swords on 6 small maps, with weights |
| `playlists/lone-wolves.playlist.json` | Mixed-mode rotation from `main` (not used on this branch) |
| `CONFIG-REFERENCE.md` | Every setting, its possible values and what changing it does |
| `setup-windows.ps1` | Builds the server folder, copies the config, opens the firewall, runs `dedicated check` |

Docs: https://projectreclaimer.dev/host.html

## Rotation

Every game is Swords (`game-modes/swords.json`): Energy Sword only, no map weapons, vehicles or
grenades, so the map's normal power weapons and equipment don't spawn. Stock map layouts.
Players = Bungie's recommended count.

Each vote offers 3 maps drawn by weight, plus "None of the above". **On ballot** = chance the map
is one of the 3. **Played** = chance it's played if votes are random (with no votes, the first
offered map starts, which gives the same odds). Total weight 48.

| Map | Weight | On ballot | Played | Players | Why this weight |
|---|---|---|---|---|---|
| Guardian | 10 | 59% | 20% | 2-6 | Tight, vertical, lifts: classic sword fights |
| Heretic | 10 | 59% | 20% | 2-8 | Small symmetric arena, built around a sword spawn |
| Construct | 8 | 51% | 17% | 2-8 | Small, lifts and corridors |
| Citadel | 8 | 51% | 17% | 2-6 | Small, close quarters |
| Epitaph | 6 | 40% | 13% | 2-6 | Small but some open lanes |
| Cold Storage | 6 | 40% | 13% | 2-6 | Small, a bit flat |

Left out: Narrows (long bridge, slow for swords), Isolation (vehicles, big), and every map Bungie
rates for 4+ players (The Pit, Foundry, Ghost Town, Orbital) or bigger.

### Custom modes

`game-modes/` is copied to the server's `content\Game Modes` by `setup-windows.ps1`.

- **Swords** (`swords.json`): Energy Sword only, no weapons/vehicles/grenades on the map, unlimited
  sword battery, 25 kills, 10 min. Option values copied from the bundled Gun Game mode.

If `dedicated content` already lists a built-in "Swords", use that name instead.

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
4. Launch your normal client, open the Server Browser, join "Good times FFA - H3 originals".
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
