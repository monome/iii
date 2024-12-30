![](images/iii.jpg)

# iii

_note: this documentation is transitional as we work this all out. it's going to change._

an evolution of capabilities for monome grids, where an interactive scripting environment runs on the device itself.

- scripting is in lua (which is familiar to [norns](https://monome.org/docs/norns) and [crow](https://monome.org/docs/crow))
- scripts can be uploaded and stored, to be executed on startup
- in addition to usb-tty access to the scripting REPL, the device enumerates as usb-midi and provides scripting control over all midi communication
- lua libraries are provided for time-based operations (metros, measurement) and writing arbitrary data to the internal flash (think presets or stored sequences)

## why do this?

the grid was originally conceived of as "doing nothing by itself" without being connected to a computer running a program. now, the tiny computer inside the grid is capable enough of doing some interesting things. we're hoping this means in some cases simply requiring less complexity (as in, a specialized eurorack module or DAW plugin or tricky command line framework). it also provides the possibility to connect to less-general-purpose computers (like phones) who prefer midi.

that said! the original method of interfacing via norns or serialosc (and any of the [various languages and environments](https://monome.org/docs/grid/grid-computer/)) is a fundamentally excellent approach. iii fills a small gap.

the new firmware is capable of toggling between iii and monome/serial modes.

## why NOT do this

this is alpha software and such:

- there are bugs, almost certainly
- there are limitations we know about
- there are limitations we haven't yet identified
- initial documentation and examples are sparse

furthermore we're not looking at this (yet) as part of the product: as such it has no promised functionality, a warranty, or a timeline to become official.

practically speaking: the grid is a very constrained device when it comes to user interface. in a typical norns script or max for live patch there is helpful text and interface details that assist with the navigation of a blank grid. an iii script running on the device itself will require some clever design to accommodate the minimal interface. (note, we're working on extending `diii` (the text interface) to include some amount of interface display and OSC exchange, which may serve some of these needs.)

## compatibility

- yes: grids one and zero, 2022 and later
- no: 2020-2021 grids use different microcontroller, hence cannot use this firmware. (they are, however, mechanically compatible so we are considering a PCB upgrade. TBA.)
- no: all other grids. they use an FTDI usb-serial chip which means they can't do usb-midi 

## firmwares

- Download the [most recent firmware for your specific device](https://github.com/monome/iii/releases) (grids from 2022 have a different LED driver and hence require a different firmware. identify the PCB revision by checking the date on the corner).
- Remove the bottom screws.
- Locate the golden pushbutton near the USB port. Hold it down while connecting the grid to a computer.
- A USB drive will enumerate. Download the appropriate firmware listed below and copy the file to this drive. The drive will unmount immediately upon copying the file (on macOS this may cause a benign alert).
- Disconnect and put the screws back on (make sure to place the spacers first).

## undo

to go back to the original firmware, see [these instructions](https://monome.org/docs/grid/firmware/).

## modes

the "mode" is defined by the startup light pattern.

- particles: this is standard monome/serial mode, compatible with norns, serialosc, ansible, etc
- plasma: iii mode with a blank script. if a script is present in flash, the plasma will not be shown as the script will launch immediately.

to change the mode, hold down key 0,0 (top left) while powering up the device.

note: if a script is currently stored (or locking up the device) holding the key on boot will erase the script and start iii clean. if the key is held while powered with a blank script it will toggle into monome/serial mode.


## diii

a text interface for iii devices, based on [druid](https://monome.org/docs/crow/druid/).

send commands, get text feedback, and upload scripts.

### install

requires `python` and is installable via `pip` ie:

```
sudo pip3 install monome-diii
```


(for extended install instructions see [druid's install guide](https://monome.org/docs/crow/druid/#install-druid) and remember to replace `monome-druid` with `monome-diii`).

### run

_ALERT_ - things get really weird/broken when serialosc and `diii` run at once, or when multiple copies of `diii` are running. be aware!

for ease of managing scripts, navigate to the folder with your iii scripts ie:

```
cd ~/iii
```

type `diii` in a terminal.

if things are working, it will report your device connected. a few quick commands:

```
^^p         print script
^^c         clear script
^^z         reboot script
^^r         reboot device
```

to upload a script:

```
u step.lua
```

to re-upload the same script you can just enter `u`.

all other commands will be passed to the device's lua environment and results will be printed if there are any.

`q` or CTRL-C to quit.


## writing scripts

note, there is no `init()` or similar. the script is simply run from the start to the end. you'll need to design/plan for whatever initialization you need.

## lua library

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

-- print utils
ps(formatted_string,...)
pt(table_to_print)
```

### grid

```
function grid(x,y,z) -- callback for grid keypresses. example to print key data:
  ps("grid %d %d %d",x,y,z)
end
```

`grid_led_all` and `grid_led` queue LED state changes which will be seen with the next `grid_refresh`

### midi

`midi_rx` is the callback for raw bytes sent to the usb-midi port. note that the first byte has the channel and status separated out in advance. maybe this is weird and we'll change it. we will add some message type lookups similar to norns.

`midi_tx` sends bytes over usb-midi. `midi_note_on`, `midi_note_off`, and `midi_cc` are helper functions so you don't need to remember the midi protocol. we'll add more of these helpers for other midi messages.

### metro

`metro(index,stage)` is the one callback for timed metronome objects. right now the system supports 8 metros (we need to stress-test stability). separate actions should happen per index, ie:

```
function metro(index,stage)
  if(index==1) then print("hi")
  else print("bye") end
end
```

set and start a metro with `metro_set(index, time, stages)`.

- if `stages` is omitted or set to -1 the metro will repeat indefinitely.
- if `time` is set to 0 the timer will be stopped (if running)

### flash

4k sized blocks can be read, written, and cleared. each block is referenced with an index. we haven't defined an upper limit as the user flash occupies the end of the memory map. (we'll clarify this later).

the flash can be used arbitrarily, though we expect it to be most useful for presets or similar.

```
cmd = "print('hello world i am in the flash!')"
flash_write(0,cmd) -- this will now survive power cycling
(...)
cmd = flash_read(0)
dostring(cmd) -- prints the message!
```

TODO: we need to add a table serializer. because flash is just blocks of bytes (text). ie:

```
x = {20,22,26,29}
preset = table_serialize(x) -- preset now is the string "{20,22,26,29}" 
flash_write(0,preset)
(...)
x = dostring(flash_read(0)) -- recall a preset
```

### utils

`dostring(cmd)` executes the string cmd. be careful.

`ps(formatted_string,...)` is a helper to give `printf` capabilities, for example:

```
ps("i am %s and i like the number %d", "awake", 3) -- "i am awake and i like the number 3"
```

`pt(table)` attempts to print a table nicely.



## TODO

- grid id and size query
- midi helpers
  - send
  - receive
  - clock division
- table serializer ie http://lua-users.org/wiki/TableSerialization


## contributing

small lua tests and doc fixes welcome.

discussion happens at the [repository](https://github.com/monome/iii/discussions)

_note_ this repository is not for the firmware itself, which we have not yet determined how/if to license.
