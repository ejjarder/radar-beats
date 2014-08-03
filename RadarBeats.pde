/*************************************************************************
 * RadarBeats.pde
 *
 *************************************************************************/

private static final int OCTAVE = 7;
private static final int BEAT_COUNT = 16;
private static final int TOTAL_NOTES = OCTAVE * BEAT_COUNT;
private static final int SCREEN_WIDTH = 800;
private static final int SCREEN_HEIGHT = 720;
private static final int RADAR_CENTER_X = 478;
private static final int RADAR_CENTER_Y = SCREEN_HEIGHT / 2;
private static final int MIN_CIRCLE_RADIUS = 36;
private static final int MAX_CIRCLE_RADIUS = 312;
private static final float ARC_WIDTH = TWO_PI / BEAT_COUNT;
private static final float ARC_HEIGHT = (MAX_CIRCLE_RADIUS - MIN_CIRCLE_RADIUS) / OCTAVE;
private static final int FRAME_RATE = 60;
private static final int MIN_BPM = 60;
private static final int DEFAULT_BPM = 120;
private static final int MAX_BPM = 300;
private static final int DEFAULT_KEY = 0;
private static final int MIN_KEY = -3;
private static final int MAX_KEY = 8;
private static final float MIN_FREQUENCY = 0.1;
private static final float MAX_FREQUENCY = 5;
private static final int MIN_RANDOM_NOTES = 10;
private static final int MAX_RANDOM_NOTES = 43;
private static final float NOTE_INTERVAL = pow(2, 1.0/12);

PVector zeroVector = new PVector(1, 0);

Maxim maxim;

WavetableSynth synths[] = new WavetableSynth[OCTAVE];

float[] wavetable = new float[514];

float[] octave = 
{
  261.62558f, // C4
  293.664764f, // D4
  329.627563f, // E4
  349.228241f, // F4
  391.995422f, // G4
  440.f,       // A4
  493.883301f // B4
};

int[] octaveColors = new int[OCTAVE]; 

boolean notes[][];

int currentNote = 0;

int playHead = 0;

Slider waveFrequency;
Slider waveFrequency2;
Slider bpmSlider;
Slider keySlider;

Button randomize;
Button clear;

int bpm;
int newBPM;
float bps;
float framesPerBeat;
int maxFramesPerBeat;
int currentKey = 0;
int newKey = 0;

int backgroundColor = 76;

AudioPlayer metronome;

void setup()
{
  size(SCREEN_WIDTH, SCREEN_HEIGHT);
  maxim = new Maxim(this);
  frameRate(FRAME_RATE);
  strokeWeight(2);
  ellipseMode(RADIUS);
  
  notes = new boolean[BEAT_COUNT][OCTAVE];
  
  for (int octaveIndex = 0; octaveIndex < OCTAVE; ++octaveIndex)
  {
    synths[octaveIndex] = maxim.createWavetableSynth(514);
    synths[octaveIndex].setFrequency(octave[octaveIndex]);
    octaveColors[octaveIndex] = (int) map(octaveIndex, 0, OCTAVE, 0, 255);
  } 
  
  newBPM = DEFAULT_BPM;
  updateBeat();
  
  initializeGUI();
  
  updateWaveTable();
  
  metronome = maxim.loadFile("metronome.wav");
  metronome.setLooping(false);
  metronome.volume(1.0);
}

void initializeGUI()
{
  waveFrequency = new Slider("freq 1", 1, MIN_FREQUENCY, MAX_FREQUENCY, 10, 10, 47, 281, VERTICAL);
  waveFrequency2 = new Slider("freq 2", 1, MIN_FREQUENCY, MAX_FREQUENCY, 10, 301, 47, 281, VERTICAL);
  bpmSlider = new Slider("bpm", DEFAULT_BPM, MIN_BPM, MAX_BPM, 67, 10, 47, 281, VERTICAL);
  keySlider = new Slider("key", DEFAULT_KEY, MIN_KEY, MAX_KEY, 67, 301, 47, 281, VERTICAL);
  
  randomize = new Button("randomize", 10, 602, 104, 42);
  clear = new Button("clear", 10, 654, 104, 42); 
}

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

void clearNotes()
{
  for (int arcIndex = 0; arcIndex < BEAT_COUNT; ++arcIndex)
  {
    for (int rIndex = OCTAVE - 1; rIndex >= 0; --rIndex)
    {
      notes[arcIndex][rIndex] = false;
    }
  }
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
    wavetable[i] *= 0.9;
  } 

  for (int octaveIndex = 0; octaveIndex < OCTAVE; ++octaveIndex)
  {
    synths[octaveIndex].loadWaveTable(wavetable);
  }
}

void draw()
{
// code that happens every frame
  background(76);
  updateBeat();
  updateFrequency();
  updateWaveTable();
  playBeat();
  drawNotes();
  drawGUI();
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
      synths[octaveIndex].setFrequency(octave[octaveIndex] * pow(NOTE_INTERVAL, currentKey));
    }
    
    newKey = -13;
  }
}

void playBeat()
{
  int playHeadInBeat = (int) (playHead % framesPerBeat);
  
  if (playHeadInBeat < framesPerBeat / 2)
  { 
    boolean[] beatNotes = notes[getCurrentBeat()];
    
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
    
    if (playHeadInBeat < framesPerBeat / 3)
    { 
      backgroundColor = (int) map(playHeadInBeat, 0, framesPerBeat / 3, 89, 76);
    }
    
    if (playHeadInBeat < 1)
    {
      metronome.play();
    }
  }
}

int getCurrentBeat()
{
  return (int) map(playHead, 0, maxFramesPerBeat, 0, BEAT_COUNT);
}

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

void displayValues()
{
  fill(255);
  
  displaySliderValue(waveFrequency);
  displaySliderValue(waveFrequency2);
  displaySliderValue(bpmSlider);
  displaySliderValue(keySlider, true);
}

void displaySliderValue(Slider slider)
{
  displaySliderValue(slider, false);
}

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
  
  text(displayValue, slider.pos.x + 10, slider.pos.y + (slider.extents.y / 2));
}

void drawGrid()
{
  stroke(255);
  noFill();
  
  for (int i = 0; i < BEAT_COUNT / 2; ++i)
  {
    float angle = map(i, 0, BEAT_COUNT / 2, 0, PI);
    if (angle % HALF_PI == 0)
    {
      stroke(178, 0, 0);
    }
    else
    {
      stroke(178);
    }
    pushMatrix();
      translate(RADAR_CENTER_X, RADAR_CENTER_Y);
      rotate(angle);
      line(-MAX_CIRCLE_RADIUS, 0, MAX_CIRCLE_RADIUS, 0);
    popMatrix();
  }
  
  for (int i = 1; i < OCTAVE + 1; ++i)
  {
    float radius = map(i, 0, OCTAVE, MIN_CIRCLE_RADIUS, MAX_CIRCLE_RADIUS);
    ellipse(RADAR_CENTER_X, RADAR_CENTER_Y, radius, radius);
  }
  
  fill(backgroundColor);
  ellipse(RADAR_CENTER_X, RADAR_CENTER_Y, MIN_CIRCLE_RADIUS, MIN_CIRCLE_RADIUS);
}

void drawNotes()
{
  for (int arcIndex = 0; arcIndex < BEAT_COUNT; ++arcIndex)
  {
    for (int rIndex = OCTAVE; rIndex > 0; --rIndex)
    {
      if (notes[arcIndex][rIndex - 1])
      {
        colorMode(HSB);
        fill(octaveColors[rIndex - 1], 89, 255);
        colorMode(RGB);   
      }
      else
      {
        fill(backgroundColor);
      }
      
      float radius = map(rIndex, 0, OCTAVE, MIN_CIRCLE_RADIUS, MAX_CIRCLE_RADIUS);
      
      arc(RADAR_CENTER_X, RADAR_CENTER_Y, radius, radius, arcIndex * ARC_WIDTH, (arcIndex + 1) * ARC_WIDTH, PIE);
    }
  }
  
  fill(178, 127);
  
  int currentBeat = getCurrentBeat();
  
  arc(RADAR_CENTER_X, RADAR_CENTER_Y, MAX_CIRCLE_RADIUS, MAX_CIRCLE_RADIUS, currentBeat * ARC_WIDTH, (currentBeat + 1) * ARC_WIDTH, PIE);
  
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
  PVector mouseVector = new PVector(mouseX - RADAR_CENTER_X, mouseY - RADAR_CENTER_Y);
  float mouseDist = mouseVector.mag();
  if (mouseDist > MIN_CIRCLE_RADIUS && mouseDist < MAX_CIRCLE_RADIUS)
  {
    int octave = (int) map(mouseDist, MIN_CIRCLE_RADIUS, MAX_CIRCLE_RADIUS, 0, OCTAVE);
    float a = PVector.angleBetween(zeroVector, mouseVector);
    if (mouseVector.y < 0)
    {
      a = TWO_PI - a;
    }
    int beat = (int) map(a, 0, TWO_PI, 0, BEAT_COUNT);
    notes[beat][octave] = !notes[beat][octave];
  }
  waveFrequency.mousePressed();
  waveFrequency2.mousePressed();
  bpmSlider.mousePressed();
  keySlider.mousePressed();
  newBPM = (int) bpmSlider.get();
  newKey = (int) keySlider.get();
  randomize.mousePressed();
  clear.mousePressed();
}

void mouseReleased()
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

