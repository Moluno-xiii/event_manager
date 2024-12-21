require 'csv'
require 'google-apis-civicinfo_v2'
require 'erb'

puts 'Event Manager Initialized'

def format_zipcode (string)
  string.to_s.rjust(5, '0').slice(0, 5)
end

def get_leg_by_zipcode(zipcode)
civic_info = Google::Apis::CivicinfoV2::CivicInfoService.new
civic_info.key = 'AIzaSyClRzDqDh5MsXwnCWi0kOiiBivP6JsSyBw'

  begin
    civic_info.representative_info_by_address(address: zipcode, levels: 'country', roles: ['legislatorUpperBody', 'legislatorLowerBody']).officials
  rescue
    'Representative not found, Try www.commoncause.org/take-action/find-elected-officials'
  end

end

def save_thank_you_later (id, form_letter)
  Dir.mkdir('output') unless Dir.exist?('output')
  
  filename = "output/thanks_#{id}.html"

  File.open(filename, 'w') do |file|
    file.puts form_letter
  end

end

def format_phone_number (phone_number)
  case
  when phone_number.length < 10
    ''
  when phone_number.length == 10
    phone_number
  when phone_number.length == 11 && phone_number[0] == '1'
    phone_number.slice(1,10)
  when phone_number.length == 11 && phone_number[0] != '1'
    phone_number = ''
  else
    phone_number = ''
  end
end

def get_peak_registration_hours(date_array)
  registration_hours = Hash.new(0)

  date_array.each do |value|
#   _, time = value.split(" ")
#   hours, _ = time.split(":")
#   registration_hours[hours] += 1
  registration_time = Time.strptime(value, "%m/%d/%y %H:%M")
  hour = registration_time.hour
  registration_hours[hour] += 1
end
 registration_hours.sort_by{|key, value| value}.reverse.to_h
end

def conv_day_of_week (week_day)
  %w[sunday monday tuesday wednesday thursday friday saturday][week_day]
end

def get_peak_registration_day_of_week(date_array)
  peak_days = Hash.new(0)

  date_array.each do |date_time|
    date = Time.strptime(date_time, "%m/%d/%y %H:%M")
    peak_days[conv_day_of_week(date.wday)] += 1
  end
  peak_days.sort_by{|day, value| -value}.to_h
end

contents = CSV.open('event_attendees.csv', headers: true, header_converters: :symbol)
template_letter = File.read('form_letter.erb')
erb_template = ERB.new(template_letter)

date_array = Array.new()
contents.each do |row|
  id = row[0]
  name = row[:first_name]
  zipcode = format_zipcode(row[:zipcode])
  legislators = get_leg_by_zipcode(zipcode)
  date_array << row[:regdate]
  
  # personal_letter = template_letter.gsub('FIRST_NAME', name)
  # personal_letter.gsub!('LEGISLATORS', legislators)
  # puts "#{name} #{zipcode} #{legislators}\n"
  
  form_letter = erb_template.result(binding)
  save_thank_you_later(id, form_letter)
end
p get_peak_registration_hours(date_array)
p get_peak_registration_day_of_week(date_array)