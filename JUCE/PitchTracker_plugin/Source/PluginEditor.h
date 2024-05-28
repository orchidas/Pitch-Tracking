/*
  ==============================================================================

    This file contains the basic framework code for a JUCE plugin editor.

  ==============================================================================
*/

#pragma once

#include <JuceHeader.h>
#include "PluginProcessor.h"

//==============================================================================
/**
*/
class NewProjectAudioProcessorEditor  : public juce::AudioProcessorEditor
                                        ,private juce::Timer
{
public:
    NewProjectAudioProcessorEditor (NewProjectAudioProcessor&);
    ~NewProjectAudioProcessorEditor() override;
    enum
    {
        scopeSize = 8192,          // size of pitch data to be displayed
        maxPitch = 3700,           //maximum possible pitch
        initOctave = 1,            //start from A3
    };


    //==============================================================================
    void paint (juce::Graphics&) override;
    void resized() override;
    void timerCallback() override;
    void drawNextFrame();
    inline float mapToEqualTemperament(float frequencyHz, float maxHeight);

    
private:
    
    // This reference is provided as a quick way for your editor to
    // access the processor object that created it.
    NewProjectAudioProcessor& audioProcessor;
    float scopeData [scopeSize];    //data that is plotted
    float sampleRate;
    int numNotesToPlot;
    float fundamentalFrequency = 55.0;       //A3 in Hz
    float* noteFrequencyPixel;
    float* noteFrequencyHz;
    juce::String noteNames[12] = {"A", "Bb", "B", "C", "Db", "D", "Eb", "E", "F", "Gb", "G", "Ab"};
            
    JUCE_DECLARE_NON_COPYABLE_WITH_LEAK_DETECTOR (NewProjectAudioProcessorEditor)
};
