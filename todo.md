- add restocking fuel and torches
- Add multiple fuel items for treeFarm (sticks)
- Make dumpGoods command
- add compressing deepslate and other common blocks into their x1/x2/x9 forms
    - have to have crafty turtle?
- see if we can collect xp

- 3rd tab for outgoing messages
    - send warning message to monitor main computer if turtle in one place for too long
    (and not treeFarmStart)
- should all software have a "listen for updates" loop?
    - Respond to ping with coordinates
    - On startup open second tab to listen for commands
        - Can we stop programs in other tabs?
            - Switch tab and exit?
            - need restore state for this to work
    - update (any) programs wirelessly
        - msg is program src path|target path
        - for libraries issue multiple update commands (or do updateAll) then restart

- Make function to store item in inventory first look for existing to stack
- Storage dumping coordination between tunnel bots
    - just claim a different storage x/y/z?
    - have turtles turn/search around until they find storage to not assume it's on the right
        - maybe just peripheral.find("inventory") -- or "minecraft:chest"
- Make a shutdown and save last command to resume program
    - Storage command to file first then diff coordinates for tunnel?
    - when starting tunnel, save length/params to saveData.cfg then on startup calculate current offset and resume
- Change treeFarm to try to refuel if out of fuel
- Tunnel
    - Expand to keep doing down further rows
    - Expand to not need to input placeTorches or not
    - When in same place for a long time, send message
- Make storeGoods avoid torches by offset calculation
    - Have all turtles store in same storage (different parts)
    - Look for perpipheral on all sides with storage size
- Make navigateToPoint try other axes if one fails/pathfind?
- Monitor
    - Make monitor scrollable
- make common.log Tee to logfile as well as printing to console
    - print date before all other messages? how to tell/initialize?
    - print(os.date("%m-%d^%H:%M:%S") .. "|" .. log_level:upper() .. "|" .. msg)
    - print(os.date("%H:%M:%S") .. "|" .. log_level:upper() .. "|" .. msg)
 - Fix writing config in alphabetical order
 - Update startup programs to take label into account?


# Projects
- Mob farms with spawners
 - Zombie
 - Spider
 - Creeper
 - Cow
 - Wither?
 - End Dragon?
- More power production
- More AE drives

 upsert setStorageLocation.lua commands/setStorageLocation.lua