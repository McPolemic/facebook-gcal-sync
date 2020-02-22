require 'time'
require 'dotenv/load' if ENV["RACK_ENV"] != "production"
require 'koala'
require 'icalendar'

ACCESS_TOKEN = ENV.fetch("ACCESS_TOKEN")

class Calendar
  def initialize
    @cal = Icalendar::Calendar.new
  end

  def add_event(event)
    @cal.event do |e|
      e.dtstart = event.date
      e.summary = event.name
      e.description = event.description
    end
  end

  def to_icalendar
    @cal.publish
    @cal.to_ical
  end
end

Address = Struct.new(:name, :city, :country, :latitude, :longitude, :state, :street, :zip, keyword_init: true) do
  def self.from_json(json)
    place = json['place']
    location = place['location']
    self.new(
      name: place['name'],
      city: location['city'],
      country: location['country'],
      latitude: location['latitude'],
      longitude: location['longitude'],
      state: location['state'],
      street: location['street'],
      zip: location['zip']
    )
  end
end

Event = Struct.new(:name, :description, :date, :address, keyword_init: true) do
  def self.from_json(json)
    self.new(name: json['name'],
             description: json['description'],
             date: Time.parse(json['start_time']),
             address: Address.from_json(json))
  end
end

class FacebookEventGrabber
  def initialize(page_address)
    @page_address = page_address
  end

  def get_icalendar
    calendar = Calendar.new

    graph = Koala::Facebook::API.new(ACCESS_TOKEN)
    events_page = graph.get_object(@page_address)
    events_page.each do |json|
      event = Event.from_json(json)
      pp "Found new event: #{event.inspect}"
      calendar.add_event(event)
    end

    calendar.to_icalendar
  end
end
