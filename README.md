# Lucky Portraits

A lightweight, zero-dependency World of Warcraft addon by **LittleLuckyPup** (supporting **Retail / Midnight**, **WoW Forever**, and **Classic**) that replaces Blizzard's default player unit frame portrait with custom images—automatically swapping portraits for shapeshifts, stances, combat, disguises, and character states.

## Features

* **Live Split-Pane Setup UI (`/lp`):** Pick your Default Portrait or any reactive state on the left, then switch between **Custom Image**, **Blizzard 3D**, or **Use Default** on the right with a large live circular preview.
* **Per-Image Zoom & Position Framing:** Save independent **Zoom (1.00x–2.50x)** and **Pan X / Pan Y** adjustments for every custom image without external re-cropping, and frame any form without shifting into it first.
* **Reactive Forms, Stances & States:**
  * **Druid Forms:** Bear, Cat, Travel (Stag / Mount), Aquatic, Moonkin, Tree of Life / Treant, and Flight Form.
  * **Class Forms, Stances & Buffs:** Shaman Ghost Wolf, Priest Shadowform & Spirit of Redemption, Warrior Stances (Battle, Defensive, Berserker), Stealth / Prowl / Shadowmeld, Paladin Auras, Hunter Aspects & Feign Death, Ice Block, Divine Shield, and Dwarf Stoneform.
  * **Universal States:** Ghost / Wisp, Dead, In Combat, Resting (Inn/City), Mounted, Flight Path (Taxi), Swimming, and AFK.
  * **Crowd Control & Disguises:** Polymorph, Noggenfogger Elixir (Skeleton), Savory Deviate Delight, Furbolg Form, Orb of Deception, and costumes.
* **Update-Safe Media Folder:** Loads user images from `Interface\LuckyPortraits\` (outside `Interface\AddOns\`) with subfolder support and a click-to-copy folder path box in the UI footer, so CurseForge updates never wipe custom artwork.
* **Combat-Safe Draggable Level Circle:** Toggle a glowing drag handle directly over your level badge (`/lp drag`) or fine-tune X/Y coordinates in the UI. Anchor updates defer cleanly during combat lockdown and restore automatically after vehicle transitions.
* **Multi-Flavor Compatibility:** Built for Retail (Midnight 12.1 secret-value safe), WoW Forever, MoP Classic, TBC Anniversary, and Classic Era from a single `.toc` and Lua file.
* **Account-Wide Profiles & Import/Export:** Automatic per-character profiles with New, Clone, Copy, Rename, and Delete controls, plus portable `LP1;` export/import strings that preserve all per-image framing.
* **Draggable Minimap Icon & In-Game Guide:** Left-click to open Setup, right-click to toggle ON/OFF, or hide the icon anytime. Includes a scrollable multi-flavor **? Help** guide.
* **Clean First Install:** Defaults cleanly to Blizzard's 3D portrait and `0, 0` level offset until you assign your own artwork.

## Directory Reference (All WoW Flavors)

Each World of Warcraft client uses its own flavor folder inside your `World of Warcraft` install directory:

| WoW Version | Addon Install Folder | Update-Safe Custom Images Folder |
|---|---|---|
| **Retail (Midnight)** | `World of Warcraft/_retail_/Interface/AddOns/LuckyPortraits/` | `World of Warcraft/_retail_/Interface/LuckyPortraits/` |
| **WoW Forever** | `World of Warcraft/_forever_/Interface/AddOns/LuckyPortraits/` | `World of Warcraft/_forever_/Interface/LuckyPortraits/` |
| **MoP Classic** | `World of Warcraft/_classic_/Interface/AddOns/LuckyPortraits/` | `World of Warcraft/_classic_/Interface/LuckyPortraits/` |
| **TBC Anniversary** | `World of Warcraft/_anniversary_/Interface/AddOns/LuckyPortraits/` | `World of Warcraft/_anniversary_/Interface/LuckyPortraits/` |
| **Classic Era** | `World of Warcraft/_classic_era_/Interface/AddOns/LuckyPortraits/` | `World of Warcraft/_classic_era_/Interface/LuckyPortraits/` |

## Installation

### Via CurseForge
Open the CurseForge App, select your WoW flavor, search for **Lucky Portraits**, and click **Install**.

### Manual Installation
1. Download the latest release `.zip` (or clone this repository).
2. Place the `LuckyPortraits` folder inside the `Interface/AddOns/` directory for the WoW version you play (see the Directory Reference table above).
3. Confirm `LuckyPortraits.toc`, `LuckyPortraits.lua`, and `icon.png` sit directly inside `Interface/AddOns/LuckyPortraits/` (not nested inside an extra subfolder).
4. Launch World of Warcraft and enable **Lucky Portraits** in the AddOns list.

## Adding Custom Images

1. Create a folder named **`LuckyPortraits`** directly inside your WoW version's `Interface` directory—right next to `AddOns`, **not** inside it (see the **Update-Safe Custom Images Folder** column above).
   * *CurseForge App shortcut:* Select your WoW flavor in the CurseForge App, right-click **Lucky Portraits** -> **Open Folder**, click **Interface** in your file manager's address bar to go up two levels, and create the `LuckyPortraits` folder beside `AddOns`.
2. Prepare your image files to match WoW's texture rules:
   * **Dimensions:** Square power-of-two pixels (**`256x256`** or **`512x512`**). Other dimensions render as a solid green circle.
   * **Formats:** `.png`, `.tga`, `.jpg`, or `.blp`. Subfolders are supported (for example, `druid\cat.png`).
   * **Framing:** Keep the subject reasonably centered for the circular portrait mask.
3. **Fully close and relaunch WoW** after adding brand-new image files (`/reload` picks up settings changes, but WoW only indexes new texture files on client startup).
4. In-game, open **`/lp`**, click **Default Portrait** (or any state) on the left, select **Custom Image** on the right, enter your filename (e.g. `portrait.png`), click **Apply**, and adjust **Zoom / Pan X / Pan Y**.

## Slash Commands

| Command | Description |
|---|---|
| `/lp` or `/luckyportraits` | Open or close the Setup window |
| `/lp toggle` (`on` / `off`) | Enable or disable custom portraits |
| `/lp minimap` | Show or hide the draggable minimap button |
| `/lp drag` | Unlock or lock dragging the level circle |
| `/lp X Y` | Set level circle offset manually (e.g. `/lp -20 20`) |
| `/lp profiles` | Open the Profile Manager |
| `/lp profile Name` | Switch active character to a saved profile |
| `/lp export` / `/lp import` | Open the Import / Export window |
| `/lp status` | Print active profile, detected states, and winning portrait |
| `/lp reset` | Recenter the Setup window |
| `/lp guide` / `/lphelp` | Open the scrollable Help window or print chat quick-start |
| `/lp globalreset confirm` | Wipe all saved profiles and restore factory defaults |

## Repository Structure

```text
LuckyPortraits/
├── LuckyPortraits.toc
├── LuckyPortraits.lua
├── icon.png
├── README.md
└── LICENSE
```

## Troubleshooting

* **Solid green circle instead of your image:** Verify that (1) the file is inside your client's `Interface\LuckyPortraits\` folder (not `Interface\AddOns\LuckyPortraits\`), (2) you placed it under the right flavor folder (`_retail_`, `_forever_`, `_classic_`, `_anniversary_`, or `_classic_era_`), (3) the filename and extension match exactly, (4) the image is `256x256` or `512x512`, and (5) you fully restarted WoW after adding the file.
* **State portrait didn't trigger:** Confirm **Custom Portrait: ON** is enabled, then run `/lp status` to inspect active states and priority order.
* **Custom unit frames:** Targets Blizzard's default `PlayerFrame`. Unit frame addons that replace and hide `PlayerFrame` are not hooked.

## License

Copyright (c) 2026 LittleLuckyPup. Licensed under the [MIT License](LICENSE).