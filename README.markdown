dm-imap-adapter
=============

It's DM IMAP adapter time.  This GEM is based on the initial work of wycats.  Currently, it supports a variety of queries, updating flags, creating new emails, and moving between mailboxes.  Sorting, mailbox manipulation, and email editing should come in the future.

The gem includes a file "gmapper" which provides a sample application of the adapter with some added sugar for Gmail.  Here's how to use it:

require 'gmapper'
DataMapper.setup(:default, "imap://vanpelt%40gmail.com:pass@imap.gmail.com/INBOX")

Gmapper::Message.all(:subject => "you're awesome") 
 #=> [...500000 results...]
Gmapper::Message.first(:mailbox => "[Gmail]/Drafts", :date.gt => 2.days.ago)
 #=> { :subject => "Dear Mr. Obama" }
m = Gmapper::Message.create(:subject => "A new queue", :body => "Some YAML")
#remove message from the drafts folder
m.mailbox = "INBOX"
#mark message read and starred
m.flags = [:seen, :flagged]
m.save
 #=> { :subject => "A new queue", :flags => [:Seen]}
#archive message
m.destroy

More to come soon... imagine the possibilites!