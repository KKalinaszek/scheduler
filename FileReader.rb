def read_file(name)
    activities_list = []
    File.foreach(name) {
      |line|
        activities_list.append(line.split)
    }

    #create Activity
    activities_list.each do |activity|
      @activities.append(Activity.new(@number, activity[0], activity[1]))
      @number = @number + 1
    end

    # #create children
    activities_list.each do |activity|
      activity[2..activity.length()-1].each do |n|
        connect(activity[0], n)
      end
    end
end