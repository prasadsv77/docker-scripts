package com.broadcom.clarity.validator.util;

import com.broadcom.clarity.validator.exception.ValidationWrapperException;
import com.niku.union.utility.StringUtil;
import org.apache.logging.log4j.LogManager;
import org.apache.logging.log4j.Logger;
import org.json.JSONArray;
import org.json.JSONException;
import org.json.JSONObject;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.context.ApplicationContext;
import org.springframework.context.annotation.Scope;
import org.springframework.context.annotation.ScopedProxyMode;
import org.springframework.core.io.ClassPathResource;
import org.springframework.stereotype.Component;
import org.springframework.stereotype.Service;

import java.io.File;
import java.io.IOException;
import java.nio.file.Files;
import java.nio.file.InvalidPathException;
import java.nio.file.Paths;
import java.util.HashMap;
import java.util.Map;
import java.util.Properties;
import java.util.Set;

@Component
public class HandlerUtilities
{
  private static Logger logger = LogManager.getLogger( HandlerUtilities.class );
  private static String OS = System.getProperty( "os.name" ).toLowerCase();
  @Autowired
  private ApplicationContext applicationContext;
  private static String APP_PROPERTIES = Constants.APP_PROPS_NAME;
  private Map<String, Map<String, String>> containerToXPathAndHelmPathMap;
  private Map<String, Map<String, String>> xpathToDefaultValuesAndHelmPathMap;
  public static Map<String, String> environmentVariableMap = System.getenv();

  public static Map getOsEnvironmentVariables()
  {
    return System.getenv();
  }

  public static File loadResourceFileFromClassPath( String classPathResourceFileName ) throws IOException
  {
    File resource = new ClassPathResource( classPathResourceFileName ).getFile();

    if( resource != null )
    {
      return resource;
    }
    return null;
  }

  public static File loadResourceFileFromSystemPath( String path, String fileName )
  {
    File _resourceFile = null;
    if( path != null && fileName != null )
    {
      if( isValidPath( path ) )
      {
        _resourceFile = new File( path + File.separator + fileName );
      }
      if( _resourceFile.exists() )
      {
        return _resourceFile;
      }
    }

    return null;
  }

  public static String getJsonContentFromFile( String path, String fileName, boolean systemFilePath ) throws IOException
  {
    String fileContent = null;
    if( systemFilePath )
    {
      File _resource = loadResourceFileFromSystemPath( path, fileName );
      if( _resource != null )
      {
        fileContent = new String( Files.readAllBytes( _resource.toPath() ) );
      }

    }
    return fileContent;
  }

  public static boolean isJSONValid( String test )
  {
    try
    {
      new JSONObject( test );
    }
    catch( JSONException ex )
    {
      try
      {
        new JSONArray( test );
      }
      catch( JSONException ex1 )
      {
        return false;
      }
    }
    return true;
  }

  private static boolean isValidPath( String path )
  {
    try
    {
      Paths.get( path );
    }
    catch( InvalidPathException | NullPointerException ex )
    {
      return false;
    }
    return true;
  }

  public static boolean isWindows()
  {
    return (OS.indexOf( "win" ) >= 0);
  }

  public ApplicationContext getApplicationContext()
  {
    return applicationContext;
  }

  public void setApplicationContext( ApplicationContext applicationContext )
  {
    this.applicationContext = applicationContext;
  }

  public void populateMappings( String mappingJSONFileName )
  {
    //This map will have the mapping between container key(PPM_DB_VENDOR) and xpath in properties.xml(databaseServer/@vendor) and helm path(db.vendor)
    containerToXPathAndHelmPathMap = (Map<String, Map<String, String>>) applicationContext.getBean( "containerToXPathAndHelmPathMap" );
    //This map will have the mapping between xpath in properties.xml(databaseServer/@fetchSize) and default value(60) of that property and helm path
    xpathToDefaultValuesAndHelmPathMap = (Map<String, Map<String, String>>) applicationContext.getBean( "xpathToDefaultValuesAndHelmPathMap" );
    logger.info( "Processing JSON mapping." );
    Properties propertiesObject = (Properties) applicationContext.getBean( APP_PROPERTIES );
    try
    {
      if( propertiesObject != null )
      {
        String _fileJsonContent = HandlerUtilities.getJsonContentFromFile( propertiesObject.getProperty( Constants.APP_VALIDTION_DEF_JSON_PATH ),
          propertiesObject.getProperty( mappingJSONFileName ), true );
        if( _fileJsonContent != null && HandlerUtilities.isJSONValid( _fileJsonContent ) )
        {
          JSONObject jsonObject = new JSONObject( _fileJsonContent );
          populateMapsFromJSON( jsonObject );
        }
      }
      logger.debug( "containerToXPathAndHelmPathMap:" + containerToXPathAndHelmPathMap );
      logger.debug( "xpathToDefaultValuesAndHelmPathMap:" + xpathToDefaultValuesAndHelmPathMap );
      logger.info( "Processed JSON mapping." );
    }
    catch( Exception e )
    {
      logger.error( "Error while reading container variable definition file -" +
                    propertiesObject.getProperty( Constants.APP_VALIDTION_DEF_JSON_PATH )
                    + File.separator
                    + propertiesObject.getProperty( Constants.CLRT_MAPPING_JSON_PROP ) + " ", e.getMessage() );
      throw new ValidationWrapperException( "Message:Error while reading container variable definition file", e,
        "401" );
    }
  }

  public void populateMapsFromJSON( JSONObject jsonObject )
  {
    logger.debug( "Populating Maps with all the json values" );
    Set<String> keys = jsonObject.keySet();
    Map<String, String> map = null;
    if( keys.contains( Constants.CONTAINER_KEY ) || keys.contains( Constants.XPATH ) )
    { // Here we are first getting the map on the container key and if it not exists then creating a map
      // and adding word "xpath" as key and actual xpath as value
      // and then we are adding this map to the another map with container key as map key.
      // For below json this map will populate as <PPM_EXTERNAL_URL, <xpath,applicationServer/@externalUrl>>
      //      "containerKey": "PPM_EXTERNAL_URL",
      //      "xpath": "applicationServer/@externalUrl"
      //      "userKey": "app.externalUrl"
      if( jsonObject.keySet().contains( Constants.CONTAINER_KEY ) && jsonObject.keySet().contains( Constants.XPATH ) )
      {
        map = containerToXPathAndHelmPathMap.get( (String) jsonObject.get( Constants.CONTAINER_KEY ) );
        if( map == null )
        {
          map = new HashMap<>();
        }
        map.put( Constants.XPATH, (String) jsonObject.get( Constants.XPATH ) );
        containerToXPathAndHelmPathMap.put( (String) jsonObject.get( Constants.CONTAINER_KEY ), map );
      }
      // Here we are first getting the map on the container key and as we already added the same container key in the above condition we will get that map
      // and adding word "userKey" as key and actual userKey as value.(if map does not exist we will create it)
      // and then we are adding this map to the another map with container key as map key.
      // For below json this map will populate as <PPM_EXTERNAL_URL,<(xpath,applicationServer/@externalUrl),(userKey,app.externalUrl)>>
      //      "containerKey": "PPM_EXTERNAL_URL",
      //      "xpath": "applicationServer/@externalUrl"
      //      "userKey": "app.externalUrl"
      if( jsonObject.keySet().contains( Constants.CONTAINER_KEY ) && jsonObject.keySet().contains( Constants.USER_KEY ) )
      {
        map = containerToXPathAndHelmPathMap.get( (String) jsonObject.get( Constants.CONTAINER_KEY ) );
        if( map == null )
        {
          map = new HashMap<>();
        }
        map.put( Constants.USER_KEY, (String) jsonObject.get( Constants.USER_KEY ) );
        containerToXPathAndHelmPathMap.put( (String) jsonObject.get( Constants.CONTAINER_KEY ), map );
      }

      // Here we are first getting the map on the xpath and if it not exists then creating a map
      // and adding word "defaultValue" as key and actual defaultValue as value
      // and then we are adding this map to the another map with xpath as map key.
      // For below json this map will populate as <dwhDatabaseServer/database/@isCustomDBLink, <defaultValue,true>>
      //    "xpath": "dwhDatabaseServer/database/@isCustomDBLink",
      //    "defaultValue": "true"
      if( jsonObject.keySet().contains( Constants.XPATH ) && jsonObject.keySet().contains( Constants.DEFAULT_VALUE ) )
      {
        map = xpathToDefaultValuesAndHelmPathMap.get( (String) jsonObject.get( Constants.XPATH ) );
        if( map == null )
        {
          map = new HashMap<>();
        }
        map.put( Constants.DEFAULT_VALUE, (String) jsonObject.get( Constants.DEFAULT_VALUE ) );
        xpathToDefaultValuesAndHelmPathMap.put( (String) jsonObject.get( Constants.XPATH ), map );
      }

      // Here we are first getting the map on the xpath and if it not exists then creating a map
      // and adding word "userKey" as key and actual userKey as value
      // and then we are adding this map to the another map with xpath as map key.
      // For below json this map will populate as <applicationServer/@externalUrl, <userKey,app.externalUrl>>
      //    "containerKey": "PPM_EXTERNAL_URL",
      //      "xpath": "applicationServer/@externalUrl",
      //      "userKey": "app.externalUrl"
      if( jsonObject.keySet().contains( Constants.XPATH ) && jsonObject.keySet().contains( Constants.USER_KEY ) )
      {
        map = xpathToDefaultValuesAndHelmPathMap.get( (String) jsonObject.get( Constants.XPATH ) );
        if( map == null )
        {
          map = new HashMap<>();
        }
        map.put( Constants.USER_KEY, (String) jsonObject.get( Constants.USER_KEY ) );
        xpathToDefaultValuesAndHelmPathMap.put( (String) jsonObject.get( Constants.XPATH ), map );
      }
    }
    else
    {
      for( String key : keys )
      {
        populateMapsFromJSON( (JSONObject) jsonObject.get( key ) );
      }
    }
    logger.debug( "Populated Maps with all the json values" );
  }

  public static boolean isNullOrEmptyEnvironmentVariable( String envVariableName_ )
  {
    return !environmentVariableMap.containsKey( envVariableName_ ) || StringUtil
      .isNullOrEmpty( environmentVariableMap.get( envVariableName_ ).trim() );
  }

}