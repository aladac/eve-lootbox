require "yaml"


names = File.readlines('names.txt').map(&:chomp)

output = []

names.each do |name|
  hash = {
    name: name,
    escalates_to: nil
  }
  output.push hash
end

puts output.to_yaml
