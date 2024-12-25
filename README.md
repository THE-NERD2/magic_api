# magic_api
An API for adding magic powers in Minetest

### A minimal example:
```lua
magic_api.register_power("mymod:magic_power", {
    description = "My Magic Power",
    image = "symbol.png",
    on_activate = function(player)
        minetest.chat_send_player(player:get_player_name(), "Activated!")
    end,
    on_deactivate = function(player)
        minetest.chat_send_player(player:get_player_name(), "Deactivated.")
    end
})
```

#### Notes:
- The `description` field is not currently implemented. In the future it will be, so I recommend setting it.
- The `image` field should be a 64x64 symbol representing the magic power.

## License information
- **Code**: Licensed under [GNU GPLv3](LICENSE)
- **Art**: Licensed under [CC0 1.0 Universal License](LICENSE_CC0)
