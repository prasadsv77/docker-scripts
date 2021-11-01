package com.broadcom.clarity.validator.services;

import com.broadcom.clarity.validator.response.Messages;
import com.broadcom.clarity.validator.services.helpers.IgnoreSpecifiedValidationMessages;
import org.apache.logging.log4j.LogManager;
import org.apache.logging.log4j.Logger;

import java.util.ArrayList;
import java.util.List;

public abstract class AbstractPrepareMessages
{
  private static Logger logger = LogManager.getLogger( AbstractPrepareMessages.class );

  public List<Messages> initiateAllValidationsForProduct()
  {
    List<Messages> _messagesList = new ArrayList<>();
    if( this instanceof ApplicationHandlerService )
    {
      ((ApplicationHandlerService) this).populateMappings();
      try
      {
        Messages _msgsProdValidation = ((ApplicationHandlerService) this).productValidation( null );
        if( _msgsProdValidation != null )
        {
          _messagesList.add( _msgsProdValidation );
        }
      }
      catch( Exception e )
      {
        logger.error( "Error while doing product validation : ", e );
      }

      try
      {
        Messages _msgsContainerValidation = ((ApplicationHandlerService) this).containerValidation();
        if( _msgsContainerValidation != null )
        {
          _messagesList.add( _msgsContainerValidation );
        }
      }
      catch( Exception e )
      {
        logger.error( "Error while doing container validation : ", e );
      }

    }

    if( _messagesList.size() > 0 )
    {
      IgnoreSpecifiedValidationMessages ignoredValidationMessages = new IgnoreSpecifiedValidationMessages();
      return ignoredValidationMessages.getActualMessageList( _messagesList );
    }
    else
    {
      return _messagesList;
    }
  }
}