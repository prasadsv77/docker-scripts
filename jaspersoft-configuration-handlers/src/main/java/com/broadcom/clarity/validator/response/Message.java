package com.broadcom.clarity.validator.response;

import com.fasterxml.jackson.annotation.JsonProperty;
import org.springframework.stereotype.Component;

import javax.xml.bind.annotation.XmlAccessType;
import javax.xml.bind.annotation.XmlAccessorType;
import javax.xml.bind.annotation.XmlAttribute;
import java.util.Objects;

/**
 * @author Shirish Samantaray <shirish.samantaray@broadcom.com>
 * @since 7/8/2019
 */

@XmlAccessorType( XmlAccessType.NONE )
@Component
public class Message
{

  @XmlAttribute( name = "attributeName" )
  private String attributeName;
  @XmlAttribute( name = "type" )
  private String type;
  @XmlAttribute( name = "description" )
  private String value;
  @XmlAttribute( name = "id" )
  private String id;

  public Message()
  {
  }

  @JsonProperty( "attributeName" )
  public String getAttributeName()
  {
    return attributeName;
  }

  public void setAttributeName( String attributeName )
  {
    this.attributeName = attributeName;
  }

  @JsonProperty( "type" )
  public String getType()
  {
    return type;
  }

  public void setType( String type )
  {
    this.type = type;
  }

  @JsonProperty( "description" )
  public String getValue()
  {
    return value;
  }

  public void setValue( String value )
  {
    this.value = value;
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

  @Override
  public String toString()
  {
    return "Message{" +
        "attributeName='" + attributeName + '\'' +
        ", type='" + type + '\'' +
        ", value='" + value + '\'' +
        ", id='" + id + '\'' +
        '}';
  }

  @Override
  public boolean equals( Object o )
  {
    if( this == o )
      return true;
    if( !(o instanceof Message) )
      return false;
    Message message = (Message) o;
    return getAttributeName().equals( message.getAttributeName() ) &&
        getType().equals( message.getType() ) &&
        getValue().equals( message.getValue() ) &&
        getId().equals( message.getId() );
  }

  @Override
  public int hashCode()
  {
    return Objects.hash( getAttributeName(), getType(), getValue(), getId() );
  }
}
