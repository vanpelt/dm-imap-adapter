require File.dirname(__FILE__)+'/imap_adapter'
module Gmapper
  ImapTypes = DataMapper::Adapters::Imap
  
  class Message
    include DataMapper::Resource

    property :id, ImapTypes::Uid
    property :subject, ImapTypes::Subject
    property :sender, ImapTypes::Sender
    property :from, ImapTypes::From
    property :to, ImapTypes::To
    property :date, ImapTypes::InternalDate
    property :body, ImapTypes::Body, :lazy => true
    property :flags, ImapTypes::Flags
    property :sequence, Integer, :key => true
    property :mailbox, String

    def mailbox=(mailbox)
      repository.adapter.imap.copy(@sequence, mailbox)
      @mailbox = mailbox
    rescue Net::IMAP::NoResponseError
      false
    end
    
    def inspect
      self.class.properties(:default).inject({}) {|s,x| s.merge(x.name => self.instance_variable_get("@#{x.name}"))}.inspect
    end
  end
end