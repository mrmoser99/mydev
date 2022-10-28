/**
 * This class is used in RESTCallout service class to create callout and set params. 
 * It provide request body wrapper for Create Order callout
 * 
 * @author Elena Sokolova @date 2021-06-21
 */
public with sharing class CreateOrderRequestBodyWrapper extends BaseRequestBodyWrapper {

    public String OrderId;
    public Blob Document;
    public String DocumentName;
    public String DocumentTitle;
    public String DocumentDescription;
    public String SignerName;
    public String SignerSSN;
    public Date OrderExpiry;

    public CreateOrderRequestBodyWrapper() {}

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

        // get document info
        ContentVersion doc = ESignInformationController.getDocumentByType(
            ESignInformationController.getDocumentsByQuoteId(esignInfo.Quote__c),
            esignInfo.Document_Name__c
        );

       

        if (doc == null) {
            throw new ErrorLogger.ErrorLoggerException(label.Contact_Admin_Error);
        }

        this.OrderId = 'SFDC' + orderId;
        this.Document = doc.VersionData; //base64format
        this.DocumentName = doc.Title;
        this.DocumentTitle = doc.Title;
        this.DocumentDescription = doc.Description;
        this.SignerName = esignInfo.Signer_Name__c;
        this.SignerSSN = esignInfo.SSN_Number__c;
        this.OrderExpiry = esignInfo.ExpirationDate__c;
    }
}