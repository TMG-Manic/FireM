# 🌐 FiveM Master Gateway (BungeeCord-Style Bridge)

![FiveM](https://img.shields.io/badge/FiveM-Native-orange.svg)
![Node.js](https://img.shields.io/badge/Node.js-Gateway-green.svg)
![Redis](https://img.shields.io/badge/Redis-Global_State-red.svg)
![Lua](https://img.shields.io/badge/Lua-Bridge-blue.svg)

A robust, enterprise-grade routing architecture for FiveM. This project enables seamless virtual server instances (e.g., Roleplay and Minigames) on a single physical FXServer by bridging FiveM Routing Buckets with a Node.js Master Gateway and a Redis database.

Traditionally, expanding a FiveM community to include diverse game modes; like serious roleplay and casual minigames; meant forcing server owners to spin up entirely separate servers, fracturing their community across different IPs. This architecture was designed specifically to eliminate that barrier by keeping your entire playerbase unified under a single connection. By leveraging native routing buckets and a centralized Node.js gateway, server owners can now offer multiple distinct, fully isolated environments within one physical server. This ensures that your community remains cohesive and connected, entirely removing the need to segregate your players or manage multiple costly server hosts.

## A note from the creator
I am currently looking for servers to integrate this with. If you are a developer or server owner and want somebody to work alongside you with this kind of project, I would love to hear from you and have you in my DM's.

Discord: tmg_manic

## ✨ Features

*  Dynamic Virtual Server Switching:** Players can seamlessly transition between virtual servers (buckets) using the `/server [id]` command, a custom NUI Hub (`/hub`), or physical 3D portals in-game.
*  Secure Authentication:** Prevents direct connections using a one-time cryptographic token handshake between the game client and the Master Gateway.
*  Isolated Virtual Profiles:** Leverages `oxmysql` to save player coordinates and inventories specific to each virtual server (e.g., your RP inventory won't bleed into the Minigame hub).
*  Cross-Bucket Communication:** Global chat intercepts, Bungee-style `/msg` systems, and cross-server announcements via Redis Pub/Sub.
*  Party System:** Players can create parties, invite friends across different servers, and warp the entire party into the same virtual instance simultaneously.
*  Queue & State Management:** Tracks global player counts (`/glist`), locates specific players (`/find`), and strictly enforces server capacity limits.
*  Connection Watchdog:** Built-in Lua watchdog that polls the Gateway and triggers an emergency state-save if the network connection drops.
*  Dynamic Area Sharding (MMO-Style Instancing): Eliminate localized lag during massive server events without fracturing your community. When the Gateway detects an overcrowded area (like a massive car meet or gang turf war), it automatically splits the crowd into temporary, isolated routing buckets. Because players only render entities and other players that belong to their specific bucket, this drastically reduces client-side entity overload and server network pressure. Your players enjoy buttery-smooth FPS during 50+ player events, all while staying unified on a single server with a seamlessly bridged global chat.

## Work In Progress

* 64 Player Sharding in RP servers. This feature will allow big servers to accommodate 1000 players without dealing with imbalancing. This way in a 1000 player server, there will be 16 instances of players playing together. However, based on job roles, it will balance the players immediately. If a player is a police officer and there is another shard without one, the player will be prompted to join that instance. (Maybe a better menu will make this more accomodating)
* Auction House between shards. People can trade with the full 1000 player server.
* Add functionality with MongoDB.
* Create portals and small games for people waiting in the hub to join a 64 slot RP instance.

## 📋 Prerequisites

Before installing, ensure your environment meets the following requirements:
* **FiveM FXServer** (Latest Artifacts)
* **Node.js** (v16.x or higher)
* **Redis** (If hosting on Windows, running Redis inside **WSL** is highly recommended)
* **oxmysql** (FiveM resource for database management)

---

## 🚀 Installation & Setup

### 1. Redis Setup (Windows/WSL)
Redis: Redis does not have a native Windows port. Open PowerShell as Administrator and install the Windows Subsystem for Linux (WSL) by typing:
```text
wsl --install
```
Once installed and your PC reboots, open your new Ubuntu terminal and run:
```text
sudo apt update
sudo apt install redis-server
sudo service redis-server start
```
If you are running Redis on Windows via WSL, ensure your `redis.conf` allows external connections:
```text
sudo nano /etc/redis/redis.conf
```
Modify these two items here.

```text
bind 0.0.0.0
protected-mode no
```
*Note: Restart the Redis service after making these changes.*
```text
sudo service redis-server restart
```

### 2. Master Gateway Setup (Node.js)
1. Navigate to the `FireM` directory (Gateway).
2. Install the required dependencies:
   ```bash
   npm install express ioredis crypto
   ```
3. Update the Redis connection IP in `gateway.js`, `queue-manager.js`, `social-manager.js`, and `state-manager.js` to point to your Redis host.
4. Start the Gateway:
   ```bash
   node gateway.js
   ```

### 3. FiveM Bridge Setup (Lua)
1. Import `tables.sql` into your MySQL database to create the `bungee_virtual_profiles` table.
2. Place the `fivem-bungee-bridge` resource into your FiveM `resources` folder.
3. Edit `fivem-bungee-bridge/config.lua` to point `Config.GatewayURL` to your Node.js Gateway address (e.g., `http://127.0.0.1:3000` or your WSL IP).
4. Add `ensure fivem-bungee-bridge` to your `server.cfg`.

---

### 🌐 IP Configuration Guide

Depending on how your server infrastructure is set up (e.g., natively, using WSL, or on separate dedicated boxes), you will need to configure the IP addresses in two distinct areas:

#### 1. Redis Connection IPs (Node.js Files)
These files tell the Master Gateway how to connect to the Redis database. By default, they should point to `127.0.0.1` if Redis is hosted natively on the same machine as Node.js. If you are using WSL or an external Redis host, change this to the respective IP.
In WSL find your IP using this command:
```text
ip addr show eth0
```

Update the `host` parameter inside the `new Redis()` initialization in the following four files:
* `gateway.js`
* `queue-manager.js`
* `social-manager.js`
* `state-manager.js`

**Example:**
```javascript
const redis = new Redis({ host: 'YOUR_REDIS_IP', port: 6379 });
```

#### 2. Master Gateway API IPs (FiveM Lua Files)
These files tell the FiveM FXServer how to communicate with the Node.js Gateway API. If the Node.js server is running on the same machine as the FiveM server, leave this as `127.0.0.1`. If Node.js is hosted on a different machine (or crossing a WSL virtual adapter), change it to that machine's IP.

Update the URLs in these two files:

* **`fivem-bungee-bridge/config.lua`**
  Change the `Config.GatewayURL` variable:
  ```lua
  Config.GatewayURL = "http://YOUR_NODE_IP:3000"
  ```

* **`server.lua`** (Inside your core authentication resource)
  Change the `GATEWAY_URL` variable at the very top:
  ```lua
  local GATEWAY_URL = "http://YOUR_NODE_IP:3000/internal/validate_token"
  ```

## 💻 Commands

| Command | Description | Permission Level |
| :--- | :--- | :--- |
| `/server [id]` | Seamlessly transfers the player to the specified Virtual Server bucket. | Player |
| `/hub` | Opens the NUI Gateway Hub to visually select a server instance. | Player |
| `/msg [license] [msg]`| Sends a cross-server private message to another player. | Player |
| `/party [action]` | Party management (create, invite, accept, warp). | Player |
| `/glist` | Displays network-wide player counts per Virtual Server. | Admin/Console |
| `/find [license]` | Locates which Virtual Server a specific player is currently in. | Admin/Console |

## 🏗️ Architecture Blueprint

1. **The Client** attempts to connect and receives a cryptographic token.
2. **The FXServer** (`server.lua`) suspends the connection (deferrals) and asks the Node.js Gateway to validate the token.
3. **The Node.js Gateway** checks the Redis token cache, assigns the player a Routing Bucket based on capacity, and approves the connection.
4. **The FiveM Bridge** (`bridge.lua` & `database.lua`) intercepts bucket transfers, saves the old state, loads the new instance state, and securely transitions the player.

---

### 🛠️ How to Implement into Existing Frameworks (QBCore)

Because this Gateway utilizes native FiveM Routing Buckets, it is highly compatible with existing frameworks like QBCore. However, because players are sharing a single physical server, you must intercept how QBCore handles saving and loading player states to ensure their data stays isolated to the correct virtual instance.

Here is a step-by-step guide on bridging this Gateway with QBCore:

#### 1. Hooking into QBCore Inventories
By default, the `server/database.lua` file uses empty JSON brackets for the inventory placeholder. You must replace this with QBCore's native inventory export to ensure items don't bleed across instances.

**Example (QBCore Integration in `server/database.lua`):**
```lua
-- Inside SaveVirtualProfile()
local Player = QBCore.Functions.GetPlayer(source)
local inventoryData = json.encode(Player.PlayerData.items) 

-- Inside LoadVirtualProfile()
local pos = json.decode(data.position)
local inv = json.decode(data.inventory)

if pos then
    SetEntityCoords(GetPlayerPed(source), pos.x, pos.y, pos.z, false, false, false, false)
end

if inv then
    Player.Functions.SetInventory(inv) -- QBCore specific inventory set
end
```

#### 2. Delaying Framework Player Loads
QBCore triggers its main initialization events (like `QBCore:Server:PlayerLoaded`) the moment a player spawns. 

You should wrap or delay QBCore's spawn logic until **after** the Master Gateway assigns the Routing Bucket in `server/bridge.lua`. If QBCore spawns them *before* the Gateway routes them, the player might temporarily see entities from the wrong bucket.

#### 3. Disabling Conflicting Native Resources
To ensure the Bungee-style features work flawlessly, disable any duplicate features provided by QBCore or base FiveM:
*   **Chat Resources:** If you are using the Master Gateway's cross-server global chat relay, ensure you disable or modify `qb-chat` so messages aren't broadcast twice.
*   **Private Messaging:** Disable native `/msg`, `/r`, or `/reply` commands in QBCore so they don't override the Gateway's Redis-powered social manager.
*   **Hardcoded Routing Buckets:** Search QBCore and its associated scripts (like `qb-apartments` or `qb-houses`) for `SetPlayerRoutingBucket`. Because housing scripts use routing buckets for interiors, you will need to offset your Gateway's virtual server IDs (e.g., use Buckets 100+ for the Gateway) so they don't collide with QBCore's apartment interior buckets (usually 1-99).



---
*Built for the next generation of FiveM networks.*
