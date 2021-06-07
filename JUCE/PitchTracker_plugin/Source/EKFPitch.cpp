/*
 ==============================================================================
 
 EKFPitch.cpp
 Created: 4 Jun 2021 3:02:06pm
 Author:  Orchisama Das
 
 ==============================================================================
 */
#include "EKFPitch.h"

//Constructr
EKFPitch::EKFPitch(){}


//Destructor
EKFPitch::~EKFPitch(){}


//initialize before playing
void EKFPitch::prepare(float fs, int bs){
    
    sampleRate = fs;
    bufferSize = bs;
    fftSize = 4*bufferSize;
    Ts = 1.0/sampleRate;
    f0 = 1; amp = 0.001; phi = 0.001*PI;
    
    //define constants
    input.resize(1);                        //this should be a single element vector
    R.resize(1);   R << 1;                  //measurement noise
    Iden << Eigen::Matrix3cf::Identity();   //3x3 complex identity matrix
    H << 0,0.5,0.5;                         //observation matrix
    coeff = 5;                              //adaptive process noise coefficient
    I.real(0); I.imag(1);                   // complex numner 0 + 1i
    unity.real(1); unity.imag(0);           //complex number 1 + 0i
}


//detects if current buffer is silent
bool EKFPitch::detectSilence(const float* channelData){
    float energy = 0.0f;
    
    //calculate energy of buffer
    for (int i = 0; i < bufferSize; i++){
        energy += pow(channelData[i],2);
    }
    if (10*log10(energy) < threshold)
        return true;
    else
        return false;
    
}


/*initial pitch estimate by FFT peak detection, We do this by first
 looking for all local peaks in the magnitude spectrum (values greater
 than neighbouring samples). Then, to pick the fundamental, we find
 the first local peak that exceeds a threshold. The threshold is half
 the maximum peak value*/

void EKFPitch::findInitialPitch(const float* channelData){
    
    
    //fftData needs to be twice the size of the input buffer,
    // with the second half containing only zeros, and first
    // half containing the buffer.
    float fftData[fftSize];
    for(int i = 0; i < fftSize; i++){
        if (i < bufferSize)
            fftData[i] = channelData[i];
        else
            fftData[i] = 0.0f;
    }
    
    
    //window the data
    juce::dsp::WindowingFunction<float> window(fftSize,
                                               juce::dsp::WindowingFunction<float>::hann);
    window.multiplyWithWindowingTable(fftData, fftSize);
    
    //do a complex FFT, this needs complex input and output vectors
    std::complex <float> complexFFTData[fftSize];
    for(int i = 0; i < fftSize; i++){
        complexFFTData[i].real(fftData[i]);
        complexFFTData[i].imag(0.0f);
    }
    
    
    //calculate complex FFT
    std::complex <float> fftOutput[fftSize];
    juce::dsp::FFT forwardFFT(log2(fftSize));
    forwardFFT.perform(complexFFTData, fftOutput, false);
    
    
    //make magnitude and phase vectors separately
    float fftMag[fftSize/2]; float fftAng[fftSize/2];
    //look at first half of data only, since it is symmetric
    for(int i = 0; i < fftSize/2; i++){
        fftMag[i] = std::abs(fftOutput[i]);
        fftAng[i] = std::arg(fftOutput[i]);
    }
    
    
    //multiply with exponential window to reduce magnitude of harmonics
    /*int alpha = 3;
     for (int i = 0; i < fftSize/2; i++)
     fftMag[i] *= exp(-0.5*alpha*i/(fftSize-1));*/
    
    
    //get dB magnitude of FFT vector
    float dbFFT[fftSize/2];
    for(int i = 0; i < fftSize/2; i++){
        dbFFT[i] = juce::Decibels::gainToDecibels(fftMag[i], negInf);
    }
    
    
    //discard peaks below 50Hz
    int start = 50*fftSize/(int)sampleRate;
    
    
    //find max peak and set the threshold to its half
    float peakThreshold = negInf;
    for (int i = start+1; i < fftSize/2; i++){
        if (dbFFT[i] > peakThreshold)
            peakThreshold = dbFFT[i];
    }
    peakThreshold *= 0.5;
    
    
    // find first peak in FFT
    //for parabolic interpolation around peak
    std::pair<float, float> peak_interp;
    for (int i = start+1; i < fftSize/2-1; i++){
        if ((dbFFT[i] > dbFFT[i-1]) && (dbFFT[i] > dbFFT[i+1]))
        {
            if(dbFFT[i] > peakThreshold){
                peak_interp = parabolicInterpolation(dbFFT[i-1], dbFFT[i], dbFFT[i+1]);
                f0 = (sampleRate/(float)fftSize) * ((float)i + peak_interp.first);
                amp =  juce::Decibels::decibelsToGain(peak_interp.second)/fftSize;
                phi = fftAng[i];
                
                std::cout << f0 << std::endl;
                return;
            }
            
        }
    }
}




//parabolic interpolation on FFT peak magnitude
std::pair<float, float> EKFPitch::parabolicInterpolation(float a, float b, float c){
    std::pair<float, float> peak;
    peak.first = 0.5*((a-c)/(a - 2*b + c +
                             std::numeric_limits<float>::epsilon())); //peak position
    peak.second = b - 0.25*(a-c)*peak.first;  //peak magnitude
    return peak;
}


//rest the covariance matrix when transitioning from silent to pitched buffer
void EKFPitch::resetCovarianceMatrix(){
    
    // covariance matrix is just a bunch of zeros
    P_ << 0,0,0,
    0,0,0,
    0,0,0;
    
    // initial state vector
    x_ << std::exp(PI*2*I*f0*Ts), amp*std::exp(2*PI*I*f0*Ts+I*phi),
    amp*std::exp(-2*PI*I*f0*Ts-I*phi);
}


/*ECKF pitch tracker implementation, takes the current audio
 sample as input and returns the estimated pitch. This is a
 sanoke-synchronous pitch tracker. For more information, see
 O. Das et al. "Real-time pitch tracking in audio signals with
 the Extended Complex Kalman Filter" - DAFx 2017.*/

float EKFPitch::kalmanFilter(const float audioSample){
    
    //input data must be converted to Eigen's complex vector
    input << audioSample;
    //Kalman filter update
    K = (P_*H.adjoint()) * (H*P_*H.adjoint()+R).inverse();
    P = P_ - K*H*P_;
    x = x_ + K*(input - H*x_);
    x_next << x(0), x(0)*x(1), x(2)/x(0);
    F << 1,0,0,
    x(1),x(0),0,
    -x(2)/(x(0)*x(0)),0, unity/x(0);
    D = input - H*x;
    Q = pow(10,-(coeff-std::abs(D(0))));
    
    P_next = F*P*F.adjoint() + Q*Iden;
    f0 = std::abs(std::log(x(0))/(PI*2*I*Ts));
    
    //next iteration
    P_ = P_next;
    x_ = x_next;
    
    return f0;
}

