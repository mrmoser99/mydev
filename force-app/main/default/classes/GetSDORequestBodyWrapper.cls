/**
 * This class is used in RESTCallout service class to create callout and set params. 
 * It provide request body wrapper for Get SDO callout
 * 
 * @author Elena Sokolova @date 2021-06-22
 */public with sharing class GetSDORequestBodyWrapper extends BaseRequestBodyWrapper {
    public String OrderId;
    public String DocumentName;
    public Boolean IsPAdESRequired = true;

    public GetSDORequestBodyWrapper() {}
    /**
     * Method sets class variables.
     * Override the parent class method with this signature.
     */
    public override void init(Map<String, Object> params) {
        String originalOrderId = (String) params.get('orderId');
        getAllParamsByOrderId(originalOrderId);
    }

    private void getAllParamsByOrderId(Id orderId) {
        // get order info by order Id
        E_Sign_Information__c esignInfo = new ESignInformationController.WoSSelector().getESignInfo(orderId);

        this.OrderId = 'SFDC' + orderId;
        this.DocumentName = esignInfo.Document_Type__c;
    }
}