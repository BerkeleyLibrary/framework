class TindDownloadController < ApplicationController

  before_action :authorize!

  def index
    render locals: { root_collections: root_collections }
  end

  def download
    collection = params[:collection]
    out = StringIO.new
    UCBLIT::TIND::Export.export_libreoffice(collection, out)
    # TODO: figure out why this isn't sending data
    send_data(
      out.string,
      filename: "#{collection.parameterize}.ods",
      type: 'application/vnd.oasis.opendocument.spreadsheet'
    )
  end

  # TODO: get rid of this
  def current_user
    @current_user ||= User.from_omniauth(
      {
        'uid' => 'dmoles',
        'provider' => 'calnet',
        'extra' => {
          'berkeleyEduAffiliations' => ['EMPLOYEE-TYPE-STAFF'],
          'berkeleyEduCSID' => '3035408457',
          'departmentNumber' => 'KPADM',
          'displayName' => 'David Moles',
          'berkeleyEduOfficialEmail' => 'dmoles@berkeley.edu',
          'employeeNumber' => '10002302',
          'givenName' => 'David',
          'surname' => 'Moles',
          'berkeleyEduUCPathID' => '10002302',
          'uid' => '1684944',
          'berkeleyEduIsMemberOf' => [
            'cn=edu:berkeley:org:libr:libr-developers,ou=campus groups,dc=berkeley,dc=edu',
            'cn=edu:berkeley:org:libr:libr-managers,ou=campus groups,dc=berkeley,dc=edu',
            'cn=edu:berkeley:org:libr:ezproxy:ezproxy_access,ou=campus groups,dc=berkeley,dc=edu',
            'cn=edu:berkeley:org:libr:devops:vsphere_access,ou=campus groups,dc=berkeley,dc=edu',
            'cn=edu:berkeley:org:libr:framework:LIBR-framework-admins,ou=campus groups,dc=berkeley,dc=edu',
            'cn=edu:berkeley:org:libr:libr-devops,ou=campus groups,dc=berkeley,dc=edu'
          ]
        }
      }
    )
  end

  private

  def root_collections
    @root_collections ||= UCBLIT::TIND::API::Collection.all
  end

  def authorize!
    authenticate!

    raise Error::ForbiddenError unless current_user.ucb_staff?
  end

end
