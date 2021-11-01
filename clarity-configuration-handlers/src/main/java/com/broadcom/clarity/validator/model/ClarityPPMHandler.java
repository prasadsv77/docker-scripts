package com.broadcom.clarity.validator.model;

import com.broadcom.clarity.validator.services.clarity.ppm.ClarityPPMHandlerServiceImpl;
import com.broadcom.clarity.validator.util.Constants;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.stereotype.Component;

@Component(Constants.CLARITY)
public class ClarityPPMHandler implements Application
{

  @Autowired
  ClarityPPMHandlerServiceImpl clarityPpmHandlerServiceImpl;

  public Object validate() throws SecurityException, IllegalArgumentException
  {
    return clarityPpmHandlerServiceImpl.initiateAllValidationsForProduct();
  }

  public ClarityPPMHandlerServiceImpl getClarityPpmHandlerServiceImpl()
  {
    return clarityPpmHandlerServiceImpl;
  }

  public void setClarityPpmHandlerServiceImpl( ClarityPPMHandlerServiceImpl clarityPpmHandlerServiceImpl )
  {
    this.clarityPpmHandlerServiceImpl = clarityPpmHandlerServiceImpl;
  }

  @Override
  public Object update()
  {
    return clarityPpmHandlerServiceImpl.updateConfigurations();
  }

  @Override
  public Object populate()
  {
    return clarityPpmHandlerServiceImpl.populateConfigurations();
  }
}