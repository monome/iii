![](images/iii.jpg)

# iii

_note: This documentation is transitional as we work this all out. It's going to change._

An evolution of capabilities for monome grids, where an interactive scripting environment runs on the device itself.

- scripting is in Lua (which is familiar to [norns](https://monome.org/docs/norns) and [crow](https://monome.org/docs/crow))
- scripts can be uploaded and stored, to be executed on startup
- in addition to USB-TTY access to the scripting REPL, the device enumerates as USB-MIDI and provides scripting control over all MIDI communication
- Lua libraries are provided for time-based operations (metros, measurement) and writing arbitrary data to the internal flash (ie: presets or stored sequences)

## why do this?

The grid was originally conceived of as "doing nothing by itself" without being connected to a computer running a program. Now, the tiny computer inside the grid (RP2040) is capable enough of doing some interesting things. We're hoping this means in some cases simply requiring less complexity (as in, a specialized eurorack module or DAW plugin or tricky command line framework). It also provides the possibility to connect to less-general-purpose computers (like phones) who prefer MIDI.

That said! The original method of interfacing via norns or serialosc (and any of the [various languages and environments](https://monome.org/docs/grid/grid-computer/)) is a fundamentally excellent approach. iii fills a small gap.

The new firmware is capable of toggling between iii and monome/serial modes.

## why NOT do this

This is alpha software and such:

- there are bugs, almost certainly
- there are limitations we know about
- there are limitations we haven't yet identified
- initial documentation and examples are sparse

Furthermore we're not looking at this (yet) as part of the product: as such it has no promised functionality, a warranty, or a timeline to become official.

Practically speaking: the grid is a very constrained device when it comes to user interface. In a typical norns script or Max patch, there is helpful text and interface details that assist with the navigation of a blank grid. An iii script running on the device itself will require some clever design to accommodate the minimal interface.

_note: we're working on extending `diii` (the text interface) to include some amount of interface display and OSC exchange, which may serve some of these needs._

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

To go back to the original firmware, see [these instructions](https://monome.org/docs/grid/firmware/).

## modes

The "mode" is indicated by the startup light pattern.

- particles: this is standard monome/serial mode, compatible with norns, serialosc, ansible, etc.
- plasma: iii mode with a blank script. Note that if a script is present in flash, the plasma will not be shown as the script will launch immediately.

To change the mode, hold down key 0,0 (top left) while powering up the device. If a script is currently stored (or locking up the device) holding the 'change mode' key while booting will erase the script and start iii clean. If the 'change mode' key is held while booting with a blank script, it will toggle into monome/serial mode.

## diii

A terminal text interface for iii devices, based on [druid](https://monome.org/docs/crow/druid/). Send commands, get text feedback, and upload scripts. See the source [here](https://github.com/monome/diii).

### install

Requires `python` and is installable via `pip`:

```
sudo pip3 install monome-diii
```

(For extended install instructions see [druid's install guide](https://monome.org/docs/crow/druid/#install-druid) and remember to replace `monome-druid` with `monome-diii`).

### run

**_ALERT_ - things get really weird/broken when serialosc (the service / daemon) and `diii` are running at the same time, or when multiple copies of `diii` are running. Be aware!**

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
-- callbacks
grid(x,y,z)
midi_rx(ch,status,data1,data2)
metro(index,stage)

-- functions
grid_led_all(z)
grid_led(x,y,z)
grid_refresh()
midi_note_on(note,vel,ch)
midi_note_off(note,vel,ch)
midi_cc(cc,val,ch)
midi_tx(ch,status,data1,data2)
metro_set(index,time,stages)
metro_stop(index)
flash_read(index)
flash_write(index,string)
flash_clear(index)

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

`grid_led_all` and `grid_led` queue LED state changes which will be seen with the next `grid_refresh`. All 1-indexed.

### midi

`midi_rx` is the callback for raw bytes sent to the USB-MIDI port. Note that the first byte has the channel and status separated out in advance. Maybe this is weird and we'll change it. We will also add some message type lookups similar to norns.

`midi_tx` sends bytes over USB-MIDI. `midi_note_on`, `midi_note_off`, and `midi_cc` are helper functions so you don't need to remember the MIDI protocol. We'll add more of these helpers for other MIDI messages.

### metro

`metro(index,stage)` is the one callback for timed metronome objects. Right now the system supports 8 metros (we need to stress-test stability). Separate actions should happen per index, ie:

```
function metro(index,stage)
  if(index==1) then print("hi")
  else print("bye") end
end
```

Set and start a metro with `metro_set(index, time, stages)`.

- if `stages` is omitted or set to -1 the metro will repeat indefinitely
- if `time` is set to 0 the timer will be stopped (if running)

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

TODO: we need to add a table serializer. Because flash is just blocks of bytes (text), ie:

```
x = {20,22,26,29}
preset = table_serialize(x) -- preset now is the string "{20,22,26,29}" 
flash_write(0,preset)
(...)
x = dostring(flash_read(0)) -- recall a preset
```

### utils

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


## TODO

- grid id and size query
- midi helpers
  - send
  - receive
  - clock division
- table serializer ie http://lua-users.org/wiki/TableSerialization


## contributing

Small Lua tests and docs fixes welcome. Also suggestions for inclusion in the core scripting library (which is compiled into the firmware).

Discussion happens at the [repository](https://github.com/monome/iii/discussions).

_note: this repository is not for the firmware itself, which we have not yet determined how / if to license._
