require 'date'

raise "Запуск осуществляется так: ruby build_calendar.rb teams.txt 01.08.2026 01.06.2027 calendar.txt" if ARGV.length < 4

teams_file, start_date_str, end_date_str, output_file = ARGV 

teams = {}
File.foreach(teams_file) do |line|
    line = line.strip

    next if line.empty?

    if line.include?('—')
        parts = line.split('—').map(&:strip)

        name = parts[0].include?('.') ? parts[0].split('.').last.strip : parts[0]
        city = parts[1]
        
        teams[name] = city
    end
    
end

raise "Нужно минимум 2 команды!" if teams.length < 2

start_date = Date.parse(start_date_str)
end_date = Date.parse(end_date_str)
raise "Дата начала позже даты окончания!" if start_date > end_date

team_names = teams.keys

games = []

team_names.each do |home_team|
  team_names.each do |away_team|
    next if home_team == away_team
    
    games.push({
      home: home_team,
      away: away_team,
      city: teams[home_team]
    })
  end
end

puts "Всего игр: #{games.length}"

GAME_DAYS = [5, 6, 0] 
GAME_TIMES = ['12:00', '15:00', '18:00']
MAX_GAMES_PER_SLOT = 2

slots = []

current_date = start_date
while current_date <= end_date
  if GAME_DAYS.include?(current_date.wday)
    GAME_TIMES.each do |time|
      slots << {
        date: current_date,
        time: time,
        games: []
      }
    end
  end
  current_date += 1
end

if slots.length * MAX_GAMES_PER_SLOT < games.length
  raise "Не хватает слотов! Нужно мест: #{games.length}, Есть: #{slots.length * MAX_GAMES_PER_SLOT}"
end

games.shuffle!

slot_index = 0

games.each do |game|
  placed = false
  
  while !placed
    current_slot = slots[slot_index]
    
    if current_slot[:games].size < MAX_GAMES_PER_SLOT
      current_slot[:games] << game
      placed = true
    end
    
    slot_index = (slot_index + 1) % slots.length
  end
end

slots.sort_by! { |slot| [slot[:date], slot[:time]] }

File.open(output_file, 'w') do |file|
  day_names = {
    0 => "Воскресенье", 1 => "Понедельник", 2 => "Вторник",
    3 => "Среда", 4 => "Четверг", 5 => "Пятница", 6 => "Суббота"
  }
  
  slots.each do |slot|
    next if slot[:games].empty?
    
    date_str = slot[:date].strftime("%d.%m.%Y")
    day_str = day_names[slot[:date].wday]  
    
    file.puts "#{date_str} (#{day_str}), #{slot[:time]}"
    
    slot[:games].each do |game|
      file.puts "#{game[:home]} vs #{game[:away]} (г. #{game[:city]})"
    end
    file.puts
  end
end

puts "Готово! Календарь сохранен в файл: #{output_file}"