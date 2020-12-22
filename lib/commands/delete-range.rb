require 'google/apis/calendar_v3'
require_relative '../base_cli'


module Commands
  class DeleteRange < BaseCli
    Calendar = Google::Apis::CalendarV3

    desc 'list_calendars', 'List all calendars'
    def list_calendars
      calendar = Calendar::CalendarService.new
      calendar.authorization = user_credentials_for(Calendar::AUTH_CALENDAR_READONLY)

      available_calendars = calendar.list_calendar_lists
      say "Available calendars:"
      available_calendars.items.each do |item|
        say "- #{ format_calendar item }"
      end
      # event = calendar.get_calendar_list('primary', event, send_notifications: true)
      # say "Created event '#{event.summary}' (#{event.id})"
    end

    desc 'list_events', 'List upcoming recurring events in the specified calendar'
    method_option :calendar_id, type: :string, required: true
    method_option :limit, type: :numeric, default: 50
    def list_events
      calendar = Calendar::CalendarService.new
      calendar.authorization = user_credentials_for(Calendar::AUTH_CALENDAR_EVENTS_READONLY)

      page_token = nil
      limit = options[:limit]
      now = Time.now.iso8601
      begin
        result = calendar.list_events(options[:calendar_id],
                                      max_results: limit,
                                      single_events: false,
                                      order_by: 'startTime',
                                      time_min: now,
                                      page_token: page_token,
                                      fields: 'items(id,summary,start),next_page_token')

        result.items.each do |event|
          time = event.start.date_time || event.start.date
          say "#{time}, #{event.summary}"
        end
        limit -= result.items.length
        page_token = if result.next_page_token
          result.next_page_token
        else
          nil
        end
      end while !page_token.nil? && limit > 0
    end

    private

    def format_calendar(calendar)
      result = calendar.summary
      result += ' (primary)' if calendar.primary?

      result
    end
  end
end
