![](images/iii.jpg)

# iii

_note: we're approaching version 1.0.0. some features may change before then!_

An evolution of capabilities for monome grids, where an interactive scripting environment runs on the device itself.

- scripting is in Lua (which is familiar to [norns](https://monome.org/docs/norns) and [crow](https://monome.org/docs/crow))
- scripts can be uploaded and stored, to be executed on startup
- in addition to USB-TTY access to the scripting REPL, the device enumerates as USB-MIDI and provides scripting control over all MIDI communication
- Lua libraries are provided for time-based operations (metros, measurement) and writing arbitrary data to the internal flash (ie: presets or stored sequences)

## why do this?

The grid was originally conceived of as "doing nothing by itself" without being connected to a computer running a program. Now, the tiny computer inside the grid (RP2040) is capable enough of doing some interesting things. We're hoping this means in some cases simply requiring less complexity (as in, a specialized eurorack module or DAW plugin or tricky command line framework). It also provides the possibility to connect to less-general-purpose computers (like phones) who prefer MIDI.

That said, the original method of interfacing via norns or serialosc (and any of the [various languages and environments](https://monome.org/docs/grid/grid-computer/)) is a fundamentally excellent approach. iii fills a small gap.

The new firmware is capable of toggling between iii and monome/serial modes.

## compatibility

[editions](https://monome.org/docs/grid/editions/)

- yes: 2022 and later grids (includes grids one and zero)
- no: 2020-2021 grids use different microcontroller, hence cannot use this firmware. (they are, however, mechanically compatible so we are considering a PCB upgrade. TBA.)
- no: all other grids use an FTDI USB Serial chip which means they can't do USB-MIDI. 

## firmwares

- Download the [most recent firmware for your specific device](https://github.com/monome/iii/releases) (Note that grids from 2022 have a different LED driver and hence require a different firmware. Identify the PCB revision by checking the date on the corner).
- Remove the bottom screws.
- Locate the golden pushbutton near the USB port. Hold it down while connecting the grid to a computer. This will start the device in bootloader mode.
- A USB drive will enumerate. Download the appropriate firmware listed below and copy the file to this drive. The drive will unmount immediately upon copying the file (on macOS this may cause a benign alert).
- Disconnect and put the screws back on (make sure to place the spacers first).

For firmware _updates_ you can use the `diii` command `^^b` to reboot the device into bootloader mode without opening the unit again.

## undo

In theory the monome/serial compatibility layer is functionally identical to the previous firmware but even so, to go back to the original firmware see [these instructions](https://monome.org/docs/grid/firmware/).

## modes

The "mode" is indicated by the startup light pattern.

- particles: this is standard monome/serial mode, compatible with norns, serialosc, ansible, etc.
- plasma: iii mode with a blank script.
- something else: previously uploaded iii script.

To change the mode, hold down key 1,1 (top left) while powering up the device.

To force-clear a script, switch _into_ iii mode while holding down the key for two full seconds. (This may be helpful for debugging a locked-up script).

## diii

A terminal text interface for iii devices, based on [druid](https://monome.org/docs/crow/druid/). Send commands, get text feedback, and upload scripts. See the source [here](https://github.com/monome/diii).

### install

Requires `python` and is installable via `pip`:

```
sudo pip3 install monome-diii
```

(For extended install instructions see [druid's install guide](https://monome.org/docs/crow/druid/#install-druid) and remember to replace `monome-druid` with `monome-diii`).

### run

For ease of managing scripts, navigate to the folder with your iii scripts ie:

```
cd ~/iii
```

Type `diii` in a terminal.

If things are working, it will report your device connected.  
A few quick commands:

```
^^p         print script
^^c         clear script
^^z         reboot script
^^r         reboot device
^^b         reboot into bootloader mode
```

To upload a script:

```
u step.lua
```

To re-upload the same script, you can just execute `u`.

All other commands will be passed to the device's Lua environment and any results will be printed.

To quit, execute `q` or CTRL-C.


## writing scripts

Note that there is no `init()` or similar. The script is simply run from the start to the end. You'll need to design/plan for whatever initialization you need.

## Lua library

`help()` will display a built-in quick reference which is stored on the device itself (and _should_ match capabilities and syntax).

```
-- grid
(event) grid(x,y,z)
grid_led_all(z)
grid_led(x,y,z)
grid_led_rel(x,y,z,zmin,zmax)
grid_led_get(x,y)
grid_refresh()
grid_size_x()
grid_size_y()

-- arc
(event) arc(n,d)
(event) arc_key(z)
arc_led(x,y,z)
arc_led_rel(x,y,z,zmin,zmax) -- adds z to current value, zmin/zmax optional
arc_led_all(x,z)
arc_refresh()

-- midi
(event) midi_rx(ch,status,data1,data2)
midi_note_on(note,vel,ch)
midi_note_off(note,vel,ch)
midi_cc(cc,val,ch)
midi_tx(ch,status,data1,data2)

-- metro
id = metro.new(callback, time_ms, count_optional)
metro.stop(id)
-- slew
id = slew.new(callback, start_val, end_val, time_ms, quant)
slew.stop(id)

-- pset
table = pset_read(index)
pset_write(index, table)

-- utils
dostring()
get_time()
ps(formatted_string,...)
pt(table_to_print)
clamp(n,min,max)
round(number,quant)
linlin(slo,shi,dlo,dhi,f)
wrap(n,min,max)
```

### grid

```
function grid(x,y,z) -- callback for grid keypresses. example to print key data:
  ps("grid %d %d %d",x,y,z)
end
```

**LEDs**

Drawing queues LED state changes which will be seen with the next `grid_refresh()`. Coordinates are all 1-indexed (meaning `(1,1)` is the top-left corner):

- `grid_led_all(z)`: set all LEDs to `z`
- `grid_led(x,y,z)`: set the LED at `(x, y)` to `z`
- `grid_led_rel(x,y,z,zmin,zmax)`: move relative to the last LED command

Additionally, `grid_led_get(x,y)` returns the level of the LED at `(x,y)`.

### midi

`midi_rx` is the callback for raw bytes sent to the USB-MIDI port. Note that the first byte has the channel and status separated out in advance. Maybe this is weird and we'll change it. We will also add some message type lookups similar to norns.

`midi_tx` sends bytes over USB-MIDI. `midi_note_on`, `midi_note_off`, and `midi_cc` are helper functions so you don't need to remember the MIDI protocol. We'll add more of these helpers for other MIDI messages.

### metro

The system supports fifteen timed metronome objects.

`id = metro.new(callback, time_ms, count_optional)`

- `id`: an alias for our metronome
- `callback`: a function called on every metronome tick, passing the current stage with each execution
- `time_ms`: the interval (in milliseconds) to execute each tick
- `count`: (optional) the number of ticks to execute
  - if `count` is omitted or set to `-1`, the metro will repeat indefinitely

For example:

```lua
example_metro = metro.new(
  function(stage)
    print(stage)
  end,
  1000, -- interval of 1000ms
  2 -- execute the callback twice
)
print(example_metro)
```

Running the code above will result in:

```
1
2
```

Note that when a metro is created, it is automatically started.

Stop a running metro with `metro.stop(id)`.

### slew

Use `slew` to smoothly count between two values over a specified time.

`id = slew.new(callback, start_val, end_val, time_ms, quant)`

- `id`: an alias for our slew
- `callback`: a function called on every increment, passing the current value with each execution
- `start_val`: our starting value
- `end_val`: our destination value
- `time_ms`: how many milliseconds the journey from our starting value to the destination value will take
- `quant`: (optional) the granularity between each interim value
  - if `quant` is omitted, values will change by `1`

For backwards movement, make `start_val` greater than `end_val`.

Stop a running slew with `slew.stop(id)`.  
Stop all running slews with `slew.stopall()`.

See [slew.lua](https://github.com/monome/iii/blob/250201/slew.lua) for an example.

### flash

4k sized blocks can be read, written, and cleared. Each block is referenced with an index. We haven't defined an upper limit as the user flash occupies the end of the memory map. (We'll clarify this later).

The flash can be used arbitrarily, though we expect it to be most useful for presets or similar.

```
cmd = "print('hello world i am in the flash!')"
flash_write(0,cmd) -- this will now survive power cycling
(...)
cmd = flash_read(0)
dostring(cmd) -- prints the message!
```

### presets

Scripts can store and recall tables of data into/from the RP2040's flash storage, using a simple 'preset' mechanism:

- `pset_write(n,table)`: writes `table` to flash position `n`
- `pset_read(n)`: returns the table stored at flash position `n`

#### as of release `250201`

The `pset` functions need a bit more design work -- these slots have no awareness of which script wrote them or if the tables will be valid for the current script.

Each flash slot (there are 256 of them) can be cleared with `flash_clear(id)`.

To clear every flash slot, run this command:

```lua
for i=1,256 do flash_clear(i) end
```

### utils

`device_id()` returns the string name of the connected device.

`dostring(cmd)` executes the string cmd. *Be careful.*

`get_time()` returns time since boot in milliseconds. Helpful for measuring intervals.

`ps(formatted_string,...)` is a helper to give `printf` capabilities, For example:

```
ps("i am %s and i like the number %d", "awake", 3) -- "i am awake and i like the number 3"
```

`pt(table)` attempts to print a table nicely.

`clamp(n,min,max)` clamps value `n` between a `min` and `max`.

`round(number,quant)` rounds to a multiple of a `number` with `quant` precision.

`linlin(slo,shi,dlo,dhi,f)` linearly maps value `f` from one range to another range.

`wrap(n,min,max)` wraps integer `n` to a positive `min`/`max` range.

## notes

- Lua is 1-indexed, so grid coordinates start at 1,1, and metro indices also start at 1.
- Script size is currently limited to 32k. (This could change if needed).

## TODO

- midi helpers
  - send
  - receive
  - clock division

## contributing

Small Lua tests and docs fixes welcome. Also suggestions for inclusion in the core scripting library (which is compiled into the firmware).

Discussion happens at the [repository](https://github.com/monome/iii/discussions).

_note: this repository is not for the firmware itself, which we have not yet determined the license._
