#!/bin/bash

print "Executing the Maintenance Commands..."
# Drop PPM db schema & JSFT schema/Org removal
PPM_JS_ORG_ID=$(echo 'cat //properties/reportServer/@orgId' | xmllint --shell $PPM_HOME/config/properties.xml | awk -F'[="]' '!/>/{print $(NF-1)}')
ppm_reset_tenant_data ( ) {
  print "Dropping Tenant Data...."
 	print "Dropping PPM Schema..."
 	$PPM_HOME/bin/admin db drop -Dsysusername=$PPM_DB_PRIVILEGED_USER -Dsyspassword=$PPM_DB_PRIVILEGED_USER_PWD -Dforce=true -Dtousername=$PPM_DB_USERNAME -Dtodatabase=$PPM_DB_SERVICE_ID -Dschema=$PPM_DB_SCHEMA_NAME
 	print "Dropping DWH Schema...."
 	$PPM_HOME/bin/admin db drop-dwh -Ddwhsysusername=$PPM_DB_PRIVILEGED_USER -Ddwhsyspassword=$PPM_DB_PRIVILEGED_USER_PWD -Dforce=true -Ddwhtousername=$PPM_DWH_DB_USERNAME -Ddwhtodatabase=$PPM_DWH_DB_SERVICE_ID -Ddwhschema=$PPM_DWH_DB_SCHEMA_NAME
}

ppm_reset_jsft_tenant_data ( ) {
  print "~START~: Dropping JS ORG.... $PPM_JS_ORG_ID from $PPM_JS_URL"

    print "$PPM_HOME/bin/admin jaspersoft delete -orgName $PPM_JS_ORG_ID -url $PPM_JS_URL -userName ************* -password ************** "
 	$PPM_HOME/bin/admin jaspersoft delete -orgName $PPM_JS_ORG_ID -url $PPM_JS_URL -userName $JS_PRIVILEGED_USER -password $JS_PRIVILEGED_USER_PWD
  
  print "Dropping JS ORG.... $PPM_JS_ORG_ID from $PPM_JS_URL :~END~"

}

ppm_reset_hdp_tenant_data ( ) {
  print "~START~: Dropping database readonly user and role for HDP..."
    
	print "$PPM_HOME/bin/admin cd drop_readonly_user -Ddwhsysusername=************ -Ddwhsyspassword=************ "
 	$PPM_HOME/bin/admin cd drop_readonly_user -Ddwhsysusername=$PPM_DB_PRIVILEGED_USER -Ddwhsyspassword=$PPM_DB_PRIVILEGED_USER_PWD
  
  print "Dropping database readonly user and role for HDP... :~END~"

  print "~START~: Deleting HDP user from server..."

 	print "$PPM_HOME/bin/admin odataservice deleteUser -serverUrl $HDP_SERVER_URL -adminUser ***** -adminPassword ***** -userName $HDP_USERNAME"
 	$PPM_HOME/bin/admin odataservice deleteUser -serverUrl $HDP_SERVER_URL -adminUser $HDP_PRIVILEGED_USER -adminPassword $HDP_PRIVILEGED_USER_PWD -userName $HDP_USERNAME

  print "Deleting HDP user from server... :~END~"
}

if [[ "$PPM_RESET_HDP_CONFIG" = "true" && "$PPM_HDP_INTEGRATION_ENABLE" = "true" ]]; then
	ppm_reset_hdp_tenant_data
fi

if [[ "$PPM_RESET_JSFT_CONFIG" = "true" && "$PPM_JS_INTEGRATION_ENABLE" = "true" ]]; then
	ppm_reset_jsft_tenant_data
fi

if [ "$PPM_RESET_TENANT_DATA" = "true" ]; then
    ppm_reset_tenant_data
fi
