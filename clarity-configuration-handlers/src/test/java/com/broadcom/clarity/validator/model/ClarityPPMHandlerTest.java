package com.broadcom.clarity.validator.model;

import com.broadcom.clarity.validator.response.Messages;
import com.broadcom.clarity.validator.services.clarity.ppm.ClarityPPMHandlerServiceImpl;
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
public class ClarityPPMHandlerTest {

    private List<Messages> msgList = new ArrayList<Messages>();

    @InjectMocks //create class instances which needs to be tested in test class.
    ClarityPPMHandler clarityPPMHandler;

    @Mock //creates objects and inject mocked dependencies
    ClarityPPMHandlerServiceImpl clarityPpmHandlerServiceImpl;

    //test for validate() invocation in ClarityPPMHandler class.
    @Test
    public void testValidate(){
        clarityPPMHandler.validate();
        Mockito.verify(clarityPpmHandlerServiceImpl, Mockito.times(1)).initiateAllValidationsForProduct(); //checking for 1 time invocation
    }

    //test for validate() with object in ClarityPPMHandler class.
    //validating msgList, msg object | id, description of msg object.
    @Test
    public void testobjectValidate(){
        Messages msg = new Messages();
        msg.setId("99");
        msg.setDescription( "ppm-devops testing validate()" );
        msgList.add(msg);
        Mockito.when(clarityPpmHandlerServiceImpl.initiateAllValidationsForProduct()).thenReturn(msgList); //creating dummy return values

        //Expected :[Messages{messageList=[], description='ppm-devops testing validate()', id='99'}]
        Assert.assertEquals(clarityPPMHandler.validate(), msgList); //msgList object validation

        //Expected :Messages{messageList=[], description='ppm-devops testing validate()', id='99'}
        Assert.assertEquals(((List<Messages>)clarityPPMHandler.validate()).get(0),msg); //msg object validation

        //Expected :99
        Assert.assertEquals(((List<Messages>)clarityPPMHandler.validate()).get(0).getId(),msg.getId()); //id value validation

        //Expected :ppm-devops testing validate()
        Assert.assertEquals(((List<Messages>)clarityPPMHandler.validate()).get(0).getDescription(),msg.getDescription()); //description value validation
    }

    //test for getClarityPpmHandlerServiceImpl() in ClarityPPMHandler class.
    @Test
    public void testGetClarityPpmHandlerServiceImpl(){
        //Expected :clarityPpmHandlerServiceImpl
        Assert.assertEquals(clarityPPMHandler.getClarityPpmHandlerServiceImpl(),clarityPpmHandlerServiceImpl); //validating for object returned by getter
    }

    //test for setClarityPpmHandlerServiceImpl() with null in ClarityPPMHandler class.
    @Test
    public void testSetClarityPpmHandlerServiceImpl(){
        clarityPPMHandler.setClarityPpmHandlerServiceImpl( null ); //passing null to setter
        //Expected :null
        Assert.assertEquals( clarityPPMHandler.getClarityPpmHandlerServiceImpl(),null ); //validating the return to be null
    }

    //test for setClarityPpmHandlerServiceImpl() with object in ClarityPPMHandler class.
    @Test
    public void testobjectSetClarityPpmHandlerServiceImpl(){
        clarityPPMHandler.setClarityPpmHandlerServiceImpl(clarityPpmHandlerServiceImpl);
        //Expected :clarityPpmHandlerServiceImpl
        Assert.assertEquals(this.clarityPpmHandlerServiceImpl,clarityPpmHandlerServiceImpl);
    }

    //test for update() invocation in ClarityPPMHandler class.
    @Test
    public void testUpdate(){
        clarityPPMHandler.update();
        Mockito.verify(clarityPpmHandlerServiceImpl, Mockito.times(1)).updateConfigurations(); //checking for 1 time invocation
    }

    //test for update() with object in ClarityPPMHandler class.
    //validating msgList object | id, description of msg object.
    @Test
    public void testUpdateObject(){
        Messages msg = new Messages();
        msg.setId( "88" );
        msg.setDescription( "ppm-devops testing update()" );
        msgList.add(msg);
        Mockito.when(clarityPpmHandlerServiceImpl.updateConfigurations()).thenReturn(msgList); //creating dummy return values

        //Expected :[Messages{messageList=[], description='ppm-devops testing update()', id='88'}]
        Assert.assertEquals(clarityPPMHandler.update(), msgList); //object validation

        //Excepted: 88
        Assert.assertEquals(((List<Messages>)clarityPPMHandler.update()).get(0).getId(),msg.getId()); //value validation

        //Expected: ppm-devops testing update()
        Assert.assertEquals(((List<Messages>)clarityPPMHandler.update()).get(0).getDescription(),msg.getDescription()); //value validation
    }

    //test for populate() invocation in ClarityPPMHandler class.
    @Test
    public void testPopulate(){
        clarityPPMHandler.populate();
        Mockito.verify(clarityPpmHandlerServiceImpl, Mockito.times(1)).populateConfigurations(); //checking for 1 time invocation
    }

    //test for populate() with object in ClarityPPMHandler class.
    //validating msgList object | id, description of msg object.
    @Test
    public void testPopulateObject(){
        Messages msg = new Messages();
        msg.setId( "77" );
        msg.setDescription( "ppm-devops testing populate()" );
        msgList.add(msg);
        Mockito.when(clarityPpmHandlerServiceImpl.populateConfigurations()).thenReturn(msgList); //creating dummy return values

        //Expected :[Messages{messageList=[], description='ppm-devops testing populate()', id='77'}]
        Assert.assertEquals(clarityPPMHandler.populate(), msgList); //msgList object validation

        //Excepted: 77
        Assert.assertEquals(((List<Messages>)clarityPPMHandler.populate()).get(0).getId(),msg.getId()); //id value validation

        //Excepted: ppm-devops testing populate()
        Assert.assertEquals(((List<Messages>)clarityPPMHandler.populate()).get(0).getDescription(),msg.getDescription()); //description value validation
    }
}