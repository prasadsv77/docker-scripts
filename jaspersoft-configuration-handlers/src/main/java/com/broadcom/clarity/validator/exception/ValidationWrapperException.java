package com.broadcom.clarity.validator.exception;

public class ValidationWrapperException extends RuntimeException
{

  private static final long serialVersionUID = -9037952690408398084L;
  private String errorCode = "";
  private String parameter = "";

  public ValidationWrapperException(String message, String errorCode, String parameter) {
    super(message);
    this.setErrorCode(errorCode);
    this.setParameter(parameter);

  }

  public ValidationWrapperException(String message, Throwable cause, String errorCode) {
    super(message, cause);
    this.errorCode = errorCode;
  }


  public void setErrorCode(String errorCode) {
    this.errorCode = errorCode;
  }
  public String getErrorCode() {
    return this.errorCode;
  }
  public void setParameter(String parameter) {
    this.parameter = parameter;
  }
  public String getParameter() {
    return this.parameter;
  }
}