tablespoon-fun
==============

Fun scripts from tablespoon

* `adblocker.sh` - blocks ads and malware at router-level (OpenWrt only)
  * Documentation can be found here: https://www.reddit.com/r/technology/comments/3iy9d2/fcc_rules_block_use_of_open_source/cul12pk
* `auto-blockip` - squashes breakin attempts automatically
* `awesome-background-changer` - randomly select a new wallpaper every hour (gnome 2 only!)
* `bt-auto-lock` - lock/unlock gnome 2 session based on cell phone proximity
  * you will need to create ~/lib/bluetooth-phone and add "MAC=\<your phone's bluetooth mac address\>" to it for this to work
* `cli-clock` - make a clock with ANSI art
  * --world : shows multiple clocks with timezone labels
  * --24hour : displays a 24 hour clock (this is the default)
  * --12hour : displays a 12 hour clock
  * This script can also be used to print strings. For a demonstration, try: ./cli-clock 'Hello, world!'
  * Because of tiny memory leaks in bash, this script will eventually (over the course of weeks/months) begin to lag a little bit. The python re-implementation below doesn't have as many features as this bash version, but it can run indefinitely without any slowdown. I submitted a bug report to the bash devs (https://lists.gnu.org/archive/html/bug-bash/2014-01/msg00012.html), but they didn't seem to think it was worth fixing.
* `cli-clock.py` - re-implementation of cli-clock using python. Prettier than the bash version, and unaffected by bash's tiny memory leaks. However, only provides basic clock functionality.
* `cpi` - bash parallel pi estimator
* `cpi.py` - python pi estimator (not parallel... my bash is stronger than my python)
* `last_n_minutes` - bash script to print the last N minutes of a standard linux log file
* `nvidia-update` - check for (and optionally download) a newer nvidia driver


