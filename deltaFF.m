function [normDat] = deltaFF (dat1, controlFfit)
    
normDat = ((dat1 - controlFfit)./ controlFfit)*100; %this gives deltaF/F - *100 = % dF/F?