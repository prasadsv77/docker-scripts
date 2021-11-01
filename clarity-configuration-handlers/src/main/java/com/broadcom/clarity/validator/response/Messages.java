package com.broadcom.clarity.validator.response;

/**
 * @author Shirish Samantaray <shirish.samantaray@broadcom.com>
 * @since 7/8/2019
 */

import com.broadcom.clarity.validator.util.Constants;
import com.fasterxml.jackson.annotation.JsonProperty;
import org.springframework.stereotype.Component;

import javax.xml.bind.annotation.XmlAccessType;
import javax.xml.bind.annotation.XmlAccessorType;
import javax.xml.bind.annotation.XmlAttribute;
import javax.xml.bind.annotation.XmlElement;
import java.util.ArrayList;
import java.util.List;
import java.util.Objects;

@XmlAccessorType( XmlAccessType.NONE )
@Component
public class Messages
{
  public Messages()
  {
  }

  @XmlElement( name = "message" )
  private List<Message> messageList = new ArrayList<>();

  @XmlAttribute( name = "description" )
  private String description;

  @XmlAttribute( name = "id" )
  private String id;

  @XmlAttribute( name = "status" )
  private String status= Constants.Status.SUCCESS.toString();

  @JsonProperty( "message" )
  public List<Message> getMessageList()
  {

    return this.messageList;

  }

  public void setMessageList( List<Message> arg )
  {

    this.messageList = arg;

  }

  @JsonProperty( "description" )
  public String getDescription()
  {
    return description;
  }

  public void setDescription( String description )
  {
    this.description = description;
  }

  @JsonProperty( "id" )
  public String getId()
  {
    return id;
  }

  public void setId( String id )
  {
    this.id = id;
  }

  @JsonProperty( "status" )
  public String getStatus()
  {
    return status;
  }

  public void setStatus( String status )
  {
    this.status = status;
  }

  @Override
  public boolean equals( Object o )
  {
    if( this == o )
      return true;
    if( !(o instanceof Messages) )
      return false;
    Messages messages = (Messages) o;
    return getMessageList().equals( messages.getMessageList() ) &&
        getDescription().equals( messages.getDescription() ) &&
        getId().equals( messages.getId() );
  }

  @Override
  public int hashCode()
  {
    return Objects.hash( getMessageList(), getDescription(), getId() );
  }

  @Override
  public String toString()
  {
    return "Messages{" +
        "messageList=" + messageList +
        ", description='" + description + '\'' +
        ", id='" + id + '\'' +
        '}';
  }
}
