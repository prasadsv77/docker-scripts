package com.broadcom.clarity.validator.model;

public interface Application
{

  public Object validate() throws SecurityException, IllegalArgumentException;

  public Object update();

  public Object populate();

}