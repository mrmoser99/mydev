/**
 * Class implements REST CallourHelper for getting submit application and credit assessment
 * 
 * Version 1.0 @author Elena Sokolova @date 2021-02-03
 * Version 1.1 @author Ravisha Chugani @date 2021-03-08
 * Version 1.2 @author Neha Tyagi @date 2021-05-17 (Cashflow in Asset)
 * Version 1.3 @author Elena Sokolova @date 2021-05-21 (maintenance section has been added to the Calculation API params)
 * Version 1.4 @author Elena Sokolova @date 2021-07-02 (added Create Order, Cancel Order, Get SDO, Send Code callouts)
 * Version 1.5 @author Ravisha Chugani @date 2021-07-06 (SoftCost and Maintanence)
 * Version 1.6 @author Neha Tyagi @date 2021-07-15 (Issue Fee, Invoice Fee and Extenion Rent)
 * Version 1.7 @author Anujit @date 2021-07-15 US#505177
 * Version 1.8 @author Neha Bansal @date 2021-08-19 US#491659 
 * Version 1.9 @author Ravisha Chugani @date 2021-08-24 (Submit Application) 
 * Version 1.10 @author Ravisha Chugani @date 2021-08-24 (Bug #679202 : Updated nominal rate logic)
 * Version 1.11 @author Neha Tyagi @date 2021-12-07 US-677493 
 */
 
/**
*Name: RESTCalloutHelper
*Purpose: to perform Callout for submit application and credit assessment. 
*/
public with sharing class RESTCalloutHelper {
    
    public static String errorField = '';
    public static String errorMessage = Constants.ERROR_MESSAGE;

    /**
    *Name: makeSubmitAppRequest
    *Purpose: to send callout request to restcalloutservice and get response for submit application.  
    */
    @AuraEnabled
    public static String makeSubmitAppRequest(String parameters, Boolean saveLogsAsync) {
        //Params defiend to get all the body parameters
        Map<String, Object> params = new Map<String, Object>();
        
        params = SubmitApplicationHelper.getBodyParameters(parameters);
        
        
        //Params defiend to get all the submit application parameters
        Map<String, Object> submitApplicationParams = (Map<String, Object>) JSON.deserializeUntyped(parameters);

        String opportunityId = (String) submitApplicationParams.get('oppId');
        String quoteId = (String) submitApplicationParams.get('quoteId');

        //checks if the there is already a quote in assessment status and if so throws exception.      
        if (!new WoSSelector().getQuotesWithAssessmentStatus(opportunityId).isEmpty()) {
            throw new ErrorLogger.ErrorLoggerException(Label.One_quote_version_can_be_sent_for_credit_assessment_at_a_time);
        }

        //Callout for RESTCalloutService and sents appropriate response for contractNumber  
        try{
            RESTCalloutService calloutService = new RESTCalloutService();
            SubmitApplicationResponseBodyWrapper response = (SubmitApplicationResponseBodyWrapper) calloutService.performCallout(Constants.SUBMIT_APPLICATION, params, null, null, saveLogsAsync);

          
            
            return JSON.serialize(response.statusCode);
        }   catch (Exception e) {
            ErrorLogger errorLog = new ErrorLogger();
            errorLog.logException(e, Constants.INTEGRATION_ERRORLOG_RECORDTYPE, quoteId, true); 
            errorMessage = errorMessage.removeEnd(',');
            return JSON.serialize(new Map<String,String>{'message' => errorMessage});
        }
    }

    /**
    *Name: makeCreditAssessmentRequest
    *Purpose: to send callout request to restcalloutservice and get response for credit assessment.  
    */
    @AuraEnabled
    public static String makeCreditAssessmentRequest(String quoteId, Boolean saveLogsAsync) {
        //Params defiend to get all the Credit Assessment parameters
        Map<String, Object> params = new Map<String, Object>();
        Map<String, String> headerParams = new Map<String, String>();
        headerParams = getHeaderParameters(quoteId);

        //Callout for RESTCalloutService and sents appropriate response for Credit Assessment   
        try{
            //CustomerSetupController.updateQuoteStatus(quoteId,'Assessment');
            RESTCalloutService calloutService = new RESTCalloutService();
            CreditAssessmentResponseBodyWrapper response = 
                (CreditAssessmentResponseBodyWrapper) calloutService.performCallout(Constants.CREDIT_ASSESSMENT, params, headerParams, null, saveLogsAsync);
            if(response.statusCode != 200){
                CustomerSetupController.updateQuoteStatus(quoteId,Constants.QUOTE_CALCULATION_STATUS);
            }
            return JSON.serialize(response.statusCode);
        }catch (Exception e) {
            ErrorLogger errorLog = new ErrorLogger();
            errorLog.logException(e, Constants.INTEGRATION_ERRORLOG_RECORDTYPE, quoteId, true);
            return JSON.serialize(new Map<String,String>{'message' => e.getMessage()});
        }
    } 

    /**
    *Name: getCustomer
    *Purpose: Method defined to get customer details and search party response  
    */     
    @AuraEnabled
    public static String getCustomer(String quoteId, String identifier, String identifierType) {
        String countryCode = new CustomerSetupController.WoSSelector().getQuoteById(quoteId).Applicable_Offers__r.Offer__r.Program__r.Region__r.ISO_Code__c;

        Map<String, Object> params = new Map<String, Object>();
        params.put('externalOrganizationId', identifier);
        params.put('uniqueIdentifierType', identifierType);
        params.put('countryOfRegistration', countryCode);

        //Callout for RESTCalloutService and sents appropriate response for Search Party
        try {
            RESTCalloutService calloutService = new RESTCalloutService();
            SearchPartyResponseBodyWrapper response =
                (SearchPartyResponseBodyWrapper) calloutService.performCallout(Constants.SEARCH_PARTY, params, null, null, true);
            return JSON.serialize(response); 
        } catch (Exception e) {
            ErrorLogger errorLog = new ErrorLogger();
            errorLog.logException(e, Constants.INTEGRATION_ERRORLOG_RECORDTYPE, quoteId, true);
            return JSON.serialize(new Map<String,String>{'message' => e.getMessage()});
        }
    }

    /**
    *Name: getHeaderParameters
    *Purpose: Method to define header parameters  
    */
    private static Map<String, String> getHeaderParameters (String quoteId) {
        Map<String, String> headerParams = new Map<String, String>();
        Quote quote = new WosSelector().getQuoteDetails(quoteId);
        String regionCode = quote.Applicable_Offers__r.Offer__r.Program__r.Region__r.ISO_Code__c;
        String quoteVersion = quote.Name.substringAfterLast('-');
        String contractNumber = quote.Opportunity.Name + '-' + quoteId + '-' + quoteVersion;

        headerParams.put('id', contractNumber);
        headerParams.put('regionCode', regionCode);

        return headerParams;
    }
    
    /**
    *Name: setErrorField
    *Purpose: Method to define error field and message for submit application  
    */
    public static object setErrorField(String fieldName){
        
        errorField = fieldName;
        errorMessage += '' + errorField +',';
        return null;
    }
  
    
    /***
    Name: sendCalloutToCalculationApi(cacheable=true)
    Purpose: pass the request details to the RestCalloutService class for calculation api callout
    **/
    @AuraEnabled(cacheable=true)
    public static CalculationAPIHelper.CalculationOutputWrapper sendCalloutToCalculationApi(String paramsForCalculation, Boolean saveLogsAsync) {
    
        CalculationAPIHelper.CalculationInputWrapper wrapper = (CalculationAPIHelper.CalculationInputWrapper) JSON.deserialize(paramsForCalculation, CalculationAPIHelper.CalculationInputWrapper.class);
        //get parameters for callout
        Map<String, Object> params = CalculationAPIHelper.createCalloutParams(wrapper);
        Map<String, String> headerParams = CalculationAPIHelper.createHeaderParams(wrapper);
        Map<String, String> urlParams = CalculationAPIHelper.createURLParams(wrapper);
		Double totalItadFees = CalculationAPIHelper.getITADFees(wrapper);
        
        CalculationAPIHelper.CalculationOutputWrapper wr = new CalculationAPIHelper.CalculationOutputWrapper();
        try {

            RESTCalloutService calloutService = new RESTCalloutService();
            CalculationResponseBodyWrapper response = (CalculationResponseBodyWrapper) calloutService.performCallout(Constants.CALCULATION, params, headerParams, urlParams, saveLogsAsync); // request method call. in future we should catch exception in the class that calls it

            if (response.statusCode == 200) {
                wr = CalculationAPIHelper.getCalcOutputWrapper(response, wrapper, totalItadFees);
            } else {
                //return custom message for Residual and insurance Amount if its outside the boundries                         
                if ((response.message.contains(Constants.INSURANCE) || response.message.contains(Constants.RESIDUAL_VALUE)) && response.message.contains('boundaries')){
                    String  tempMsg;
                    String[] msg = response.message.split(';');
                    if(response.message.contains(Constants.RESIDUAL_VALUE) ){
                         tempMsg = Label.RV_out_of_Boundaries ; // msg[0].remove('['+msg[0].substringBetween('[',']')+']');
                    }else{
                         tempMsg = Label.Insurance_out_of_Boundaries ; 
                    }
                    
                    
                    String modelName =  msg[1].split('modelName')[1].substringBetween('[',']');  
                    
                    String customMsg = tempMsg +' '+modelName+','+ msg[2];
                    
                    wr.errorMessage = customMsg;
                }else{
                    wr.errorMessage = response.message;
                }
                
            }
        }
        catch (Exception e) {
            wr.errorMessage = e.getMessage();
            ErrorLogger errorLog = new ErrorLogger();
            errorLog.logException(e, Constants.INTEGRATION_ERRORLOG_RECORDTYPE, null, true);
        }

        return wr;
    }

    /**
    *Name: createOrder
    *Purpose: Callout sends order Id and document info to Azure when user fills in necessary data on AML screen.
    *         Salesforce gets response with "Active" order status 
    *         and signURL value
    */
    @AuraEnabled
    public static string createOrder(String orderId) {
        // get params for request body wrapper
        Map<String, Object> params = new Map<String, Object>();
        params.put('orderId', orderId);

        // make callout form RESTCalloutService and receive appropriate response for Create Order
        try {
            RESTCalloutService calloutService = new RESTCalloutService();
            CreateOrderResponseBodyWrapper response =
                (CreateOrderResponseBodyWrapper) calloutService.performCallout(Constants.CREATE_ORDER, params, null, null, true);

            // salesforce receives status code 200 when order is successfully created
            if (response.statusCode == 200) {
                Map<String,Object> eSignInfoFieldValues = new Map<String,Object>{
                    'Id' => orderId, 
                    'Status__c' => Constants.ACTIVE_STATUS,
                    'iFrame_URL__c' => response.Item.SigningProcessResults.SigningProcessResult[0].SignURL
                };
                
                // update the esign record
                ESignInformationController.updateESignInfo(eSignInfoFieldValues); 
                // return map with message and sign URl
                return JSON.serialize(new Map<String,String>{'Success message' => 'Order is updated Successfully', 'iframeURL' => String.valueof(eSignInfoFieldValues.get('iFrame_URL__c'))});
            // if order is not created error message will be returned
            } else {
                return JSON.serialize(new Map<String,String>{'Error message' => 'Status code: ' + response.statusCode + '. Error message: ' + response.message});
            }
        } catch (Exception e) {
            ErrorLogger errorLog = new ErrorLogger();
            errorLog.logException(e, Constants.INTEGRATION_ERRORLOG_RECORDTYPE, orderId, true); 
            return JSON.serialize(new Map<String,String>{'Error message' => e.getMessage()});
        }
    }

    /**
    *Name: cancelOrder
    *Purpose: Callout sends Order Id to Azure to cancel order from E-Sign screen
    */
    public static String cancelOrder(String orderId) {
        // get params for request body wrapper
        Map<String, Object> params = new Map<String, Object>();
        params.put('orderId', 'SFDC' + orderId);

        // make callout form RESTCalloutService and receive appropriate response for Cancel Order
        try {
            RESTCalloutService calloutService = new RESTCalloutService();
            CancelOrderResponseBodyWrapper response =
                (CancelOrderResponseBodyWrapper) calloutService.performCallout(Constants.CANCEL_ORDER, params, null, null, true);

            // salesforce receives status code 200 when order is successfully canceled
            if (response.statusCode == 200) {
                Map<String,Object> eSignInfoFieldValues = new Map<String,Object>{
                    'Id' => orderId, 
                    'Status__c' => Constants.CANCELLED_STATUS
                };

                // update the esign record
                ESignInformationController.updateESignInfo(eSignInfoFieldValues);
                // return map with message
                return JSON.serialize(new Map<String,String>{'Success message' => Label.Order_has_been_canceled});
            // if order is canceled error message will be returned    
            } else {
                return JSON.serialize(new Map<String,String>{'Error message' => 'Status code: ' + response.statusCode + '. Error message: ' + response.message});
            }
        } catch (Exception e) {
            ErrorLogger errorLog = new ErrorLogger();
            errorLog.logException(e, Constants.INTEGRATION_ERRORLOG_RECORDTYPE, orderId, true); 
            return JSON.serialize(new Map<String,String>{'Error message' => e.getMessage()});
        }
    }

    /**
    *Name: getSDO
    *Purpose: call queueable method because this method is invoked by PB for list Ids (1 transaction per 1 Id)
    */
    @InvocableMethod(label='Get SDO' description='Get SDO by order Id when order status is changed to Complete' callout=true)
    public static void getSDO(List<Id> orderIds) {
        for (Id orderId : orderIds) {
            Id jobId = System.enqueueJob(new QueueableCalloutService(
                'Get_SDO', 
                new Map<String,Object>{'orderId' => orderId}
            ));
        }
    }

    /**
    *Name: getSDOCallout
    *Purpose: Callout sends to Azure to get and save SDO by order Id
    */
    public static void getSDOCallout(Id orderId) {
        // get order info by order Id
        E_Sign_Information__c esignInfo = new ESignInformationController.WoSSelector().getESignInfo(orderId);

        // get params for request body wrapper
        Map<String, Object> params = new Map<String, Object>();
        params.put('orderId', orderId);

        // make callout form RESTCalloutService and receive appropriate response for Get SDO
        try {
            RESTCalloutService calloutService = new RESTCalloutService();
            GetSDOResponseBodyWrapper response =
                (GetSDOResponseBodyWrapper) calloutService.performCallout(Constants.GET_SDO, params, null, null, false);

            // salesforce receives status code 200 with SDO
            if (response.statusCode == 200) {
                String SDOBodyAsString = response.B64SDOBytes;
                String PAdESBodyAsString = response.PAdESSignedDocumentBytes;
                Map<String,String> documents = new Map<String,String>{Constants.SDO_DOCUMENT_TYPE => SDOBodyAsString, Constants.PAdES_DOCUMENT_TYPE => PAdESBodyAsString};
				
                Map<String,Object> sendDocParam = new Map<String,Object>();
                sendDocParam.put('orderId', orderId);
                sendDocParam.put('documents', documents);
                sendDocParam.put('documentType', esignInfo.Document_Type__c);
                sendDocParam.put('oppName', esignInfo.Opportunity__r.Name);
                sendDocParam.put('quoteName', esignInfo.Quote__r.Name);
                sendDocParam.put('recipientID', esignInfo.SSN_Number__c);
                sendDocParam.put('recipientName', esignInfo.Signer_Name__c);
                sendDocParam.put('email', esignInfo.Customer_Email__c);
                sendDocParam.put('dateSigned', esignInfo.Date_Of_Signing__c);
                
                
                Id jobId = System.enqueueJob(new QueueableCalloutService(
                    Constants.SEND_DOCUMENTS, 
                    //new Map<String,Object>{'orderId' => orderId, 'documents' => documents, 'documentType' => esignInfo.Document_Type__c}
                    sendDocParam
                ));

                List<GenericUtilityClass.DocumentInfo> docInfo = new List<GenericUtilityClass.DocumentInfo>{
                    new GenericUtilityClass.DocumentInfo(Constants.SDO_DOCUMENT_TYPE + '-' + esignInfo.Name, Constants.SDO_DOCUMENT_TYPE, SDOBodyAsString), 
                    new GenericUtilityClass.DocumentInfo(Constants.PAdES_DOCUMENT_TYPE + '-' + esignInfo.Name, Constants.PAdES_DOCUMENT_TYPE, PAdESBodyAsString)
                };

                GenericUtilityClass.createAndAttachFilesToRecords(docInfo, new Set<Id>{orderId});
            }
        } catch (Exception e) {
            ErrorLogger errorLog = new ErrorLogger();
            errorLog.logException(e, Constants.INTEGRATION_ERRORLOG_RECORDTYPE, orderId, true); 
        }
    }

    /**
    *Name: sendCode
    *Purpose: Callout sends Code and order Id to Azure to get Signer info (name, SSN)
    */
    @AuraEnabled
    public static String sendCode(String paramsString) {
        // deserialize params from JSON string
        Map<String, Object> sendCodeParams = (Map<String, Object>) JSON.deserializeUntyped(paramsString);
        Map<String, Object> params = new Map<String, Object>();

        // get params for request header
        Map<String, String> urlParams = new Map<String, String>();
        urlParams.put('authCode', (String) sendCodeParams.get('code'));

        // make callout form RESTCalloutService and receive appropriate response for Sen Code
        try {
            RESTCalloutService calloutService = new RESTCalloutService();
            SendCodeResponseBodyWrapper response =
                (SendCodeResponseBodyWrapper) calloutService.performCallout(Constants.SEND_CODE, params, null, urlParams, true);

            // return map with message if salesforce receives status code 200 with SDO    
            if (response.statusCode == 200) {                               
                return JSON.serialize(new Map<String,String>{'Success message' => 'Signer information has been updated'});
            // if order is canceled error message will be returned     
            } else {
                return JSON.serialize(new Map<String,String>{'Error message' => 'Status code: ' + response.statusCode + '. Error message: ' + response.message});               
            }
        } catch (Exception e) {
            ErrorLogger errorLog = new ErrorLogger();
            errorLog.logException(e, Constants.INTEGRATION_ERRORLOG_RECORDTYPE, null, true); 
            return JSON.serialize(new Map<String,String>{'Error message' => e.getMessage()});
        }
    }

    /**
    *Name: sendDocumentsToDCV
    *Purpose: Callout sends main document (when salesforce receives it from Smartcom) 
    *         or SDO and PAdES to DCV (when salesforce receives it from Nets)
    */
    //public static void sendDocumentsToDCV(Id quoteId, Id orderId, String documentType, Map<String,String> documents,String type) {
    public static integer sendDocumentsToDCV(Map<String,Object> params) {
        
        SendDocumentsResponseBodyWrapper response = new SendDocumentsResponseBodyWrapper();
        String type = (String) params.get('type');
        Id orderId = (Id) params.get('orderId');

        // make callout form RESTCalloutService and receive appropriate response for Send Documents
        try {
            RESTCalloutService calloutService = new RESTCalloutService();           
            response = (SendDocumentsResponseBodyWrapper) calloutService.performCallout(Constants.SEND_DOCUMENTS, params, null, null, false);
            
              //Execute this code only for unsigned documnet
            //update order if unsigned doc sent to DCV successfully or not           
            if(type == Constants.UNSIGNED_DOCUMENT_TYPE){
                E_Sign_Information__c esignInfo = new E_Sign_Information__c();
                esignInfo.id = orderId;
                if(response.statusCode == 200){
                    esignInfo.UnSigned_Doc_Status__c=Constants.UNSIGNED_STATUS_SENT;
                }else{
                    esignInfo.UnSigned_Doc_Status__c=Constants.UNSIGNED_STATUS_FAIL;
                } 
                
                //update esignInfo for unsigned doc sent to DCV successfully or not      
                new GenericUtilityClass.WoSDMLProcessor().updateRecords(new List<E_Sign_Information__c>{esignInfo});
            }
            
        } catch (Exception e) {
            ErrorLogger errorLog = new ErrorLogger();
            //String recordId = orderId != null ? orderId : quoteId;
            errorLog.logException(e, Constants.INTEGRATION_ERRORLOG_RECORDTYPE, orderId, true);        
        }
        return response.statusCode;
    }
    
    
     /*
    *Name: smartcommDocCallout
    *Purpose: make callout using RESTCalloutService, if any exception occoured then perform retry callout till retry attemup count, and attach generated doc from smartComm api response on quote and opportunity.
    */
    public static void smartcommDocCallout(Map<String, Object> reqParams, Boolean saveLogsAsync){
       
        RESTCalloutService calloutService ;
        SmartCommResponseBodyWrapper response;
        Map<String, Object> responseMap = new Map<String, Object>();
        responseMap.put('quoteId',(Id)reqParams.get('quoteId'));
        responseMap.put('oppId',(Id)reqParams.get('oppId'));
        responseMap.put('docType',(String)reqParams.get('docType'));
        responseMap.put('docCount',Integer.valueOf(reqParams.get('docCount')));
              
        try{            
            calloutService = new RESTCalloutService();
            response =(SmartCommResponseBodyWrapper) calloutService.performCallout(Constants.SMART_COMM_DOC, reqParams, null, null, saveLogsAsync);
            SmartCommHelper.saveDocument(responseMap,response);
           
         }catch (Exception e) {            
            ErrorLogger errorLog = new ErrorLogger();
            errorLog.logException(e, Constants.INTEGRATION_ERRORLOG_RECORDTYPE, (Id)reqParams.get('quoteId'), true); 
        }
    }

    /**
     * Inner class-selector
     */
    public without sharing class WoSSelector {

        /**
        *Name: getQuotesWithAssessmentStatus
        *Purpose: Returns query for assessment and opportunityId from quote
        */
        private List<Quote> getQuotesWithAssessmentStatus(String opportunityId) {             
            return [SELECT Id FROM Quote WHERE Status = :Constants.QUOTE_CALCULATION_EXPIRED_STATUS AND opportunityId = :opportunityId];               
        }

      
        /**
        *Name: getQuoteDetails
        *Purpose: queries all body parameters from quote.  
        */
        private Quote getQuoteDetails(String quoteId) {    
            return 
            [
                SELECT 
                    Id,
                   
                    Name, 
                    Owner.firstname,Owner.lastname, 
                    CreatedBy.Final_Id__c,
                    CreatedBy.Email,
                    Valid_From__c,  
                    Account.Name,
                    Account.id,
                    Account.Doing_Business_As__c, 
                    Account.Org_No__c,
                    Account.Invoice_Fee_Amount__c,
                    //Account.Extension_Fee__c,
                    Account.Start_Up_Fee_Amount__c,
                    Account.Start_Up_Fee_Split_Percentage__c,
                    Account.Goes_to_DLL_partner_Startup__c,
                    Account.External_Identifier__c, 
                    Account.Margin_Matrix__c,
                    Account.Final_Id__c,
                    Applicable_Offers__c,
                    Applicable_Offers__r.Name, 
                    Applicable_Offers__r.Offer__r.Name,
                    OpportunityId,  
                    Opportunity.Name,
                    Value_downpayment__c,
                    Opportunity.Owner.Name, 
                    Opportunity.CreatedDate, 
                    Opportunity.CloseDate,
                    Opportunity.CurrencyIsoCode,               
                    Quote_Rate__r.Cost_Of_Funds__c,
                    Term__c, 
                    Insurance_Display_Options__c,
                    Applicable_Offers__r.Offer__r.Program__r.Region__r.ISO_Code__c,
                    Applicable_Offers__r.Offer__r.Program__r.Business_Unit__r.Business_Unit_Code__c,
                    Applicable_Offers__r.Offer__r.Program__r.Business_Unit__r.Name,
                    Applicable_Offers__r.Offer__c,
                    Applicable_Offers__r.Offer__r.Program__r.Name,
                    //Applicable_Offers__r.Offer__r.IS_RV_Applicable__c,
                    Applicable_Offers__r.Offer__r.RV_Type__c,
                    Applicable_Offers__r.Offer__r.Program__r.Asset_Program__c,
                    Applicable_Offers__r.Offer__r.Selectable_Agreement_Term__c,
                    Applicable_Offers__r.Offer__r.Program__r.Allowed_Maximum_Deposit__c,
                    Applicable_Offers__r.Offer__r.Program__r.Allowed_Minimum_Deposit__c,
                    Opportunity.End_User__r.name,
                    Opportunity.End_User__r.BillingAddress,
                    Opportunity.End_User__r.Org_No__c,
                    Opportunity.End_User__r.Phone,
                    Opportunity.Account.Name,
                    Opportunity.Account.Doing_Business_As__c,
                    Opportunity.Account.BillingAddress  ,
                    Opportunity.Account.Org_No__c,
                    Opportunity.Account.Website,
                    Opportunity.Account.Phone,
                    Opportunity.Account.Start_Up_Fee_Amount__c,
                    //Opportunity.Account.Extension_Fee__c,   
                    Opportunity.Account.Legal_Entity_Description__c,
                    Contact.Email,
                    Contact.Name,
                    Contact.Phone,
                    Financed_Amount__c,
                    Rental_Amount__c,
                    Frequency__c,
                    ITAD_Category__c,
                    Payment_Timing__c,
                    Quote_Rate__r.Name,
                    Quote_Rate__r.Date__c,
                    Quote_Rate__r.Rate_Type__c,
                    Quote_Rate__r.Backoffice_Reference__c,
                    Applicable_Offers__r.Offer__r.Contract_Document__c,
                    Applicable_Offers__r.Offer__r.Extension_Code__c,
                    Applicable_Offers__r.Offer__r.General_Terms_and_Conditions__r.SmartComTemplateReference__c,
                    Interest__c 
            FROM Quote
            WHERE Id = :quoteId
            ];     
        }
        
    
    }
}