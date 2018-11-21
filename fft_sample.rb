#sample fft
require 'rx'

def fft a
    n = a.size
    return a if n == 1
    w = Complex.polar(1, -2 * Math::PI / n)
    a1 = fft((0 .. n / 2 - 1).map {|i| a[i] + a[i + n / 2] })
    a2 = fft((0 .. n / 2 - 1).map {|i| (a[i] - a[i + n / 2]) * (w ** i) })
    a1.zip(a2).flatten
end

N = 64
a = (0...N).map do |n|
  v = Math.sin(3 * 2 * Math::PI * n / N) * 2
  v + Math.cos(5 * 2 * Math::PI * n / N)
end

=begin
a.map do |v|
    s = [" "] * 20
    min, max = [(-v * 3 + 10).round, 10].sort
    s[min..max] = ["#"] * (max - min)
    s
  end.transpose.each do |l|
    puts l.join
end
=end

def fft_p a
    fft(a)[0, N/2].each_with_index do |v, n|
        next if n == 0
        puts "%2d Hz: %.3f" % [n, v.abs / (N / 2)]
    end
end

source = Rx::Observable.generate(
    0,1..3
)

subscription = source.subscribe(
    lambda {|x|
        #puts 'Next: ' + x.to_s
        fft_p a
    },
    lambda {|err|
        puts 'Error: ' + err.to_s
    },
    lambda {
        puts 'Completed'
    }
)

