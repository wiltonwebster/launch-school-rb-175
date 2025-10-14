require "yaml"

list = Psych.load_file("users.yaml")

sum = list.values.map { |attributes| attributes[:interests].size}.inject(:+)

p sum