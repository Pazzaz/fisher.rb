# frozen_string_literal: true
class FishEvaluator
	def initialize(**args)
		@stack = args[:stack] || []
		@debugging = !!args[:debugging]
		if args[:input]
			@stdin = false
			@input = args[:input]
		else
			@stdin = true
		end
		@sea = parse_sea(args[:code])
		@delay = (args[:delay] || 0) / 1000.0
		@frame = 0
		@registers = [nil]
		@string_parsing = false
		@done = false
		@location = [0,0]
		@direction = 'right'
		@output = String.new
		@current_row = ""
		@stacks = [@stack]
	end

	def parse_sea(code)
		sea = code.split("\n").map do |i|
			i = i.split('').map! do |e|
				if e == " "
					0
				else
					e.ord
				end
			end
		end
		return sea
	end

	def get_input
		if @stdin
			value = STDIN.getc
		else
			value = @input.shift
		end
		if value.nil?
			-1
		else
			value.ord
		end
	end

	def start_loop
		until @done do
			step_frame
		end
	end

	def step_frame
		@frame += 1
		fetch_value = @sea.fetch(@location[1], []).fetch(@location[0], 0)
		command = (fetch_value != 0 ? fetch_value.chr : " ")
		if @string_parsing
			if command == ?' || command == ?"
				@string_parsing = false
			else
				@stack << command.ord
			end
		else
			case command
			when '>'
				@direction = 'right'
			when '<'
				@direction = 'left'
			when 'v'
				@direction = 'down'
			when '^'
				@direction = 'up'
			when 'x'
				@direction = ['right','left','down','up'].sample
			when '/'
				@direction =
				case @direction
				when 'right' then 'up'
				when 'left' then 'down'
				when 'down' then 'left'
				when 'up' then 'right'
				end
			when '\\'
				@direction =
				case @direction
				when 'right' then 'down'
				when 'left' then 'up'
				when 'down' then 'right'
				when 'up' then 'left'
				end
			when '|'
				@direction =
				case @direction
				when 'right' then 'left'
				when 'left' then 'right'
				end
			when '_'
				@direction =
				case @direction
				when 'up' then 'down'
				when 'down' then 'up'
				end
			when '#'
				@direction =
				case @direction
				when 'right' then 'left'
				when 'left' then 'right'
				when 'down' then 'up'
				when 'up' then 'down'
				end
			when '+'
				@stack << @stack.pop(2).reduce(:+)
			when '-'
				@stack << @stack.pop(2).reduce(:-)
			when '*'
				@stack << @stack.pop(2).reduce(:*)
			when ','
				@stack << @stack.pop(2).reduce{|a,b| (a / b.to_f).round(8)}
			when '%'
				@stack << @stack.pop(2).reduce(:%)
			when ?', ?"
				@string_parsing = true
			when 'o'
				@output = @stack.pop.chr
			when 'n'
				value = @stack.pop
				@output = value.to_i == value ? value.to_i.to_s : value.to_s
			when /[0-9a-f]/
				@stack << command.to_i(16)
			when '='
				a, b = @stack.pop(2)
				@stack << (a == b ? 1 : 0)
			when ')'
				a, b = @stack.pop(2)
				@stack << (a > b ? 1 : 0)
			when '('
				a, b = @stack.pop(2)
				@stack << (a < b ? 1 : 0)
			when '!'
				move_fish
			when '?'
				value = @stack.pop
				if value == 0
					move_fish
				end
			when ':'
				@stack << @stack[-1]
			when '~'
				@stack.pop
			when '$'
				@stack[-1], @stack[@stack.length - 2] = @stack[@stack.length - 2], @stack[-1]
			when '@'
				@stack += @stack.pop(3).rotate!(2)
			when 'l'
				@stack << @stack.size
			when 'r'
				@stack.reverse!
			when '['
				length = @stack.pop
				if length == 0
					@stacks[-1], new_stack = @stack, []
				else
					@stacks[-1], new_stack = @stack[0, (@stack.size - length)], @stack[(@stack.size - length), (@stack.size)]
				end
				@stacks << new_stack
				@stack = new_stack
				@registers << nil
			when ']'
				old_stack = @stacks.pop()
				if @stacks.empty?
					@stacks << []
				else
					@stacks[-1] += old_stack
				end
				@stack = @stacks[-1]

				@registers.pop()
				if @registers.size > 1
					@registers.pop()
				else
					@registers[0] = nil
				end
			when '}'
				@stack.rotate!(-1)
			when '{'
				@stack.rotate!(1)
			when 'g'
				x, y = @stack.pop(2)
				fetch_value = @sea.fetch(y, []).fetch(x, 0)
				@stack << (fetch_value != 0 ? fetch_value : 0)
			when 'p'
				z, x, y = @stack.pop(3)
				@sea[y][x] = z

				# May add outside of the map.
				@sea[y].map! {|n| n.nil? ? 0 : n}
			when 'i'
				@stack << get_input
			when '.'
				y, x = @stack.pop(), @stack.pop()
				@location = [x.to_i, y.to_i]
			when '&'
				if @registers[-1].nil?
					@registers[-1] = @stack.pop
				else
					@stack << @registers[-1]
					@registers[-1] = nil
				end
			end
		end
		if @debugging
			draw_sea
		else
			print_output
		end

		sleep(@delay)
		move_fish
		if (command == ';') && (@string_parsing == false)
			@done = true
		end
	end

	def move_fish
		case @direction
		when 'right'
			@location[0] += 1
			@location[0] = 0 if @location[0] > (@sea[@location[1]].size - 1)
		when 'left'
			@location[0] -= 1
			@location[0] = (@sea[@location[1]].size - 1) if @location[0] < 0
		when 'down'
			@location[1] += 1
			@location[1] = 0 if @location[1] > (@sea.size - 1)
		when 'up'
			@location[1] -= 1
			@location[1] = (@sea.size - 1) if @location[1] < 0
		end
	end

	def draw_sea
		rows = []
		@sea.size.times do |y|
			row = ''
			@sea.max_by(&:size).size.times do |x|
				value = @sea.fetch(y, []).fetch(x, 0)
				if value.chr =~ /[[:print:]]/
					if @location[0] == x && @location[1] == y
						row += "\e[31;47m#{value.chr}\e[0m"
					else
						row += value.chr
					end
				elsif value == 0
					row += ' '
				else
					row += '▯'
				end
			end
			rows << row
		end
		print "\e[" + '?25' + 'l'
		print ("\r" + ("\e[A"*(@sea.size + 3)) + "\e[K") if @frame != 1
		if @output != ""
			@current_row += @output
			puts @current_row + "\e[K"
			if @output == "\n"
				@current_row.clear
			end
			@output.clear
		else
			puts @current_row + "\e[K"
		end
		puts '―' * @sea.max_by(&:size).size + "\e[K"
		puts rows.join("\n")
		puts "#{@frame}#{@stacks}#{@stack}\e[K"
		print "\e[" + '?25' + 'h'
	end

	def print_output
		print @output
		@output.clear
	end
end

def testing
	arguments = {}
	if ARGV.include?('-c')
		arguments[:code] = ARGV[ARGV.index('-c') + 1]
	else
		arguments[:code] = File.read(ARGV[0])
	end
	if ARGV.include?('-i')
		arguments[:input] = ARGV[ARGV.index('-i') + 1].split('').map(&:ord)
		arguments[:input] << "\n".ord
	end
	if ARGV.include?('-v')
		arguments[:stack] = ARGV[ARGV.index('-v') + 1].split(' ').map(&:to_i)
	end
	if ARGV.include?('-d')
		arguments[:debugging] = true
	end
	if ARGV.include?('-t')
		arguments[:delay] = ARGV[ARGV.index('-t') + 1].to_i
	end
	fisher = FishEvaluator.new(arguments)
	fisher.start_loop
end

testing