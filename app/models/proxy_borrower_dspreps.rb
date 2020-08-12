# == Schema Information
#
# Table name: proxy_borrower_dspreps
#
# id            :bigint
# dsp_rep_name  :string
#

class ProxyBorrowerDspreps < ActiveRecord::Base
  validates :dsp_rep_name,
            presence: true
end
