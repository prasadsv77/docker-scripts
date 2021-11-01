package com.broadcom.clarity.validator.services;

import com.broadcom.clarity.validator.response.Messages;
import org.w3c.dom.Document;

import java.util.List;

public interface ApplicationHandlerService
{
  public Messages productValidation( Document doc );

  public Messages containerValidation();

  public List<Messages> updateConfigurations();

  public List<Messages> populateConfigurations();

  public void populateMappings();
}