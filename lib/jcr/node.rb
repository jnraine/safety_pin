class JCR
  class Node
    include_class 'javax.jcr.PropertyType'
    include_class 'java.util.Calendar'
    include_class 'java.util.Date'
    
    def self.find(path)
      raise ArgumentError unless path.to_s.start_with?("/")
      Node.new(session.get_node(path.to_s))
    rescue javax.jcr.PathNotFoundException
      nil
    end
    
    def self.session
      JCR.session
    end
    
    attr_reader :j_node
    
    def initialize(j_node)
      @j_node = j_node
    end
    
    def path
      @path ||= j_node.path
    end
    
    def children
      child_nodes = []
      j_node.get_nodes.each do |child_j_node|
        child_nodes << Node.new(child_j_node)
      end
      child_nodes
    end
    
    def child(relative_path)
      child_j_node = j_node.get_node(relative_path)
      Node.new(child_j_node)
    rescue javax.jcr.PathNotFoundException
      nil
    end
    
    def name
      @name ||= j_node.name
    end
    
    def read_attribute(name)
      property = j_node.get_property(name)
      property_type = PropertyType.name_from_value(property.type)
      case property_type
      when "String"
        property.string
      when "Boolean"
        property.boolean
      when "Double"
        property.double
      when "Long"
        property.long
      when "Date"
        Time.at(property.date.time.time / 1000)
      when "Name"
        "Name wuz here" #"Name: #{property.string}"
      else
        raise PropertyTypeError.new("Unknown property type: #{property_type}")
      end
    rescue javax.jcr.PathNotFoundException
      raise NilPropertyError.new("#{name} property not found on node")
    end
    
    def write_attribute(name, value)
      if value.is_a? Time or value.is_a? Date
        calendar_value = Calendar.instance
        calendar_value.set_time(value.to_java)
        j_node.set_property(name, calendar_value)
      else
        j_node.set_property(name, value)
      end
    end
    
    def save
      j_node.save
      not j_node.modified?
    end
    
    def reload
      j_node.refresh(false)
    end
    
    def [](name)
      read_attribute(name)
    end
    
    def []=(name, value)
      write_attribute(name, value)
    end
    
    def changed?
      j_node.modified?
    end
    
    def new?
      j_node.new?
    end
    
    def properties
      props = {}
      prop_iter = j_node.properties
      while prop_iter.has_next
        prop_name = prop_iter.next_property.name
        props[prop_name] = self[prop_name]
      end
      props
    end
  end
  
  class PropertyTypeError < Exception; end
  class NilPropertyError < Exception; end
end