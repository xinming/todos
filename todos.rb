#! /usr/bin/ruby

require 'rubygems'
require 'active_support/core_ext'
require "active_support/time_with_zone"
require "colored"

DEBUG = false
Time.zone = "Bangkok"
CURRENT_TIME = DateTime.now.beginning_of_day

class Todo
  attr_accessor :name, :due_date, :is_important, :tags, :plain_text, :project, :project_list

  def initialize(name, is_important = false, due_date = nil, tags = [])
    @name = name
    @is_important = is_important
    @due_date = due_date
    @tags = tags
  end
  
  def is_done
    return @tags.include? "done"
  end
  
  def self.init_text(todo_string)
    todo_string.strip!
    todo_string.gsub!(/^\- /, "")
    tags = todo_string.scan(/@[a-zA-Z0-9\-_]+/).collect{|a| a.gsub(/^@/, "")}
    
    # important
    is_important = tags.include? "important"
    tags = tags - ["important"]
    
    # due_date
    due_date = nil
    tags.each do |tag|
      if tag.match(/[0-9]{4}-[0-9]{2}-[0-9]{2}/)
        due_date = Time.zone.parse(tag).to_datetime
        tags = tags - [tag]
      end
    end
    
    name = todo_string.scan(/[^@]*/)[0].strip
    todo = Todo.new(name, is_important, due_date, tags)
    todo.plain_text = todo_string
    return todo
  end
  
  def is_overdue
    
  end
  
  def due_in
    return nil if @due_date == nil
    days = (@due_date - CURRENT_TIME).to_i
    return "Today".blue_on_black  if days == 0
    return "Tomorrow".yellow_on_black  if days == 1
    return "Yesterday".red_on_black  if days == -1
    return "Overdue #{-days} Days".red_on_black  if days < 0
    return "In #{days} Days".yellow_on_black 
  end
  
  def print
    tags = (@tags != []) ? @tags.collect{|a| "@" + a }.join(" ").green : ""
    puts "|#{("%-16s" % @project_list).red}|#{("%-14s" % @project).blue}|#{@name}#{" " + tags if tags!= ""}#{" " + due_in if due_in}"
  end
end


# ----------UTILITIES---------#

def all_todos(the_list = nil)
  all_lists = Hash.new
  project_lists = []
  if the_list
    the_list_path = File.dirname(__FILE__) + "/#{the_list}.taskpaper"
    if File.exist? the_list_path
      project_lists = [the_list_path]
    else
      abort "File #{the_list_path} not found"
    end
  else
    project_lists = Dir.glob(File.dirname(__FILE__) + "/*.taskpaper")
  end
  project_lists.each do |project_list_name|
    lines = File.read(project_list_name).split(/[\n]+/)
    project_list_name = project_list_name.gsub(".taskpaper", "").gsub(/[^\/]*\//, "")
    all_lists[project_list_name] = Hash.new
    current_project_list = all_lists[project_list_name]
    current_project = nil
    project_name = nil
    lines.each do |line|
      if line.match(/^[^\@\:]+\:[\ ]*$/)
        project_name = line.gsub(":", "").strip
        current_project_list[project_name] = Array.new
        current_project = current_project_list[project_name]
      end
      if line.match(/^\t\-\ .*/)
        todo = Todo.init_text(line.gsub(/^\t/, ""))
        todo.project = project_name
        todo.project_list = project_list_name
        current_project.push todo
      end
    end
  end
  return all_lists
end

def loop_todos(todos_tree, do_print=false)
  results = [] if !do_print
  todos_tree.each do |project_list_name, projects|
    projects.each do |project_name, todos|
      todos.each do |todo|
        if do_print
          todo.print if yield(todo)
        else
          results.push(todo) if yield(todo)
        end
      end
    end
  end
  return results if !do_print
end




# ----------MAIN------------#

command = ARGV[0]
case command
when "important"
  puts "-important".upcase.blue
  loop_todos(all_todos, true) do |todo|
    todo.is_important && !todo.is_done
  end
when "commit"
when "due"
  puts "-due".upcase.blue
  loop_todos(all_todos, true) do |todo|
    todo.due_in && !todo.is_done
  end
when "all"
  loop_todos(all_todos, true) do |todo|
    !todo.is_done
  end
when "edit"
  `mate #{File.dirname(__FILE__)}`
when 'list'
  the_list = ARGV[1]
  if !the_list
    puts "-all lists".upcase.blue
    project_lists = Dir.glob(File.dirname(__FILE__) + "/*.taskpaper").collect!{|filename| filename.gsub(/[^\/]*\//, "").gsub(".taskpaper","")}
    puts project_lists
  else
    puts "-#{the_list}".upcase.blue
    loop_todos(all_todos(the_list), true) do |todo|
      !todo.is_done
    end
  end
when 'open'
  the_list = ARGV[1]
  abort "No list name given" if !the_list
  the_list_path = File.dirname(__FILE__) + "/#{the_list}.taskpaper"
  `open -a "Taskpaper.app" #{the_list_path}`
when 'tags'
  puts "-tags".upcase.blue
  puts loop_todos(all_todos){|todo| todo.tags != [] && !todo.is_done}.collect{|todo| todo.tags}.flatten.uniq.collect{|todo| "@#{todo}"}
when 'tag'
  the_tag = ARGV[1]
  abort "No tag name given" if !the_tag
  loop_todos(all_todos, true) do |todo|
    todo.tags.include?(the_tag) && !todo.is_done
  end
when 'done'
  loop_todos(all_todos, true) do |todo|
    todo.is_done
  end
end