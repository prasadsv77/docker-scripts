package com.broadcom.clarity.validator.model;

import com.broadcom.clarity.validator.services.hdp.HDPHandlerServiceImpl;
import com.broadcom.clarity.validator.util.Constants;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.stereotype.Component;

@Component( Constants.HDP )
public class HDPHandler implements Application
{

  @Autowired
  HDPHandlerServiceImpl hdpHandlerServiceImpl;

  public Object validate() throws SecurityException, IllegalArgumentException
  {
    return hdpHandlerServiceImpl.initiateAllValidationsForProduct();
  }

  public HDPHandlerServiceImpl getHDPHandlerServiceImpl()
  {
    return hdpHandlerServiceImpl;
  }

  public void setHDPHandlerServiceImpl( HDPHandlerServiceImpl hdpHandlerServiceImpl )
  {
    this.hdpHandlerServiceImpl = hdpHandlerServiceImpl;
  }

  @Override
  public Object update()
  {
    return hdpHandlerServiceImpl.updateConfigurations();
  }

  @Override
  public Object populate() {
    return null;
  }
}
