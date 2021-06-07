#pragma once

#include <JuceHeader.h>
#include <Eigen/Dense>
#include "EKFPitch.h"

//==============================================================================
/*
    This component lives inside our window, and this is where you should put all
    your controls and content.
*/
class MainComponent  : public juce::AudioAppComponent,
                       private juce::Timer
{
public:
    //==============================================================================
    MainComponent();
    ~MainComponent() override;

    //==============================================================================
    void prepareToPlay (int samplesPerBlockExpected, double sampleRate) override;
    void getNextAudioBlock (const juce::AudioSourceChannelInfo& bufferToFill) override;
    void releaseResources() override;
    
    //==============================================================================
    void paint (juce::Graphics& g) override;
    void resized() override;
    void timerCallback() override;
    void drawNextFrame();

    
    enum
    {
        pitchSize = 128,        //size of pitch to be stored
        scopeSize = 8192,      //size of data to be displayed
        nBufferToReset = 20,    // reset the filter after these many buffers
        minPitch = 50,          //minimum pitch in Hz
        maxPitch = 5000,        //maximum pitch
        nUpdate =  4            //update KF every nUpdate samples, must be a divisor of bufferSize
    };
    

private:
    //==============================================================================
    // Your private member variables go here...
    EKFPitch ekf;           //instance of pitch tracker class
    
    bool prevBufferSilent;      //flag to check if previous buffer was silent
    bool curBufferSilent;       //flag to check if current buffer is silent
    int pitchIndex = 0;
    int nBuffer;                //keep track of buffers
    
    bool nextPitchBlockReady = false;       //is next block ready for display?
    float pitch [pitchSize];                //pitch values to be stored
    float scopeData [scopeSize];            //data that is plotted
    float sampleRate;


    JUCE_DECLARE_NON_COPYABLE_WITH_LEAK_DETECTOR (MainComponent)
};
