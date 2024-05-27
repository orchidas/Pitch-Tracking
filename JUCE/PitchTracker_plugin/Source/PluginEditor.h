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
        maxPitch = 9000,            //maximum possible pitch
        initOctave = 3,           //start from A3
        maxFreqToPlot = 3700      //for plotting purposes
    };


    //==============================================================================
    void paint (juce::Graphics&) override;
    void resized() override;
    void timerCallback() override;
    void drawNextFrame();
    
private:
    
    // This reference is provided as a quick way for your editor to
    // access the processor object that created it.
    NewProjectAudioProcessor& audioProcessor;
    float scopeData [scopeSize];    //data that is plotted
    float sampleRate;
    int numNotesToPlot;
    float fundamentalFrequency = 220;       //A3 in Hz
    juce::String noteNames[12] = {"A", "Bb", "B", "C", "Db", "D", "Eb", "E", "F", "Gb", "G", "Ab"};
            
    JUCE_DECLARE_NON_COPYABLE_WITH_LEAK_DETECTOR (NewProjectAudioProcessorEditor)
};
