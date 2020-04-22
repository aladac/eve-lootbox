require "bundler"
Bundler.require

require "yaml"

class Util
  def self.data_loader(name)
    YAML.load_file("data/#{name}.yml").map { |h| OpenStruct.new(h) }
  end
end

class Anom
  attr_accessor :id, :name, :escalates_to, :faction_id

  def initialize(anom)
    @id = anom.id
    @name = anom.name
    @escalates_to = anom.escalates_to
    @faction_id = anom.faction_id
  end

  def self.all
    Util.data_loader(:anoms).map { |a| Anom.new(a) }
  end

  def escalation
    Ded.all.select { |d| d.id == @escalates_to }.first
  end
end

class Ded
  attr_accessor :id, :name, :escalates_from, :faction_id

  def initialize(ded)
    @id = ded.id
    @name = ded.name
    @escalates_from = ded.escalates_from
    @faction_id = ded.faction_id
  end

  def self.all
    Util.data_loader(:deds).map { |a| Ded.new(a) }
  end
end

binding.pry

anoms = data_loader(:anoms)
bosses = data_loader(:bosses)
deds = data_loader(:deds)

get '/' do
  @deds = deds
  @anoms = anoms
  @bosses = bosses
  slim :index
end
