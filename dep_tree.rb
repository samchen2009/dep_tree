# =========================================
# Script to pass the C header dependancy.
#
#     Author: shanchen@marvell.com
#   Revision:
#         0.1. 2012-09-04
# ==========================================


class Node
  attr_accessor :name,:parent,:childs,:is_leaf

  def initialize(name,parent=nil,is_leaf=false)
    @name = name
    @parent = parent
    @childs = []
    @is_leaf = is_leaf
  end

  def my_parents_has?(him)
    node = self
    while !is_root?(node) and node.name != him.name
      node = node.parent
    end
    if (node.name == him.name)
      #puts "find #{him.name} in parents"
    end
    return node.name == him.name
  end

  def is_root?(node)
    node.parent.nil?
  end

  def add_child(child)
    if !child.is_a?(Node)
      child = Node.new(child,self) 
      return if my_parents_has?(node)
    end
    @childs << child #if !my_parents_has?(child)
    puts "#{self.name} depends on #{child.name}"
  end

  def find_root()
    node = self
    while !node.parent.nil?
      node = node.parent
    end
    node
  end

  def tree_has?(node)
    root = find_root
    found = root.has_child?(node)
    #puts "====> #{node.name} already existed, not go into tree" if found == true
    found
  end

  def has_child?(node)
    found = false
    self.childs.each do |child|
      return true if (child.name == node.name)
      return true if child.has_child?(node)
    end
    false
  end

  #return the dependancies name
  def find_nodes(src_dir="./",full_tree=false)
    file = File.open("#{@name}") if !self.is_leaf
    file.each_line do |line|
      match = /.*#include\s+[<|"](.*?)[\>|"]\s*/.match(line)
      if !match.nil? and !match[1].nil?
        header = match[1]
        name = Dir.glob("#{src_dir}/**/#{header}").first
        if name.nil? or name == ""
          node = Node.new(header,self,true)
        else
          node = Node.new(name,self,false)
        end
        existed = full_tree ? my_parents_has?(node) : tree_has?(node)
        if full_tree
          add_child(node) if !existed
        else
          node.is_leaf = existed if !node.is_leaf
          add_child(node)
        end
      end
    end
    self.childs
  end

  def build_tree(i,src_dir="./",options)
    name = File.basename(self.name)
    system("mkdir -p #{i}_#{name}")
    return if self.is_leaf
    Dir.chdir("#{i}_#{name}") do
      childs = self.find_nodes(src_dir,!options.include?("i"))
      childs.each do |c|
        c.build_tree(i+1,src_dir,options) if !c.nil?
      end
    end
  end

end

def show_tree(path)
  puts `tree #{path}`
end

if ($0 == __FILE__)
  usage = "usage: ruby dep_tree.rb path/to/your/source/code"

  if (!ARGV[0])
    puts usage
    exit 1
  end

  options = []
  filelist = []
  ARGV.each do |arg|
    if (arg =~ /^-(\w*)/)
      options << arg.gsub(/^-/,'')
    else
      filelist << arg
    end
  end

  src_dir = Dir.pwd
  name = File.absolute_path(filelist.first)
  root = Node.new(name)
  system('mkdir -p ./tree')
  system('rm ./tree/* -rf')
  Dir.chdir("./tree") do
    root.build_tree(0,src_dir,options)
  end
  show_tree("./tree")
end
