require 'rails_helper'

describe ApplicationController do
  let(:controller_classes) do
    inflector = Rails.application.autoloaders.main.inflector
    Dir.glob('app/controllers/*_controller.rb').map do |f|
      class_name = inflector.camelize(File.basename(f, '.rb'), nil)
      Module.const_get(class_name)
    end
  end

  let(:expected_addresses) do
    {
      # baker-library@berkeley.edu
      ServiceArticleRequestFormsController => 'baker-library@berkeley.edu',

      # eref-library@berkeley.edu
      GalcRequestFormsController => 'eref-library@berkeley.edu',

      # helpbox-library@berkeley.edu (default)
      ApplicationController => 'helpbox-library@berkeley.edu',
      FinesController => 'helpbox-library@berkeley.edu',
      HomeController => 'helpbox-library@berkeley.edu',
      TindDownloadController => 'helpbox-library@berkeley.edu',
      AlmaItemSetController => 'helpbox-library@berkeley.edu',
      BibliographicsController => 'helpbox-library@berkeley.edu',
      HoldingsRequestsController => 'helpbox-library@berkeley.edu',
      SessionsController => 'helpbox-library@berkeley.edu',
      CampusNetworksController => 'helpbox-library@berkeley.edu',
      ValidateProxyPatronController => 'helpbox-library@berkeley.edu', # never displayed, but no harm done

      # privdesk-library@berkeley.edu
      AffiliateBorrowRequestFormsController => 'privdesk-library@berkeley.edu',
      AuthenticatedFormController => 'privdesk-library@berkeley.edu',
      DoemoffStudyRoomUseFormsController => 'privdesk-library@berkeley.edu',
      LibstaffEdevicesLoanFormsController => 'privdesk-library@berkeley.edu',
      ProxyBorrowerAdminController => 'privdesk-library@berkeley.edu',
      ProxyBorrowerFormsController => 'privdesk-library@berkeley.edu',
      ReferenceCardFormsController => 'privdesk-library@berkeley.edu',
      StackPassAdminController => 'privdesk-library@berkeley.edu',
      StackPassFormsController => 'privdesk-library@berkeley.edu',
      StackRequestsController => 'privdesk-library@berkeley.edu',
      StudentEdevicesLoanFormsController => 'privdesk-library@berkeley.edu',

      # prntscan@lists.berkeley.edu
      ScanRequestFormsController => 'prntscan@lists.berkeley.edu'
    }
  end

  it 'has the expected value' do
    aggregate_failures do
      controller_classes.each do |cc|
        expected = expected_addresses[cc]
        actual = cc.support_email
        expect(actual).to eq(expected), "#{cc}.support_email: expected #{expected}, was #{actual}"
      end
    end
  end
end
