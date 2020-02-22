require 'sinatra'
require './facebook_event_grabber'

get '/' do
  grabber = FacebookEventGrabber.new("secondhandcinema/events")
  grabber.get_icalendar
end
