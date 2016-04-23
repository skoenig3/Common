x = reshape(1:100,[10 10]);
x = x';
x(90:100)= NaN;
x(85:87) = NaN;
tic
y = circshift_row(x);
toc
%%

x = randi(1000,1000);
tic
y = circshift_cvtnew(x);
toc

tic
y = circshift_row(x);
toc

tic
y = circshift_acrosstrials(x);
toc