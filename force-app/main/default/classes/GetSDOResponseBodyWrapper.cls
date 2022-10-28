/**
 * This class is used in RESTCallout service class to handle callout response. 
 * It provides response body wrapper for Get SDO callout
 * 
 * @author Elena Sokolova @date 2021-06-22
 */
public with sharing class GetSDOResponseBodyWrapper extends BaseResponseBodyWrapper {
    public String B64SDOBytes;
    public String PAdESSignedDocumentBytes;
}