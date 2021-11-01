package com.broadcom.clarity.validator.util;

/**
 * @author Shirish Samantaray <shirish.samantaray@broadcom.com>
 * @since 7/8/2019
 */
public class Constants
{
  public static final String JSON_MEDIATYPE = "json";
  public static final String XML_MEDIATYPE = "xml";

  public static final String APP_PROPS_NAME = "application-constants";
  public static final String APP_DEV_PROPS_NAME = "application-dev-constants";
  public static final String APP_VALIDTION_DEF_JSON_PATH = "containerVariableValidationJsonFilePath";
  public static final String CONTAINER_MAP_NAME = "container-helmpath-map";

  //HDP
  public static final String HDP = "hdp";
  public static final String HDP_ENV_VARIABLE_JSON_PROP = "hdpEnvVariableJson";
  public static final String HDP_MAPPING_JSON_PROP = "hdpMappingJson";

  //Clarity
  public static final String CLARITY = "clarity";
  public static final String CLARITY_CONTEXT_PATH_KEY = "appContextPath";
  public static final String CLARITY_PROP_FILE_KEY = "clarityConfigFileName";
  public static final String CLARITY_CONFIG_FILE_TEMPLATE_PATH_KEY = "clarityConfigFileTemplatePath";
  public static final String CLRT_PROD_VALIDATION_ID = "CLRT-PROD-VALIDATION";
  public static final String CLRT_PROD_VALIDATION_DESC = "Clarity Product Validations Message Response";
  public static final String CLRT_CONTAINER_VALIDATION_ID = "CLRT-CONTAINER-VALIDATION";
  public static final String CLRT_CONTAINER_VALIDATION_DESC = "Clarity Container Validations Message Response";
  public static final String CLRT_ENV_VARIABLE_JSON_PROP = "clarityEnvVariableJson";
  public static final String CLRT_CONFIG_FOLDER = "config";
  public static final String CLRT_MAPPING_JSON_PROP = "clarityMappingJson";
  public static final String CLRT_APP_MAPPING_JSON_PROP = "clarityAppMappingJson";
  public static final String CLRT_CONFIG_FILE_PATH = "/input/configs/ppm.properties";

  //JSFT
  public static final String JASPERSOFT = "jaspersoft";
  public static final String JSFT_ENV_VARIABLE_JSON_PROP = "jsftEnvVariableJson";
  public static final String JSFT_MAPPING_JSON_PROP = "jsftMappingJson";


  public static final String COMMON_VALIDATOR = "common_validator";
  public static final String PROD_CONTAINER_VALIDATION = "CONTAINER-VALIDATION";
  public static final String MESSAGE_BUILDER_BEAN_NAME = "message-builder-factory";

  public static final String PROPERTIES_ELEMENT = "/properties/";
  public static final String PPM_DB_PORT_KEY = "PPM_DB_PORT";
  public static final String PPM_DB_HOST_KEY = "PPM_DB_HOST";
  public static final String PPM_DB_SERVICE_ID_KEY = "PPM_DB_SERVICE_ID";
  public static final String PPM_DWH_DB_HOST_KEY = "PPM_DWH_DB_HOST";
  public static final String PPM_DWH_DB_PORT_KEY = "PPM_DWH_DB_PORT";
  public static final String PPM_DWH_DB_SERVICE_ID_KEY = "PPM_DWH_DB_SERVICE_ID";
  public static final String PPM_DB_VENDOR_KEY = "PPM_DB_VENDOR";
  public static final String PPM_DWH_DB_VENDOR_KEY = "PPM_DWH_DB_VENDOR";
  public static final String PPM_DB_SPECIFY_URL_KEY = "PPM_DB_SPECIFY_URL";
  public static final String PPM_DWH_DB_SPECIFY_URL_KEY = "PPM_DWH_DB_SPECIFY_URL";
  public static final String PPM_DB_USE_URL_KEY = "PPM_DB_USE_URL";
  public static final String PPM_DWH_DB_USE_URL_KEY = "PPM_DWH_DB_USE_URL";
  public static final String PPM_DB_USERNAME_KEY = "PPM_DB_USERNAME";
  public static final String PPM_DB_PASSWORD_KEY = "PPM_DB_PASSWORD";
  public static final String PPM_DWH_DB_USERNAME_KEY = "PPM_DWH_DB_USERNAME";
  public static final String PPM_DWH_DB_PASSWORD_KEY = "PPM_DWH_DB_PASSWORD";
  public static final String PPM_JS_INTEGRATION_ENABLE_KEY = "PPM_JS_INTEGRATION_ENABLE";
  public static final String PPM_DB_SCHEMA_NAME_KEY = "PPM_DB_SCHEMA_NAME";
  public static final String PPM_DWH_DB_SCHEMA_NAME_KEY = "PPM_DWH_DB_SCHEMA_NAME";
  public static final String PPM_DB_URL_ADD_PARAMS_KEY = "PPM_DB_URL_ADD_PARAMS";
  public static final String PPM_DWH_URL_ADD_PARAMS_KEY = "PPM_DWH_URL_ADD_PARAMS";

  public static final String PPM_DB_PRIVILEGED_USER_KEY = "PPM_DB_PRIVILEGED_USER";
  public static final String PPM_DB_PRIVILEGED_USER_PWD_KEY = "PPM_DB_PRIVILEGED_USER_PWD";

  public static final String JS_PRIVILEGED_USER_KEY = "JS_PRIVILEGED_USER";
  public static final String JS_PRIVILEGED_USER_PWD_KEY = "JS_PRIVILEGED_USER_PWD";

  public static final String HDP_PRIVILEGED_USER_KEY = "HDP_PRIVILEGED_USER";
  public static final String HDP_PRIVILEGED_USER_PWD_KEY = "HDP_PRIVILEGED_USER_PWD";

  public static final String PPM_DS_ADMIN_USER_KEY = "PPM_DS_ADMIN_USER";
  public static final String PPM_DS_ADMIN_PASSWORD_KEY = "PPM_DS_ADMIN_PASSWORD";

  public static final String PPM_SSL_PASSWORD_KEY = "PPM_SSL_PASSWORD";

  public static final String PPM_MAILSERVER_USERNAME_KEY = "PPM_MAILSERVER_USERNAME";
  public static final String PPM_MAILSERVER_PASSWORD_KEY = "PPM_MAILSERVER_PASSWORD";

  public static final String PPM_DB_INDX_SMALL_TS_KEY = "PPM_DB_INDX_SMALL_TS";
  public static final String PPM_DB_INDX_LARGE_TS_KEY = "PPM_DB_INDX_LARGE_TS";
  public static final String PPM_DB_USERS_LARGE_TS_KEY = "PPM_DB_USERS_LARGE_TS";
  public static final String PPM_DB_USERS_SMALL_TS_KEY = "PPM_DB_USERS_SMALL_TS";
  public static final String PPM_DWH_DATA_DIM_TS_KEY = "PPM_DWH_DATA_DIM_TS";
  public static final String PPM_DWH_DATA_FACT_TS_KEY = "PPM_DWH_DATA_FACT_TS";
  public static final String PPM_DWH_INDX_DIM_TS_KEY = "PPM_DWH_INDX_DIM_TS";
  public static final String PPM_DWH_INDX_FACT_TS_KEY = "PPM_DWH_INDX_FACT_TS";

  //default tablespace values for vendors
  //postgres
  public static final String PPM_POSTGRES_DB_INDX_TS_VALUE = "clarity_indx";
  public static final String PPM_POSTGRES_DB_USERS_TS_VALUE = "clarity_data";
  public static final String PPM_POSTGRES_DWH_INDX_TS_VALUE = "clarity_dwh_indx";
  public static final String PPM_POSTGRES_DWH_USERS_TS_VALUE = "clarity_dwh_data";

  public static final String HDP_DWH_RO_ROLE_KEY = "HDP_DWH_RO_ROLE";
  public static final String HDP_DWH_RO_USERNAME_KEY = "HDP_DWH_RO_USERNAME";
  public static final String HDP_DWH_RO_USER_PASSWORD_KEY = "HDP_DWH_RO_USER_PASSWORD";

  public static final String CONTAINER_KEY = "containerKey";
  public static final String XPATH = "xpath";
  public static final String DEFAULT_VALUE = "defaultValue";
  public static final String USER_KEY = "userKey";

  public static final String JDBC_DRIVER_CLASS_ORACLE = "com.ca.clarity.jdbc.oracle.OracleDriver";
  public static final String JDBC_DRIVER_CLASS_MSSQL = "com.ca.clarity.jdbc.sqlserver.SQLServerDriver";
  public static final String JDBC_DRIVER_CLASS_POSTGRES = "org.postgresql.Driver";

  public static final String DB_VENDOR_ORACLE = "oracle";
  public static final String DB_VENDOR_MSSQL = "mssql";
  public static final String DB_VENDOR_POSTGRES = "postgres";

  public static final String PPM_APP_DB_DRIVER_PATH = "database/@driver";
  public static final String PPM_DWH_DB_DRIVER_PATH = "dwhDatabaseServer/database/@driver";

  public static final String DB_VENDOR_PATH = "/properties/database/@vendor";
  public static final String DWH_DB_VENDOR_PATH = "/properties/dwhDatabaseServer/database/@vendor";

  public static final String PPM_JS_URL = "reportServer/@webUrl";

  public static final String DEFAULT_NIKU_SCHEMA = "niku";
  public static final String DEFAULT_PPM_DWH_SCHEMA = "ppm_dwh";
  public static final String DEFAULT_JASPER_URL = "http://&lt;my_reportserver&gt;/reportservice";

  public static final String ANY = "...";


  public enum ReponseType
  {
    xml( "xml" ),
    json( "json" );

    private String value;

    ReponseType( String value )
    {
      this.value = value;
    }

    public String toString()
    {
      return String.valueOf( value );
    }
  }

  public enum SupportedApps
  {
    clarity( "clarity" ),
    jaspersoft( "jaspersoft" ),
    hdp( "hdp" );

    private String value;

    SupportedApps( String value )
    {
      this.value = value;
    }

    public String toString()
    {
      return String.valueOf( value );
    }

    public static boolean isExists( String text )
    {
      boolean valueExists = false;
      for( SupportedApps b : SupportedApps.values() )
      {
        if( String.valueOf( b.value ).equals( text ) )
        {
          valueExists = true;
          break;
        }
      }
      return valueExists;
    }
  }

  public enum Status
  {

    SUCCESS( "SUCCESS" ),
    ERROR( "ERROR" ),
    INPROGRESS( "INPROGRESS" );;

    private String value;

    Status( String value )
    {
      this.value = value;
    }

    public String toString()
    {
      return String.valueOf( value );
    }

  }

  public enum MsgValues
  {

    IS_MANDATORY( "Mandatory attribute cannot be null or empty." ),
    INVALID_VALUE( "Invalid value, possible values are " ),
    INVALID_PORT( "Invalid port number, the values should within the range starting from 0 to 65535" ),
    INVALID_URL(
      "Invalid URL format, the URL should start with http/https followed by lowercase alphanumeric characters and allowed special characters are / - : = % + . ? & # with a valid domain name. No spaces allowed " ),
    DEPENDENT_MISSING( "cannot be empty or null" ),
    INVALID_JASPER_TEXT_FORMAT(
      "Invalid object name, the object should contain only lowercase alphanumeric characters and allowed special character is _ (underscore)" );

    private String value;

    MsgValues( String value )
    {
      this.value = value;
    }

    public String toString()
    {
      return String.valueOf( value );
    }

  }

  public enum SupportedOperations
  {

    validate( "validate" ),
    update( "update" ),
    populate( "populate" );

    private String value;

    SupportedOperations( String value )
    {
      this.value = value;
    }

    public String toString()
    {
      return String.valueOf( value );
    }

    public static boolean isExists( String text )
    {
      boolean valueExists = false;
      for( SupportedOperations b : SupportedOperations.values() )
      {
        if( String.valueOf( b.value ).equals( text ) )
        {
          valueExists = true;
          break;
        }
      }
      return valueExists;
    }
  }
}