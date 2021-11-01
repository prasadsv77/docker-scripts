#!/bin/bash
CURRENT_FILE="$(basename "${BASH_SOURCE[0]}")"
PPM_JS_ORG_ID=$(echo 'cat //properties/reportServer/@orgId' | xmllint --shell $PPM_HOME/config/properties.xml | awk -F'[="]' '!/>/{print $(NF-1)}')
PPM_JS_URL=$(echo 'cat //properties/reportServer/@webUrl' | xmllint --shell $PPM_HOME/config/properties.xml | awk -F'[="]' '!/>/{print $(NF-1)}')
generate_ppm_keystore ( ) {
    print "Generating keystores for the integration...."
    # generate keystore
    $PPM_HOME/bin/admin jaspersoft keystore
    cp -f $PPM_HOME/config/$PPM_JS_ORG_ID.* $PPM_HOME/keystore/
}

enable_xog_client ( ) {
    print "Enable XOG Client...."
    $PPM_HOME/bin/admin cd enable_xog_client -Dxog.enabled=$PPM_ENABLE_XOG_CLIENT
}

jaspersoft_url_check ( )  {
    apiPath=$1
    if [[ ! -z $apiPath ]]; then
      status=$(curl -k -S -s -f -u $JS_PRIVILEGED_USER:$JS_PRIVILEGED_USER_PWD $PPM_JS_URL/$apiPath)
      returnCode=$?
      if [[ "$status" != *"<externallyDefined>"* ]] || [[ $returnCode -gt 0 ]]; then
        return 1
      else
        return 0
      fi
    fi
}

import_jsft_content ( ) {
    if [ ! "$PPM_JS_ONLY_KEY_STORE_GEN" = "true" ]; then
        print "Install/Import JSFT content package...."
        print "Checking whether Jaspersoft URL is valid/active or not...."
        jaspersoft_url_check "rest_v2/users/superuser"
        urlStatus=$?
        if test $urlStatus -ne 0; then
              print "Jaspersoft URl :-  $PPM_JS_URL is not valid/active, please check the URL" "RED"
              return 1
        fi


        for js_addin in ${PPM_JS_CONTENT//,/ }
        do
          echo $PPM_HOME/bin/admin content-jaspersoft $js_addin -userName $JS_PRIVILEGED_USER -password *******
          $PPM_HOME/bin/admin content-jaspersoft $js_addin -userName $JS_PRIVILEGED_USER -password $JS_PRIVILEGED_USER_PWD
          _command_status=$?
          if test $_command_status -ne 0; then
              print "JSFT content import Failed for addin :- $js_addin " "RED"
              return 1
          fi
        done


        orgId_lc=$(echo $PPM_JS_ORG_ID | tr "[:upper:]" "[:lower:]")
        orgTest=$(curl -k -s -S -H "Accept: application/json" -u $JS_PRIVILEGED_USER:$JS_PRIVILEGED_USER_PWD $PPM_JS_URL/rest_v2/organizations/$orgId_lc)
        if [[ ! -z $orgTest ]]
            then
            retCode=$(echo $orgTest | grep -i resource.not.found | wc -l)
            if test $retCode -eq 0; then
                print "JSFT content import successful." "GREEN"
                return 0
            else
                print "JSFT content import Failed." "RED"
                return 1
            fi
        else
            print "JSFT content import Failed." "RED"
            return 1
        fi
    fi
}

enable_ppm_ux ( ) {
    print "Enabling PPM UX...."
    $PPM_HOME/bin/admin cd enable_ppmux
}

setup_validation (){
    _check_function=$1
    source $PPM_HOME_SCRIPTS/healthcheck/dbhealthcheck.sh
    if [ "$_check_function" = "JSFT" ]; then
        check_jasper_ks_health
    elif [ "$_check_function" = "HDP" ]; then
        check_hdp_health
    fi
    _db_check=$?
    return $_db_check
}
_jsft_final_status=0
if [ "$PPM_JS_INTEGRATION_ENABLE" = "true" ]; then
  print "Initiating Jaspersoft integration with Clarity." "GREEN"
  check_status_in_config_map $CURRENT_FILE "JSFT"
  _jsft_config_status=$?
  check_addin_health $CLARITY_RELEASE 'csk'
  _is_csk_installed=$?

  if test $_is_csk_installed -ne 0; then
    print "CSK addin missing." "RED"
    return 1
  fi
  if test $_jsft_config_status -eq 0; then
      print "JSFT integration is already done."
  else
      print "JSFT integration is not done yet."
      generate_ppm_keystore
      _keystore_status=$?

      if test $_keystore_status -eq 0; then
          import_jsft_content
          _import_status=$?
          if test $_import_status -eq 0; then
              setup_validation "JSFT"
              _jsft_content_status=$?
              if test $_jsft_content_status -eq 0; then
                   print "Updating config map."
                   update_status_in_config_map $CURRENT_FILE "JSFT"
                   _config_status=$?
                   if test $_config_status -eq 0; then
                      _jsft_final_status=0
                      print "Integration of Jaspersoft with Clarity is successfull." "GREEN"
                   else
                      print "Config map update failed for JSFT integration status." "RED"
                      _jsft_final_status=1
                   fi
              else
                   print "JSFT content validation failed." "RED"
                   _jsft_final_status=1
              fi
           else
                print "JSFT content import failed." "RED"
                _jsft_final_status=1
           fi
      else
           _jsft_final_status=1
           print "JSFT key store generation failed." "RED"
      fi
  fi

  # Process patch operation if it is patch
  if [ "$PPM_INSTALL_TYPE" = "patch" ]; then
    print $PPM_HOME/bin/admin cd integrate_jaspersoft -DjasperUserName=$JS_PRIVILEGED_USER -DjasperUserPassword=******** -Dispatch=true
    $PPM_HOME/bin/admin cd integrate_jaspersoft -DjasperUserName=$JS_PRIVILEGED_USER -DjasperUserPassword=$JS_PRIVILEGED_USER_PWD -Dispatch=true
    _command_status=$?
    if test $_command_status -ne 0; then
        print "Jaspersoft content patch import Failed." "RED"
        exit 1
    fi
  fi

  # Process upgrade operation if it is upgrade
  if [ "$PPM_INSTALL_TYPE" = "upgrade" ]; then
    print $PPM_HOME/bin/admin cd integrate_jaspersoft -DjasperUserName=$JS_PRIVILEGED_USER -DjasperUserPassword=******** -Disupgrade=true
    $PPM_HOME/bin/admin cd integrate_jaspersoft -DjasperUserName=$JS_PRIVILEGED_USER -DjasperUserPassword=$JS_PRIVILEGED_USER_PWD -Disupgrade=true
    _command_status=$?
    if test $_command_status -ne 0; then
        print "Jaspersoft content upgrade import Failed." "RED"
        exit 1
    fi
  fi

fi

if [ "$PPM_XOG_CLIENT_ENABLE" = "true" ]; then
    enable_xog_client
fi

if [ "$PPM_UX_ENABLE" = "true" ]; then
    enable_ppm_ux
fi

_hdp_final_status=0
if [ "$PPM_HDP_INTEGRATION_ENABLE" = "true" ]; then
   print "Initiating HDP integration with Clarity." "GREEN"
   check_status_in_config_map $CURRENT_FILE "HDP"
   _hdp_config_status=$?
   if test $_hdp_config_status -eq 0; then
      print "HDP integration is already done."
        _hdp_final_status=0
   else
      print "HDP integration is not done yet."
      enable_hdp
      _hdp_enable_status=$?
      if test $_hdp_enable_status -eq 0; then
          setup_validation "HDP"
          _hdp_status=$?
          if test $_hdp_status -eq 0; then
              print "Updating config map."
               update_status_in_config_map $CURRENT_FILE "HDP"
               _config_status=$?
               if test $_config_status -eq 0; then
                    _hdp_final_status=0
                    print "Integration of HDP with Clarity is successfull." "GREEN"
               else
                    print "Config map update failed for HDP integration status." "RED"
                    _hdp_final_status=1
               fi
          else
            print "HDP integration validation failed."
             _hdp_final_status=1
          fi
      else
           print "HDP integration failed."
           _hdp_final_status=1
      fi
  fi
fi

_sso_enable_final_status=0
if [ ! -z "$PPM_SSO_SAML_ENABLED" ]; then
  check_status_in_config_map "$CURRENT_FILE" "SSO"
  _sso_config_status=$?
  if test $_sso_config_status -eq 0; then
      print "SSO integration is already done."
      _sso_enable_final_status=0
  else
    if [ "$PPM_SSO_SAML_ENABLED" = "true" ]; then
      print "-----------------Enabling SSO-----------------" "GREEN"
      "$PPM_HOME"/bin/admin system-options -add SAML_ENABLED 1 -force
      _sso_cmd_status=$?

      if [ $_sso_cmd_status -eq 0 ]; then
        if [ ! -z "$PPM_SSO_SAML_ROUTER_COOKIE" ]; then
          print "Triggering admin system options to set saml router cookie - $PPM_SSO_SAML_ROUTER_COOKIE"
          "$PPM_HOME"/bin/admin system-options -add SAML_SHARED_COOKIE "$PPM_SSO_SAML_ROUTER_COOKIE" -force
          _sso_cmd_status=$?

          if [ $_sso_cmd_status -ne 0 ]; then
            print "Failed to set SSL SAML ROUTER COOKIE" "RED"
            _sso_enable_final_status=1
          fi
        fi
      else
        print "Failed to enable SSO" "RED"
        _sso_enable_final_status=1
      fi

      if [ $_sso_enable_final_status -eq 0 ]; then
        print "Updating config map."
        update_status_in_config_map "$CURRENT_FILE" "SSO"
        _sso_config_status=$?

        if test $_sso_config_status -eq 0; then
          print "-----------------SSO Integration SUCCESS-----------------" "GREEN"
        else
          print "Config map update failed for SSO integration status." "RED"
          return 1
        fi
      else
        print "-----------------SSO Integration FAILED-----------------" "RED"
        return 1
      fi
    else
      print "-----------------Disabling SSO-----------------" "GREEN"
      "$PPM_HOME"/bin/admin system-options -add SAML_ENABLED 0 -force
      _sso_cmd_status=$?

      if [ $_sso_cmd_status -eq 0 ]; then
        _sso_enable_final_status=0
        print "Updating config map."
        update_status_in_config_map "$CURRENT_FILE" "SSO"
        _sso_config_status=$?

        if test $_sso_config_status -eq 0; then
          print "-----------------Disabling SSO SUCCESS-----------------" "GREEN"
        else
          print "Config map update failed for disable SSO." "RED"
          return 1
        fi
      else
        _sso_enable_final_status=1
        print "-----------------Disabling SSO FAILED-----------------" "RED"
      fi
    fi
  fi
fi

_final_status=$(($_jsft_final_status + $_hdp_final_status + $_sso_enable_final_status))

if [ "$PPM_JS_INTEGRATION_ENABLE" = "true" ] || [ "$PPM_HDP_INTEGRATION_ENABLE" = "true" ] || [ "$PPM_SSO_SAML_ENABLED" = "true" ] ; then
    if test $_final_status -eq 0; then
       print "Integrations are successful." "GREEN"
       return 0
    else
       print "Integrations are not successful." "RED"
       return 1
    fi
else
    return 0
fi
