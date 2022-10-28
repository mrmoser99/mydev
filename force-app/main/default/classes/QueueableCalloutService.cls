/*****************************************************************************************
Name: QueueableCalloutService 
===============================================================================================
Purpose: Pass callout name and params in the constructor and call an appropriate callout from
RESTCalloutHelper class.
Why Queable - because we have to enqueue multiple callouts one after another and also perform DML.
A benefit of using the Queueable interface methods is that some governor limits are 
higher than for synchronous Apex, such as heap size limits.
================================================================================================
================================================================================================
History
-------
* Version 1.0 @author Elena Sokolova @date 2021-08-01
* Version 1.2 @author Neha Bansal @date 2021-08-20 US#491659 
******************************************************************************************/

public without sharing class QueueableCalloutService implements Queueable,Database.AllowsCallouts {
    public String calloutName;
    public Map<String,Object> params; 

    public QueueableCalloutService(String calloutName, Map<String,Object> params) {
        this.calloutName = calloutName;
        this.params = params;
    }

    public void execute(QueueableContext context) {
        // check callout name and call an appropriate method
        if (this.calloutName == Constants.SEND_DOCUMENTS) {
            sendDocumentsToDCV(this.params);
        } else if (this.calloutName == Constants.GET_SDO) {
            getDocumentsFromNets(this.params);
        } else if (this.calloutName == Constants.SMART_COMM_DOC) {
            getSmartCommDocuments(this.params);
        }
    }
    
    /**
     * Name: sendDocumentsToDCV
     * Purpose: Set params and call Send Documents to DCV callout
     */
    private void sendDocumentsToDCV(Map<String,Object> params) {
        /*Id orderId = (Id) params.get('orderId');
        Id quoteId = (Id) params.get('quoteId');
        String type = (String) params.get('type');
        String documentType = (String) params.get('documentType');
        Map<String,String> documents = (Map<String,String>) params.get('documents');
        RESTCalloutHelper.sendDocumentsToDCV(quoteId, orderId, documentType, documents,type);
        */
        RESTCalloutHelper.sendDocumentsToDCV(params);
    }

    /**
     * Name: getDocumentsFromNets
     * Purpose: Set params and call Get SDO callout
     */
    private void getDocumentsFromNets(Map<String,Object> params) {
        Id orderId = (Id) params.get('orderId');
        RESTCalloutHelper.getSDOCallout(orderId);
    }
    
     /**
     * Name: getSmartCommDocuments
     * Purpose: Set params and call SmartCommDoc callout from SmartCommHelper
     */
    private void getSmartCommDocuments( Map<String,Object> params) {
        
        Map<String, Object> reqParams = SmartCommHelper.getRequestBodyParam(params);
        RESTCalloutHelper.smartcommDocCallout(reqParams,false); 
    }
       
}