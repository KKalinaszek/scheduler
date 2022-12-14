require_relative 'FileReader'

class Table
    attr_accessor(
        :col_labels,
        :arr,
        :columns,
    )
    def initialize(
        col_labels = { date: "Date", from: "From", subject: "Subject" },
        arr = [{date: "2014-12-01", from: "Ferdous", subject: "Homework this week"},
            {date: "2014-12-01", from: "Dajana", subject: "Keep on coding! :)"},
            {date: "2014-12-02", from: "Ariane", subject: "Re: Homework this week"}
        ])
        @col_labels = col_labels
        @arr = arr
        @columns = col_labels.each_with_object({}) { |(col,label),h| h[col] = { label: label, width: [arr.map { |g| g[col].size }.max, label.size].max } }
    end

    def write_header
        puts "| #{ @columns.map { |_,g| g[:label].ljust(g[:width]) }.join(' | ') } |"
    end

    def write_divider
        puts "+-#{ @columns.map { |_,g| "-"*g[:width] }.join("-+-") }-+"
    end

    def write_line(h)
        str = h.keys.map { |k| h[k].ljust(@columns[k][:width]) }.join(" | ")
        puts "| #{str} |"
    end

    def write
        write_divider
        write_header
        write_divider
        arr.each { |h| write_line(h) }
        write_divider
    end
end
class Node
    attr_accessor(
        :name,
        :cost,
        ###############
        :visited,
        :before,
        :after,
        ###########
        :earlyStart,
        :earlyFinish,
        :latestStart,
        :latestFinish,
        :delay,
        :TaskWorking,
        :Critical,
    )

    def initialize(name, cost, after)
        @name = name
        @cost = cost
        @before = []
        if after.any?
            @after = []
        else
            @after = after
        end
        @visited = false
        @earlyStart = 0
        @earlyFinish = 0
        @latestStart = 0
        @latestFinish = -1
        @delay = 0
        @TaskWorking = false
        @Critical = false
    end

    def after_to_s
        s = ""
        if @after.any?
            @after.each do |a|
                s = s + a.name + " "
            end
        end
        return s
    end

    def before_to_s
        s = ""
        if @before.any?
            @before.each do |a|
                s = s + a.name + " "
            end
        end
        return s
    end

    def to_s
        space = 5
        if @after.any?
            "Name: #{@name.ljust(space)} \
            Cost: #{@cost.to_s.ljust(space)} \
            After: #{after_to_s}"
        else
            "Name: #{@name} \
            Cost: #{@cost}"
        end
    end

    def to_s_l
        space = 6
        "Name: #{@name.ljust(space)} \
        Cost: #{@cost.to_s.ljust(space)} \
        After: #{@after_to_s} \
        earlyStart: #{@earlyStart.to_s} \
        earlyFinish: #{@earlyFinish.to_s} \
        latestStart: #{@latestStart.to_s} \
        latestFinish: #{@latestFinish.to_s}\
        delay: #{@delay.to_s}"
    end

    def addConnections(after)
        if after.any?
            @after |= after # |= joines two arrays without duplicates
        end
    end
end
class Machine
    attr_accessor(
        :name,
        :criticalCost,
        :path,
    )
end
class Graph
    attr_accessor(
        :name,
        :nodes,
        :start,
        :end,
        :criticalCost,
        :pathList,
        :machines,
    )

    def initialize(name)
        @name = name
        @start = Node.new("start", 0, [])
        @end = Node.new("end", 0, [])
        @nodes = Hash[@start.name => start, @end.name => @end]
        @criticalCost = 0
        @pathList = [[]]
        @machines = Hash.new([])
    end

    def to_s
        col_labels = { name: "Zadanie", cost: "Koszt", before: "Poprzedniki", after: "Nastepniki" }
        arr = []
        if @nodes.any?
            @nodes.each {|key, node|
                arr.append({name: node.name, cost: node.cost.to_s, before: node.before_to_s, after: node.after_to_s})
            }
        end
        table = Table.new(col_labels, arr)
        puts "Graph " + @name.to_s
        table.write
    end

    def cleanSE
        @nodes.each do |key, node|
            if node.after.length > 1
                node.after.delete(@end)
                node.after.each do |a|
                    @start.after.delete(a)
                end
            end
        end
    end

    def afterAdd
        @nodes.each do |key, node|
            node.after.each do |child|
                child.before |= [node]
            end
        end
    end

    def addNodes(nodes)
        if nodes.any?
            nodes.each do |node|
                if !@nodes.has_value?(node)
                    node.addConnections([@end])
                    @start.addConnections([node])
                    @nodes[node.name] = node
                end
            end
            cleanSE
            afterAdd
        end
    end

    def isCyclic_h(node, visited, recStack)
        if recStack[node]
            return true
        end

        if visited[node]
            return false
        end

        recStack[node] = true
        visited[node] = true

        children = node.after

        children.each do |child|
            if isCyclic_h(child, visited, recStack)
              return true
            end
        end
        
        recStack[node] = false

        return false
    end
    
    def isCyclic?

        visited = Hash.new()
        recStack = Hash.new()

        @nodes.each do |key, hash|
            visited[hash] = false
            recStack[hash] = false
        end

        @nodes.each do |key, node|
            if isCyclic_h(node, visited, recStack)
                return true
            end
        end

        return false
    end

    def earlySFSet(node)
        node.after.each do |child|
            if child.earlyStart < node.earlyStart + node.cost
                child.earlyStart = node.earlyStart + node.cost
            end
            earlySFSet(child)
        end
        node.earlyFinish = node.earlyStart + node.cost
    end

    def latestSFSet(node)
        if node==@end
            node.latestFinish = @criticalCost
            node.latestStart = node.latestFinish - node.cost
        else
            node.after.each do |child|
                latestSFSet(child)
                if node.latestFinish > child.latestStart || node.latestFinish==-1
                    node.latestFinish = child.latestStart
                    node.latestStart = node.latestFinish - node.cost
                    node.delay = node.latestStart - node.earlyStart 
                end
            end
        end
    end

    #w druga strone sciezka która ma Es1 == Lf2 i Ls1==Lf2
    def findPaths(node, list)
        puts list.to_s
        node.before.each do |parent|
            if parent.earlyStart==node.latestFinish && node.latestFinish==parent.latestFinish
                list.append(node)
                findPaths(parent, list)
            end
        end
    end

    def traverseDownUp
        if isCyclic?
            puts "Can't traverse cyclic graph!"
        else
            earlySFSet(@start)
            @criticalCost = @end.earlyFinish
            latestSFSet(@start)
            puts "Path:"
            findPaths(@end, [])
        end
    end

    def CPM_to_s
        col_labels = {
            name: "Zadanie",
            cost: "Koszt",
            earlyStart: "earlyStart",
            earlyFinish: "earlyFinish",
            latestStart: "latestStart",
            latestFinish: "latestFinish",
            delay: "delay",
            isCritica: "Is critical?"
        }
        arr = []
        if @nodes.any?
            @nodes.each {|key, node|
                arr.append({
                    name: node.name,
                    cost: node.cost.to_s,
                    earlyStart: node.earlyStart.to_s,
                    earlyFinish: node.earlyFinish.to_s,
                    latestStart: node.latestStart.to_s,
                    latestFinish: node.latestFinish.to_s,
                    delay: node.delay.to_s,
                    isCritica: node.Critical.to_s
                    })
            }
        end
        table = Table.new(col_labels, arr)

        table.write
        puts "Koszt krytyczny = " + @criticalCost.to_s

        #tasks print
        puts "Ścieżki:"
        if @pathList.any? 
            @pathList.each do |path|
                puts path.to_s
            end
        else
            puts "[]"
        end
    end
end

#############################################################
#interfacetraverseDown_h
def interface(graph)
    graph.to_s
    if graph.isCyclic?
        puts "Graph is cyclic, CPM calculation not posible!"
    else
        puts "Graph is not cyclic, CPM calculation is posible."
        graph.traverseDownUp
        graph.CPM_to_s
    end
end
#############################################################
# a = Node.new("A", 4, [])
# b = Node.new("B", 10, [])
# c = Node.new("F", 3, [])
# d = Node.new("Q", 2, [])
# e = Node.new("G", 3, [])
# f = Node.new("H", 2, [])
# g = Node.new("U", 1, [])
# h = Node.new("J", 6, [])

# b.addConnections([c, a])
# d.addConnections([a, b, g, e])
# e.addConnections([f, c])
# f.addConnections([c])
# g.addConnections([c])

# graph = Graph.new("graph1")
# graph.addNodes([c, a, b, d, e, f, g, h])

# interface(graph)

########################################

f = Node.new("F", 3, [])
a = Node.new("A", 4, [])
b = Node.new("B", 7, [])
q = Node.new("Q", 2, [])

b.addConnections([f, a])
q.addConnections([a, b])

graph2 = Graph.new("graph2")
graph2.addNodes([a, b, f, q])

interface(graph2)