function [controlfit] = controlfit (dat1, dat2)

reg = polyfit(dat2, dat1, 1);

a = reg(1);
b = reg(2);

if a < 0
   warning('Regression coefficient is negative - changed to 1');
   a = 1;
   b = mean(dat1) - mean(dat2);
end

controlfit = a.*dat2(:) + b;
