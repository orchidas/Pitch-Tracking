#include "MainComponent.h"

//==============================================================================
MainComponent::MainComponent()
{
    // Make sure you set the size of the component after
    // you add any child components.
    for(int i = 0; i < scopeSize; i++)
        scopeData[i] = 0.0f;
    
    startTimer(10);    //timerCallback every 100ms
    setSize (800, 600);

    // Some platforms require permissions to open input channels so request that here
    if (juce::RuntimePermissions::isRequired (juce::RuntimePermissions::recordAudio)
        && ! juce::RuntimePermissions::isGranted (juce::RuntimePermissions::recordAudio))
    {
        juce::RuntimePermissions::request (juce::RuntimePermissions::recordAudio,
                                           [&] (bool granted) { setAudioChannels (granted ? 2 : 0, 2); });
    }
    else
    {
        // Specify the number of input and output channels that we want to open
        setAudioChannels (2, 2);
    }
}

MainComponent::~MainComponent()
{
    // This shuts down the audio device and clears the audio source.
    shutdownAudio();
}

//==============================================================================
void MainComponent::prepareToPlay (int samplesPerBlockExpected, double sampleRate)
{
    // This function will be called when the audio device is started, or when
    // its settings (i.e. sample rate, block size, etc) are changed.

    // You can use this function to initialise any resources you might need,
    // but be careful - it will be called on the audio thread, not the GUI thread.

    // For more details, see the help for AudioProcessor::prepareToPlay()
    
    this->sampleRate = (float)sampleRate;       //set sample rate
    ekf.prepare(this->sampleRate, samplesPerBlockExpected);     //prepare pitch tracker
    prevBufferSilent = true;    //set buffer flag
    nBuffer = 0;
    for(int i = 0; i < scopeSize; i++){
        pitch[i] = 0.0f;        //make sure initial pitch values are not garbage
    }
}

void MainComponent::getNextAudioBlock (const juce::AudioSourceChannelInfo& bufferToFill)
{
    // Your audio-processing code goes here!
    
    //Hoe many input channels?
    const int numInputChannels = bufferToFill.buffer->getNumChannels();
    // How many samples in the buffer for this block?
    const int numSamples = bufferToFill.buffer->getNumSamples();
    
    
    for (int channel = 0; channel < numInputChannels; ++channel)
    {
        float* channelData = bufferToFill.buffer->getWritePointer(0, bufferToFill.startSample);
        
        //we are dealing with single channel data here for pitch detection
        if (channel == 0){
            
            //check if current audio buffer is silent or pitched
            curBufferSilent = ekf.detectSilence(channelData);
            
            //if there is an onset, reset the filter
            if ((prevBufferSilent && !curBufferSilent) || nBuffer == nBufferToReset){
                ekf.findInitialPitch(channelData);
                ekf.resetCovarianceMatrix();
                nBuffer = 0;
                std::cout << "Kalman filter reset" << std::endl;

            }
            
            //track pitch if buffer is not silent - currently pitch stays at 0,
            //this should not happen
            
                
            //update the pitch every 10 samples, otherwise too slow
            for (int i = 0; i < numSamples; i+=10)
            {
                if (pitchIndex == scopeSize){
                    pitchIndex = 0;
                    nextPitchBlockReady = true;
                }
                if (!curBufferSilent)
                    pitch[pitchIndex++]= ekf.kalmanFilter(channelData[i]);
                else
                    pitch[pitchIndex++] = 0.0f;
                
                std::cout << pitch[pitchIndex] << std::endl;
            }
            nBuffer++;
            
            
            prevBufferSilent = curBufferSilent;
        }
    }

    // For more details, see the help for AudioProcessor::getNextAudioBlock()

    // Right now we are not producing any data, in which case we need to clear the buffer
    // (to prevent the output of random noise)
    //.clearActiveBufferRegion();
}

void MainComponent::releaseResources()
{
    // This will be called when the audio device stops, or when it is being
    // restarted due to a setting change.

    // For more details, see the help for AudioProcessor::releaseResources()
}




//==============================================================================
void MainComponent::timerCallback(){
    if (nextPitchBlockReady)
    {
        drawNextFrame();
        nextPitchBlockReady = false;
        repaint();
    }
}

void MainComponent::drawNextFrame() {
    
    
    for (int i = 0; i < scopeSize; ++i)                         // [3]
    {
        //pitch wont exceed half of sample Rate
        float constrainedPitch = juce::jlimit<float>(0.0f, sampleRate/2.0, pitch[i]);
        scopeData[i] = constrainedPitch/(sampleRate/2.0);
        //std::cout << scopeData[i] << std::endl;
    }
}


void MainComponent::paint (juce::Graphics& g)
{

    g.fillAll (juce::Colours::black);
    g.setColour(juce::Colours::orange);
    g.setFont (15.0f);
    
    
    //y axis (pitch) values between 0 and 5000Hz should fit between height 0 and 300
    //x-axis values between 0 and 1s need to fit between width 0 and 600
    
    for (int i = 1; i < scopeSize; ++i)
    {
        auto width  = getLocalBounds().getWidth();
        auto height = getLocalBounds().getHeight();
        
        //jmap (Type sourceValue, Type sourceRangeMin, Type sourceRangeMax,
        // Type targetRangeMin, Type targetRangeMax)
        g.drawLine ({
            
            //plotting on linear scale
            /*(float) juce::jmap (i - 1, 0, scopeSize - 1, 0, width),
            juce::jmap (scopeData[i-1], 0.0f, (float)maxPitch, (float) height, 0.0f),
            (float) juce::jmap (i, 0, scopeSize - 1, 0, width),
            juce::jmap (scopeData[i], 0.0f, (float)maxPitch, (float) height, 0.0f)*/
            
             //normalize pitch values and plot on log scale
             (float) juce::jmap (i - 1, 0, scopeSize - 1, 0, width),
             juce::mapToLog10 (scopeData[i-1], (float) height, 1.0f),
             (float) juce::jmap (i, 0, scopeSize - 1, 0, width),
             juce::mapToLog10 (scopeData[i], (float) height, 1.0f)
        });
    }
}

void MainComponent::resized()
{
    // This is called when the MainContentComponent is resized.
    // If you add any child components, this is where you should
    // update their positions.
}
