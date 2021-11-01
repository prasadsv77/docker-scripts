package com.broadcom.clarity.validator.response.builder.factory;

import com.broadcom.clarity.validator.exception.ValidationWrapperException;
import com.broadcom.clarity.validator.response.Messages;
import com.broadcom.clarity.validator.response.WrapperResponse;
import com.broadcom.clarity.validator.util.Constants;
import com.fasterxml.jackson.databind.ObjectMapper;
import org.apache.logging.log4j.LogManager;
import org.apache.logging.log4j.Logger;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.stereotype.Component;

import javax.xml.bind.JAXBContext;
import javax.xml.bind.Marshaller;
import java.io.IOException;
import java.io.StringWriter;
import java.util.List;

@Component( Constants.MESSAGE_BUILDER_BEAN_NAME )
public class MessageBuilderFactory
{
  private static Logger logger = LogManager.getLogger( MessageBuilderFactory.class );
  @Autowired
  private WrapperResponse wrapperResponse = null;
  @Autowired
  private MessageBuilderFactory messageBuilderFactory = null;

  public String getResponse( String _responseType, List<Messages> messagesList )
  {
    String _response = null;

    if( messagesList != null )
    {
      addToWrapperResponse( messagesList );
      if( _responseType.equals( Constants.ReponseType.json.toString() ) )
      {
        _response = convertToJson();
      }
      else if( _responseType.equals( Constants.ReponseType.xml.toString() ) )
      {
        _response = convertToXml();
      }
    }

    return _response;
  }

  private void addToWrapperResponse( List<Messages> _messages )
  {
    wrapperResponse.setMessagesList( _messages );
  }

  private String convertToXml()
  {
    String result = null;
    StringWriter sw = new StringWriter();
    try
    {
      if( wrapperResponse != null )
      {
        JAXBContext jaxbContext = JAXBContext.newInstance( WrapperResponse.class );
        Marshaller _marshaller = jaxbContext.createMarshaller();
        _marshaller.setProperty( Marshaller.JAXB_FORMATTED_OUTPUT, true );
        _marshaller.marshal( getWrapperResponse(), sw );
        result = sw.toString();

      }
    }
    catch( Exception e )
    {
      logger.error( "Error while converting the response object to xml", e.getMessage() );
      throw new ValidationWrapperException( "Message: Error while converting the response object to xml", e, "401" );
    }
    return (result != null ? result : null);
  }

  private String convertToJson()
  {
    ObjectMapper Obj = new ObjectMapper();
    String jsonStr = null;
    try
    {
      if( wrapperResponse != null )
      {
        jsonStr = Obj.writeValueAsString( getWrapperResponse() );
      }
    }
    catch( IOException e )
    {
      logger.error( "Error while converting the response object to json", e.getMessage() );
      throw new ValidationWrapperException( "Message: Error while converting the response object to json", e, "401" );
    }
    return (jsonStr != null ? jsonStr : null);
  }

  public WrapperResponse getWrapperResponse()
  {
    return wrapperResponse;
  }

  public void setWrapperResponse( WrapperResponse wrapperResponse )
  {
    this.wrapperResponse = wrapperResponse;
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

