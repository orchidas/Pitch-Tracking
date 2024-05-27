/*
  ==============================================================================

    This file contains the basic framework code for a JUCE plugin processor.

  ==============================================================================
*/

#pragma once

#include <JuceHeader.h>
#include "EKFPitch.h"
#include <Eigen/Dense>

//==============================================================================
/**
*/
class NewProjectAudioProcessor  : public juce::AudioProcessor
{
public:
    //==============================================================================
    NewProjectAudioProcessor();
    ~NewProjectAudioProcessor() override;

    //==============================================================================
    void prepareToPlay (double sampleRate, int samplesPerBlock) override;
    void releaseResources() override;

   #ifndef JucePlugin_PreferredChannelConfigurations
    bool isBusesLayoutSupported (const BusesLayout& layouts) const override;
   #endif

    void processBlock (juce::AudioBuffer<float>&, juce::MidiBuffer&) override;

    //==============================================================================
    juce::AudioProcessorEditor* createEditor() override;
    bool hasEditor() const override;

    //==============================================================================
    const juce::String getName() const override;

    bool acceptsMidi() const override;
    bool producesMidi() const override;
    bool isMidiEffect() const override;
    double getTailLengthSeconds() const override;

    //==============================================================================
    int getNumPrograms() override;
    int getCurrentProgram() override;
    void setCurrentProgram (int index) override;
    const juce::String getProgramName (int index) override;
    void changeProgramName (int index, const juce::String& newName) override;

    //==============================================================================
    void getStateInformation (juce::MemoryBlock& destData) override;
    void setStateInformation (const void* data, int sizeInBytes) override;
    int getBufferSize();
    
    enum
    {
        pitchSize = 128,        //size of pitch to be stored
        nBufferToReset = 20,    // reset the filter after these many buffers
        nUpdate =  4,           //update KF every nUpdate samples, must be a divisor of bufferSize
        minPitch = 50           //minimum possible pitch in Hz
        
    };
    
    bool nextPitchBlockReady = false;
    float pitch [pitchSize];        //pitch values

private:
    EKFPitch ekf;           //instance of pitch tracker class
    
    bool prevBufferSilent;      //flag to check if previous buffer was silent
    bool curBufferSilent;       //flag to check if current buffer is silent
    int pitchIndex = 0;
    int nBuffer;                //keep track of buffers
    
    //==============================================================================
    JUCE_DECLARE_NON_COPYABLE_WITH_LEAK_DETECTOR (NewProjectAudioProcessor)
};
