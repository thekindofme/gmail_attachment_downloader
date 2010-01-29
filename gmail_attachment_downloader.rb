#! /usr/bin/ruby
#This script is baised on http://snippets.dzone.com/posts/show/7530

username = "username@gmail.com"
password = "pa$sword"
look_in_folder = "gmail_label_of_the_messages_whose_attachments_you_want_downloaded"
move_downloaded_mails_to_folder = "gmail_label_to_be_applied_for_processed_emails"
save_to_folder = "/path/to/folder/where/attachments/will/be/saved"

require 'net/imap'
require 'rubygems'
require 'tmail'

# This is a convenience monkey patch
class Net::IMAP
  def uid_move(uid, mailbox)
    uid_copy(uid, mailbox)
    uid_store(uid, "+FLAGS", [:Deleted])
  end
end

puts 'Starting...'
imap = Net::IMAP.new('imap.gmail.com', '993', true)

puts "Logging in as #{username} ..."

imap.login(username, password)
imap.select(look_in_folder)
mails = imap.uid_search(["NOT", "DELETED"])

puts "Found #{mails.count} mail(s) in folder '#{look_in_folder}'"

puts "\nFetching the next email (this might take some time depending on the size of the message/attachment..."
mails.each do |uid|
  # save_attachment
  mail = TMail::Mail.parse( imap.uid_fetch(uid, 'RFC822').first.attr['RFC822'] )
  puts "Processing '#{mail.subject}'"
  if ! mail.attachments.blank?
    puts "Detected #{mail.attachments.count} attachment(s)"
    mail.attachments.each {|attachment|
      puts "Saving attachment to '#{attachment.original_filename}'..."
      File.open(save_to_folder + attachment.original_filename,"w+") { |local_file|
        local_file << attachment.gets(nil)
      }
    }

  end

  # archive mail to mailbox
  puts "Moving '#{mail.subject}' to folder '#{move_downloaded_mails_to_folder}'"
  imap.uid_move(uid, move_downloaded_mails_to_folder)
end

imap.expunge
puts "Logging out..."
imap.logout

