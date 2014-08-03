/*************************************************************************
 * BeatThreads.pde 
 * 
 * Author: Eugene Jarder
 *
 * For completion of requirements for Creative Programming for Digital 
 * Media & Mobile Apps at Coursera.
 *
 * This is the product of the developer playing around with the gravity of
 * the world. Whenever the user presses the mouse down, the balls will
 * move towards the direction of the mouse. As you move the mouse around,
 * the balls will form threads on the screen. The color of the balls will
 * also change to the beat of the music.
 * 
 * The music used was taken from the following link:
 *   - https://www.freesound.org/people/bigjoedrummer/sounds/77293/
 * I chose a rock beat because the beat is more obvious to our ears.
 *
 * Code is found on the following link:
 *   - https://github.com/ejjarder/BeatThreads
 *
 * Known bug: There is a chance that the balls will not move when the
 * mouse is presses. The developer is not sure why this happens.
 *
 *************************************************************************/

private static final int OCTAVE = 7;
private static final int BEAT_COUNT = 16;
private static final int SCREEN_WIDTH = 640;
private static final int SCREEN_HEIGHT = 400;
private static final int NOTES_WIDTH = 640;
private static final int NOTES_HEIGHT = 357;
private static final int BEAT_WIDTH = floor(NOTES_WIDTH / BEAT_COUNT);
private static final int BEAT_HEIGHT = floor(NOTES_HEIGHT / OCTAVE);
private static final int FRAME_RATE = 60;
private static final int MIN_BPM = 60;
private static final int DEFAULT_BPM = 120;
private static final int MAX_BPM = 300;
private static final int SLIDERS_Y = 360;
private static final int SLIDERS_X1 = 10;
private static final int SLIDERS_X2 = 270;
private static final int DEFAULT_KEY = 0;
private static final int MIN_KEY = -2;
private static final int MAX_KEY = 8;

Maxim maxim;

WavetableSynth synths[] = new WavetableSynth[OCTAVE];

float[] wavetable = new float[514];

float[] octave = {
  261.62558f, // C4
  293.664764f, // D4
  329.627563f, // E4
  349.228241f, // F4
  391.995422f, // G4
  440.f,       // A4
  493.883301f // B4
};

boolean tracks[][];

int currentNote = 0;

int playHead = 0;

Slider waveFrequency;
Slider waveFrequency2;
Slider bpmSlider;
Slider keySlider;

int bpm;
int newBPM;
float bps;
float framesPerBeat;
int maxFramesPerBeat;
int currentKey = 0;
int newKey = 0;

void setup()
{
  size(SCREEN_WIDTH, SCREEN_HEIGHT);
  maxim = new Maxim(this);
  frameRate(FRAME_RATE);
  strokeWeight(2);
  
  tracks = new boolean[BEAT_COUNT][OCTAVE];
  
  for (int octaveIndex = 0; octaveIndex < OCTAVE; ++octaveIndex)
  {
    synths[octaveIndex] = maxim.createWavetableSynth(514);
    synths[octaveIndex].setFrequency(octave[octaveIndex]);
  }
  
  newBPM = DEFAULT_BPM;
  updateBeat();
  
  waveFrequency = new Slider("freq 1", 1, 0.1, 1.9, SLIDERS_X1, SLIDERS_Y, 250, 15, HORIZONTAL);
  waveFrequency2 = new Slider("freq 2", 0, 0, 1.9, SLIDERS_X1, SLIDERS_Y + 20, 250, 15, HORIZONTAL);
  bpmSlider = new Slider("bpm", DEFAULT_BPM, MIN_BPM, MAX_BPM, SLIDERS_X2, SLIDERS_Y, 250, 15, HORIZONTAL);
  keySlider = new Slider("key", DEFAULT_KEY, MIN_KEY, MAX_KEY, SLIDERS_X2, SLIDERS_Y + 20, 250, 15, HORIZONTAL);
  
  updateWaveTable();
}

void updateWaveTable()
{
  float maxAmp = 0;
  for (int i = 0; i < 514 ; i++) {
    wavetable[i] = sin(i * TWO_PI * waveFrequency.get()/ 514);
    wavetable[i] += sin(i * TWO_PI * waveFrequency2.get()/ 514);
    
    if (abs(wavetable[i]) > maxAmp)
    {
      maxAmp = wavetable[i];
    }
  }
  
  for (int i = 0; i < 514 ; i++) {
    wavetable[i] /= maxAmp;
    wavetable[i] *= 0.75;
  } 

  for (int octaveIndex = 0; octaveIndex < OCTAVE; ++octaveIndex)
  {
    synths[octaveIndex].loadWaveTable(wavetable);
  }
}

void draw()
{
// code that happens every frame
  background(200);
  updateBeat();
  updateFrequency();
  playBeat();
  drawTracks();
  drawGUI();
  println("currentKey = " + currentKey);
  println("newKey = " + newKey);
}

void updateBeat()
{
  if (newBPM != -1)
  {
    bpm = newBPM;
    bps = bpm / 60;
    framesPerBeat = FRAME_RATE / bps;
    maxFramesPerBeat = (int) framesPerBeat * BEAT_COUNT;
    newBPM = -1;
  }
  
  playHead = (playHead + 1) % maxFramesPerBeat;
}

void updateFrequency()
{
  if (newKey != -13)
  {
    currentKey = newKey;
    for (int octaveIndex = 0; octaveIndex < OCTAVE; ++octaveIndex)
    {
      synths[octaveIndex].setFrequency(octave[octaveIndex] * pow(1.6, currentKey));
    }
    
    newKey = -13;
  }
}

void playBeat()
{
  int playHeadInBeat = (int) (playHead % framesPerBeat);
  
  int currentBeat =  (int) map(playHead, 0, maxFramesPerBeat, 0, BEAT_COUNT);
  
  if (playHeadInBeat < FRAME_RATE / 2);
  {
    updateWaveTable();    
    
    boolean[] beatNotes = tracks[currentBeat];
    
    for (int octaveIndex = 0; octaveIndex < OCTAVE; ++octaveIndex)
    {
      if (beatNotes[octaveIndex])
      {
        synths[octaveIndex].ramp(1, 0.3);
        synths[octaveIndex].play();
      }
      else
      {
        synths[octaveIndex].ramp(0, 2);
      }      
    }
  
    fill(127, 127);
    rect(currentBeat * BEAT_WIDTH, 0, 
         BEAT_WIDTH, NOTES_HEIGHT); 
  }
}

void drawGUI()
{
  waveFrequency.display();
  waveFrequency2.display();
  bpmSlider.display();
  keySlider.display();
}

void drawGrid()
{
  stroke(255);
  noFill();
  rect(0, 0, NOTES_WIDTH, NOTES_HEIGHT);
  
  for (int octIndex = 1; octIndex < OCTAVE; ++octIndex)
  {
    int lineY = (int) map(octIndex, 0, OCTAVE, 0, NOTES_HEIGHT);
    line(0, lineY, NOTES_WIDTH, lineY); 
  }
  
  for (int beatIndex = 1; beatIndex < BEAT_COUNT; ++beatIndex)
  {
    if (beatIndex % 4 == 0)
    {
      stroke(255, 0, 0);
    } 
    
    int lineX = (int) map(beatIndex, 0, BEAT_COUNT, 0, NOTES_WIDTH);
    line(lineX, 0, lineX, NOTES_HEIGHT);
    
    if (beatIndex % 4 == 0)
    {
      stroke(255);
    } 
  }
}

void drawTracks()
{
  fill(255);
  for (int xIndex = 0; xIndex < BEAT_COUNT; ++xIndex)
  {
    for (int yIndex = 0; yIndex < OCTAVE; ++yIndex)
    {
      if (tracks[xIndex][yIndex])
      {
        rect(xIndex * BEAT_WIDTH, yIndex * BEAT_HEIGHT, 
             BEAT_WIDTH, BEAT_HEIGHT); 
      }
    }
  }
  drawGrid();
}

void mouseDragged()
{
  waveFrequency.mouseDragged();
  waveFrequency2.mouseDragged();
  bpmSlider.mouseDragged();
  keySlider.mouseDragged();
  newBPM = (int) bpmSlider.get();
  newKey = (int) keySlider.get();
}

void mousePressed()
{
  if (mouseY < NOTES_HEIGHT)
  {
    int beatIndex = (int) map(mouseX, 0, NOTES_WIDTH, 0, BEAT_COUNT);
    int octaveIndex = (int) map(mouseY, 0, NOTES_HEIGHT, 0, OCTAVE);
    
    tracks[beatIndex][octaveIndex] = !tracks[beatIndex][octaveIndex];
  }
  
  waveFrequency.mousePressed();
  waveFrequency2.mousePressed();
  bpmSlider.mousePressed();
  keySlider.mousePressed();
  newBPM = (int) bpmSlider.get();
  newKey = (int) keySlider.get();
}

void mouseReleased()
{
}

