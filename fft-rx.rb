require 'rx'

subject_puts = Rx::Subject.new

subscription_puts = subject_puts.subscribe(Rx::Observer.create(
    lambda {|x|
        puts 'Puts_Next: ' + x.to_s
        x[0, N/2].each_with_index do |v, n|
            next if n == 0
            puts "%2d Hz: %.3f" % [n, v.abs / (N / 2)]
        end
    },
    lambda {|err|
        puts 'Error: ' + err.to_s
    },
    lambda { puts 'Completed'}
))

#nで定まる処理を,subjectのobserverに与え,_nextに繋げる
def subscribe_split(n,subject,subject_next) #n:分割前
    subject.subscribe(Rx::Observer.create(
        lambda {|array|
            puts "split.n: " + n.to_s 
            @n = n/2 # @n:分割"後"の各配列(a1,a2,..)の長さ
            @w = Complex.polar(1, -2 * Math::PI / (@n*2))
            @w_i = [*0 ... @n].map{|i| @w ** i} #w**iを事前計算
            return subject_next.on_next(p array) if @n < 1
            @r = (0 ... array.size).map{|i|
                @ii = i % @n 
                if (i/@n).even? 
                    then array[i] + array[i + @n]
                    else (array[i - @n] - array[i]) * @w_i[@ii]
                end}

            p @r
            subject_next.on_next @r
        },
        lambda {|err|
            puts 'Error: ' + err.to_s
        },
        lambda { puts 'Completed'}
    ))
end

#nを指定した,subscriptionを生成する
def subscribe_merge(n,subject,subject_next) 
    subject.subscribe(Rx::Observer.create(
        lambda {|array|
            @n = n  # 統合"後"の各配列(a1 + a2,..)の長さ
            puts "merge.n: " + @n.to_s
            return subject_next.on_next(p array) if @n == 2
            @r = (0 ... array.size).map{|i|
                @ii = i % @n #相対添え字
                if @ii.even? 
                    then array[(@ii / 2) + (i - @ii)]
                    else array[(@ii -1)/2 + @n/2 + (i - @ii)]
                end}
            p @r
            subject_next.on_next @r
        },
        lambda {|err|
            puts 'Error: ' + err.to_s
        },
        lambda { puts 'Completed_merge'}
    ))
end

N = 64 #a.size
a = (0...N).map do |n|
  v = Math.sin(3 * 2 * Math::PI * n / N) * 2 
  v + Math.cos(5 * 2 * Math::PI * n / N)
end
puts "a: " + a.to_s


def fft_rx_set (size,subjects,end_subject) #dataSize,生成サブジェクト保持用配列,終端サブジェクト
    return if size < 2 
    n = size
    while n >= 1 do
        subscribe_split(n ,subjects.last ,subjects.push(Rx::Subject.new).last)
        n /= 2
    end
    n = 1
    while n < size do
        n *= 2
        break if n == size
        subscribe_merge(n ,subjects.last ,subjects.push(Rx::Subject.new).last)
    end
        subscribe_merge(n ,subjects.last ,subjects.push(end_subject).last)
end

subjects = [Rx::Subject.new]
fft_rx_set(a.size,subjects,subject_puts)
subjects.first.on_next(a)



