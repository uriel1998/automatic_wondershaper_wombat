# automatic_wondershaper_wombat
A script in bash (with some assorted tools) to collect info about available bandwidth and to perform traffic shaping


requires speedtest (python or perl version)

Python: https://github.com/sivel/speedtest-cli
Speedtest-cli logs in this manner:

Mon 1 00:01
Ping: 16.828 ms
Download: 14.05 Mbit/s
Upload: 1.02 Mbit/s

Perl: https://metacpan.org/pod/App::SpeedTest
Perl App::SpeedTest logs in this manner:

$ speedtest -1Qv0
DL:   40.721 Mbit/s, UL:   30.307 Mbit/s

In my tests, the Perl module reports significantly *slower* speeds 
across the board than the python version. For comparison, these tests 
were done sequentially with no other traffic on my network (yeah, I 
don't have the fastest internet, which is why this is important to me):

speedtest (perl) - Up:13.120  Down:0.849  
speedtest-cli (python) - Up:16.64 Down:0.91  
speetest.net (web) - Up:17.4 Down:1.06  
speedguide.net (web) - Up:16.61 Down:0.87  

So if you're interested in matching with web-based tools, go with the 
pythonic version. If you're interested in *ensuring* you don't over-
allocate your bandwidth, the perl version will be better. 

Interestingly, the perl version is pretty close to 80% of the bandwidth 
reported by other tools, which is what you need for traffic shaping.