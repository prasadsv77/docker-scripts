package com.broadcom.clarity.validator.model;

import com.broadcom.clarity.validator.response.Messages;
import com.broadcom.clarity.validator.services.hdp.HDPHandlerServiceImpl;
import org.junit.Assert;
import org.junit.Test;
import org.junit.runner.RunWith;
import org.mockito.InjectMocks;
import org.mockito.Mock;
import org.mockito.Mockito;
import org.mockito.runners.MockitoJUnitRunner;

import java.util.ArrayList;
import java.util.List;

@RunWith(MockitoJUnitRunner.class) //MockitoJUnitRunner gives you automatic validation of framework usage, as well as an automatic initMocks()
public class HDPHandlerTest
{
  private List<Messages> msgList = new ArrayList<Messages>();

  @InjectMocks //create class instances which needs to be tested in test class.
  HDPHandler hDPHandler;

  @Mock //creates objects and inject mocked dependencies
  HDPHandlerServiceImpl hdpHandlerServiceImpl;

  //test for validate() invocation in HDPHandler class.
  @Test
  public void testValidate(){
    hDPHandler.validate();
    Mockito.verify(hdpHandlerServiceImpl, Mockito.times(1)).initiateAllValidationsForProduct(); //checking for 1 time invocation
  }

  //test for validate() with object in HDPHandler class.
  //validating msgList | id, description of msg object.
  @Test
  public void testobjectValidate(){
    Messages msg = new Messages();
    msg.setId( "99" );
    msg.setDescription( "ppm-devops testing validate()" );
    msgList.add(msg);
    Mockito.when(hdpHandlerServiceImpl.initiateAllValidationsForProduct()).thenReturn( msgList ); //creating dummy return values

    //Expected :Expected :[Messages{messageList=[], description='ppm-devops testing validate()', id='99'}]
    Assert.assertEquals( hDPHandler.validate(),msgList ); //msgList object validation

    //Expected :99
    Assert.assertEquals( ((List<Messages>)hDPHandler.validate()).get(0).getId(),msg.getId() ); //id value validation

    //Expected :ppm-devops testing validate()
    Assert.assertEquals( ((List<Messages>)hDPHandler.validate()).get(0).getDescription(),msg.getDescription() ); //description value validation
  }

  //test for getHDPHandlerServiceImpl() in HDPHandler class.
  @Test
  public void testGetHDPHandlerServiceImpl(){
    //Expected :hdpHandlerServiceImpl
    Assert.assertEquals( hDPHandler.getHDPHandlerServiceImpl(),hdpHandlerServiceImpl ); //validating for object returned by getter
  }

  //test for setHDPHandlerServiceImpl() with null in HDPHandler class.
  @Test
  public void testSetHDPHandlerServiceImpl(){
    hDPHandler.setHDPHandlerServiceImpl( null ); //passing null to setter
    //Expected: null
    Assert.assertEquals( hDPHandler.getHDPHandlerServiceImpl(),null ); //validating the return to be null
  }

  //test for setHDPHandlerServiceImpl() with object in HDPHandler class.
  @Test
  public void testobjectSetHDPHandlerServiceImpl(){
    HDPHandlerServiceImpl testObj = new HDPHandlerServiceImpl(); //creating a dummy object
    hDPHandler.setHDPHandlerServiceImpl(testObj); //setting up dummy object to setter
    //Expected :testObj
    Assert.assertEquals( hDPHandler.getHDPHandlerServiceImpl(),testObj ); //validating the dummy object recieved by getter
  }

  //test for update() invocation in HDPHandler class.
  @Test
  public void testUpdate(){
    hdpHandlerServiceImpl.updateConfigurations();
    Mockito.verify(hdpHandlerServiceImpl,Mockito.times( 1 )).updateConfigurations(); //checking for 1 time invocation
  }

  //test for update() with object in HDPHandler class.
  //validating msgList | id, description of msg object.
  @Test
  public void testUpdateObject(){
    Messages msg = new Messages();
    msg.setId( "88" );
    msg.setDescription( "ppm-devops testing update()" );
    msgList.add(msg);
    Mockito.when(hdpHandlerServiceImpl.updateConfigurations()).thenReturn( msgList ); //creating dummy return values

    //Expected :Expected :[Messages{messageList=[], description='ppm-devops testing update()', id='88'}]
    Assert.assertEquals( hdpHandlerServiceImpl.updateConfigurations(), msgList ); //msgList object validation

    //Expected :88
    Assert.assertEquals( hdpHandlerServiceImpl.updateConfigurations().get(0).getId(), msg.getId()); //id value validation

    //Expected :ppm-devops testing update()
    Assert.assertEquals( hdpHandlerServiceImpl.updateConfigurations().get(0).getDescription(), msg.getDescription() ); //description value validation
  }

  //test for populate() in HDPHandler class.
  @Test
  public void testPopulate(){
    //Expected :null
    Assert.assertEquals( hDPHandler.populate(),null ); //return null validation
  }

  //test for update() with object in HDPHandler class.
  //validating msgList | id, description of msg object.
  @Test
  public void testPopulateObject(){
    Messages msg = new Messages();
    msg.setId( "77" );
    msg.setDescription( "ppm-devops testing populate()" );
    msgList.add(msg);
    Mockito.when(hdpHandlerServiceImpl.populateConfigurations()).thenReturn( msgList ); //creating dummy return values

    //Expected :[Messages{messageList=[], description='ppm-devops testing populate()', id='77'}]
    Assert.assertEquals( hdpHandlerServiceImpl.populateConfigurations(), msgList ); //msgList object validation

    //Expected :77
    Assert.assertEquals( hdpHandlerServiceImpl.populateConfigurations().get(0).getId(), msg.getId()); //id value validation

    //Expected :ppm-devops testing populate()
    Assert.assertEquals( hdpHandlerServiceImpl.populateConfigurations().get(0).getDescription(), msg.getDescription() ); //description value validation
  }
}
