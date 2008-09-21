require 'rubygems'
require 'pathname'
require 'ostruct'
require Pathname(__FILE__).dirname + 'imap_adapter/version'
gem 'dm-core', DataMapper::More::ImapAdapter::VERSION
require 'dm-core'

gem 'extlib', '>=0.9.5'
require 'extlib'

require 'dm-serializer'
require 'net/imap'
require Pathname(__FILE__).dirname + 'imap_adapter/types'

module DataMapper
  module Adapters
    
    class ImapAdapter < AbstractAdapter
      include Extlib
      attr_reader :imap
      attr_accessor :mailbox
      
      def connect!
        @imap = Net::IMAP.new(@uri.host, @uri.port || 993, true)
        begin
          @imap.send(:send_command, "authenticate", "login")
        rescue
        ensure
          @imap.send(:send_command, "login", URI.unescape(@uri.user), @uri.password)
        end
        @mailbox = @uri.path.gsub(%r{^/}, "")
        @imap.select(@mailbox) rescue raise("Mailbox #{@mailbox} not found")
        @imap
      end
      
      def connection
        @connection ||= connect!
      end
      
      def update(attributes, query)
        arr = if key_condition = query.conditions.find {|op,prop,val| prop.key?}
          [ make_imap_result(query, attributes, key_condition.last) ]
        else
          read_many(query).map do |obj|
            obj = make_imap_result(query, attributes, obj.key)
          end
        end
        attributes.map do |key, val|
          #To avoid removing other flags...
          if key.name == :flags && val == [:deleted]
            key = OpenStruct.new(:name => "+flags")
          end
          puts "@imap.store(#{arr.map{|r| r.sequence}.inspect}, #{key.name.to_s.upcase.inspect}, #{val.inspect})"
          @imap.store(arr.map{|r| r.sequence}, key.name.to_s.upcase, val)
        end.length
      end
      
      def create(resources)
        resources.map do |resource|
          if resource.mailbox
            connection.create(resource.mailbox)
          else
            body = <<-BODY
Subject: #  {resource.subject}
From: #{resource.from}
To: #{resource.to}
            
#{resource.body}
            BODY
            puts "@imap.append(#{@mailbox}, some_shit, #{resource.flags.inspect}, #{resource.date.inspect})"
            connection.append(@mailbox, body.gsub(/\n/, "\r\n"), resource.flags, resource.date)
          end
        end.length
      end
      
      def delete(query)
        if key_condition = query.conditions.find {|op,prop,val| prop.name == :mailbox}
          #This is a place to potentially remove a mailbox... not very elegant right now
          #connection.delete(key_condition.last)
        else
          update({Property.new(query.model, :flags, Object) => [:deleted]}, query)
        end
      end
      
      # A dummy method to allow migrations without upsetting any data
      def destroy_model_storage(*args)
        true
      end
      
      # A dummy method to allow migrations without upsetting any data
      def create_model_storage(*args)
        true
      end
      
      def read_many(query)
        Collection.new(query) do |set|
          read(query, set)
        end
      end
      
      def read_one(query)
        read(query, query.model, true)
      end
      
      #Typecasters
      def typecast_load(obj, prop)
        if [Date, Time, DateTime].include?(prop.primitive)
          Time.parse(obj)
        else
          obj
        end
      end
      
      def typecast_dump(obj)
        case obj
        when Date, Time, DateTime
          obj.strftime("%d-%b-%Y")
        else
          obj
        end
      end
      
      protected
      
      def read(query, set, single = false)
        if cond = query.conditions.find {|op, prop, val| prop.name == :mailbox }
          begin
            connection.select(cond.last)
            @mailbox = cond.last
          rescue
            raise("Mailbox #{@mailbox} not found")
          end
        end
        query_array = query_to_array(query)
        #query_array.unshift "ALL" unless single
        puts "@imap.search(#{query_array.inspect})" unless query_array.empty?
        imap_seqs = query_array.empty? ? [1] : Array(connection.search(query_array))
        puts "@imap.fetch(#{imap_seqs.inspect}, #{imap_props(query.fields).inspect})"
        imap_results = imap_seqs.empty? ? [] : connection.fetch(imap_seqs, imap_props(query.fields))
        materialize_imap_results(set, Array(imap_results), query, single)
      rescue Net::IMAP::NoResponseError
        retry
      end
      
      def query_to_array(query)
        result = []
        query.conditions.each do |op, prop, val|
          next if [:mailbox, :sequence].include?(prop.name) 
          result += (prop.type.query_details[op] + [typecast_dump(val)])
        end
        result
      end
      
      def make_imap_result(query, attrs, key = nil)
        obj = query.model.new
        obj.sequence = query.conditions.find {|op,prop,val| prop.key?}.last if key
        attrs.each do |prop,val|
          obj.send("#{prop.name}=", val)
        end
        obj
      end
      
      def materialize_imap_results(set, results, query, single = false)
        return nil unless results[0]
        properties = query.fields
        properties_with_indexes = Hash[*properties.zip((0...properties.size).to_a).flatten]
        
        if single
          set.load normalize(results[0], properties_with_indexes), query
        else
          results.each do |result|
            set.load normalize(result, properties_with_indexes)
          end
        end
      end
      
      def normalize(result, properties_with_indexes)
        return nil? unless result
        properties_with_indexes.inject([]) do |accum, prop_idx|
          prop, idx = prop_idx
          if prop.field == "sequence"
            accum[idx] = result.seqno
          elsif prop.field == "mailbox"
            accum[idx] = @mailbox
          else
            prop_result = result.attr[prop.field.upcase]
            prop_result = prop_result.send(prop.type.envelope_name) if prop.type.envelope?
            accum[idx] = typecast_load(prop_result, prop)
          end
          accum
        end
      end
      
      def imap_props(properties)
        properties.map {|prop| ["sequence", "mailbox"].include?(prop.field) ? nil : prop.field.upcase}.compact.uniq
      end
    end
  end  
end