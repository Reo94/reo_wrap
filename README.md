# REO WRAP v1.0.0

A roleplay-focused WRAP restraint system for FiveM by **REO Development**.

## Dependencies
- qbx_core
- ox_lib
- ox_inventory
- ox_target

## Installation
1. Put `reo_wrap` in your resources folder.
2. Add the inventory item below to `ox_inventory/data/items.lua`.
3. Ensure dependencies start first.
4. Add `ensure reo_wrap`.
5. Restart the server.

## REQUIRED ox_inventory item
Add this inside the main item table, before its final closing brace:

```lua
['wrap_restraint'] = {
    label = 'WRAP Restraint',
    weight = 2500,
    stack = true,
    close = true,
    description = 'A full-body restraint system used to secure combative subjects.'
},
```

The internal item name must match `Config.WrapItem = 'wrap_restraint'`.

## Features
- Server-authoritative WRAP state
- Job authorization
- Inventory validation/removal/return
- Cuff/incapacitated requirement
- ox_target interactions
- ox_lib progress/notifications
- Restrained animation and control lockouts
- Vehicle placement/removal
- State-bag synchronization
- Development commands and cleanup

## Cuff / Incapacitated Integration

REO WRAP requires the target player to be cuffed or incapacitated before the WRAP restraint can be applied.

By default, REO WRAP checks the following common cuff state-bag keys:

```lua
Config.CuffedStateKeys = {
    'isCuffed',
    'handcuffed',
    'cuffed'
}
```

For incapacitated players, REO WRAP checks:

```lua
Config.IncapacitatedStateKeys = {
    'isDead',
    'dead',
    'laststand',
    'isLaststand',
    'downed'
}
```

Your police, handcuff, or medical resource may use different state keys. These values can be changed in `config.lua` to match your server.

### Troubleshooting: Player Is Cuffed but WRAP Will Not Apply

If the player is visibly cuffed but REO WRAP displays:

> **The person must be cuffed or incapacitated first.**

this usually means your handcuff resource uses a different player state than the states included with REO WRAP by default.

#### Step 1 — Identify Your Cuff State

Check the police or handcuff resource used by your server and determine what state is set when a player becomes cuffed.

For example, your resource may use:

```lua
LocalPlayer.state.isCuffed
```

or another custom state name.

#### Step 2 — Add the State to REO WRAP

Open:

```text
reo_wrap/config.lua
```

Find:

```lua
Config.CuffedStateKeys = {
    'isCuffed',
    'handcuffed',
    'cuffed'
}
```

Add the state used by your server. For example:

```lua
Config.CuffedStateKeys = {
    'isCuffed',
    'handcuffed',
    'cuffed',
    'yourCuffStateHere'
}
```

Restart `reo_wrap` and test the restraint again.

#### Step 3 — Development Testing

If you need to determine whether the cuff-state check is causing the problem, temporarily change:

```lua
Config.RequireRestrainedTarget = true
```

to:

```lua
Config.RequireRestrainedTarget = false
```

This disables the cuff/incapacitated requirement and is intended for troubleshooting only.

If the WRAP works after disabling this requirement, the issue is most likely that your server's cuff state has not been added to `Config.CuffedStateKeys`.

Once testing is complete, change it back to:

```lua
Config.RequireRestrainedTarget = true
```

#### Still Having Problems?

If your restraint resource does not expose cuff status through a replicated player state bag, additional integration may be required.

In that situation, REO WRAP may need to be configured to use an export, event, or another method provided by your police or handcuff resource.

## Usage
Normal use is through ox_target. Development commands are:
```text
/wrap [server ID]
/unwrap [server ID]
/wrapstatus
```
Set `Config.EnableDevCommands = false` for production.

## V1 visual limitation
GTA V has no native WRAP restraint model. V1 implements the functional restraint system with an animation. A custom streamed model/prop can be integrated later.

## Support
REO Development project. Server-specific integrations may require configuration changes.
