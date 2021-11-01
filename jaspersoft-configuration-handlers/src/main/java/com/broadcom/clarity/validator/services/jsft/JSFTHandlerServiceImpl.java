package com.broadcom.clarity.validator.services.jsft;

import com.broadcom.clarity.validator.exception.ValidationWrapperException;
import com.broadcom.clarity.validator.response.Messages;
import com.broadcom.clarity.validator.services.AbstractPrepareMessages;
import com.broadcom.clarity.validator.services.ApplicationHandlerService;
import com.broadcom.clarity.validator.services.helpers.CommonValidator;
import com.broadcom.clarity.validator.util.Constants;
import com.broadcom.clarity.validator.util.HandlerUtilities;
import org.apache.logging.log4j.LogManager;
import org.apache.logging.log4j.Logger;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.context.ApplicationContext;
import org.springframework.context.annotation.Scope;
import org.springframework.context.annotation.ScopedProxyMode;
import org.springframework.stereotype.Service;
import org.w3c.dom.Document;

import java.io.File;
import java.util.List;
import java.util.Properties;

@Service
@Scope(proxyMode = ScopedProxyMode.TARGET_CLASS, value = "prototype")
public class JSFTHandlerServiceImpl extends AbstractPrepareMessages implements ApplicationHandlerService
{
  private static Logger logger = LogManager.getLogger( JSFTHandlerServiceImpl.class );
  @Autowired
  private ApplicationContext applicationContext;
  @Autowired
  private CommonValidator commonValidator;
  private static String APP_PROPERTIES = Constants.APP_PROPS_NAME;

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


  @Override
  public Messages productValidation(Document doc) {
    return null;
  }

  @Override
  public Messages containerValidation()
  {
    Properties jsftPropertiesObject = (Properties) applicationContext.getBean( APP_PROPERTIES );
    try
    {
      if(jsftPropertiesObject != null)
      {
        String _fileJsonContent = HandlerUtilities.getJsonContentFromFile( jsftPropertiesObject.getProperty( Constants.APP_VALIDTION_DEF_JSON_PATH ),
          jsftPropertiesObject.getProperty( Constants.JSFT_ENV_VARIABLE_JSON_PROP ), true );
        if( _fileJsonContent != null && HandlerUtilities.isJSONValid( _fileJsonContent ) )
        {
          logger.debug( "JSON File Content " + _fileJsonContent );
          Messages messages = commonValidator.validationForEnvVar( _fileJsonContent, Constants.SupportedApps.jaspersoft.toString() );
          return messages;
        }
      }
    }
    catch( Exception e )
    {
      logger.error( "Error while reading container variable definition file -" +
                    jsftPropertiesObject.getProperty( Constants.APP_VALIDTION_DEF_JSON_PATH )
                    + File.separator
                    + jsftPropertiesObject.getProperty( Constants.JSFT_ENV_VARIABLE_JSON_PROP ) + " ", e.getMessage() );
      throw new ValidationWrapperException( "Message:Error while reading container variable definition file", e,
        "401" );
    }

    return null;
  }

  @Override
  public List<Messages> updateConfigurations()
  {
    return null;
  }

  @Override
  public List<Messages> populateConfigurations()
  {
    return null;
  }

  @Override
  public void populateMappings(){
    handlerUtilities.populateMappings( Constants.JSFT_MAPPING_JSON_PROP );
  }
}
