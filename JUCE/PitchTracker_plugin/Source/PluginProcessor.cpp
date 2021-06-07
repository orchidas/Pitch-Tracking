/*
  ==============================================================================

    This file contains the basic framework code for a JUCE plugin processor.

  ==============================================================================
*/

#include "PluginProcessor.h"
#include "PluginEditor.h"

//==============================================================================
NewProjectAudioProcessor::NewProjectAudioProcessor()
#ifndef JucePlugin_PreferredChannelConfigurations
     : AudioProcessor (BusesProperties()
                     #if ! JucePlugin_IsMidiEffect
                      #if ! JucePlugin_IsSynth
                       .withInput  ("Input",  juce::AudioChannelSet::stereo(), true)
                      #endif
                       .withOutput ("Output", juce::AudioChannelSet::stereo(), true)
                     #endif
                       )
#endif
{
    //make sure pitch starts at 0
    for(int i = 0; i < pitchSize; i ++){
        pitch[i] = 0.0f;
    }
    
}

NewProjectAudioProcessor::~NewProjectAudioProcessor()
{
}

//==============================================================================
const juce::String NewProjectAudioProcessor::getName() const
{
    return JucePlugin_Name;
}

bool NewProjectAudioProcessor::acceptsMidi() const
{
   #if JucePlugin_WantsMidiInput
    return true;
   #else
    return false;
   #endif
}

bool NewProjectAudioProcessor::producesMidi() const
{
   #if JucePlugin_ProducesMidiOutput
    return true;
   #else
    return false;
   #endif
}

bool NewProjectAudioProcessor::isMidiEffect() const
{
   #if JucePlugin_IsMidiEffect
    return true;
   #else
    return false;
   #endif
}

double NewProjectAudioProcessor::getTailLengthSeconds() const
{
    return 0.0;
}

int NewProjectAudioProcessor::getNumPrograms()
{
    return 1;   // NB: some hosts don't cope very well if you tell them there are 0 programs,
                // so this should be at least 1, even if you're not really implementing programs.
}

int NewProjectAudioProcessor::getCurrentProgram()
{
    return 0;
}

void NewProjectAudioProcessor::setCurrentProgram (int index)
{
}

const juce::String NewProjectAudioProcessor::getProgramName (int index)
{
    return {};
}

void NewProjectAudioProcessor::changeProgramName (int index, const juce::String& newName)
{
}

//==============================================================================
void NewProjectAudioProcessor::prepareToPlay (double sampleRate, int samplesPerBlock)
{
    // Use this method as the place to do any pre-playback
    // initialisation that you need..
    ekf.prepare((float)sampleRate, samplesPerBlock);     //prepare pitch tracker
    prevBufferSilent = true;                                    //set buffer flag
    nBuffer = 0;
    for(int i = 0; i < pitchSize; i++){
        pitch[i] = 0.0f;                                //make sure initial pitch values are not garbage
    }
}

void NewProjectAudioProcessor::releaseResources()
{
    // When playback stops, you can use this as an opportunity to free up any
    // spare memory, etc.
}

#ifndef JucePlugin_PreferredChannelConfigurations
bool NewProjectAudioProcessor::isBusesLayoutSupported (const BusesLayout& layouts) const
{
  #if JucePlugin_IsMidiEffect
    juce::ignoreUnused (layouts);
    return true;
  #else
    // This is the place where you check if the layout is supported.
    // In this template code we only support mono or stereo.
    if (layouts.getMainOutputChannelSet() != juce::AudioChannelSet::mono()
     && layouts.getMainOutputChannelSet() != juce::AudioChannelSet::stereo())
        return false;

    // This checks if the input layout matches the output layout
   #if ! JucePlugin_IsSynth
    if (layouts.getMainOutputChannelSet() != layouts.getMainInputChannelSet())
        return false;
   #endif

    return true;
  #endif
}
#endif

void NewProjectAudioProcessor::processBlock (juce::AudioBuffer<float>& buffer, juce::MidiBuffer& midiMessages)
{
    //Hoe many input channels?
    const int numInputChannels = buffer.getNumChannels();
    // How many samples in the buffer for this block?
    const int numSamples = buffer.getNumSamples();
    
    
    for (int channel = 0; channel < numInputChannels; ++channel)
    {
        const float* channelData = buffer.getReadPointer(0);
        float f0;
        
        //we are dealing with single channel data here for pitch detection
        if (channel == 0){
            
            //check if current audio buffer is silent or pitched
            curBufferSilent = ekf.detectSilence(channelData);
            
            //if there is an onset, reset the filter
            if ((prevBufferSilent && !curBufferSilent)
                || ((nBuffer >= nBufferToReset) && !curBufferSilent))
            {
                ekf.findInitialPitch(channelData);
                ekf.resetCovarianceMatrix();
                nBuffer = 0;
                //std::cout << "Kalman filter reset" << std::endl;
            }
            
           
            //update the pitch every uUpdate samples, otherwise too slow
            for (int i = 0; i < numSamples; i+=nUpdate)
            {
                if (pitchIndex >= pitchSize){
                    pitchIndex = 0;
                    nextPitchBlockReady = true;
                }
                if (curBufferSilent){
                    pitch[pitchIndex++] = 0.0f;
                }
                else{
                    f0 = ekf.kalmanFilter(channelData[i]);
                    pitch[pitchIndex++] = f0 < minPitch ? 0.0f : f0;
                }
                //std::cout << pitch[pitchIndex] << std::endl;
                
            }
            nBuffer++;
            
            prevBufferSilent = curBufferSilent;
        }
    }
    
}
    

//==============================================================================
bool NewProjectAudioProcessor::hasEditor() const
{
    return true; // (change this to false if you choose to not supply an editor)
}

juce::AudioProcessorEditor* NewProjectAudioProcessor::createEditor()
{
    return new NewProjectAudioProcessorEditor (*this);
}

//==============================================================================
void NewProjectAudioProcessor::getStateInformation (juce::MemoryBlock& destData)
{
    // You should use this method to store your parameters in the memory block.
    // You could do that either as raw data, or use the XML or ValueTree classes
    // as intermediaries to make it easy to save and load complex data.
}

void NewProjectAudioProcessor::setStateInformation (const void* data, int sizeInBytes)
{
    // You should use this method to restore your parameters from this memory block,
    // whose contents will have been created by the getStateInformation() call.
}

int NewProjectAudioProcessor::getBufferSize(){
    return ekf.bufferSize;
}

//==============================================================================
// This creates new instances of the plugin..
juce::AudioProcessor* JUCE_CALLTYPE createPluginFilter()
{
    return new NewProjectAudioProcessor();
}
