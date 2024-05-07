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
    setSize (500, 300);
}

NewProjectAudioProcessorEditor::~NewProjectAudioProcessorEditor()
{}

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
            float constrainedPitch = juce::jlimit<float>(0.0f, audioProcessor.getSampleRate()/2.0, audioProcessor.pitch[i]);
            //scopeData[i] = constrainedPitch/(audioProcessor.getSampleRate()/2.0);
            scopeData[i] = constrainedPitch;
            
        }
    }
}

void NewProjectAudioProcessorEditor::paint (juce::Graphics& g)
{
    // (Our component is opaque, so we must completely fill the background with a solid colour)
    //g.fillAll (getLookAndFeel().findColour (juce::ResizableWindow::backgroundColourId));
    //g.setColour(juce::Colours::white);
    //g.setFont (15.0f);
    //g.drawFittedText ("Hello World!", getLocalBounds(), juce::Justification::centred, 1);

    g.fillAll (juce::Colours::black);
    g.setColour(juce::Colours::orange);
    g.setFont (15.0f);

    
    //y axis (pitch) values between 0 and 5000Hz should fit between height 0 and 300
    //x-axis values between 0 and 1s need to fit between width 0 and 600
    
    for (int i = 1; i < scopeSize; ++i)
    {
        auto width  = getLocalBounds().getWidth();
        auto height = getLocalBounds().getHeight();
        
        // Pitch values should fit within the height of the screen. Use jmap
        // jmap (Type sourceValue, Type sourceRangeMin, Type sourceRangeMax,
        // Type targetRangeMin, Type targetRangeMax)
        g.drawLine ({
            
            //plotting on linear scale
            (float) juce::jmap (i - 1, 0, scopeSize - 1, 0, width),
            juce::jmap (scopeData[i-1], 0.0f, (float)maxPitch, (float) height, 0.0f),
            (float) juce::jmap (i, 0, scopeSize - 1, 0, width),
            juce::jmap (scopeData[i], 0.0f, (float)maxPitch, (float) height, 0.0f)
            
            //normalize pitch values and plot on log scale
            /*(float) juce::jmap (i - 1, 0, scopeSize - 1, 0, width),
             juce::mapToLog10 (scopeData[i-1], (float) height, 1.0f),
             (float) juce::jmap (i, 0, scopeSize - 1, 0, width),
             juce::mapToLog10 (scopeData[i], (float) height, 1.0f)*/
        });
    }
    
}

void NewProjectAudioProcessorEditor::resized()
{
    // This is generally where you'll want to lay out the positions of any
    // subcomponents in your editor..
}

