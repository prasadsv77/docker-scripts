package com.broadcom.clarity.validator.model;

import com.broadcom.clarity.validator.services.jsft.JSFTHandlerServiceImpl;
import com.broadcom.clarity.validator.util.Constants;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.stereotype.Component;

@Component(Constants.JASPERSOFT)
public class JSFTHandler implements Application
{

  @Autowired
  JSFTHandlerServiceImpl jsftHandlerServiceImpl;

  @Override
  public Object validate() throws SecurityException, IllegalArgumentException
  {
    return jsftHandlerServiceImpl.initiateAllValidationsForProduct();
  }

  public JSFTHandlerServiceImpl getJSFTHandlerServiceImpl()
  {
    return jsftHandlerServiceImpl;
  }

  public void setJSFTHandlerServiceImpl( JSFTHandlerServiceImpl jsftHandlerServiceImpl )
  {
    this.jsftHandlerServiceImpl = jsftHandlerServiceImpl;
  }

  @Override
  public Object update()
  {
    return null;
  }

  @Override
  public Object populate()
  {
    return null;
  }
}
