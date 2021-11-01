package com.broadcom.clarity.validator.entrypoint;

import com.broadcom.clarity.validator.model.Application;
import com.broadcom.clarity.validator.response.Messages;
import com.broadcom.clarity.validator.response.builder.factory.MessageBuilderFactory;
import com.broadcom.clarity.validator.util.Constants;
import org.apache.logging.log4j.LogManager;
import org.apache.logging.log4j.Logger;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.boot.Banner;
import org.springframework.boot.CommandLineRunner;
import org.springframework.boot.SpringApplication;
import org.springframework.boot.autoconfigure.SpringBootApplication;
import org.springframework.context.ApplicationContext;
import org.springframework.context.annotation.ComponentScan;
import org.springframework.context.annotation.ImportResource;

import java.io.File;
import java.util.List;

@ComponentScan( basePackages = "com.broadcom.clarity.validator" )
@ImportResource( { "classpath*:applicationContext.xml" } )
@SpringBootApplication
public class ConfigurationHandler implements CommandLineRunner
{
  private static Logger logger = LogManager.getLogger( ConfigurationHandler.class );
  @Autowired
  private MessageBuilderFactory messageBuilderFactory = null;

  private static String _apps = null;
  private static String _responseType = null;
  private static String _operation = null;
  private static String[] _arrOfApps = null;

  @Autowired( required = true )
  private ApplicationContext appContext;

  public static void main( String[] args )
  {
    logger.info( "*** Validation Handler execution initiated ***" );
    SpringApplication app = new SpringApplication( ConfigurationHandler.class );
    app.setBannerMode( Banner.Mode.OFF );
    app.run( args );
  }

  public void run( String... args ) throws Exception
  {

    if( args.length == 0 || !validateAndProcessArgs( args ) )
    {
      logger.info( "### Please Check Program Arguments Passed. They Might Be 'EMPTY' Or 'INVALID'. Below Is the Usage Detail. ###" );
      printValidUsage();
      System.exit( 1 );
    }

    Constants.SupportedOperations operations = Constants.SupportedOperations.valueOf( _operation );
    switch( operations )
    {
      case validate:
        validateOperation();
        break;
      case update:
        updateOperation();
        break;
      case populate:
        populateOperation();
        break;
      default:
        printValidUsage();
        System.exit( 9 );
    }
  }

  private void validateOperation()
  {
    boolean _status = false;
    Application _validatorApp = null;
    String outPutString = null;
    if( _arrOfApps != null && _arrOfApps.length > 0 )
    {
      for( String app : _arrOfApps )
      {
        switch( app )
        {
          case Constants.CLARITY:
            _validatorApp = (Application) appContext.getBean( Constants.CLARITY );
            break;
          case Constants.JASPERSOFT:
            _validatorApp = (Application) appContext.getBean( Constants.JASPERSOFT );
            break;
          case Constants.HDP:
            _validatorApp = (Application) appContext.getBean( Constants.HDP );
        }
        List<Messages> messages = (List<Messages>) _validatorApp.validate();
        _status = isValidationSuccessful( messages );
        if( messages != null )
        {
          outPutString = getMessageBuilderFactory().getResponse( _responseType, messages );
        }
      }
    }

    if( !_status )
    {
      logger.info( "Output -->\t" + (outPutString != null ? outPutString : "#NO_VALIDATE_RESPONSE") );
      logger.error( "*** Few validation failed. Review the logs reponses for the failures. ***" );
      System.exit( 400 );
    }
  }

  private void updateOperation()
  {
    Application _validatorApp = (Application) appContext.getBean( Constants.CLARITY );
    List<Messages> messages = (List<Messages>) _validatorApp.update();
    boolean _status = false;
    String outPutString = null;
    if( messages != null )
    {
      _status = isValidationSuccessful( messages );
      logger.info( "_status:"+_status );
      outPutString = getMessageBuilderFactory().getResponse( _responseType, messages );
      logger.info( "Output -->\t" + (outPutString != null ? outPutString : "#NO_UPDATE_RESPONSE") );
    }
    else
    {
      _status = true;
      logger.info( "*** Property update completed successfully ***" );
    }

    if( !_status )
    {
      logger.info( "Output -->\t" + (outPutString != null ? outPutString : "#NO_UPDATE_RESPONSE") );
      logger.error( "*** Config update failed as few validations failed. Review the logs reponses for the failures. ***" );
      System.exit( 500 );
    }
  }

  private void populateOperation()
  {
    Application _validatorApp = (Application) appContext.getBean( Constants.CLARITY );
    List<Messages> messages = (List<Messages>) _validatorApp.populate();
    boolean _status = false;
    String outPutString = null;
    if( messages != null )
    {
      _status = isValidationSuccessful( messages );
      outPutString = getMessageBuilderFactory().getResponse( _responseType, messages );
    }
    else
    {
      _status = true;
      logger.info( "*** Property update completed successfully ***" );
    }

    if( !_status )
    {
      logger.info( "Output -->\t" + (outPutString != null ? outPutString : "#NO_UPDATE_RESPONSE") );
      logger.error( "*** Config update failed as few validations failed. Review the logs reponses for the failures. ***" );
      System.exit( 500 );
    }
  }

  private boolean validateAndProcessArgs( String... args_ )
  {
    boolean isCmdValid = true;

    for( int i = 0; i < args_.length; i++ )
    {
      String arg = args_[i];

      if( arg.equalsIgnoreCase( "--apps" ) )
      {
        _apps = args_[++i];
        if( _apps == null )
        {
          isCmdValid = false;
          break;
        }
        _arrOfApps = _apps.split( "#" );
        if( _arrOfApps == null || _arrOfApps.length == 0 || !isValidApp() )
        {
          isCmdValid = false;
          break;
        }
      }
      else if( arg.equalsIgnoreCase( "--response-type" ) )
      {
        _responseType = args_[++i];
      }
      else if( arg.equalsIgnoreCase( "--operation" ) )
      {
        _operation = args_[++i];

        if( !Constants.SupportedOperations.isExists( _operation ) )
        {
          isCmdValid = false;
          break;
        }
      }
      else
      {
        logger.error( "Invalid args passed :: " + args_[i] );
      }
      if( _responseType == null )
      {
        _responseType = Constants.XML_MEDIATYPE;
      }
    }
    return isCmdValid;
  }

  private static void printValidUsage()
  {
    logger.error(
        "\nUsage: com.clarity.validator.entrypoint.ExecValidator --app <\"CLRT|DWH|JSFT|HDP\"> --response-type <xml OR json> --operation <validate|update>\n" );
  }

  public ApplicationContext getAppContext()
  {
    return appContext;
  }

  public void setAppContext( ApplicationContext appContext )
  {
    this.appContext = appContext;
  }

  private boolean isValid( String filePath )
  {
    File tempFile = new File( filePath );
    return tempFile.exists();
  }

  private boolean isValidApp()
  {
    boolean isValid = true;
    if( _arrOfApps != null && _arrOfApps.length == 0 )
    {
      for( String app : _arrOfApps )
      {
        if( !Constants.SupportedApps.isExists( app ) )
        {
          isValid = false;
        }
      }
    }
    return isValid;
  }

  private boolean isValidationSuccessful( List<Messages> _messageList )
  {
    boolean isSuccess = true;
    if( _messageList != null )
    {
      for( Messages msgs : _messageList )
      {
        if( msgs.getStatus().equals( Constants.Status.ERROR.toString() ) )
        {
          isSuccess = false;
          break;
        }
      }
    }
    return isSuccess;
  }

  public MessageBuilderFactory getMessageBuilderFactory()
  {
    return messageBuilderFactory;
  }

  public void setMessageBuilderFactory( MessageBuilderFactory messageBuilderFactory )
  {
    this.messageBuilderFactory = messageBuilderFactory;
  }
}