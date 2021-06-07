#include "MainComponent.h"

//==============================================================================
MainComponent::MainComponent()
{
    // Make sure you set the size of the component after
    // you add any child components.
    for(int i = 0; i < scopeSize; i++)
        scopeData[i] = 0.0f;
    
    startTimer(50);    //timerCallback every 100ms
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
    
    this->sampleRate = (float)sampleRate;                       //set sample rate
    ekf.prepare(this->sampleRate, samplesPerBlockExpected);     //prepare pitch tracker
    prevBufferSilent = true;                                    //set buffer flag
    nBuffer = 0;
    for(int i = 0; i < pitchSize; i++){
        pitch[i] = 0.0f;                                //make sure initial pitch values are not garbage
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
        const float* channelData = bufferToFill.buffer->getReadPointer(0, bufferToFill.startSample);
        float f0;
        
        //we are dealing with single channel data here for pitch detection
        if (channel == 0){
            
            //check if current audio buffer is silent or pitched
            curBufferSilent = ekf.detectSilence(channelData);
            
            //if there is an onset, reset the filter
            if ((prevBufferSilent && !curBufferSilent)
                || ((nBuffer >= nBufferToReset) && !curBufferSilent))
            {
                ekf.findInitialPitchFFT(channelData);
                ekf.resetCovarianceMatrix();
                nBuffer = 0;
                //std::cout << "Kalman filter reset" << std::endl;
            }
            
            /*if (curBufferSilent)
                std::cout << "silent buffer" << std::endl;
            else
                std::cout << "not silent" << std::endl;*/
                
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
                    pitch[pitchIndex++] = f0 < minPitch? 0.0f : f0;
                }
                //std::cout << pitch[pitchIndex] << std::endl;

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
    if (nextPitchBlockReady){
        //std::cout << "Next block ready to print" << std::endl;
        drawNextFrame();
        nextPitchBlockReady = false;
        repaint();
    }
}

void MainComponent::drawNextFrame() {
    
    
    for (int i = scopeSize-1; i >= 0; i--)
    {
        //shift existing samples to the right
        if (i >= pitchSize)
            scopeData[i]  = scopeData[i-pitchSize];
        else{
            //fill the first half with new pitch samples
            //pitch wont exceed half of sample Rate
            float constrainedPitch = juce::jlimit<float>(0.0f, sampleRate/2.0, pitch[i]);
            scopeData[i] = constrainedPitch/(sampleRate/2.0);
            //scopeData[i] = constrainedPitch;

        }
    }
}


void MainComponent::paint (juce::Graphics& g)
{

    g.fillAll (juce::Colours::black);
    g.setColour(juce::Colours::orange);
    g.setFont (15.0f);
    
    
    for (int i = 1; i < scopeSize; ++i)
    {
        auto width  = getLocalBounds().getWidth();
        auto height = getLocalBounds().getHeight();
        
        //Pitch values should fit within the height of the screen. Use jmap
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
