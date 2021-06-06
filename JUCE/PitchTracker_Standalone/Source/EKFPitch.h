/*
  ==============================================================================

    EKFPitch.h
    Created: 4 Jun 2021 3:02:06pm
    Author:  Orchisama Das

  ==============================================================================
*/

#pragma once
#include "JuceHeader.h"
#include <Eigen/Dense>
#include <complex>
#include <cmath>

class EKFPitch{

public:
    
    EKFPitch();
    ~EKFPitch();
    
    void prepare(float sampleRate, int bufferSize);         //initialize
    bool detectSilence(const float* channelData);           //detects if current buffer is silent
    void findInitialPitch(const float* channelData);        //initial pitch estimate by FFT peak detection
    void resetCovarianceMatrix();                           // resent error covariance matrix and re-initialize                                                         filter
    float kalmanFilter(const float audioSample);             // EKF implementation
    std::pair<float, float> parabolicInterpolation(
                            float, float, float);           //parabolic interpolation on FFT peak magniutde
    
    float f0, phi, amp;     //instantaneous frequency, phase and amplitude
    int bufferSize;         //buffer size
    


    
private:
    float sampleRate;                           //sample rate
    float Ts;                                   //inverse of sampleRate
    const float threshold = -40.0f;             //energy threshold for detecting silence
    const float PI = std::acos(-1);             //pi
    const float negInf = -150.f;                //peak value at negative infinity
    int fftSize;                                //FFT size
    std::complex<float> I;                      //Imaginary number i
    std::complex<float> unity;                  //Real number 1
    
    
    
    //Kalman filter parameters
    Eigen::Matrix3cf P_;            //previous error covariance matrix
    Eigen::Matrix3cf P;             //current error covariance matrix
    Eigen::Matrix3cf P_next;        //future error covariance matrix
    Eigen::Vector3cf x_;            //previous state vector
    Eigen::Vector3cf x;             //current state vector
    Eigen::Vector3cf x_next;        //future state vector
    Eigen::VectorXcf input;         //input data (has to be an Eigen structure)
    Eigen::RowVector3cf H;          //observation vector
    Eigen::Matrix3cf F;             //State transition matrix
    Eigen::VectorXcf K;             //Kalman gain
    Eigen::VectorXcf D;             //temporary variable, stores difference between data and prediction
    Eigen::VectorXcf R;             //process noise
    Eigen::Matrix3cf Iden;          //identity matrix
    
    float Q;                        //process noise
    float coeff;                    //adaptive process noise coefficient,
                                    //determines smoothness of pitch trajectory
    
};
