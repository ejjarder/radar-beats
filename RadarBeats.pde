/*************************************************************************
 * RadarBeats.pde
 *
 * Author: Eugene Jarder
 *
 * For completion of requirements for Creative Programming for Digital
 * Media & Mobile Apps at Coursera.
 *
 * This is my implementation of a music machine, where the notes are shown
 * around a circle instead of along bars. An indicator spins around the
 * circle, and will play notes along the arc it passes through.
 *
 * To add a note, the user can click on the various empty areas on the
 * circle. The notes near the center of the circle have a low pitch,
 * and the pitch increases as you go away from the center. 
 *
 * The user can then use the BPM slider to change the playback
 * speed. The user can also change the key of the playback through a
 * slider as well.
 *
 * Two more sliders are used to change the waveform input. The waveform is
 * a simple sinusoid based wave, whose frequency can be changed through
 * the sliders. The two sliders control one waveform each. The two
 * waveforms are then added and normalized so the values will be between
 * -1 and 1. 
 *  
 * Two buttons are available: One to input random notes, and another to
 * clear the sheet.
 *
 * The metronome sound was taken from here:
 *   - https://www.freesound.org/people/TicTacShutUp/sounds/406/
 *
 * The code is available at:
 *   - https://github.com/ejjarder/radar-beats
 *
 *************************************************************************/

// The notes to play for each bar.
private static final float[] OCTAVE = 
{
  261.62558f, // C4
  293.664764f, // D4
  329.627563f, // E4
  349.228241f, // F4
  391.995422f, // G4
  440.f,       // A4
  493.883301f // B4
};

// Theoretical frequency difference between a note and the half step above it.
private static final float NOTE_INTERVAL = pow(2, 1.0/12);

// Total number of beats per round
private static final int BEAT_COUNT = 16;

// Total number of notes on display
private static final int TOTAL_NOTES = OCTAVE.length * BEAT_COUNT;

// Screen dimensions
private static final int SCREEN_WIDTH = 640;
private static final int SCREEN_HEIGHT = 480;

// Radar location and dimensions
private static final int RADAR_CENTER_X = 400;
private static final int RADAR_CENTER_Y = SCREEN_HEIGHT / 2;
private static final int MIN_CIRCLE_RADIUS = 10;
private static final int MAX_CIRCLE_RADIUS = 230;

// Arc properties derived from the above values
private static final float ARC_WIDTH = TWO_PI / BEAT_COUNT;
private static final float ARC_HEIGHT =
    (MAX_CIRCLE_RADIUS - MIN_CIRCLE_RADIUS) / OCTAVE.length;

// Beat properties
private static final int FRAME_RATE = 30;
private static final int MIN_BPM = 60;
private static final int DEFAULT_BPM = 120;
private static final int MAX_BPM = 180;

// Key properties
private static final int DEFAULT_KEY = 0;
private static final int MIN_KEY = -3;
private static final int MAX_KEY = 8;
private static final int INVALID_KEY = -13;

// Frequency properties
private static final float DEFAULT_FREQUENCY = 1;
private static final float MIN_FREQUENCY = 0.1;
private static final float MAX_FREQUENCY = 5;

// Properties for randomization
private static final int MIN_RANDOM_NOTES = 10;
private static final int MAX_RANDOM_NOTES = 43;

// background color properties
private static final int BACKGROUND_COLOR = 76;
private static final int BEAT_BACKGROUND_COLOR = 86;

// Used to compute the angle to find which note has been toggled.
private static final PVector ZERO_VECTOR = new PVector(1, 0);

// length of the wavetable
private static final int WAVE_RESOLUTION = 514;

Maxim maxim; // Needed to load and play sounds

// Contains the frequency of each octave
WavetableSynth synths[] = new WavetableSynth[OCTAVE.length];

AudioPlayer metronome; // Metronome to help in the beat

int[] noteColors = new int[OCTAVE.length]; // The colors to use for each note

// The notes on the board
boolean notes[][] = new boolean[BEAT_COUNT][OCTAVE.length];

// The current frame of the program. Used to determine of a beat has been
// reached so a note will be played
int playHead = 0;

// Sliders to control the waveform.
Slider waveFrequency;
Slider waveFrequency2;

Slider bpmSlider; // Slider to control the beats per minute
Slider keySlider; // Slider to control the key of the playback

Button randomize; // Button to put random notes on the board
Button clear; // Button to clear the board

int bpm; // beats per minute
float bps; // beats per second
float framesPerBeat; // frames per beat
int maxFramesPerBeat; // total number of frames in the board
int currentKey = 0; // key of the playback

// Stores the current background color. Used to handle the beat flash.
int backgroundColor = BACKGROUND_COLOR;

/* setup()
 * Initialize the sketch
 *
 */
void setup()
{
  size(SCREEN_WIDTH, SCREEN_HEIGHT);
  maxim = new Maxim(this);
  metronome = maxim.loadFile("metronome.wav");
  metronome.setLooping(false);
  metronome.volume(1.0);
  frameRate(FRAME_RATE);
  
  strokeWeight(2);
  ellipseMode(RADIUS);
  
  initializeGUI();
  
  initializeBoard();
}

/* initializeBoard()
 * Initialize the notes, the beat and the waveform to use.
 *
 */
void initializeBoard()
{
  for (int octaveIndex = 0; octaveIndex < OCTAVE.length; ++octaveIndex)
  {
    synths[octaveIndex] = maxim.createWavetableSynth(WAVE_RESOLUTION);
    synths[octaveIndex].setFrequency(OCTAVE[octaveIndex]);
    noteColors[octaveIndex] =
        (int) map(octaveIndex, 0, OCTAVE.length, 0, 255);
  }
  
  updateBeatRate();
  
  updateWaveTable();
}

/* initializeGUI()
 * Initialize the sliders and buttons.
 *
 */
void initializeGUI()
{
  waveFrequency = new Slider("freq 1", 1, MIN_FREQUENCY, MAX_FREQUENCY,
                             10, 10, 38, 187, VERTICAL);
  waveFrequency2 = new Slider("freq 2", 1, MIN_FREQUENCY, MAX_FREQUENCY,
                              10, 207, 38, 187, VERTICAL);
  bpmSlider = new Slider("bpm", DEFAULT_BPM, MIN_BPM, MAX_BPM,
                         58, 10, 38, 187, VERTICAL);
  keySlider = new Slider("key", DEFAULT_KEY, MIN_KEY, MAX_KEY,
                         58, 207, 38, 187, VERTICAL);
  
  randomize = new Button("randomize", 10, 404, 73, 28);
  clear = new Button("clear", 10, 442, 73, 28); 
}

/* putRandomNotes()
 * Toggle random number of notes on the board
 *
 */
void putRandomNotes()
{
  for (int i = MIN_RANDOM_NOTES; i < MAX_RANDOM_NOTES; ++i)
  {
    int randomNote = (int) random(TOTAL_NOTES);
    
    int randomOctave = (int) randomNote / BEAT_COUNT;
    int randomBeat = randomNote % BEAT_COUNT;
    
    notes[randomBeat][randomOctave] = true;
  } 
}

/* clearNotes()
 * Clear the board.
 *
 */
void clearNotes()
{
  for (int beatIndex = 0; beatIndex < BEAT_COUNT; ++beatIndex)
  {
    for (int rIndex = OCTAVE.length - 1; rIndex >= 0; --rIndex)
    {
      notes[beatIndex][rIndex] = false;
    }
  }
}

/* updateWaveTable()
 * Update the wavetable based on the values in the sliders.
 *
 */
void updateWaveTable()
{
  float[] wavetable = new float[WAVE_RESOLUTION];
  
  for (int i = 0; i < WAVE_RESOLUTION ; i++) 
  {
    wavetable[i] = (sin(i * TWO_PI * waveFrequency.get()/ WAVE_RESOLUTION)
        + sin(i * TWO_PI * waveFrequency2.get()/ WAVE_RESOLUTION)) / 2;
  }

  for (int octaveIndex = 0; octaveIndex < OCTAVE.length; ++octaveIndex)
  {
    synths[octaveIndex].loadWaveTable(wavetable);
  }
}

/* draw()
 * Code that happens on each frame
 *
 */
void draw()
{
  background(BACKGROUND_COLOR);
  updateBeatRate();
  updateKey();
  updateWaveTable();
  updatePlayback();
  drawBoard();
  drawGUI();
}

/* updateBeatRate()
 * Update the beat if there are changes in the slider
 *
 */
void updateBeatRate()
{
  if (bpm != (int) bpmSlider.get())
  { 
    bpm = (int) bpmSlider.get();
    bps = bpm / 60;
    framesPerBeat = FRAME_RATE / bps;
    maxFramesPerBeat = (int) framesPerBeat * BEAT_COUNT;    
  }
  
  playHead = (playHead + 1) % maxFramesPerBeat;
}

/* updateKey()
 * Update the key if there are changes in the slider
 *
 */
void updateKey()
{
  if (currentKey != (int) keySlider.get())
  {    
    currentKey = (int) keySlider.get();
    for (int octaveIndex = 0; octaveIndex < OCTAVE.length; ++octaveIndex)
    {
      synths[octaveIndex].setFrequency(
        OCTAVE[octaveIndex] * pow(NOTE_INTERVAL, currentKey));
    }
  }
}

/* updatePlayback()
 * Check if it is time to play notes. 
 *
 */
void updatePlayback()
{
  int playHeadInBeat = (int) (playHead % framesPerBeat);
  
  if (playHeadInBeat < framesPerBeat / 2)
  { 
    playCurrentBeat();
    displayBeatEffect(playHeadInBeat);
  }
}

/* getCurrentBeat()
 * Get the current beat
 *
 */
int getCurrentBeat()
{
  return (int) map(playHead, 0, maxFramesPerBeat, 0, BEAT_COUNT);
}

/* displayBeatEffect()
 * Flash the board and play the metronome tick if it is on the beat.
 *
 */
void displayBeatEffect(int playHeadInBeat)
{
  if (playHeadInBeat < framesPerBeat / 3)
  {
    backgroundColor = (int) map(playHeadInBeat, 0, framesPerBeat / 3,
                      BEAT_BACKGROUND_COLOR, BACKGROUND_COLOR);
  }
  
  if (playHeadInBeat < 1)
  {
    metronome.play();
  }
}

/* playCurrentBeat()
 * Play the notes on the current beat.
 *
 */
void playCurrentBeat()
{
  int currentBeat = getCurrentBeat();

  for (int octaveIndex = 0; octaveIndex < OCTAVE.length; ++octaveIndex)
  {
    playNote(currentBeat, octaveIndex);
  }
}

/* playNote()
 * Play or stop one note.
 *
 */
void playNote(int currentBeat, int octaveIndex)
{
  if (notes[currentBeat][octaveIndex])
  {
    synths[octaveIndex].ramp(1, 0.3);
    synths[octaveIndex].play();
  }
  else
  {
    synths[octaveIndex].ramp(0, 2);
  }
}

/* drawGUI()
 * Draw the GUI elements
 *
 */
void drawGUI()
{
  waveFrequency.display();
  waveFrequency2.display();
  bpmSlider.display();
  keySlider.display();
  
  randomize.display();
  clear.display();
  
  displayValues();
}

/* displayValues()
 * Display the values of the sliders
 *
 */
void displayValues()
{
  fill(255);
  
  displaySliderValue(waveFrequency);
  displaySliderValue(waveFrequency2);
  displaySliderValue(bpmSlider);
  displaySliderValue(keySlider, true);
}

/* displaySliderValue()
 * Display the value of one slider in the middle of the slider. Default float
 * version.
 *
 */
void displaySliderValue(Slider slider)
{
  displaySliderValue(slider, false);
}

/* displaySliderValue()
 * Display the value of one slider in the middle of the slider. Can set the
 * isInt parameter to handle the value as an int.
 *
 */
void displaySliderValue(Slider slider, boolean isInt)
{
  String displayValue;
  
  if (isInt)
  {
    displayValue = String.format("%d", (int) slider.get());
  }
  else
  {
    displayValue = String.format("%.1f", slider.get());
  }
  
  text(displayValue, slider.pos.x + 2, slider.pos.y + (slider.extents.y / 2));
}

/* drawGrid()
 * Draw the grid.
 *
 */
void drawGrid()
{
  stroke(255);
  noFill();
  
  drawCircles();
  drawSpokes();
  
  fill(backgroundColor);
  ellipse(RADAR_CENTER_X, RADAR_CENTER_Y, 
          MIN_CIRCLE_RADIUS, MIN_CIRCLE_RADIUS);
}

/* drawSpokes()
 * Draw the spokes radiating from the middle of the board.
 *
 */
void drawSpokes()
{
  for (int i = 0; i < BEAT_COUNT / 2; ++i)
  {
    drawSpokeOnAngle(map(i, 0, BEAT_COUNT / 2, 0, PI));
  }
}

/* updateSpokeStroke()
 * Update the color and weight of the spoke.
 *
 */
void updateSpokeStroke(float angle)
{
  if (angle % HALF_PI == 0)
  {
    strokeWeight(3);
    stroke(178, 0, 0);
  }
  else
  {
    strokeWeight(2);
    stroke(178);
  }
}

/* drawSpokeOnAngle()
 * Draw the spoke on the given angle
 *
 */
void drawSpokeOnAngle(float angle)
{
  updateSpokeStroke(angle);
  pushMatrix();
    translate(RADAR_CENTER_X, RADAR_CENTER_Y);
    rotate(angle);
    line(-MAX_CIRCLE_RADIUS, 0, MAX_CIRCLE_RADIUS, 0);
  popMatrix();
}

/* drawCircles()
 * Draw the circles of the grid
 *
 */
void drawCircles()
{
  for (int i = 1; i < OCTAVE.length + 1; ++i)
  {
    float radius = map(i, 0, OCTAVE.length, 
                       MIN_CIRCLE_RADIUS, MAX_CIRCLE_RADIUS);
    ellipse(RADAR_CENTER_X, RADAR_CENTER_Y, radius, radius);
  }
}

/* drawBoard()
 * Draw the whole board: Notes, grid, and the beat indicator
 *
 */
void drawBoard()
{
  colorMode(HSB);
  drawNotes();
  
  colorMode(RGB);
  
  drawBeatIndicator();
  
  drawGrid();
}

/* drawNotes()
 * Draw the notes.
 *
 */
void drawNotes()
{
  for (int beatIndex = 0; beatIndex < BEAT_COUNT; ++beatIndex)
  {
    drawNotesOnBeat(beatIndex);
  }
}

/* drawNotes()
 * Draw the notes on the current beat.
 *
 */
void drawNotesOnBeat(int beatIndex)
{
  for (int noteIndex = OCTAVE.length; noteIndex > 0; --noteIndex)
  {
    updateNoteColor(beatIndex, noteIndex - 1);
    
    float radius = map(noteIndex, 0, OCTAVE.length,
                       MIN_CIRCLE_RADIUS, MAX_CIRCLE_RADIUS);
    
    arc(RADAR_CENTER_X, RADAR_CENTER_Y, radius, radius, beatIndex * ARC_WIDTH,
        (beatIndex + 1) * ARC_WIDTH, PIE);
  }
}

/* updateNoteColor()
 * Update the color to use based on the current note.
 *
 */
void updateNoteColor(int beatIndex, int noteIndex)
{
  if (notes[beatIndex][noteIndex])
  {
    fill(noteColors[noteIndex], 89, 255);
  }
  else
  {
    fill(backgroundColor);
  }
}

/* drawBeatIndicator()
 * Draw the beat indicator.
 *
 */
void drawBeatIndicator()
{
  fill(178, 127);
  
  int currentBeat = getCurrentBeat();
  
  arc(RADAR_CENTER_X, RADAR_CENTER_Y, MAX_CIRCLE_RADIUS, MAX_CIRCLE_RADIUS,
      currentBeat * ARC_WIDTH, (currentBeat + 1) * ARC_WIDTH, PIE);
}

/* mouseDragged()
 * Handle the slider dragging.
 *
 */
void mouseDragged()
{
  waveFrequency.mouseDragged();
  waveFrequency2.mouseDragged();
  bpmSlider.mouseDragged();
  keySlider.mouseDragged();
}

/* mousePressed()
 * Handle buttons and toggling of the notes, as well as jumping of values on
 * the sliders.
 *
 */
void mousePressed()
{
  handleBoardButtons();
  waveFrequency.mousePressed();
  waveFrequency2.mousePressed();
  bpmSlider.mousePressed();
  keySlider.mousePressed();
  randomize.mousePressed();
  clear.mousePressed();
}

/* handleBoardButtons()
 * Check if the mouse click is on the board. Toggle notes if it is.
 *
 */
void handleBoardButtons()
{
  PVector mouseVector = new PVector(mouseX - RADAR_CENTER_X,
                                    mouseY - RADAR_CENTER_Y);
  float mouseDist = mouseVector.mag();
  
  if (mouseDist > MIN_CIRCLE_RADIUS && mouseDist < MAX_CIRCLE_RADIUS)
  {
    toggleBoardButtons(mouseVector);
  }
}

/* toggleBoardButtons()
 * Toggle the notes on and off.
 *
 */
void toggleBoardButtons(PVector mouseVector)
{
  int octaveIndex = (int) map(mouseVector.mag(), MIN_CIRCLE_RADIUS, 
                              MAX_CIRCLE_RADIUS, 0, OCTAVE.length);
  float a = PVector.angleBetween(ZERO_VECTOR, mouseVector);
  if (mouseVector.y < 0)
  {
    a = TWO_PI - a;
  }
  int beat = (int) map(a, 0, TWO_PI, 0, BEAT_COUNT);
  notes[beat][octaveIndex] = !notes[beat][octaveIndex];
}

/* mouseReleased()
 * Handle the button presses, as well as  jumping of values on the sliders.
 *
 */
void mouseReleased()
{
  handleButtons();
  
  waveFrequency.mouseReleased();
  waveFrequency2.mouseReleased();
  bpmSlider.mouseReleased();
  keySlider.mouseReleased();
}

/* handleButtons()
 * Handle the button presses. Toggle their respective operations.
 *
 */
void handleButtons()
{
  if (randomize.mouseReleased())
  {
    putRandomNotes();
  }
  
  if (clear.mouseReleased())
  {
    clearNotes();
  }
}

