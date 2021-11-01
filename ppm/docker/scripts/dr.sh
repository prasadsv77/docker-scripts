#!/usr/bin/env bash
CURRENT_FILE="$(basename "${BASH_SOURCE[0]}")"


reset_all_dependency_tokens () {
   print "Updating tokens for all operations..."
   update_status_in_config_map "install-db.sh" "db"
   update_status_in_config_map "install-db.sh" "dwh"
   update_status_in_config_map "install-db.sh" "db_link"
   # Listing installed addins from db and resetting token for that
   $PPM_HOME/bin/admin cd fetch_addins
   source /tmp/installed_addins.properties
   addins=$PPM_INSTALLED_ADDINS
   if  [ ! -z "$addins" ]
    then
        for addin in ${addins//,/ }
        do
          update_status_in_config_map "install-addins.sh" "$addin"
        done
    fi
   # Listing installed plugins from db and resetting token for that
   $PPM_HOME/bin/admin cd fetch_plugins
   source /tmp/installed_plugins.properties
   plugins=$PPM_INSTALLED_PLUGINS
   if  [ ! -z "$plugins" ]
    then
        for plugin in ${plugins//,/ }
        do
          if [ "$plugin" = "pl_itd_ae" ]; then
            plugin="itd"
          fi
          update_status_in_config_map "install-plugins.sh" "$plugin"
        done
   fi

   if [ "$PPM_JS_INTEGRATION_ENABLE" = "true" ]; then
    update_status_in_config_map "integrations.sh" "JSFT"
   fi

   if [ "$PPM_HDP_INTEGRATION_ENABLE" = "true" ]; then
    update_status_in_config_map "integrations.sh" "HDP"
   fi

   if [ "$PPM_SSO_SAML_ENABLED" = "true" ]; then
   update_status_in_config_map "integrations.sh" "SSO"
   fi

   update_status_in_config_map "operations.sh" "operation_status"
   print "Updated tokens for all operations."
}


_main () {

  # setting loop back db link with latest db details for DR
  create_loop_back_db_link
  _loop_back_db_link_status_on_dr=$?
  check_status_exit_on_error $_loop_back_db_link_status_on_dr "loop back db link creation successful." "loop back db link creation failed."

  # create extension if not exists before creating db link
  create_extension
  _extension_status=$?
  check_status_exit_on_error $_extension_status "Extension creation successful." "Extension creation failed."

  # setting db link with latest db details for DR
  create_db_link
  _db_link_status_on_dr=$?
  check_status_exit_on_error $_db_link_status_on_dr "db link creation successful." "db link creation failed."

  # Running syncPPMContext with latest clarity details for DR if jsft integrations is enabled
  if [ "$PPM_JS_INTEGRATION_ENABLE" = "true" ]; then
    run_syncPPMContext
    _jsft_syncPPMContext_status_on_dr=$?
    check_status_exit_on_error $_jsft_syncPPMContext_status_on_dr "Japser PPM sync successful." "Japser PPM sync failed."
  fi

  # Updating HDP for DR if HDP integrations is enabled
  if [ "$PPM_HDP_INTEGRATION_ENABLE" = "true" ]; then
    reset_hdp
    _hdp_reset_status_on_dr=$?
    check_status_exit_on_error $_hdp_reset_status_on_dr "Reset HDP successful." "Reset HDP failed."

    enable_hdp
    _hdp_setup_status_on_dr=$?
    check_status_exit_on_error $_hdp_setup_status_on_dr "HDP integration is successful." "HDP integration failed."
  fi

  #Updating the tokens in dependency config map, so that no completed operation will be repeated once DR flag is disabled.
  reset_all_dependency_tokens

}


echo
print "############################## INITIATED DR Operations for Clarity ##############################" "GREEN"
echo
_main