/*
  ==============================================================================

    This file contains the basic framework code for a JUCE plugin editor.

  ==============================================================================
*/

#include "PluginProcessor.h"
#include "PluginEditor.h"

//==============================================================================
NewProjectAudioProcessorEditor::NewProjectAudioProcessorEditor (NewProjectAudioProcessor& p)
    : AudioProcessorEditor (&p), audioProcessor (p)
{
    
    
    //Make sure that before the constructor has finished, you've set the
    //editor's size to whatever you need it to be.
    for(int i = 0; i < scopeSize; i++)
        scopeData[i] = 0.0f;
    
    startTimer(50);    //timerCallback every 100ms
    setSize (500, 700);
    sampleRate = (float)audioProcessor.getSampleRate();
    
    //for plotting notes on y-axis
    auto height = getLocalBounds().getHeight();
    numNotesToPlot = int(std::round(std::log2((float) maxPitch / fundamentalFrequency) * 12));
    noteFrequencyPixel = new float[numNotesToPlot];
    noteFrequencyHz = new float[numNotesToPlot];
    for (int k = 0; k < numNotesToPlot; k++){
        
        //frequency of musical notes
        noteFrequencyHz[k] = fundamentalFrequency * std::pow(2, (float)k / 12.0);
        
        //linear mapping
        //noteFrequencyPixel[k] = juce::jmap (noteFrequencyHz[k], 0.0f, (float)maxPitch, (float)height, 0.0f);
        
        //log mapping for better visibility
        //float normNoteFrequency = noteFrequencyHz[k]/((float) maxPitch);
        //noteFrequencyPixel[k] = juce::mapToLog10 (normNoteFrequency, (float) height, 1.0f);
        
        //equal temperament mapping
        noteFrequencyPixel[k] = height - mapToEqualTemperament(noteFrequencyHz[k], (float) height);
    }
}

NewProjectAudioProcessorEditor::~NewProjectAudioProcessorEditor()
{
    delete [] noteFrequencyHz;
    delete [] noteFrequencyPixel;
}

//==============================================================================

void NewProjectAudioProcessorEditor::timerCallback(){
    if (audioProcessor.nextPitchBlockReady)
    {
        drawNextFrame();
        audioProcessor.nextPitchBlockReady = false;
        repaint();
    }
    
}

void NewProjectAudioProcessorEditor::drawNextFrame() {
    
    
    for (int i = scopeSize-1; i >= 0; i--)
    {
        //shift existing samples to the right
        if (i >= audioProcessor.pitchSize)
            scopeData[i]  = scopeData[i-audioProcessor.pitchSize];
        else{
            //fill the first half with new pitch samples
            //pitch wont exceed half of sample Rate
            float constrainedPitch = juce::jlimit<float>(0.0f, sampleRate/2.0, audioProcessor.pitch[i]);
            //scopeData[i] = constrainedPitch/(float)maxPitch;
            scopeData[i] = constrainedPitch;
            
        }
    }
}

inline float NewProjectAudioProcessorEditor::mapToEqualTemperament(float frequencyHz, float maxHeight){
    //maps a frequency in Hz to a vertical pixel position for drawing, such that
    //consecutive notes occupy equal distances
    
    if (frequencyHz <= fundamentalFrequency)
        return 0.0f;
    else{
        float numNotes = std::log2((float) maxPitch / fundamentalFrequency);
        return std::log2(frequencyHz / fundamentalFrequency) * maxHeight / numNotes;
    }
}

void NewProjectAudioProcessorEditor::paint (juce::Graphics& g)
{

    g.fillAll (juce::Colours::black);
    g.setColour(juce::Colours::orange);
    g.setFont (15.0f);
    g.setOpacity(1.0f);
    
    auto width  = getLocalBounds().getWidth();
    auto height = getLocalBounds().getHeight();

    
    //y axis (pitch) values between 0 and 5000Hz should fit between height 0 and 300
    //x-axis values between 0 and 1s need to fit between width 0 and 600
    
    for (int i = 1; i < scopeSize; ++i)
    {
        // Pitch values should fit within the height of the screen. Use jmap
        // jmap (Type sourceValue, Type sourceRangeMin, Type sourceRangeMax,
        // Type targetRangeMin, Type targetRangeMax)
        g.drawLine ({
            
            //plotting on linear scale
            /*(float) juce::jmap (i - 1, 0, scopeSize - 1, 0, width),
            juce::jmap (scopeData[i-1], 0.0f, (float)maxPitch, (float) height, 0.0f),
            (float) juce::jmap (i, 0, scopeSize - 1, 0, width),
            juce::jmap (scopeData[i], 0.0f, (float)maxPitch, (float) height, 0.0f)
             */
            
            
             //normalize pitch values and plot on log scale
             /* (float) juce::jmap (i - 1, 0, scopeSize - 1, 0, width),
             juce::mapToLog10 (scopeData[i-1], (float) height, 1.0f),
             (float) juce::jmap (i, 0, scopeSize - 1, 0, width),
             juce::mapToLog10 (scopeData[i], (float) height, 1.0f)*/
            
            //plotting on an equal temperament scale
            (float) juce::jmap (i - 1, 0, scopeSize - 1, 0, width),
            height - mapToEqualTemperament(scopeData[i-1], (float) height),
            (float) juce::jmap (i, 0, scopeSize - 1, 0, width),
            height  - mapToEqualTemperament(scopeData[i], (float) height)
        });
        
    }
    
    //draw horizontal lines at note values, starting from fundamental
    g.setColour(juce::Colours::grey);
    g.setOpacity(0.5f);
    
    for (int k = 0 ; k < numNotesToPlot; k++){
        //Point <float> (x, y)
        juce::Line<float> line (juce::Point<float> (0, noteFrequencyHz[k]),
                                    juce::Point<float> (scopeSize, noteFrequencyHz[k]));
    
        
        //draw horizontal line at note frequency
        g.drawHorizontalLine(noteFrequencyPixel[k], 0.0f, (float)scopeSize);
        
        //write the note name also - note name + octave
        juce::String noteName = noteNames[k % 12] + (juce::String)(initOctave + (k / 12));
        
        //drawText(String text, int x, int y, int width, int height);
        g.drawText(noteName, 10, noteFrequencyPixel[k], 30, 10, juce::Justification::centred, false);
        
    }
    
}

void NewProjectAudioProcessorEditor::resized()
{
    // This is generally where you'll want to lay out the positions of any
    // subcomponents in your editor..
}

