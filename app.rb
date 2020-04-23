require "bundler"
Bundler.require

require "yaml"
require "active_support/number_helper"

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
  attr_accessor :id, :name, :escalates_from, :faction_id, :level, :parts

  def initialize(ded)
    @parts = ded.parts
    @level = ded.level
    @id = ded.id
    @name = ded.name
    @escalates_from = ded.escalates_from
    @faction_id = ded.faction_id
  end

  def self.all
    Util.data_loader(:deds).map { |a| Ded.new(a) }
  end

  def self.find(id)
    Ded.all.select { |ded| ded.id == id }.first
  end

  def boss
    Boss.all.select { |b| b.boss_of == @id }.first
  end

  def loot
    Loot.from(self)
  end
end

class Boss
  attr_accessor :id, :boss_of, :loot, :name

  def initialize(boss)
    @name = boss.name
    @id = boss.id
    @boss_of = boss.boss_of
    @loot = boss.loot
  end

  def self.all
    Util.data_loader(:bosses).map { |a| Boss.new(a) }
  end
end

class Loot
  attr_accessor :id, :price, :name

  def initialize(id, name, price)
    @id = id
    @name = name
    @price = price
  end

  def self.from(ded)
    types = ESI::UniverseApi.new.post_universe_names ded.boss.loot
    types.map do |type|
      price = get_price(type.id)
      new type.id, type.name, price
    end
  end

  def self.prices
    @prices ||= ESI::MarketApi.new.get_markets_prices
  end

  def self.get_price(type_id)
    prices.select { |price| price.type_id == type_id }.first.average_price
  rescue
    0
  end
end

class Faction
  attr_accessor :id, :name, :pattern

  def initialize(faction)
    @id = faction.id
    @name = faction.name
    @pattern = faction.pattern
  end

  def self.all
    Util.data_loader(:factions).map { |f| Faction.new(f) }
  end

  def self.find(id)
    Faction.all.select { |ded| ded.id == id }.first
  end
end

get '/' do
  @factions = Faction.all
  @anoms = Anom.all.sort_by { |a| a.name }
  slim :index
end

get '/loot/:id' do
  @ded = Ded.find(params['id'].to_i)
  @faction = Faction.find(@ded.faction_id)
  @loot = @ded.loot
  slim :loot
end

get '/faction/:id' do
  @factions = Faction.all
  @faction = Faction.find(params['id'].to_i)
  @anoms = Anom.all.select { |a| a.faction_id == @faction.id }.sort_by { |a| a.escalation.level }
  slim :faction
end
