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

    desc 'select_calendar', 'Select a calendar from the list of available calendars'
    def select_calendar
      calendar = Calendar::CalendarService.new
      calendar.authorization = user_credentials_for(Calendar::AUTH_CALENDAR_READONLY)

      available_calendars = calendar.list_calendar_lists
      say "Available calendars:"
      available_calendars.items.each_with_index do |item, index|
        say "#{index + 1} - #{ format_calendar item }"
      end
      options = (1..available_calendars.items.length).map(&:to_s)
      selected_index = ask('Select a calendar', limited_to: options).to_i

      result = available_calendars.items[selected_index - 1]
      say "Selected #{result.summary} (#{result.id})"
      result
    end

    desc 'list_events CALENDAR_ID', 'List events in the calendar CALENDAR_ID'
    method_option :from, type: :string, default: DateTime.now.iso8601, desc: 'Date time from which to list events, in ISO-8601 format.'
    method_option :to, type: :string, default: DateTime.now.next_month.iso8601, desc: 'Date time up to which to list events, in ISO-8601 format.'
    def list_events(calendar_id = 'primary')
      calendar = Calendar::CalendarService.new
      calendar.authorization = user_credentials_for(Calendar::AUTH_CALENDAR_EVENTS_READONLY)

      page_token = nil
      from = DateTime.parse options[:from]
      to = DateTime.parse options[:to]
      loop do
        page = calendar.list_events(calendar_id,
                                    single_events: true,
                                    order_by: 'startTime',
                                    time_min: from,
                                    time_max: to,
                                    page_token: page_token,
                                    fields: 'items(id,summary,start,recurrence),next_page_token')

        page.items.each do |event|
          event_start = event.start
          if event_start.nil?
            say "Event #{event.id} has no start information, skipping"
            next
          end
          time = event_start.date_time || event_start.date
          say "#{time}, #{event.summary}"
        end

        page_token = page.next_page_token
        break if page_token.nil?
      end
    end

    desc 'list_recurring_events CALENDAR_ID', 'List recurring events in the calendar CALENDAR_ID'
    method_option :from, type: :string, default: DateTime.now.iso8601, desc: 'Date time from which to list events, in ISO-8601 format.'
    method_option :to, type: :string, default: DateTime.now.next_month.iso8601, desc: 'Date time up to which to list events, in ISO-8601 format.'

    def list_recurring_events(calendar_id = 'primary')
      calendar = Calendar::CalendarService.new
      calendar.authorization = user_credentials_for(Calendar::AUTH_CALENDAR_EVENTS_READONLY)

      page_token = nil
      from = DateTime.parse options[:from]
      to = DateTime.parse options[:to]

      result = []

      loop do
        page = calendar.list_events(calendar_id,
                                    single_events: false,
                                    time_min: from,
                                    time_max: to,
                                    page_token: page_token,
                                    fields: 'items(id,summary,start,recurrence),next_page_token')

        base_recurring_events = page.items.reject { |e| e.recurrence.nil? }
        result.concat base_recurring_events

        page_token = page.next_page_token
        break if page_token.nil?
      end

      result.each_with_index do |event, i|
        start = event.start.date_time || event.start.date
        say "#{i + 1} - #{event.id} #{start}, #{event.summary}"
      end
    end

    desc 'list_recurring_event_instances CALENDAR_ID RECURRING_EVENT_ID', 'List instances of recurring event RECURRING_EVENT_ID in the calendar CALENDAR_ID'
    method_option :from, type: :string, default: DateTime.now.iso8601, desc: 'Date time from which to list events, in ISO-8601 format.'
    method_option :to, type: :string, default: DateTime.now.next_month.iso8601, desc: 'Date time up to which to list events, in ISO-8601 format.'
    def list_recurring_event_instances(calendar_id = 'primary', recurring_event_id)
      calendar = Calendar::CalendarService.new
      calendar.authorization = user_credentials_for(Calendar::AUTH_CALENDAR_EVENTS_READONLY)

      page_token = nil
      from = DateTime.parse options[:from]
      to = DateTime.parse options[:to]

      result = []

      loop do
        page = calendar.list_event_instances(calendar_id,
                                             recurring_event_id,
                                             time_min: from,
                                             time_max: to,
                                             page_token: page_token,
                                             fields: 'items(id,summary,start),next_page_token')

        result.concat page.items

        page_token = page.next_page_token
        break if page_token.nil?
      end

      result.each_with_index do |event, i|
        start = event.start.date_time || event.start.date
        say "#{i + 1} - #{event.id} #{start}, #{event.summary}"
      end
    end

    desc 'delete RECURRING_EVENT_ID, CALENDAR_ID, FROM, TO', 'Delete all instances of recurring event RECURRING_EVENT_ID in the calendar CALENDAR_ID between FROM and TO'
    def delete(recurring_event_id, calendar_id = 'primary', from = DateTime.now.iso8601, to = DateTime.now.next_month.iso8601)
      calendar = Calendar::CalendarService.new
      calendar.authorization = user_credentials_for(Calendar::AUTH_CALENDAR_EVENTS)

      page_token = nil
      from = DateTime.parse from
      to = DateTime.parse to

      instances = []

      loop do
        page = calendar.list_event_instances(calendar_id,
                                             recurring_event_id,
                                             time_min: from,
                                             time_max: to,
                                             page_token: page_token,
                                             fields: 'items(id,summary,start),next_page_token')

        instances.concat page.items

        page_token = page.next_page_token
        break if page_token.nil?
      end

      if instances.empty?
        say "No instances found between #{from.iso8601} and #{to.iso8601}"
        return
      end

      num_instances = instances.length
      say "About to delete all of the following #{num_instances} instances:\n" + instances.map {|i| format_event i}.join("\n")
      confirm = yes? 'Confirm?'
      unless confirm
        say 'Aborting'
        return
      end

      instances.each_with_index do |instance, i|
        say "Deleting #{i+1}/#{num_instances}..."
        calendar.delete_event(calendar_id, instance.id)
      end

      say 'DONE'
    end

    no_commands do
      private

      def format_calendar(calendar)
        result = calendar.summary
        result += ' (primary)' if calendar.primary?

        result
      end

      def format_event(event)
        start = event.start.date_time || event.start.date
        "#{start}, #{event.summary}"
      end
    end
  end
end
