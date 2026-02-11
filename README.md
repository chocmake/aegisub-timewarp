## Aegisub Timewarp

Timewarp is an Aegisub plugin for batch adjustments of subtitle timing. Multiple subtitles can be selected and the timestamps between the first and last selection (A and B) automatically interpolated/stretched proportionally to match new timestamp values.

![Diagram](diagram.svg)

> In the diagram above the gray rectangles represent unselected subtitles and the green rectangles selected subtitles. The bright green lines represent the A and B start times. The new values have adjusted the timestamp offset and duration of the intermediate subtitles between the A and B selections.


## Use cases

Say you've already subtitled a video but then find out that the version of the video you were subtitling against ran at 30fps when it's meant to run at 29.97fps, causing a desync. Or maybe you want to speed up a video to play at double speed and you need to update the subtitles to match. This plugin simplifies this.

Timewarp can also be used as a more precise alternative to Aegisub's native Shift Times, for just the selected subtitles. Shift Times only supports centisecond resolution but Timewarp supports milliseconds (and centiseconds, depending on the fractional input).


## Installation

1. Open your Aegisub user directory, that contains the `automation` sub-directory.
1. Copy `timewarp.lua` to the `autoload` sub-directory within `automation`.
3. Restart Aegisub, or from the *Automation* menu select *Automation...>Rescan Autoload Dir*.


## Usage

**Video demo:**

https://github.com/user-attachments/assets/2d8b3304-aca5-4440-83f0-0608090e5f2d

### Syntax

Timestamps take for form of `[H]H:MM:SS[.frac]`.
> Eg:
> - `01:03:08.123` (milliseconds precision)
> - `1:03:08.12` (no leading hour zero, centiseconds precision)
> - `1:03:08` (no fractional seconds value)

### Interpolating between A-B points of multiple subtitles

1. Select two or more subtitles and from Aegisub's *Automation* menu select *Timewarp*.
2. In the *New Time A*/*New Time B* fields adjust the timestamps as wanted. These represent the start time of the first and last items in the selection, respectively.
3. Click *OK*.

If both A and B timestamps are changed then both subtitle A and B will have the offsets applied and any subtitles in-between A and B will be proportionally interpolated proportionally to fit between the new values.

Alternatively if for example only subtitle A's time is adjusted then every subtitle from and including subtitle A's start time up to but not including subtitle B's start time will be interpolated.

### Shifting the time of a single subtitle

1. Select a single subtitle and from Aegisub's *Automation* menu select *Timewarp*.
2. In the *New Time Shift* field change the timestamp to the new time you want the subtitle to begin.
3. Click *OK*.

This will offset that subtitle while preserving its duration.

### Shifting the time of multiple subtitles

1. Select two or more subtitles and from Aegisub's *Automation* menu select *Timewarp*.
2. In the *New Time A*/*New Time B* fields adjust both timestamps by the same amount backward/forward in time.
	> Eg: if sub A's time is `00:02:12.340` and B's `00:05:52.560` then to shift all the subtitles equally back by 2s they should become `00:02:10.340` and `00:02:50.340`, respectively.
3. Click *OK*.

Effectively like Shift Time but using absolute timestamps and only adjusting the selected subtitles.
