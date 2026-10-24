# Config reference

Every setting you can change, its possible values, and what changing it does.
"Ours" = what this server uses now. Source: https://projectreclaimer.dev/host.html and /modes.html.
With `auto_reload = true`, saved edits apply while the server runs (from the next vote); `anti_cheat` needs a restart.

## 1. `dedicated.toml`, top level (whole machine)

| Setting | Values | Default | Ours | Changing it |
|---|---|---|---|---|
| `game` | folder | `"game"` | `"game"` | Where the Halo 3 files are |
| `content` | folder | `"content"` | `"content"` | Shared Maps / Game Modes / Mods folder |
| `data` | folder | `"data"` | `"data"` | Per-server logs and live status |
| `bans` | file | `"bans.json"` | `"bans.json"` | Shared ban list |
| `public_address` | IP or DNS name, or empty | auto | auto | `127.0.0.1` = only this PC sees it; `192.168.x.x` = only your LAN; public IP/DNS = internet |
| `upnp` | true / false | false | false | true = router opens the ports itself. Keep false on AWS |
| `auto_update` | true / false | false | false | true = installs new releases and restarts (kills running games) |
| `auto_reload` | true / false | true | true | false = edits only apply after `dedicated reload` |
| `host_name` | text | "Dedicated server" | "Good times saturday - Tsavo Highway" | Shown under the server name in the browser and lobby |
| `admins` | list of player IDs | [] | [] | Those players can kick/ban on every server |
| `stats_server` | empty / `"off"` / address | public service | public | `"off"` = games don't count toward players' ranks |

**`[master]`**: `enabled` (true), `port` (49175 TCP), `peers`, `origin`. Turning it off hides the server from the LAN/local list.
**`[rcon]`**: `password` (empty = remote console off), `address` ("127.0.0.1" = only this PC can connect).

## 2. Per-server settings (`[defaults]` for all, or inside one `[[server]]`)

| Setting | Values | Default | Ours | Changing it |
|---|---|---|---|---|
| `name` | text, ≤48 chars, unique | required | "Good times saturday - Tsavo Highway" | Server browser name |
| `port` | 1024-65535 UDP, unique | required | 49176 | Must match firewall/router forward |
| `playlist` | playlist file | — | — | Voted rotation (pick **one** of playlist / map+game / variant / campaign / odst) |
| `map` + `game` | names | Guardian + Slayer | — | Same map and mode every game, no voting |
| `variant` | saved game `.json` | — | — | One saved custom game forever |
| `campaign` / `odst` | mission settings | — | Tsavo Highway, Legendary, skulls 6144 | Co-op campaign / ODST Firefight instead of multiplayer |
| `max_players` | 1-127 (campaign/ODST ≤16) | 16 | 16 | Lobby cap |
| `min_players` | 1-max_players | 1 | 1 | Vote/game doesn't start until this many joined |
| `voice` | true / false | true | true | All voice chat on/off |
| `voice_global` / `voice_team` / `voice_proximity` | true / false | true | true | Turn off V (everyone), B (team), N (nearby) keys separately |
| `text_chat` | true / false | true | true | Text chat on/off |
| `votes` | true / false | true | true | false = no map vote; playlist just picks |
| `anti_cheat` | "enforce" / "detect" / "off" | enforce | enforce | detect = logs only, no kicks; off = none. Restart to apply |
| `block_vpn` | true / false | true | true | false = VPN/proxy/cloud players allowed in |
| `max_ping` | 0-1000 ms | 0 (no limit) | 0 | Players above it are refused at join |
| `load_timeout` | 0-600 s | 30 | 30 | How long one slow loader holds everyone up before being removed; 0 = wait forever |
| `team_changing` | "balanced" / "game_type" / "off" | balanced | (unused in FFA) | Who may switch teams |
| `camera` | "first_person" / "player_choice" / "third_person" | first_person | first_person | player_choice = everyone can toggle 3rd person |
| `friendly_fire` | true / false | true | (unused in FFA) | false = teammates can't hurt each other |
| `trust_player_games` | true / false | true | true | Campaign/ODST resync behaviour only |
| `chat_log` | true / false | true | true | Daily text chat log file |
| `welcome` | text or up to 5 lines; `{name}` `{server}` | empty | set | Chat message on join |
| `hidden` | true / false | false | false | true = not listed; join by IP only |
| `password` | text | empty | empty | Private server |
| `share_mods` | true / false | false | false | Players can download missing mods from the server |
| `share_rate` | Mbit/s, 0 = unlimited | 20 | 20 | Upload cap for mod downloads |
| `customization` / `require_customization` / `no_vanilla_characters` | mod names / bools | — | — | Force character mods |
| `host_name`, `admins` | per server | — | — | Override the top-level ones for this server |
| `rcon_port`, `rcon_password` | TCP port / text | game port | — | This server's remote console |
| `enabled` | true / false | true | true | false = keep the entry but don't run it |

## 3. Playlist file

| Field | Values | Ours | Changing it |
|---|---|---|---|
| `name` | text | "Swords" | Shown in the lobby |
| `vote_seconds` | 5-120 | 20 | Voting countdown |
| `games` | 3-128 entries, no duplicates | 6 | The rotation |

Each game entry:

| Field | Values | Changing it |
|---|---|---|
| `map` | map name, `Maps/x.json`, or `workshop:<id>/<file>` | Which map |
| `game` | game type name ("Slayer", "Oddball"…), variant name, or `Game Modes/x.json` | Which mode |
| `weight` | 1-100 (default 1) | How often it appears on the ballot vs others |
| `name` | text | Name players see on the ballot, e.g. "BR Slayer" |
| `rules` | `score_to_win`, `kill_points`, `death_points`, `suicide_points`, `betrayal_points` | Scoring for this entry only |
| `options` | `"section.key": number or label` | Any Game Options change for this entry only (see 4) |
| `world` | `sprint`: "off"/"unlimited"/"stamina"; `sprint_speed_percent` 110-200 (150); `sprint_stamina_seconds` 1-30 (5) | Adds sprint (off by default for every playlist game) |
| `anti_cheat` | false | Skip anti-cheat for an odd map/mode |
| `voice_team_only` | true | Voice only to teammates for that game |
| `base_map` | map name | Only for Forge variants on mod maps |

## 4. Game options (`options` in a playlist entry or mode file)

Values can be the label the game shows ("Battle rifle", "None") or the choice number.
Documented keys:

| Key | Example values | Changing it |
|---|---|---|
| `player.primary_weapon` | "Battle rifle", "Random" (others likely "Sniper rifle", "Shotgun"… as the lobby spells them) | Starting weapon ("Random" = new one every spawn) |
| `player.secondary_weapon` | "Magnum", "Map default" | Second starting weapon |
| `player.grenades` | label / number (2 = none in Gun Game) | Starting grenades |
| `player.shields` | number (1 = no shields) | Shield strength |
| `player.ammo` | label / number (2 = unlimited in Gun Game) | Ammo rules |
| `player.pickup` | label / number | Can players pick up weapons |
| `map.weapons` | label / number (11 = none in Gun Game) | Which weapons are placed on the map |
| `map.vehicles` | "None" or map default | Vehicles on the map |
| `rounds.teams` | 0 = FFA, 1 = teams | FFA vs team game |
| `rounds.limit` | 1, 3, 5… | Number of rounds |
| `rounds.minutes` | 0 = no limit, 5, 10, 15… | Time limit per round |
| `rounds.early_victory` | on/off | End a round early when decided |
| `rounds.reset_players` | number | Reset players between rounds |
| `respawn.lives` | 0 = unlimited, 1, 3, 5… | Lives per round |
| `respawn.seconds` | number | Respawn delay |
| `mode.hill_movement`, `mode.hill_order` | KotH: 4 = every minute, 1 = map order | Mode-specific rules (each game type has its own `mode.*` keys) |

Other Halo 3 Game Options (gravity, speed, damage, motion tracker, camo, overshield respawn…) also work,
but the docs don't list their keys. To get any exact key: set it in a lobby, **Save to playlist**, and
copy what the editor writes. `dedicated check` reports unknown keys/labels by game number.

## 5. Player traits (scripted modes, `traits` action)

Value = position in the Game Options list, 0 = unchanged. Highest value per trait:
`speed` 10 (7 = 125%, 8 = 150%), `camouflage` 4 (4 = invisible), `aura` 4 (4 = white), `radar` 4,
`radar_range` 7, `ammo` 3, `pickup` 2, `grenade_regeneration` 2.
