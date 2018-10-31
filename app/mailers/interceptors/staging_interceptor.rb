# Route emails to a mailing list for testing purposes
#
# This interceptor catches outgoing emails and routes them to a mailing list,
# allowing stakeholders/QA to test email behaviors without actually sending
# them to recipients. The original to/cc/bcc are stored in custom headers
# named X-Original-{To,CC,BCC}, which are viewable in most mail clients.
#
# This should be configured in `config/environments/staging`.
#
# @see https://guides.rubyonrails.org/action_mailer_basics.html#intercepting-emails Rails Guides: Intercepting Emails
# @see https://support.google.com/mail/answer/29436?hl=en GMail: How to view headers
class StagingInterceptor
  class << self
    def delivering_email(mail)
      # Use headers to indicate who we would have emailed. Note that we don't add
      # this to the body so as not to mess up HTML/Text content.
      mail.header['X-Original-To'] = mail.to
      mail.header['X-Original-CC'] = mail.cc
      mail.header['X-Original-BCC'] = mail.bcc

      # Forward solely to the test list
      mail.to = 'lib-testmail@lists.berkeley.edu'
      mail.cc = mail.bcc = ''
    end
  end
end
