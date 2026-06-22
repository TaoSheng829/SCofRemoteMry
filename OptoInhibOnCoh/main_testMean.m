[a,b,c,d]=PL_DOGetDigitalOutputInfo;

PlexDO.h

rand

PL_InitClient 

PL_GetPars

plot(d(258,:));
[n, t, d] = PL_GetADV(s);
   plot(d);
   pause(1);
   
[numDOCards, deviceNumbers, numBits, numLines] = PL_DOGetDigitalOutputInfo
result = PL_DOInitDevice(deviceNumbers(1), 0); 
result = PL_DOClearAllBits(deviceNumbers(1));
for i = 1:10 
    
    PL_DOSetBit(deviceNumbers(1), 1); 

% Wait for approximately 1 second
PL_DOSleep(100);

% Clear bit 1.
PL_DOClearBit(deviceNumbers(1), 1);
PL_DOSleep(rand * 2000);
end
