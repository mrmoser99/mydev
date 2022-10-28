/**
 * This class is used in RESTCallout service class to handle callout response. 
 * It provides response body wrapper for Send Documents callout
 * 
 * @author Elena Sokolova @date 2021-07-26
 */
public with sharing class SendDocumentsResponseBodyWrapper extends BaseResponseBodyWrapper {
    public Status Status;

    public class Status {
        public String StatusDescription;
        public String Code;
    }
}