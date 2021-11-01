package com.broadcom.clarity.validator.services.clarity.ppm;

import com.broadcom.clarity.validator.exception.ValidationWrapperException;
import com.broadcom.clarity.validator.response.Message;
import com.broadcom.clarity.validator.response.Messages;
import com.broadcom.clarity.validator.services.AbstractPrepareMessages;
import com.broadcom.clarity.validator.services.ApplicationHandlerService;
import com.broadcom.clarity.validator.services.helpers.CommonValidator;
import com.broadcom.clarity.validator.services.helpers.IgnoreSpecifiedValidationMessages;
import com.broadcom.clarity.validator.util.Constants;
import com.broadcom.clarity.validator.util.HandlerUtilities;
import com.niku.nsa.handlers.PropertiesHandler;
import com.niku.union.config.MigratableDatabaseURL;
import com.niku.union.utility.StringUtil;
import com.niku.union.utility.UtilityXPATH;
import com.niku.union.xml.DOMUtils;
import org.apache.logging.log4j.LogManager;
import org.apache.logging.log4j.Logger;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.context.ApplicationContext;
import org.springframework.context.annotation.Scope;
import org.springframework.context.annotation.ScopedProxyMode;
import org.springframework.stereotype.Service;
import org.w3c.dom.Document;

import java.io.File;
import java.io.FileInputStream;
import java.io.InputStreamReader;
import java.util.*;

@Service
@Scope( proxyMode = ScopedProxyMode.TARGET_CLASS, value = "prototype" )
public class ClarityPPMHandlerServiceImpl extends AbstractPrepareMessages implements ApplicationHandlerService
{
  private static Logger logger = LogManager.getLogger( ClarityPPMHandlerServiceImpl.class );
  private String clarityContextPath = "C:\\ca\\clarity\\trunk\\build\\install";
  private String configFileName = "properties.xml";
  private String clarityConfigFileTemplatePath = "";
  @Autowired
  private ApplicationContext applicationContext;
  @Autowired
  private CommonValidator commonValidator;
  private static String APP_PROPERTIES = Constants.APP_PROPS_NAME;

  private static Map<String, String> environmentVariableMap = System.getenv();
  private Map<String, Map<String, String>> containerToXPathAndHelmPathMap;
  private Map<String, Map<String, String>> xpathToDefaultValuesAndHelmPathMap;

  @Autowired
  private HandlerUtilities handlerUtilities;

  public HandlerUtilities getHandlerUtilities()
  {
    return handlerUtilities;
  }

  public void setHandlerUtilities( HandlerUtilities handlerUtilities )
  {
    this.handlerUtilities = handlerUtilities;
  }

  static
  {
    if( HandlerUtilities.isWindows() )
    {
      APP_PROPERTIES = Constants.APP_DEV_PROPS_NAME;
    }
  }

  @Override
  public Messages productValidation( Document doc )
  {
    logger.info( "Starting product validation..." );
    if( applicationContext == null )
    {
      logger.error( "*** Application Context Object Is Not Initialized ***" );
      return null;
    }

    Properties clarityPropertiesObject = (Properties) applicationContext.getBean( APP_PROPERTIES );
    try
    {

      if( clarityPropertiesObject != null )
      {
        clarityContextPath = clarityPropertiesObject.getProperty( Constants.CLARITY_CONTEXT_PATH_KEY );
        configFileName = clarityPropertiesObject.getProperty( Constants.CLARITY_PROP_FILE_KEY );
      }
      if( doc == null )
      {
        doc = DOMUtils.getDocumentBuilder()
            .parse( new File( clarityContextPath + File.separator + Constants.CLRT_CONFIG_FOLDER + File.separator + configFileName ) );
      }

      System.setProperty( "install.dir", clarityContextPath );

      List<com.niku.nsa.handlers.Message> ppmMessages = PropertiesHandler.getInstance().validate( doc );

      logger.info( "Completed product validation." );
      if( ppmMessages != null && ppmMessages.size() > 0 )
      {
        Messages messages = formatMessages( ppmMessages );
        logger.debug( "Clarity Product Response : " + messages.toString() );
        return messages;
      }
    }
    catch( Exception e )
    {
      logger.error( "Error occured while doing productValidation:", e );
    }
    return null;
  }

  @Override
  public Messages containerValidation()
  {
    Properties clarityPropertiesObject = (Properties) applicationContext.getBean( APP_PROPERTIES );
    logger.info( "Starting container validation..." );
    try
    {
      if( clarityPropertiesObject != null )
      {
        String _fileJsonContent = HandlerUtilities.getJsonContentFromFile( clarityPropertiesObject.getProperty( Constants.APP_VALIDTION_DEF_JSON_PATH ),
            clarityPropertiesObject.getProperty( Constants.CLRT_ENV_VARIABLE_JSON_PROP ), true );
        String _jsonFilePath = clarityPropertiesObject.getProperty( Constants.APP_VALIDTION_DEF_JSON_PATH ) + File.separator +
            clarityPropertiesObject.getProperty( Constants.CLRT_ENV_VARIABLE_JSON_PROP );

        if( _fileJsonContent == null )
        {
          logger.error( "File not found " + _jsonFilePath );
          throw new Exception( "Message:File not found " + _jsonFilePath );
        }
        else if( _fileJsonContent != null && HandlerUtilities.isJSONValid( _fileJsonContent ) )
        {
          logger.debug( "JSON File Content " + _fileJsonContent );
          return commonValidator.validationForEnvVar( _fileJsonContent, Constants.SupportedApps.clarity.toString() );
            /*// Remove duplicate messages based on attributeName & messageId
            Set<String> nameSet = new HashSet<>();
            List<Message> messageList = messages.getMessageList().stream()
            .filter(e -> nameSet.add(e.getAttributeName()+"|"+e.getId()))
            .collect(Collectors.toList());
            // Overwrite the filtered list
            messages.setMessageList( messageList );*/
        }
        else
        {
          logger.error( "Invalid json content found in " + _jsonFilePath );
          throw new Exception(
              "Message:Invalid json content found in " + _jsonFilePath );
        }
      }
    }
    catch( Exception e )
    {
      logger.error( "Error while reading container variable definition file -" + clarityPropertiesObject.getProperty( Constants.APP_VALIDTION_DEF_JSON_PATH )
          + File.separator
          + clarityPropertiesObject.getProperty( Constants.CLRT_ENV_VARIABLE_JSON_PROP ) + " ", e );
      throw new ValidationWrapperException( "Message:Error while reading container variable definition file", e, "401" );
    }
    logger.info( "Completed container validation." );
    return null;
  }

  public List<Messages> handleConfig( String propertiesXMLPath, String propertiesMapPath )
  {
    containerToXPathAndHelmPathMap = (Map<String, Map<String, String>>) applicationContext.getBean( "containerToXPathAndHelmPathMap" );
    xpathToDefaultValuesAndHelmPathMap = (Map<String, Map<String, String>>) applicationContext.getBean( "xpathToDefaultValuesAndHelmPathMap" );
    populateMappings();
    logger.debug( "containerToXPathAndHelmPathMap:" + containerToXPathAndHelmPathMap );
    logger.debug( "xpathToDefaultValuesAndHelmPathMap:" + xpathToDefaultValuesAndHelmPathMap );
    Properties clarityPropertiesObject = (Properties) applicationContext.getBean( APP_PROPERTIES );
    if( clarityPropertiesObject != null )
    {
      clarityContextPath = clarityPropertiesObject.getProperty( Constants.CLARITY_CONTEXT_PATH_KEY );
    }

    File propertiesFile = new File( propertiesXMLPath );

    System.setProperty( "install.dir", clarityContextPath );

    Properties props = new Properties();
    try (InputStreamReader inputStream = new InputStreamReader( new FileInputStream( propertiesMapPath ), "UTF8" ))
    {
      logger.info( "loading properties from config map for processing" );
      // load properties file
      props.load( inputStream );
      loadSecrets( props );
      Document doc = DOMUtils.getDocumentBuilder().parse( propertiesFile );
      List<Messages> _messagesList = new ArrayList<>();
      Messages messages;

      doc = getDefaultValuesDoc( doc );
      doc = getUpdatedDoc( doc, props );

      messages = containerValidation();
      if( checkIfErrorMessageExists( messages ) )
      {
        _messagesList.add( messages );
      }

      messages = productValidation( doc );
      if( checkIfErrorMessageExists( messages ) )
      {
        _messagesList.add( messages );
      }

      if( _messagesList.size() > 0 )
      {
        IgnoreSpecifiedValidationMessages ignoredValidationMessages = new IgnoreSpecifiedValidationMessages();
        _messagesList = ignoredValidationMessages.getActualMessageList( _messagesList );
      }

      logger.debug( "Final Doc:" + DOMUtils.nodeToString( doc ) );
      if( _messagesList == null || _messagesList.size() == 0 )
      {
        List<com.niku.nsa.handlers.Message> _ppmMessages = PropertiesHandler.getInstance().update( doc, "properties.xml", false );

        if( _ppmMessages != null && _ppmMessages.size() > 0 )
        {
          messages = formatMessages( _ppmMessages );
          logger.debug( "Clarity Product Response : " + messages.toString() );
          List<Messages> messagesList = new ArrayList<>();
          messagesList.add( messages );
          return messagesList;
        }
        logger.info( "Updated properties.xml with input values." );
      }
      else
      {
        return _messagesList;
      }
    }
    catch( Exception e )
    {
      logger.error( "Configuration update failed.", e );
      throw new ValidationWrapperException( "Configuration update failed.", e, "44" );
    }

    return null;
  }

  @Override
  public List<Messages> updateConfigurations()
  {
    logger.debug( "Updating configuration" );
    Properties clarityPropertiesObject = (Properties) applicationContext.getBean( APP_PROPERTIES );
    if( clarityPropertiesObject != null )
    {
      clarityContextPath = clarityPropertiesObject.getProperty( Constants.CLARITY_CONTEXT_PATH_KEY );
      // In update use case, properties.xml from the config folder will be taken and all the default values will be applied to it.
      // Then user input values will be applied. All other processing will be same for both populate and update use case.
      configFileName = clarityPropertiesObject.getProperty( Constants.CLARITY_PROP_FILE_KEY );
    }

    String configFilePath = clarityContextPath + File.separator + Constants.CLRT_CONFIG_FOLDER + File.separator + configFileName;

    return handleConfig( configFilePath, clarityContextPath + Constants.CLRT_CONFIG_FILE_PATH );
  }

  @Override
  public List<Messages> populateConfigurations()
  {
    logger.debug( "Populating configuration" );
    Properties clarityPropertiesObject = (Properties) applicationContext.getBean( APP_PROPERTIES );
    if( clarityPropertiesObject != null )
    {
      clarityContextPath = clarityPropertiesObject.getProperty( Constants.CLARITY_CONTEXT_PATH_KEY );
    }

    String configFilePath = clarityContextPath + File.separator + Constants.CLRT_CONFIG_FOLDER + File.separator + configFileName;

    // If properties file already exists in the runtime then it will be the base doc object to apply values from deployment
    // otherwise template file will be the base doc object.
    File configFile = new File(configFilePath);
    if (configFile.exists())
    {
      clarityConfigFileTemplatePath = configFilePath;
    }
    else
    {
      clarityConfigFileTemplatePath = clarityPropertiesObject.getProperty( Constants.CLARITY_CONFIG_FILE_TEMPLATE_PATH_KEY );
    }

    return handleConfig( clarityConfigFileTemplatePath, clarityContextPath + Constants.CLRT_CONFIG_FILE_PATH );
  }

  private Messages formatMessages( List<com.niku.nsa.handlers.Message> ppmMessages )
  {
    logger.info( "Started formatting product validation response..." );
    Messages _messages = new Messages();
    _messages.setId( Constants.CLRT_PROD_VALIDATION_ID );
    _messages.setDescription( Constants.CLRT_PROD_VALIDATION_DESC );

    if( ppmMessages != null && ppmMessages.size() > 0 )
    {
      _messages.setStatus( Constants.Status.ERROR.toString() );
      for( com.niku.nsa.handlers.Message ppmMessage : ppmMessages )
      {
        Message message = new Message();
        message.setId( ppmMessage.getId() );
        message.setAttributeName( xpathToDefaultValuesAndHelmPathMap.get( ppmMessage.getLocation() ) != null ?
            xpathToDefaultValuesAndHelmPathMap.get( ppmMessage.getLocation() ).get( Constants.USER_KEY ) : ppmMessage.getLocation() );
        message.setType( ppmMessage.getType() );
        message.setValue( ppmMessage.getValue() );

        _messages.getMessageList().add( message );
      }
    }
    logger.info( "Completed formatting product validation response." );
    return _messages;
  }

  private boolean checkIfErrorMessageExists( Messages messages )
  {
    return (messages != null && messages.getMessageList() != null && messages.getMessageList().size() > 0);
  }

  public String getClarityContextPath()
  {
    return clarityContextPath;
  }

  public void setClarityContextPath( String clarityContextPath )
  {
    this.clarityContextPath = clarityContextPath;
  }

  public CommonValidator getCommonValidator()
  {
    return commonValidator;
  }

  public void setCommonValidator( CommonValidator commonValidator )
  {
    this.commonValidator = commonValidator;
  }

  private Document getDefaultValuesDoc( Document doc )
  {
    logger.info( "Setting default values in properties.xml..." );

    for( Map.Entry<String, Map<String, String>> entry : xpathToDefaultValuesAndHelmPathMap.entrySet() )
    {
      if( entry.getValue() != null && (entry.getValue()).get( Constants.DEFAULT_VALUE ) != null )
      {
        UtilityXPATH.setValue( doc, Constants.PROPERTIES_ELEMENT + entry.getKey(), entry.getValue().get( Constants.DEFAULT_VALUE ) );
      }
    }

    return doc;
  }

  private Document getUpdatedDoc( Document doc, Properties props )
  {
    Enumeration propsEnum = props.propertyNames();
    String vendor = "";
    String dwhVendor = "";
    logger.info( "Updating object of properties.xml with latest provided values..." );
    vendor = props.getProperty( Constants.PPM_DB_VENDOR_KEY );
    dwhVendor = props.getProperty( Constants.PPM_DWH_DB_VENDOR_KEY );
    String url = "";
    if(StringUtil.isNullOrEmpty(props.getProperty( Constants.PPM_DB_SPECIFY_URL_KEY ))){
      url = getDatabaseURL( props, false );
    } else{
      url = props.getProperty( Constants.PPM_DB_SPECIFY_URL_KEY );
    }

    if (!StringUtil.isNullOrEmpty(props.getProperty(Constants.PPM_DB_SPECIFY_URL_KEY)) ||
            !StringUtil.isNullOrEmpty(StringUtil.removeLeadingAndTrailingSingleQuotes(props.getProperty(Constants.PPM_DB_URL_ADD_PARAMS_KEY)))) {
      UtilityXPATH
              .setValue(doc, Constants.PROPERTIES_ELEMENT + containerToXPathAndHelmPathMap.get(Constants.PPM_DB_USE_URL_KEY).get(Constants.XPATH), "true");
    } else {
      UtilityXPATH
              .setValue(doc, Constants.PROPERTIES_ELEMENT + containerToXPathAndHelmPathMap.get(Constants.PPM_DB_USE_URL_KEY).get(Constants.XPATH), "false");
    }

    if( url != null && !url.isEmpty() )
    {
      UtilityXPATH.setValue( doc, Constants.PROPERTIES_ELEMENT + containerToXPathAndHelmPathMap.get( Constants.PPM_DB_SPECIFY_URL_KEY ).get( Constants.XPATH ), url );
    }
    if(StringUtil.isNullOrEmpty(props.getProperty( Constants.PPM_DWH_DB_SPECIFY_URL_KEY ))){
      url = getDatabaseURL( props, true );
    } else{
      url = props.getProperty( Constants.PPM_DWH_DB_SPECIFY_URL_KEY );
    }

    if (!StringUtil.isNullOrEmpty(props.getProperty(Constants.PPM_DWH_DB_SPECIFY_URL_KEY)) ||
            !StringUtil.isNullOrEmpty(StringUtil.removeLeadingAndTrailingSingleQuotes(props.getProperty(Constants.PPM_DWH_URL_ADD_PARAMS_KEY)))) {
      UtilityXPATH
              .setValue( doc, Constants.PROPERTIES_ELEMENT + containerToXPathAndHelmPathMap.get( Constants.PPM_DWH_DB_USE_URL_KEY ).get( Constants.XPATH ), "true" );
    } else {
      UtilityXPATH
              .setValue( doc, Constants.PROPERTIES_ELEMENT + containerToXPathAndHelmPathMap.get( Constants.PPM_DWH_DB_USE_URL_KEY ).get( Constants.XPATH ), "false" );
    }

    if( url != null && !url.isEmpty() )
    {
      UtilityXPATH
          .setValue( doc, Constants.PROPERTIES_ELEMENT + containerToXPathAndHelmPathMap.get( Constants.PPM_DWH_DB_SPECIFY_URL_KEY ).get( Constants.XPATH ), url );
    }

    //Checking db vendor and setting corresponding values.
    if( Constants.DB_VENDOR_MSSQL.equalsIgnoreCase( vendor ) )
    {
      doc = setDefaultDBValuesForMSSQL( doc );
      UtilityXPATH.setValue( doc, Constants.PROPERTIES_ELEMENT + Constants.PPM_APP_DB_DRIVER_PATH,
          Constants.JDBC_DRIVER_CLASS_MSSQL );
    }
    else if( Constants.DB_VENDOR_ORACLE.equals( vendor ) )
    {
      doc = setDefaultDBValuesForOracle( doc );
      UtilityXPATH.setValue( doc, Constants.PROPERTIES_ELEMENT + Constants.PPM_APP_DB_DRIVER_PATH,
          Constants.JDBC_DRIVER_CLASS_ORACLE );

      UtilityXPATH
          .setValue( doc, Constants.PROPERTIES_ELEMENT + containerToXPathAndHelmPathMap.get( Constants.PPM_DB_SCHEMA_NAME_KEY ).get( Constants.XPATH ),
              props.getProperty( Constants.PPM_DB_USERNAME_KEY ) );
    }
    else
    {
      //postgres
      doc = setDefaultDBValuesForPostgres( doc );
      UtilityXPATH.setValue( doc, Constants.PROPERTIES_ELEMENT + Constants.PPM_APP_DB_DRIVER_PATH, Constants.JDBC_DRIVER_CLASS_POSTGRES );
    }

    //Checking dwh vendor and setting corresponding values.
    if( Constants.DB_VENDOR_MSSQL.equalsIgnoreCase( dwhVendor ) )
    {
      doc = setDefaultDWHValuesForMSSQL( doc );
      UtilityXPATH.setValue( doc, Constants.PROPERTIES_ELEMENT + Constants.PPM_DWH_DB_DRIVER_PATH,
          Constants.JDBC_DRIVER_CLASS_MSSQL );
    }
    else if( Constants.DB_VENDOR_ORACLE.equals( dwhVendor ) )
    {
      doc = setDefaultDWHValuesForOracle( doc );
      UtilityXPATH.setValue( doc, Constants.PROPERTIES_ELEMENT + Constants.PPM_DWH_DB_DRIVER_PATH,
          Constants.JDBC_DRIVER_CLASS_ORACLE );

      UtilityXPATH
          .setValue( doc, Constants.PROPERTIES_ELEMENT + containerToXPathAndHelmPathMap.get( Constants.PPM_DWH_DB_SCHEMA_NAME_KEY ).get( Constants.XPATH ),
              props.getProperty( Constants.PPM_DWH_DB_USERNAME_KEY ) );
    }
    else
    {
      //postgres
      doc = setDefaultDWHValuesForPostgres( doc );
      UtilityXPATH.setValue( doc, Constants.PROPERTIES_ELEMENT + Constants.PPM_DWH_DB_DRIVER_PATH, Constants.JDBC_DRIVER_CLASS_POSTGRES );
    }

    // Check the status of PPM_JS_INTEGRATION_ENABLE from environment list
    if( environmentVariableMap.get( Constants.PPM_JS_INTEGRATION_ENABLE_KEY ) == null ||
        environmentVariableMap.get( Constants.PPM_JS_INTEGRATION_ENABLE_KEY ).equals( "false" ) )
    {
      String defaultUrl = Constants.DEFAULT_JASPER_URL;
      UtilityXPATH.setValue( doc, Constants.PROPERTIES_ELEMENT + Constants.PPM_JS_URL, defaultUrl );
    }


    while( propsEnum.hasMoreElements() )
    {
      String key = (String) propsEnum.nextElement();
      String value = props.getProperty( key );
      String xpath = containerToXPathAndHelmPathMap.get( key ) != null ? containerToXPathAndHelmPathMap.get( key ).get( Constants.XPATH ) : null;
      logger.debug( "key:" + key + ", xpath:" + xpath + ", value:" + value );
      if( xpath != null && value != null )
      {
        UtilityXPATH.setValue( doc, Constants.PROPERTIES_ELEMENT + xpath, StringUtil.removeLeadingAndTrailingSingleQuotes( value ).trim() );
      }

    }

    return doc;
  }

  private Document setDefaultDBValuesForMSSQL( Document doc )
  {
    logger.info( "Setting default db values for mssql" );

    UtilityXPATH
        .setValue( doc, Constants.PROPERTIES_ELEMENT + containerToXPathAndHelmPathMap.get( Constants.PPM_DB_INDX_SMALL_TS_KEY ).get( Constants.XPATH ), "" );
    UtilityXPATH
        .setValue( doc, Constants.PROPERTIES_ELEMENT + containerToXPathAndHelmPathMap.get( Constants.PPM_DB_INDX_LARGE_TS_KEY ).get( Constants.XPATH ), "" );
    UtilityXPATH
        .setValue( doc, Constants.PROPERTIES_ELEMENT + containerToXPathAndHelmPathMap.get( Constants.PPM_DB_USERS_LARGE_TS_KEY ).get( Constants.XPATH ), "" );
    UtilityXPATH
        .setValue( doc, Constants.PROPERTIES_ELEMENT + containerToXPathAndHelmPathMap.get( Constants.PPM_DB_USERS_SMALL_TS_KEY ).get( Constants.XPATH ), "" );
    UtilityXPATH.setValue( doc, Constants.PROPERTIES_ELEMENT + containerToXPathAndHelmPathMap.get( Constants.PPM_DB_SCHEMA_NAME_KEY ).get( Constants.XPATH ),
        Constants.DEFAULT_NIKU_SCHEMA );
    UtilityXPATH.setValue( doc, Constants.DB_VENDOR_PATH, Constants.DB_VENDOR_MSSQL );

    return doc;
  }

  private Document setDefaultDWHValuesForMSSQL( Document doc )
  {
    logger.info( "Setting default dwh values for mssql" );

    UtilityXPATH
        .setValue( doc, Constants.PROPERTIES_ELEMENT + containerToXPathAndHelmPathMap.get( Constants.PPM_DWH_DATA_DIM_TS_KEY ).get( Constants.XPATH ), "" );
    UtilityXPATH
        .setValue( doc, Constants.PROPERTIES_ELEMENT + containerToXPathAndHelmPathMap.get( Constants.PPM_DWH_DATA_FACT_TS_KEY ).get( Constants.XPATH ), "" );
    UtilityXPATH
        .setValue( doc, Constants.PROPERTIES_ELEMENT + containerToXPathAndHelmPathMap.get( Constants.PPM_DWH_INDX_DIM_TS_KEY ).get( Constants.XPATH ), "" );
    UtilityXPATH
        .setValue( doc, Constants.PROPERTIES_ELEMENT + containerToXPathAndHelmPathMap.get( Constants.PPM_DWH_INDX_FACT_TS_KEY ).get( Constants.XPATH ), "" );
    UtilityXPATH
        .setValue( doc, Constants.PROPERTIES_ELEMENT + containerToXPathAndHelmPathMap.get( Constants.PPM_DWH_DB_SCHEMA_NAME_KEY ).get( Constants.XPATH ),
            Constants.DEFAULT_PPM_DWH_SCHEMA );
    UtilityXPATH.setValue( doc, Constants.PROPERTIES_ELEMENT + containerToXPathAndHelmPathMap.get( Constants.HDP_DWH_RO_ROLE_KEY ).get( Constants.XPATH ), "" );
    UtilityXPATH
        .setValue( doc, Constants.PROPERTIES_ELEMENT + containerToXPathAndHelmPathMap.get( Constants.HDP_DWH_RO_USERNAME_KEY ).get( Constants.XPATH ), "" );
    UtilityXPATH
        .setValue( doc, Constants.PROPERTIES_ELEMENT + containerToXPathAndHelmPathMap.get( Constants.HDP_DWH_RO_USER_PASSWORD_KEY ).get( Constants.XPATH ),
            "" );
    UtilityXPATH.setValue( doc, Constants.DWH_DB_VENDOR_PATH, Constants.DB_VENDOR_MSSQL );

    return doc;
  }

  private Document setDefaultDBValuesForOracle( Document doc )
  {
    logger.info("Setting default db values for oracle");
    UtilityXPATH.setValue(doc, Constants.DB_VENDOR_PATH, Constants.DB_VENDOR_ORACLE);
    return doc;
  }

  private Document setDefaultDWHValuesForOracle( Document doc )
  {
    logger.info("Setting default dwh values for oracle");
    UtilityXPATH.setValue(doc, Constants.DWH_DB_VENDOR_PATH, Constants.DB_VENDOR_ORACLE);
    return doc;
  }

  private Document setDefaultDBValuesForPostgres( Document doc )
  {
    logger.info( "Setting default values for postgres" );
    UtilityXPATH
      .setValue( doc, Constants.PROPERTIES_ELEMENT + containerToXPathAndHelmPathMap.get( Constants.PPM_DB_INDX_SMALL_TS_KEY ).get( Constants.XPATH ),
        Constants.PPM_POSTGRES_DB_INDX_TS_VALUE );
    UtilityXPATH
      .setValue( doc, Constants.PROPERTIES_ELEMENT + containerToXPathAndHelmPathMap.get( Constants.PPM_DB_INDX_LARGE_TS_KEY ).get( Constants.XPATH ),
        Constants.PPM_POSTGRES_DB_INDX_TS_VALUE );
    UtilityXPATH
      .setValue( doc, Constants.PROPERTIES_ELEMENT + containerToXPathAndHelmPathMap.get( Constants.PPM_DB_USERS_LARGE_TS_KEY ).get( Constants.XPATH ),
        Constants.PPM_POSTGRES_DB_USERS_TS_VALUE );
    UtilityXPATH
      .setValue( doc, Constants.PROPERTIES_ELEMENT + containerToXPathAndHelmPathMap.get( Constants.PPM_DB_USERS_SMALL_TS_KEY ).get( Constants.XPATH ),
        Constants.PPM_POSTGRES_DB_USERS_TS_VALUE );

    UtilityXPATH.setValue( doc, Constants.DB_VENDOR_PATH, Constants.DB_VENDOR_POSTGRES );
    return doc;
  }

  private Document setDefaultDWHValuesForPostgres( Document doc )
  {
    logger.info( "Setting default values for postgres" );
    UtilityXPATH
        .setValue( doc, Constants.PROPERTIES_ELEMENT + containerToXPathAndHelmPathMap.get( Constants.PPM_DWH_DATA_DIM_TS_KEY ).get( Constants.XPATH ),
            Constants.PPM_POSTGRES_DWH_USERS_TS_VALUE );
    UtilityXPATH
        .setValue( doc, Constants.PROPERTIES_ELEMENT + containerToXPathAndHelmPathMap.get( Constants.PPM_DWH_DATA_FACT_TS_KEY ).get( Constants.XPATH ),
            Constants.PPM_POSTGRES_DWH_USERS_TS_VALUE );
    UtilityXPATH
        .setValue( doc, Constants.PROPERTIES_ELEMENT + containerToXPathAndHelmPathMap.get( Constants.PPM_DWH_INDX_DIM_TS_KEY ).get( Constants.XPATH ),
            Constants.PPM_POSTGRES_DWH_INDX_TS_VALUE );
    UtilityXPATH
        .setValue( doc, Constants.PROPERTIES_ELEMENT + containerToXPathAndHelmPathMap.get( Constants.PPM_DWH_INDX_FACT_TS_KEY ).get( Constants.XPATH ),
            Constants.PPM_POSTGRES_DWH_INDX_TS_VALUE );

    UtilityXPATH.setValue( doc, Constants.DWH_DB_VENDOR_PATH, Constants.DB_VENDOR_POSTGRES );
    return doc;
  }

  public String getDatabaseURL( Properties props, boolean isDWH )
  {
    String vendor;
    String host;
    String port;
    String sid;
    String instanceName;
    String urlParams;
    logger.debug( "isDWH:" + isDWH );
    logger.info( "Build db url for " + (isDWH ? "DWH" : "DB") );
    if( !isDWH )
    {
      vendor = props.getProperty( Constants.PPM_DB_VENDOR_KEY );
      host = props.getProperty( Constants.PPM_DB_HOST_KEY );
      port = props.getProperty( Constants.PPM_DB_PORT_KEY );
      sid = props.getProperty( Constants.PPM_DB_SERVICE_ID_KEY );
      instanceName = props.getProperty( Constants.PPM_DB_SERVICE_ID_KEY );
      urlParams= props.getProperty( Constants.PPM_DB_URL_ADD_PARAMS_KEY );
    }
    else
    {
      vendor = props.getProperty( Constants.PPM_DWH_DB_VENDOR_KEY );
      host = props.getProperty( Constants.PPM_DWH_DB_HOST_KEY );
      port = props.getProperty( Constants.PPM_DWH_DB_PORT_KEY );
      sid = props.getProperty( Constants.PPM_DWH_DB_SERVICE_ID_KEY );
      instanceName = props.getProperty( Constants.PPM_DWH_DB_SERVICE_ID_KEY );
      urlParams= props.getProperty( Constants.PPM_DWH_URL_ADD_PARAMS_KEY );
    }

    MigratableDatabaseURL newUrl = null;
    try
    {
      newUrl = new MigratableDatabaseURL( vendor, host, port, sid, instanceName );
    }
    catch( IllegalArgumentException ex )
    {
      // If db vendor is invalid, we will get illegal exception.
      // We are catching that exception letting the validation frame work to do all validations and give complete validation errors.
    }

    String finalURL = null;
    if( newUrl != null && !StringUtil.isNullOrEmpty( StringUtil.removeLeadingAndTrailingSingleQuotes( urlParams ) ) )
    {
      urlParams = StringUtil.removeLeadingAndTrailingSingleQuotes(urlParams);
      if (Constants.DB_VENDOR_POSTGRES.equalsIgnoreCase(vendor)) {
        finalURL = newUrl.toString() + (urlParams.startsWith("?") ? urlParams : "?" + urlParams);
      } else {
        finalURL = newUrl.toString() + (urlParams.startsWith(";") ? urlParams : ";" + urlParams);
      }
    }
    else
    {
      finalURL = newUrl != null ? newUrl.toString() : null;
    }

    return finalURL;
  }

  @Override
  public void populateMappings()
  {
    handlerUtilities.populateMappings( Constants.CLRT_MAPPING_JSON_PROP );
    // If properties file already exist in the runtime then
    // dont update the properties that can be modified from application with default values.
    if ( !isUpdate() )
    {
      logger.info("Properties.xml is not present in the runtime. Hence using app mapping json also.");
      handlerUtilities.populateMappings( Constants.CLRT_APP_MAPPING_JSON_PROP );
    }
  }


  private void loadSecrets( Properties props )
  {
    loadSecretIntoProps( Constants.PPM_DB_USERNAME_KEY, props );
    loadSecretIntoProps( Constants.PPM_DB_PASSWORD_KEY, props );
    loadSecretIntoProps( Constants.PPM_DWH_DB_USERNAME_KEY, props );
    loadSecretIntoProps( Constants.PPM_DWH_DB_PASSWORD_KEY, props );
    loadSecretIntoProps( Constants.PPM_DB_PRIVILEGED_USER_KEY, props );
    loadSecretIntoProps( Constants.PPM_DB_PRIVILEGED_USER_PWD_KEY, props );
    loadSecretIntoProps( Constants.JS_PRIVILEGED_USER_KEY, props );
    loadSecretIntoProps( Constants.JS_PRIVILEGED_USER_PWD_KEY, props );
    loadSecretIntoProps( Constants.HDP_DWH_RO_USERNAME_KEY, props );
    loadSecretIntoProps( Constants.HDP_DWH_RO_USER_PASSWORD_KEY, props );
    loadSecretIntoProps( Constants.HDP_PRIVILEGED_USER_KEY, props );
    loadSecretIntoProps( Constants.HDP_PRIVILEGED_USER_PWD_KEY, props );
    loadSecretIntoProps( Constants.PPM_MAILSERVER_USERNAME_KEY, props );
    loadSecretIntoProps( Constants.PPM_MAILSERVER_PASSWORD_KEY, props );
    loadSecretIntoProps( Constants.PPM_DS_ADMIN_USER_KEY, props );
    loadSecretIntoProps( Constants.PPM_DS_ADMIN_PASSWORD_KEY, props );
    loadSecretIntoProps( Constants.PPM_SSL_PASSWORD_KEY, props );
  }

  private String getStringValue( String value )
  {
    return value != null ? value : "";
  }

  private void loadSecretIntoProps( String key, Properties props )
  {
    if( !StringUtil.isNullOrEmpty( getStringValue( environmentVariableMap.get( key ) ) ) )
    {
      props.put( key, getStringValue( environmentVariableMap.get( key ) ) );
    }
  }

  private boolean isUpdate()
  {
    boolean update = false;
    Properties clarityPropertiesObject = (Properties) applicationContext.getBean( APP_PROPERTIES );
    if( clarityPropertiesObject != null )
    {
      String configFilePath = clarityPropertiesObject.getProperty( Constants.CLARITY_CONTEXT_PATH_KEY ) + File.separator + Constants.CLRT_CONFIG_FOLDER + File.separator + configFileName;

      // If properties file already exists in the runtime then it will be the update.
      File configFile = new File( configFilePath );
      if ( configFile.exists() )
      {
        update = true;
      }
    }
    return update;
  }

}