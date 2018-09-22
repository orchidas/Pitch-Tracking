<h1>Pitch detection algorithms in MATLAB</h1>

<h4>Methods implemented:</h4>
<ul>
<li><b>YIN ESTIMATOR</b> - <i>YIN, a fundamental frequency estimator for speech and music </i> - Alain de Cheveigné, Hideki Kawahara - 
<i>Journal of Acoustical Society of America, 2002.</i></li>
<p><li><b>CEPSTRUM</b> - <i>Cepstrum Pitch Determination</i> - A.M.Noll - <i>Journal of Acoustical Society of America, 1967.</i>
</li></p>
<p><li><b>MAXIMUM LIKELIHOOD</b> - <i>Maxmium Likelihood Pitch Estimation</i> - James D.Wise, James R.Caprio, Thomas W.Parks - 
<i>IEEE Transactions on Acoustics, Speech and Signal Processing, 1976.</i></li><p>
<li><b>EXTENDED KALMAN FILTER</b> - <i>Real-time Pitch Tracking in Audio Signals with the Extended Complex Kalman Filter </i> - Orchisama Das, Julius O. Smith, Chris Chafe - to appear in <i> Digital Audio Effects Conference (DAFx 2017) .</i></li></p>
</ul>
<p>
The algorithms have been tested successfully on a number of cello recordings downloaded from <a href = "http://theremin.music.uiowa.edu/MIS.html#">
this</a> link.</p>
<p>
This <a href = https://github.com/orchidas/Pitch-Tracking/tree/master/eckf_pitch_final>subfolder</a> contains programs that employ the Extended Kalman Filter in Pitch Tracking. The ECKF performs sample-synchronous pitch tracking, unlike the other algorithms that perform block based pitch detection. This is a novel algorithm to be published in the proceedings of DAFx. The paper will be uploaded soon. 
</p>
