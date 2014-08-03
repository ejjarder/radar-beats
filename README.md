RadarBeats.pde
==============

For completion of requirements for Creative Programming for Digital
Media & Mobile Apps at Coursera.

This is my implementation of a music machine, where the notes are shown
around a circle instead of along bars. An indicator spins around the
circle, and will play notes along the arc it passes through.

To add a note, the user can click on the various empty areas on the
circle. The notes near the center of the circle have a low pitch,
and the pitch increases as you go away from the center. 

The user can then use the BPM slider to change the playback
speed. The user can also change the key of the playback through a
slider as well.

Two more sliders are used to change the waveform input. The waveform is
a simple sinusoid based wave, whose frequency can be changed through
the sliders. The two sliders control one waveform each. The two
waveforms are then added and normalized so the values will be between
-1 and 1. 
 
Two buttons are available: One to input random notes, and another to
clear the sheet.

The metronome sound was taken from here:
  - https://www.freesound.org/people/TicTacShutUp/sounds/406/

The code is available at:
  - https://github.com/ejjarder/radar-beats
