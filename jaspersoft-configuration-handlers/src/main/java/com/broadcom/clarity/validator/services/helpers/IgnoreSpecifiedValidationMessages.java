package com.broadcom.clarity.validator.services.helpers;

import com.broadcom.clarity.validator.response.Messages;
import com.broadcom.clarity.validator.util.Constants;
import com.broadcom.clarity.validator.util.HandlerUtilities;

import java.util.Arrays;
import java.util.Iterator;
import java.util.List;

public class IgnoreSpecifiedValidationMessages
{
  private static final String IGNORED_VALIDATIONS = "IGNORED_VALIDATIONS";
  private static final String SPLITTER = ";";

  public List<Messages> getActualMessageList( List<Messages> messagesList_ )
  {
    List<String> ignoredValidationList = getIgnoredValidationList();

    Iterator<Messages> messagesIterator = messagesList_.iterator();

    while( messagesIterator.hasNext() )
    {
      Messages messages = messagesIterator.next();
      if( messages.getId().contains( Constants.PROD_CONTAINER_VALIDATION ) )
      {
        removeMessages( ignoredValidationList, messagesIterator, messages );
      }
      else
      {
        removeMessages( ignoredValidationList, messagesIterator, messages );
      }
    }

    if( messagesList_.size() == 0 )
    {
      return null;
    }
    else
    {
      return messagesList_;
    }
  }

  private List<String> getIgnoredValidationList()
  {
    List<String> ignoredValidationList = null;
    String ignoredValidations;

    ignoredValidations = HandlerUtilities.environmentVariableMap.get( IGNORED_VALIDATIONS );

    if( ignoredValidations != null && !"".equalsIgnoreCase( ignoredValidations ) )
    {
      ignoredValidationList = Arrays.asList( ignoredValidations.split( SPLITTER ) );
    }

    return ignoredValidationList;
  }

  private void removeMessages( List<String> ignoredValidationList_, Iterator<Messages> messagesIterator_,
                               Messages messages_ )
  {
    if( ignoredValidationList_ != null && (1 == ignoredValidationList_.size() &&
                                           "ALL".equalsIgnoreCase( ignoredValidationList_.get( 0 ) )) )
    {
      messagesIterator_.remove();
    }
    else
    {
      removeMessagesFromList( ignoredValidationList_, messages_ );

      if( messages_.getMessageList() != null && messages_.getMessageList().size() == 0 )
      {
        messagesIterator_.remove();
      }
    }
  }

  private void removeMessagesFromList( List<String> ignoredValidationList_, Messages messages_ )
  {
    if( ignoredValidationList_ != null )
    {
      for( String validationIgnored : ignoredValidationList_ )
      {
        messages_.getMessageList().removeIf( msg -> validationIgnored.equalsIgnoreCase( msg.getAttributeName() ) );
      }
    }
  }
}