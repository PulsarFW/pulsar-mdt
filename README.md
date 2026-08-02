<div align="center">

<img src="https://r2.fivemanage.com/GPYOH8Hq4GPyAY7czrgLe/pulsarbanner.png" alt="Pulsar Framework" width="100%" />

<br/>

# PULSAR-MDT

### Police Mobile Data Terminal — 8 job-based portals sharing one records core, plus a live dispatch/alerts subsystem

<br/>

![Lua](https://img.shields.io/badge/Lua_5.4-2C2D72?style=flat-square&logo=lua&logoColor=white)
![FiveM](https://img.shields.io/badge/FiveM-F40552?style=flat-square)
![Svelte](https://img.shields.io/badge/Svelte_5-FF3E00?style=flat-square&logo=svelte&logoColor=white)
![TypeScript](https://img.shields.io/badge/TypeScript-3178C6?style=flat-square&logo=typescript&logoColor=white)
![Vite](https://img.shields.io/badge/Vite-646CFF?style=flat-square&logo=vite&logoColor=white)
![Bun](https://img.shields.io/badge/Bun-000000?style=flat-square&logo=bun&logoColor=white)
![MariaDB](https://img.shields.io/badge/MariaDB-003545?style=flat-square&logo=mariadb&logoColor=white)

<br/>

<sub>Enjoy the framework? A coffee helps keep active development, hardening, and support going.</sub>

<a href="https://buymeacoffee.com/pulsarframework"><img src="https://cdn.buymeacoffee.com/buttons/v2/default-yellow.png" alt="Buy Me A Coffee" style="height: 50px !important;width: 180px !important;" /></a>

<br/>

[Overview](#overview) · [Portals](#portals) · [Dispatch & Alerts](#dispatch--alerts) · [Theming](#theming) · [Dependencies](#dependencies)

</div>

---

## Overview

The full Mobile Data Terminal — records core (People, Vehicles, Firearms, Warrants, Reports, Properties), department Roster and Fleet management, DOC prisoner processing, a permission-matrix and master charge-list admin, a Penal Code reference, and a Library of shared documents. One `Shell.svelte` + config-driven route table serves all 8 portals rather than duplicating the UI per department.

Badge and driver's license world-overlays render for nearby viewers when a badge/ID is presented (`client/badges.lua` does the proximity + line-of-sight check), and a bodycam frame overlay renders for anyone watching a live feed. `plsr.Tasks:Register` schedules recurring server-side jobs, like auto-expiring active warrants past their `expires` timestamp.

Direct `oxmysql` access, no ORM — every table read/write goes straight through native SQL.

---

## Portals

One shell, one route table (`ui/src/config.ts`), 8 permission-gated portals resolved from the player's on-duty job:

| Portal | Resolved from | Surfaces |
|---|---|---|
| **Police** | `police` job | Full records core, Roster, Fleet Manager, Penal Code, Library, Permissions, Charges admin |
| **DOJ** | `government` / `doj` workplace | Records core, Roster, Library, Permissions, Charges admin |
| **DA** | `government` / `dattorney` workplace | Records core, Roster, Library, Permissions, Charges admin |
| **Public Defenders** | `government` / `publicdefenders` workplace | Records core, Roster, Library |
| **Medical** | `ems` job | Reports, People, Roster, Library, Fleet Manager, Permissions, Charges admin |
| **DOC** | `prison` job | Records core, Roster, Penal Code, Library, Prisoners, Fleet Manager, Permissions, Charges admin |
| **Attorney** | logged-in attorney, no gov job | Records core, Roster, Library (read access for case work) |
| **Public** | no job, not an attorney | Warrants, Penal Code, Library only |

`admin-permissions` (grade × permission matrix) and `admin-charges` (master charge list) are gated per-department but always reachable to `MDTSystemAdmin` regardless of on-duty job/workplace.

---

## Dispatch & Alerts

The on-duty dispatch panel — live unit roster, incoming 911/predefined alerts, a dispatch log, and radio channels — is fully native: tracked server-side in `server/alerts/component.lua` and pushed to the NUI over the same message bridge as the rest of the MDT. No external service is required for it to work.

Set `config/shared.lua`'s `Alerts.Websocket = true` to additionally mirror alerts and dispatch-log events out to an external websocket server (see `pulsar_ws`) and open a browser-side `socket.io-client` connection — for server owners building a companion website MDT. That connection is purely supplementary; the in-game panel never depends on it.

---

## Theming

Edit `ui/src/theme.css` for colors/fonts and `ui/src/config.ts` for portal routes, report-type rules, and pagination sizes. Then rebuild:

```
cd ui
bun install
bun run build
```

Commit the rebuilt `ui/dist/` — that's what actually ships.

---

## Dependencies

- `pulsar_core` — framework core
- `pulsar_police` — the primary consumer of MDT data
- `pulsar_pwnzor` — anti-cheat check loaded alongside every resource
- `oxmysql` — direct MariaDB access for records, warrants, and charges
- `pulsar_ws` *(optional)* — only needed if `Alerts.Websocket` is enabled for an external dispatch mirror

---

## License

This resource is free to use and modify under the [Pulsar Framework License](LICENSE.md). Redistribution is welcome as long as it stays free — selling this resource or any derivative of it requires written permission from the Pulsar Framework team.

---

<div align="center">

![Pulsar Framework](https://img.shields.io/badge/Pulsar-Framework-7c3aed?style=flat-square)
![Built for FiveM](https://img.shields.io/badge/Built_for-FiveM-F40552?style=flat-square)

</div>
