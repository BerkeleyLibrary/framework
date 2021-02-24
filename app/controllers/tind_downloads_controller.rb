class TindDownloadsController < AuthenticatedFormController

  # TODO: get rid of this
  private def current_user
    @current_user ||= User.from_omniauth(
      {
        'provider' => 'calnet',
        'uid' => 'dmoles',
        'info' => { 'nickname' => 'dmoles' },
        'credentials' => { 'ticket' => 'ST-423891-rxAHIUunStJFi2bcuDqICnVL-b0auth-p3' },
        'extra' => {
          'user' => 'dmoles',
          'isFromNewLogin' => 'true',
          'bypassMultifactorAuthentication' => 'false',
          'authenticationDate' => '2021-02-22T12:30:48.843-08:00[America/Los_Angeles]',
          'authnContextClass' => 'mfa-duo',
          'displayName' => 'David Moles',
          'givenName' => 'David',
          'successfulAuthenticationHandlers' => 'mfa-duo',
          'berkeleyEduUCPathID' => '10002302',
          'employeeNumber' => '10002302',
          'samlAuthenticationStatementAuthMethod' => 'urn:oasis:names:tc:SAML:1.0:am:unspecified',
          'credentialType' => 'DuoCredential',
          'uid' => '1684944',
          'berkeleyEduCSID' => '3035408457',
          'authenticationMethod' => 'mfa-duo',
          'surname' => 'Moles',
          'departmentNumber' => 'KPADM',
          'berkeleyEduIsMemberOf' => [
            'cn=edu:berkeley:app:2StepTest:Allow2StepViewTest,ou=campus groups,dc=berkeley,dc=edu',
            'cn=edu:berkeley:official:dept:L2-Control-Unit-groups:UCBKL-OACAD,ou=campus groups,dc=berkeley,dc=edu',
            'cn=edu:berkeley:app:zoom:zoom-licensed-productivity-suite,ou=campus groups,dc=berkeley,dc=edu',
            'cn=edu:berkeley:official:current-campus-community,ou=campus groups,dc=berkeley,dc=edu',
            'cn=edu:berkeley:official:titlecode:important-titlecode-groups,ou=campus groups,dc=berkeley,dc=edu',
            'cn=edu:berkeley:org:libr:libr-developers,ou=campus groups,dc=berkeley,dc=edu',
            'cn=edu:berkeley:app:rans:Remote-Access-Full,ou=campus groups,dc=berkeley,dc=edu',
            'cn=edu:berkeley:official:dept:L4-Department-groups:UCBKL-OACAD-UCLIB-KPADM,ou=campus groups,dc=berkeley,dc=edu',
            'cn=edu:berkeley:official:employees:other-management,ou=campus groups,dc=berkeley,dc=edu',
            'cn=edu:berkeley:official:Employees-and-UCPath-Affiliates,ou=campus groups,dc=berkeley,dc=edu',
            'cn=edu:berkeley:app:auth-cas:zoom_berkeley:zoom_berkeley-allow,ou=campus groups,dc=berkeley,dc=edu',
            'cn=edu:berkeley:app:rans:Remote-Access-Core,ou=campus groups,dc=berkeley,dc=edu',
            'cn=edu:berkeley:org:libr:libr-managers,ou=campus groups,dc=berkeley,dc=edu',
            'cn=edu:berkeley:app:auth-cas:imagine_content:imagine_content-allow,ou=campus groups,dc=berkeley,dc=edu',
            'cn=edu:berkeley:official:dept:DepartmentNumber-groups:DN-KPADM,ou=campus groups,dc=berkeley,dc=edu',
            'cn=edu:berkeley:app:wifi:WiFi-Users,ou=campus groups,dc=berkeley,dc=edu',
            'cn=edu:berkeley:app:auth-cas:box_app:box_app-access,ou=campus groups,dc=berkeley,dc=edu',
            'cn=edu:berkeley:official:dept:L3-Division-groups:UCBKL-OACAD-UCLIB,ou=campus groups,dc=berkeley,dc=edu',
            'cn=edu:berkeley:app:calnet-spa:group-spa-lap-library,ou=campus groups,dc=berkeley,dc=edu',
            'cn=edu:berkeley:official:dept:UCPath-DepartmentNumber-groups:UC-KPADM,ou=campus groups,dc=berkeley,dc=edu',
            'cn=edu:berkeley:official:Employees-and-HCM-Affiliates-no-retirees,ou=campus groups,dc=berkeley,dc=edu',
            'cn=edu:berkeley:official:employees:professional-employees,ou=campus groups,dc=berkeley,dc=edu',
            'cn=edu:berkeley:app:2StepTest:Enforce2StepTest,ou=campus groups,dc=berkeley,dc=edu',
            'cn=edu:berkeley:org:libr:ezproxy:ezproxy_access,ou=campus groups,dc=berkeley,dc=edu',
            'cn=edu:berkeley:org:libr:devops:vsphere_access,ou=campus groups,dc=berkeley,dc=edu',
            'cn=edu:berkeley:app:calnet-spa:group-spa-lib-zenoss,ou=campus groups,dc=berkeley,dc=edu',
            'cn=edu:berkeley:official:employees:all-supervisors-managers,ou=campus groups,dc=berkeley,dc=edu',
            'cn=edu:berkeley:app:calnet-spa:group-spa-lib-noreply,ou=campus groups,dc=berkeley,dc=edu',
            'cn=edu:berkeley:app:sis:collegenet-access,ou=campus groups,dc=berkeley,dc=edu',
            'cn=edu:berkeley:app:2Step:Allow2StepView,ou=campus groups,dc=berkeley,dc=edu',
            'cn=edu:berkeley:app:calmessages:it-staff,ou=campus groups,dc=berkeley,dc=edu',
            'cn=edu:berkeley:app:calmessages:Other_Management_CM,ou=campus groups,dc=berkeley,dc=edu',
            'cn=edu:berkeley:app:calnet-spa:group-spa-libraryit,ou=campus groups,dc=berkeley,dc=edu',
            'cn=edu:berkeley:app:calnet:calnet-spa-access:calnet-spa-app-access,ou=campus groups,dc=berkeley,dc=edu',
            'cn=edu:berkeley:app:auth-cas:webapp-default:webapp-default-access,ou=campus groups,dc=berkeley,dc=edu',
            'cn=edu:berkeley:app:2Step:Require2Step,ou=campus groups,dc=berkeley,dc=edu',
            'cn=edu:berkeley:app:auth-cas:adobecc:adobecc-access,ou=campus groups,dc=berkeley,dc=edu',
            'cn=edu:berkeley:official:employees:staff:all-staff,ou=campus groups,dc=berkeley,dc=edu',
            'cn=edu:berkeley:org:libr:framework:LIBR-framework-admins,ou=campus groups,dc=berkeley,dc=edu',
            'cn=edu:berkeley:official:emp-aff-stu-no-retirees,ou=campus groups,dc=berkeley,dc=edu',
            'cn=edu:berkeley:official:titlecode:groups:TC-000652,ou=campus groups,dc=berkeley,dc=edu',
            'cn=edu:berkeley:app:auth-cas:fom-cchem:fom-cchem-access,ou=campus groups,dc=berkeley,dc=edu',
            'cn=edu:berkeley:app:2Step:Enforce2Step,ou=campus groups,dc=berkeley,dc=edu',
            'cn=edu:berkeley:official:all-accounts,ou=campus groups,dc=berkeley,dc=edu',
            'cn=edu:berkeley:official:Employees-Students-UCPath-Affiliates,ou=campus groups,dc=berkeley,dc=edu',
            'cn=edu:berkeley:app:auth-cas:g_suite:g_suite-access,ou=campus groups,dc=berkeley,dc=edu',
            'cn=edu:berkeley:app:auth-cas:lib_asktico:lib_asktico-access,ou=campus groups,dc=berkeley,dc=edu',
            'cn=edu:berkeley:app:auth-cas:lib_jenkins:lib_jenkins-access,ou=campus groups,dc=berkeley,dc=edu',
            'cn=edu:berkeley:app:calnet-spa:group-spa-lit-jira,ou=campus groups,dc=berkeley,dc=edu',
            'cn=edu:berkeley:app:calmessages:staff,ou=campus groups,dc=berkeley,dc=edu',
            'cn=edu:berkeley:official:employees:all-emp,ou=campus groups,dc=berkeley,dc=edu',
            'cn=edu:berkeley:app:auth-cas:gingr:gingr-allow,ou=campus groups,dc=berkeley,dc=edu',
            'cn=edu:berkeley:official:employees:staff:professional,ou=campus groups,dc=berkeley,dc=edu',
            'cn=edu:berkeley:app:bcon:adobe_console_licensing:adobe-console-employees,ou=campus groups,dc=berkeley,dc=edu',
            'cn=edu:berkeley:org:libr:libr-devops,ou=campus groups,dc=berkeley,dc=edu',
            'cn=edu:berkeley:app:zoom:zoom-sponsored-eligible,ou=campus groups,dc=berkeley,dc=edu',
            'cn=edu:berkeley:app:calmessages:All_Supervisors_and_Managers,ou=campus groups,dc=berkeley,dc=edu'
          ],
          'berkeleyEduAffiliations' => ['EMPLOYEE-TYPE-STAFF'],
          'berkeleyEduOfficialEmail' => 'dmoles@berkeley.edu',
          'longTermAuthenticationRequestTokenUsed' => 'false'
        }
      }
    )
  end

  private

  def init_form!
    @form = TindDownload.new(user: current_user)
    @form.authorize!
  end

end
