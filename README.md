![Logo](https://content.luanti.org/uploads/e73a7f4555.png)

*(Logo by Zion8992)*

# Whitelist Live Mod for Minetest

**Version:** 0.0.0
**Author:** Zion

A live-reload server whitelist mod for Minetest. Automatically prevents unlisted players from joining and provides commands for managing the whitelist in-game. Works in sandboxed environments like Luanti.

---

## Features

* Enforces a **per-world whitelist**.
* Customizable **file name and delay**.
* Automatically **auto-whitelists singleplayer**.
* Provides **live reload** of `whitelist.txt` when the file changes.
* Commands to manage the whitelist in-game:

  * `/whitelist add <name>` — Add a player to the whitelist.
  * `/whitelist remove <name>` — Remove a player from the whitelist.
  * `/whitelist list` — Show all whitelisted players.
  * `/whitelist reload` — Reload the whitelist from `whitelist.txt`.
  * `/whitelist enable` — Enable the whitelist.
  * `/whitelist disable` — Disable the whitelist.
  * `/whitelist status` — Show current whitelist status.
* Supports **bypass privileges**: players with `whitelist_bypass` can join even if not on the whitelist.
* Supports **admin privileges**: `whitelist_admin` for managing the whitelist.

---

## Installation

1. Copy the `ct_whitelist` folder into your Minetest `mods` directory.
2. Enable the mod in your world:

   * Edit `world.mt`:

     ```
     load_mod_whitelist_live = true
     ```
   * Or enable via the in-game mod UI.
   
3. The whitelist file is created automatically in the world folder:

```
<world folder>/whitelist.txt
```

4. Edit `whitelist.txt` to add one player per line. Lines starting with `#` are comments. File Name depends on settings you've set up.
   Example:

   ```
   # Whitelisted players
   zion
   sfan5
   ```

   Changes are automatically reloaded every ~5 seconds.
   (It depends on settings you've set up too)

---

## Usage

* **Auto-whitelist**: The singleplayer is automatically added to the whitelist.
* **Commands**: Only players with `whitelist_admin` can manage the whitelist.
* **Live reload**: Editing `whitelist.txt` triggers live reload; no server restart needed.
* **Bypass privilege**: Grant `whitelist_bypass` to trusted players to skip whitelist checks.
* **Checking status**: `/whitelist status` shows if the whitelist is enabled and the number of entries.
* **Customizable**: Can be customized through settings.

---

## Privileges

* `whitelist_admin` — Can manage the whitelist using `/whitelist`.
* `whitelist_bypass` — Bypass the whitelist entirely.

---

## Notes

* The whitelist file is **per world**, so each world can have its own whitelist.
* The mod also stores the whitelist in persistent mod storage, so edits in-game or via commands are saved even if `whitelist.txt` is missing.
* Works safely in **sandboxed environments** like Luanti.

---

