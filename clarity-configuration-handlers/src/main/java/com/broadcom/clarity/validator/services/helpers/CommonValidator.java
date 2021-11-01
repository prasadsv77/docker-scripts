package com.broadcom.clarity.validator.services.helpers;

import com.broadcom.clarity.validator.response.Message;
import com.broadcom.clarity.validator.response.Messages;
import com.broadcom.clarity.validator.util.Constants;
import com.broadcom.clarity.validator.util.HandlerUtilities;
import com.niku.union.utility.StringUtil;
import org.apache.logging.log4j.LogManager;
import org.apache.logging.log4j.Logger;
import org.json.JSONArray;
import org.json.JSONObject;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.context.ApplicationContext;
import org.springframework.context.annotation.Scope;
import org.springframework.context.annotation.ScopedProxyMode;
import org.springframework.stereotype.Component;

import java.util.HashMap;
import java.util.List;
import java.util.Map;
import java.util.regex.Pattern;

@Component(Constants.COMMON_VALIDATOR)
@Scope(proxyMode = ScopedProxyMode.TARGET_CLASS, value = "prototype")
public class CommonValidator
{
  private static Logger logger = LogManager.getLogger( CommonValidator.class );
  private static Map<String, String> environmentVariableMap = System.getenv();
  public static final String ANY = "...";
  @Autowired
  private ApplicationContext applicationContext;

  private HashMap<String,HashMap<String,String>> containerToXPathAndHelmPathMap;
  public Messages validationForEnvVar( String jsonStr, String productName )
  {
    containerToXPathAndHelmPathMap = (HashMap<String,HashMap<String,String>>)applicationContext.getBean( "containerToXPathAndHelmPathMap" );

    Messages _messages = new Messages();
    _messages.setId( productName.toUpperCase() + "-ENVIRONMENT-VARIABLE-" + Constants.PROD_CONTAINER_VALIDATION );
    _messages.setDescription( productName.toUpperCase() + "-ENVIRONMENT-VARIABLE-" + Constants.PROD_CONTAINER_VALIDATION );

    JSONObject jsonObject = new JSONObject( jsonStr );
    JSONArray parentJsonArray = jsonObject.getJSONArray( "env" );

    for( int i = 0; i < parentJsonArray.length(); i++ )
    {
      JSONObject envJSON = parentJsonArray.getJSONObject( i );
      validateJSONObject( envJSON, productName, _messages ); // Default validations
    }
    return _messages;
  }

  private void validateJSONObject( JSONObject jsonObject_, String productName, Messages messages_ )
  {
    String _envVarName = jsonObject_.getString( "name" );
    String isMandatory = jsonObject_.getString( "mandatory" );
    boolean mandatoryCheckFailed = validateMandatory( _envVarName, productName, messages_, isMandatory );
    // AcceptedValue condition is to be check in cases 1) if the attribute is not mandatory and but have acceptedValue in definition
    // 2) If the attribute values is Mandatory and having value
    // We can skip the case where attribute value is not mandatory and doesn't have any value defined in environment
    if (!mandatoryCheckFailed && !HandlerUtilities.isNullOrEmptyEnvironmentVariable( _envVarName ))
    {
      if( jsonObject_.has( "acceptedValues" ) )
      {
        isAcceptedValue( _envVarName, productName, messages_, jsonObject_.getJSONArray( "acceptedValues" ) );
      }
      if( jsonObject_.has( "validation" ) )
      {
        checkValidations( _envVarName, productName, messages_, jsonObject_.getJSONArray( "validation" ) );
      }
      if( jsonObject_.has( "dependents" ) )
      {
        validateDependents( _envVarName, productName, messages_, jsonObject_.getJSONArray( "dependents" ) );
      }
    }
  }

  private boolean validateMandatory( String envVariableName, String productName, Messages _messages, String isMandatory )
  {
    boolean isMandatoryError =false;
    if( Boolean.parseBoolean( isMandatory ) )
    {
      if( HandlerUtilities.isNullOrEmptyEnvironmentVariable( envVariableName ) )
      {
        logger.debug( "name --> " + envVariableName + "; mandatory --> " + isMandatory + "; NOT AVAILABLE" );
        _messages.setStatus( Constants.Status.ERROR.toString() );
        generateMessages( _messages, envVariableName, Constants.MsgValues.IS_MANDATORY.toString(), "error",
          productName.toLowerCase() + ".ENV.VARIABLE".toLowerCase().concat( ".mandatory" ) );
        isMandatoryError = true;
      }
    }
    return isMandatoryError;
  }

  private boolean isAcceptedValue( String envVariableName, String productName, Messages _messages, JSONArray _acceptedValues )
  {
    if( _acceptedValues != null )
    {
      List listOfValues = _acceptedValues.toList();
      String envVariableValue = HandlerUtilities.environmentVariableMap.get( envVariableName );
      String[] envVariableValues = (envVariableValue != null && !envVariableValue.trim().isEmpty()) ? envVariableValue.split( "," ) : null;
      if( listOfValues != null && listOfValues.size() > 0 )
      {
        if( envVariableValues != null && envVariableValues.length > 0 )
        {
          for( String value : envVariableValues )
          {
            if( !listOfValues.contains( value ) )
            {
              generateMessages( _messages, envVariableName,
                Constants.MsgValues.INVALID_VALUE.toString() + "" + listOfValues, "error",
                productName.toLowerCase() + ".ENV.VARIABLE".toLowerCase().concat( ".invalid.value" ) );
              return false;
            }
          }
        }
        else
        {
          return false;
        }
      }
    }
    return true;
  }

  private boolean checkValidations( String envVariableName, String productName, Messages _messages, JSONArray _validationList )
  {
    if (_validationList != null)
    {
      boolean result;
      List validationList = _validationList.toList();
      for( Object validation : validationList )
      {
        switch( validation.toString() )
        {
          case "isPortValid":
          {
            result = checkPort( envVariableName, productName, _messages );
            if (result)
              break;
            else
              return result;
          }
          case "isUrlValid":
            result = isUrlValid( envVariableName, productName, _messages );
            if (result)
              break;
            else
              return result;
          case "isValidJasperObject":
            result = isValidJasperObject( envVariableName, productName, _messages );
            if (result)
              break;
            else
              return result;
        }
      }
    }
    return true;
  }

  private boolean isUrlValid(String variableName, String productName, Messages _messages)
  {
    String envVariableValue = HandlerUtilities.environmentVariableMap.get( variableName );
    String url_pattern = "^(http:\\/\\/www\\.|https:\\/\\/www\\.|http:\\/\\/|https:\\/\\/)?[a-z0-9]+([\\-\\.]{1}[a-z0-9]+)*\\.[a-z]{2,5}(:[0-9]{1,5})?(\\/[a-zA-Z0-9\\+\\.\\&\\?\\=\\-\\:\\%\\#\\/]*)?$";
    if( !Pattern.matches( url_pattern, envVariableValue ) )
    {
      generateMessages( _messages, variableName, Constants.MsgValues.INVALID_URL.toString(), "error",
        productName.toLowerCase() + ".ENV.VARIABLE".toLowerCase().concat( ".url" ) );
      return false;
    }
    return true;
  }
  private boolean checkPort(String variableName, String productName, Messages _messages)
  {
    String envVariableValue = HandlerUtilities.environmentVariableMap.get( variableName );
    String port_pattern = "^()([1-9]|[1-5]?[0-9]{2,4}|6[1-4][0-9]{3}|65[1-4][0-9]{2}|655[1-2][0-9]|6553[1-5])$";
    if( !Pattern.matches( port_pattern, envVariableValue ) )
    {
      generateMessages( _messages, variableName, Constants.MsgValues.INVALID_PORT.toString(), "error",
        productName.toLowerCase() + ".ENV.VARIABLE".toLowerCase().concat( ".port" ) );
      return false;
    }
    return true;
  }
 // check whether the jaspersoft object name is valid or not
 private boolean isValidJasperObject( String variableName, String productName, Messages _messages )
 {
   String envVariableValue = HandlerUtilities.environmentVariableMap.get( variableName );
   String object_pattern = "^[a-z0-9_]*$";
   boolean isValidObject = true;
   if( !Pattern.matches( object_pattern, envVariableValue ) )
   {
     generateMessages( _messages, variableName, Constants.MsgValues.INVALID_JASPER_TEXT_FORMAT.toString(), "error",
       productName.toLowerCase() + ".ENV.VARIABLE.".toLowerCase().concat( variableName ) );
     isValidObject = false;
   }
   return isValidObject;
 }

  /**
   * Validates the dependent attributes
   *     {
   *       "name": "ENV_VAR_1",
   *       "mandatory": "true",
   *       "acceptedValues": ["od","op","azure"],
   *       "validation": [],
   *       "dependents": [
   *         {
   *           "name": "DEPENDENT_1",
   *           "acceptedParentValues": ["test"]
   *         },
   *         {
   *           "name": "DEPENDENT_2",
   *           "acceptedParentValues": ["..."]
   *         }
   *       ]
   *     }
   * The method checks that
   * 1. The env variable 'DEPENDENT_1' must be present when 'ENV_VAR_1' is present and its value is "test"
   * 2. The env variable 'DEPENDENT_2' must be present when 'ENV_VAR_1' is present
   *
   * @param dependents_ Array of dependent environment variables with name and accepted parent values
   */
  private void validateDependents( String envVarName_, String productName_, Messages messages_, JSONArray dependents_ )
  {
    String envString = HandlerUtilities.environmentVariableMap.get( envVarName_ );
    for( int i = 0; i < dependents_.length(); i++ )
    {
      JSONObject obj = (JSONObject) dependents_.get( i );
      String dependentName = obj.getString( "name" );
      JSONArray acceptedValues = (JSONArray) obj.get( "acceptedParentValues" );
      if( acceptedValues == null || acceptedValues.length() == 0 ) { continue; }

      // '...' => child should be present when parent is present
      if( acceptedValues.get( 0 ).equals( Constants.ANY ) )
      {
        //if child is not present when parent is present => throw error
        if( HandlerUtilities.isNullOrEmptyEnvironmentVariable( dependentName ))
        {
          generateMessages( messages_, dependentName, dependentName + "::" + Constants.MsgValues.DEPENDENT_MISSING.toString() , "error",
            productName_ + ".ENV.VARIABLE".toLowerCase().concat( ".mandatory" ) );
        }
      }
      // check if parent value matches with list of accepted value for child
      else
      {
        for( int j = 0; j < acceptedValues.length(); j++ )
        {

          // if parent's value matches with what child is expecting => child should be mandatory
          if( acceptedValues.toList().contains( envString ) )
          {
            if( HandlerUtilities.isNullOrEmptyEnvironmentVariable( dependentName ))
            {
              generateMessages( messages_, dependentName, dependentName + "::" + Constants.MsgValues.DEPENDENT_MISSING.toString() , "error",
                productName_ + ".ENV.VARIABLE".toLowerCase().concat( ".mandatory" ) );
              break;
            }
          }
        }
      }
    }
  }


  private void generateMessages( Messages _messages, String attrName, String value, String type, String id )
  {
    _messages.setStatus( Constants.Status.ERROR.toString() );

    Message message = new Message();
    message.setAttributeName( containerToXPathAndHelmPathMap.get(attrName)!= null ? containerToXPathAndHelmPathMap.get(attrName).get(Constants.USER_KEY): attrName );
    message.setValue( value );
    message.setType( type );
    message.setId( id );
    _messages.getMessageList().add( message );
  }

  public HashMap<String, HashMap<String, String>> getContainerToXPathAndHelmPathMap()
  {
    return containerToXPathAndHelmPathMap;
  }

  public void setContainerToXPathAndHelmPathMap( HashMap<String, HashMap<String, String>> containerToXPathAndHelmPathMap )
  {
    this.containerToXPathAndHelmPathMap = containerToXPathAndHelmPathMap;
  }
}