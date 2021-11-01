package com.broadcom.clarity.validator.response;

import com.fasterxml.jackson.annotation.JsonProperty;
import org.springframework.stereotype.Component;

import javax.xml.bind.annotation.XmlAccessType;
import javax.xml.bind.annotation.XmlAccessorType;
import javax.xml.bind.annotation.XmlElement;
import javax.xml.bind.annotation.XmlRootElement;
import java.util.ArrayList;
import java.util.List;
import java.util.Objects;

//@XmlRootElement(name = "data")
@XmlRootElement
@XmlAccessorType( XmlAccessType.NONE )
@Component
public class WrapperResponse
{
  @XmlElement( name = "messages" )
  private List<Messages> messagesList = new ArrayList<>();

  @JsonProperty("messages")
  public List<Messages> getMessagesList()
  {
    return messagesList;
  }

  public void setMessagesList( List<Messages> messagesList )
  {
    this.messagesList = messagesList;
  }

  @Override
  public boolean equals( Object o )
  {
    if( this == o )
      return true;
    if( !(o instanceof WrapperResponse) )
      return false;
    WrapperResponse that = (WrapperResponse) o;
    return getMessagesList().equals( that.getMessagesList() );
  }

  @Override
  public int hashCode()
  {
    return Objects.hash( getMessagesList() );
  }

  @Override
  public String toString()
  {
    return "WrapperResponse{" +
        "messagesList=" + messagesList +
        '}';
  }
}