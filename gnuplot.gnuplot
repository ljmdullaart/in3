set terminal png size 400,300 enhanced font "Helvetica,8"
set output 'gnuplot.png'
plot sin(x) title 'Sine Function', tan(x) title 'Tangent'
