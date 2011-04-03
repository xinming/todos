#! /usr/bin/ruby
$VERBOSE = nil

require 'rubygems'
require "activesupport"
require "colored"

DEBUG = false
Time.zone = "Bangkok"
CURRENT_TIME = DateTime.now.beginning_of_day

=begin
DATA structure: 
FILE_NAME[PROJECT_NAME][TASK_NAME]
=end

def init_content
  all_lists = Hash.new
  project_lists = Dir.glob("*.taskpaper")
  project_lists.each do |project_list_name|
    
    # puts "\n\n--debug-- List: #{file_name}" if DEBUG
    lines = File.read(project_list_name).split /[\n]+/
    project_list_name.gsub!(".taskpaper", "")
    all_lists[project_list_name] = Hash.new
    current_project_list = all_lists[project_list_name]  # CURRENT PROJECT LIST
    current_project = nil # CURRENT PROJECT
    project_name = nil
    lines.each do |line|
      if line.match /^[^\@\:]+\:[\ ]*$/
        project_name = line.gsub(":", "").strip
        # puts "--debug-- project: " + project_name if DEBUG
        current_project_list[project_name] = Array.new
        current_project = current_project_list[project_name]
      end
      if line.match /^\-\ .*/
        todo = Todo.init_text(line)
        # puts "\t--debug-- todo: " + todo.inspect if DEBUG
        todo.project = project_name
        todo.project_list = project_list_name
        current_project.push todo
      end
    end
  end

  return all_lists
end


class Todo
  attr_accessor :name, :due_date, :is_important, :tags, :plain_text, :project, :project_list

  def initialize(name, is_important = false, due_date = nil, tags = [])
    @name = name
    @is_important = is_important
    @due_date = due_date
    @tags = tags
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
    return "Today" if days == 0
    return "Tomorrow" if days == 1
    return "Yesterday" if days == -1
    return "Overdue #{-days} Days" if days < 0
    return "In #{days} Days"
  end
  
  def print
    tags = (@tags != []) ? @tags.collect{|a| "@" + a }.join(" ").green : ""
    puts "|#{("%-14s" % @project_list.capitalize).red}|#{("%-14s" %  @project).blue}|#{@name}#{" " + tags if tags!= ""}#{" " + due_in.yellow_on_black if due_in}"
  end
end

def print_todos_tree(project_lists)
  
end

# MAIN
all_lists = init_content()
command = ARGV[0]
case command
when "important"
  all_lists.each do |project_list_name, projects|
    projects.each do |project_name, todos|
      todos.each do |todo|
        todo.print if todo.is_important
      end
    end
  end
when "commit"
  
when "due"
  all_lists.each do |project_list_name, projects|
    projects.each do |project_name, todos|
      todos.each do |todo|
        todo.print if todo.due_in
      end
    end
  end
end

