/**
 * This class is used as apex controller for E-Sign screens
 * 
 * Version 1.0 @author Elena Sokolova, Anujit Das @date 2021-07-02 , US 674749 developed by Anujit 20-12-2021
 * 
 */
    public with sharing class ESignInformationController {

    /**
     * Method is called from LWC to get and display E-Sign record (orders) on E-Sign screen
     * 
     * @return JSON string with E_Sign_Information__c list
     */
    @AuraEnabled(cacheable=true)
    public static String getESignInfomation(Id qouteId) {
        return JSON.serialize(new WoSSelector().getESignInfoListByQuoteId(qouteId,null));
    }

    /**
     * Method is called from LWC (E-Sign screen) to cancel order.
     * Available for "New", "Pending Contract", "Active" statuses
     * 
     * @return String with result message
     */
    @AuraEnabled
    public static String cancelSignture(Id eSignInfoId) {
        E_Sign_Information__c eSignInfo = new WoSSelector().getESignInfo(eSignInfoId);

        // send request to Azure => Nets if order status is "Active"
        if (eSignInfo.Status__c == Constants.ACTIVE_STATUS) {
            return RESTCalloutHelper.cancelOrder(eSignInfoId);
        // update ordet status to 'CancelledByMerchant' in SF DB if order status is "New" (it means that order is not created in NETs)
        } else if (eSignInfo.Status__c == Constants.NEW_STATUS || eSignInfo.Status__c == Constants.PENDING_CONTRACT_STATUS) { 
            updateESignInfo(new Map<String,Object>{
                'Id' => eSignInfoId, 
                'Status__c' => Constants.CANCELLED_STATUS
            });
            return JSON.serialize(new Map<String,String>{'Success message' => Label.Order_has_been_canceled});
        } else {
            return JSON.serialize(new Map<String,String>{'Warning message' => (Label.Order_Status_Is + ' ' + eSignInfo.Status__c)});
        }
    }

    /**
     * Method is called from LWC (E-Sign screen) to display documents for Quote.
     * 
     * @return JSON string with map where document id is a key and document title is value
     */
    @AuraEnabled(cacheable=true)
    public static String getPDFs(Id quoteId) {
        Map<ID, String> mapIdTitle = new Map<ID, String>();
        List<ContentVersion> docs = getDocumentsByQuoteId(quoteId);

        for (ContentVersion doc : docs) {
            mapIdTitle.put(doc.ContentDocumentId, doc.Document_Type__c + '-' + doc.Title);
        }

        return JSON.serialize(mapIdTitle);
    }

    /**
     * Method finds all attached files for particular record by Id.
     * 
     * @return List<ContentVersion> list of last versions
     */
    public static List<ContentVersion> getDocumentsByQuoteId(Id quoteId) {
        // Get record file IDs        
        List<ContentDocumentLink> files = new WoSSelector().getContentDocumentLinkByLinkedId(quoteId);
        List<ID> fileIDs = new List<ID>();

        for (ContentDocumentLink docLink : files) {
            fileIDs.add(docLink.ContentDocumentId);
        }
 
        return new WoSSelector().getContentVersionsByDocumentIds(fileIDs,null);
    }

     public static ContentVersion getDocumentByType(List<ContentVersion> docs, String documentName) {
        for (ContentVersion doc : docs) {
            //if (doc.Document_Type__c == documentType) {
            if ( doc.Title == documentName) {
                return doc;
            }
        }

        return null;
    }

    /**
     * Method is called from LWC (E-Sign screen) to create order(s) in SF.
     * 
     * @return Boolean value. It is true when orders are created
     */
    @AuraEnabled
    public static boolean createEsignOrder(string esignInformation) {

       list<E_Sign_Information__c> eSignObjList = new list<E_Sign_Information__c>();
       // check if JSON string is not empty
       if(String.isNotBlank(esignInformation)){
           // deserialize JSON string using inner wrapper class (EsignInfoClass)
           list<EsignInfoClass> esignClassList = (List<EsignInfoClass>) System.JSON.deserialize(esignInformation, List<EsignInfoClass>.class); 

           for(EsignInfoClass eachEsign : esignClassList){
               E_Sign_Information__c esignObj = new E_Sign_Information__c();
                esignObj.Customer_Email__c = eachEsign.email;
                esignObj.Opportunity__c=eachEsign.opptyId;
                esignObj.Document_Type__c=eachEsign.docType;
                esignObj.Quote__c=eachEsign.quoteId;
                esignObj.Primary_Product__c = eachEsign.primaryProduct;
                esignObj.Primary_Product_Description__c = eachEsign.primaryProductDesc;
                esignObj.Document_Name__c=eachEsign.docName;
                // initial order status depends on document type
                esignObj.Status__c = esignObj.Document_Type__c.equalsIgnoreCase(Constants.AOD_DOCUMENT_TYPE) ? Constants.PENDING_CONTRACT_STATUS : Constants.NEW_STATUS;
                                                                           
                eSignObjList.add(esignObj);
           }          
            try{
                new GenericUtilityClass.WoSDMLProcessor().insertRecords(eSignObjList); //DML on Esign info object.
                Quote quoteRecord = [SELECT Status FROM Quote WHERE Id = :esignClassList[0].quoteId LIMIT 1];
                if(quoteRecord.Status == Constants.QUOTE_DOCUMENT_GEN_STATUS){
                    //update quote only at 1st time to make status as 'pending e-sign'.
                    CustomerSetupController.updateQuoteStatus(esignClassList[0]?.quoteId, Constants.PENDING_E_SIGN_STATUS);
                }
                
                return true;
            } catch(DmlException e){
                ErrorLogger errorLog = new ErrorLogger();
                errorLog.logException(e, Constants.GENERIC_ERRORLOG_RECORDTYPE, esignClassList[0]?.quoteId, true); 
                throw new ErrorLogger.ErrorLoggerException(e.getDmlMessage(0));
            } catch(exception e){
                ErrorLogger errorLog = new ErrorLogger();
                errorLog.logException(e, Constants.GENERIC_ERRORLOG_RECORDTYPE, esignClassList[0]?.quoteId, true); 
                throw new ErrorLogger.ErrorLoggerException(e.getMessage());
            }
        } return false;
    }

    /**
     * Method is called from LWC (E-Sign screen) to display authorized signatories for customer account.
     * 
     * @return JSON string with Contact list
     */
    @AuraEnabled(cacheable=true)
    public static String getAuthorizedSignatoriesInfo(String opportunityId){
        return JSON.serialize(new WoSSelector().getAuthorizedSignatories(opportunityId));
    }

    /**
     * Method updates E_Sign_Information__c object with defined params.
     * Field name is a key, field value is a value
     */
    public static void updateESignInfo(Map<String, Object> eSignInfoFieldValues) {
        E_Sign_Information__c eSignInfo = new E_Sign_Information__c();
        try {
            for (String fieldName : eSignInfoFieldValues.keySet()) {
                eSignInfo.put(fieldName, eSignInfoFieldValues.get(fieldName));
            }
            new GenericUtilityClass.WoSDMLProcessor().updateRecords(new List<SObject>{eSignInfo});
        } catch (Exception e) {
            ErrorLogger errorLog = new ErrorLogger();
            errorLog.logException(e, Constants.GENERIC_ERRORLOG_RECORDTYPE, (String) eSignInfoFieldValues.get('Id'), true); 
        } 
    }

    /**
     * Method gets E_Sign_Information__c record by order Id.
     * It used in LWCs for E-Sign
     * 
     * @return JSON String with E_Sign_Information__c record
     */
    @AuraEnabled
    public static string getEsignInfoString(String eSignInfoId){
        return JSON.serialize(new WoSSelector().getESignInfo(eSignInfoId));
    }

     /**
     * Method gets existing contact for the order id
     * It used in LWCs for esign aml screen
     * 
     * @return JSON String with contact and account ultimate benefical owner record
     */
    @AuraEnabled 
    public static string getExistingContactsString(String orderId){
        return JSON.serialize(getExistingContacts(orderId));
    }
    
    /**
     * Method used to form the wrapper of the existing contact for this order id
     * 
     * @return List<ContactWrapperClass>
     */
    private static List<ContactWrapperClass> getExistingContacts(string orderId){

        List<ContactWrapperClass> contactWrapperClassList = new List<ContactWrapperClass>();
        ContactWrapperClass contWrObj;
        E_Sign_Information__c eSignInfo = new WoSSelector().getESignInfo(orderId);
        if(eSignInfo.Opportunity__r.End_User__c != NULL){
            list<Contact> contactList = new WoSSelector().getContacts(eSignInfo.Opportunity__r.End_User__c);
            
            if(contactList.size() > 0){
                for(Contact eachCont : contactList){ 
                    contWrObj = new ContactWrapperClass();
                    contWrObj.contactName = eachCont.name;
                    contWrObj.ssn = eachCont.External_ID__c;
                    contWrObj.contactId = eachCont.id;
                    contWrObj.ultimateBenOwner = eSignInfo?.Opportunity__r.End_User__r.Ultimate_Beneficial_Owner__c;
                    contactWrapperClassList.add(contWrObj);
                }
            }else{
                //if there is no contact, then user selected 'No' in the page
                contWrObj = new ContactWrapperClass();          
                contWrObj.ultimateBenOwner = false; //[select Ultimate_Beneficial_Owner__c from account where id =: eSignInfo.Opportunity__r.End_User__c limit 1].Ultimate_Beneficial_Owner__c;
                contactWrapperClassList.add(contWrObj);
            }
            
        }
        return contactWrapperClassList;
    }

    /**
     * Method is called from LWC (AML screen) to create contacts in SF for customer account.
     * 
     * @return Boolean value. It is true when contacts are created
     */
     @AuraEnabled
     public static boolean createAndDeleteContact(String ContactJSON, list<id> deletedContactIds,string orderId){
                
        List<ContactWrapperClass> contactObj = (List<ContactWrapperClass>)System.JSON.deserialize(ContactJSON,List<ContactWrapperClass>.class);
        List<Contact> contlst = new List<Contact>();
        
        E_Sign_Information__c eSignRecord = new WoSSelector().getESignInfo(orderId);
        if(contactObj[0]?.ultimateBenOwner){  //if the response is Yes in the UI, then only create contact
            for(ContactWrapperClass eachContact: contactObj){
                Contact contObj = new Contact();
                contObj.FirstName = String.isNotBlank(eachContact.contactName) && eachContact.contactName.contains(' ') ? eachContact.contactName.substringBefore(' ') : '';
                contObj.LastName = String.isNotBlank(eachContact.contactName) && eachContact.contactName.contains(' ') ? eachContact.contactName.substringAfter(' ') : eachContact.contactName;
                contObj.External_ID__c = eachContact.ssn;
                contObj.Role__c = Constants.ULTIMATE_BENEFICIAL_OWNER_CONTACT_ROLE;
                contObj.id = String.isNotBlank(eachContact.contactId) ? eachContact.contactId : null ;
                contObj.Accountid = eSignRecord.Opportunity__r.End_User__c;
        
                contlst.add(contObj);
            }
            try{  
                new GenericUtilityClass.WoSDMLProcessor().upsertRecords(contlst); //DML on contact
                if(deletedContactIds != null && deletedContactIds.size () > 0){
                    new GenericUtilityClass.WoSDMLProcessor().deleteRecords(
                        new WoSSelector().getContactsByIds(deletedContactIds)
                    );
                }   
                new GenericUtilityClass.WoSDMLProcessor().updateRecords(new List<SObject>{
                    new Account(id = eSignRecord.Opportunity__r.End_User__c,Ultimate_Beneficial_Owner__c = contactObj[0]?.ultimateBenOwner)
                }); //dml on account
                return true;    
            }catch(Exception e){
                ErrorLogger errorLog = new ErrorLogger();
                errorLog.logException(e, Constants.GENERIC_ERRORLOG_RECORDTYPE, null, true);     
                return false;           
            }
        }else{
             try{  
                new GenericUtilityClass.WoSDMLProcessor().updateRecords(new List<SObject>{
                    new Account(id = eSignRecord.Opportunity__r.End_User__c,Ultimate_Beneficial_Owner__c = contactObj[0]?.ultimateBenOwner)
                }); //dml on account
                return true;    
            }catch(Exception e){
                ErrorLogger errorLog = new ErrorLogger();
                errorLog.logException(e, Constants.GENERIC_ERRORLOG_RECORDTYPE, eSignRecord.Opportunity__r.End_User__c, true);       
                return false;           
            }
        }    
    }
    
    /**
    *Method name: getChecklistQuestion
    *Purpose: to return the document questionaire list to show on the review screen
     */
    @AuraEnabled(cacheable=true)
    public static list<DocumentQuestionClass> getChecklistQuestion(String quoteId){

        list<DocumentQuestionClass> documentQuestionClassList = new list<DocumentQuestionClass>();

        if(String.isNotBlank(quoteId)){
            for(Document_Questionnaire__c eachDocQstn : new WoSSelector().getDocumentQuestionaires(quoteId)){
                DocumentQuestionClass docQstnObj = new DocumentQuestionClass(eachDocQstn.Question_Name__c,eachDocQstn.Response__c,
                                                        eachDocQstn.Comment__c,eachDocQstn.Reason_Code__c,eachDocQstn.Document_Type__c,
                                                        eachDocQstn.Quote__r.Opportunity.name+':'+eachDocQstn.Quote__r.name );
                documentQuestionClassList.add(docQstnObj);
            }
        }
        return documentQuestionClassList;      
    }
    
    /**
    *get the custom metadatype standard auth creds details
     */
    @AuraEnabled(cacheable=true)
    public static Standard_Auth_Credentials__mdt getStandardAuthCustomMeta(string recordName) {
        return Standard_Auth_Credentials__mdt.getInstance(recordName);
    }

    /**
    *Method name: doSaveInvoiceData
    *Purpose: to save the invoice data on customer account
     */
    @AuraEnabled
    public static boolean doSaveInvoiceData(string invoiceData) {
      
        InvoiceDataWrapperClass invoiceTypeObj = (InvoiceDataWrapperClass)System.JSON.deserialize(invoiceData,InvoiceDataWrapperClass.class);
        E_Sign_Information__c eSignRecord = new WoSSelector().getESignInfo(invoiceTypeObj.orderId);
        if(String.isNotblank(invoiceTypeObj?.invoiceType) && eSignRecord != null){  //if the user selected any of the invoice type
            return updateInvoiceInfo(eSignRecord,invoiceTypeObj);
        }
        return false;
    }

     /**
    *Method name: updateInvoiceInfo
    *Purpose: to update the invoice data on customer account
     */
    @TestVisible
    private static boolean updateInvoiceInfo(E_Sign_Information__c eSignRecord,InvoiceDataWrapperClass invoiceTypeObj){
      
        Account acc = new Account();
        acc.id = eSignRecord.Opportunity__r.End_User__c;
        acc.Invoice_Type__c = invoiceTypeObj.invoiceType;

        acc.People_ID__c = invoiceTypeObj.invoiceType == Constants.EDI ? invoiceTypeObj.pepolIdValue : '';

        /*acc.Reference__c = (invoiceTypeObj.invoiceType == Constants.EDI) ? invoiceTypeObj.ediRefrenceValue 
                            : (invoiceTypeObj.invoiceType == Constants.PDF) ? invoiceTypeObj.pdfReferenceValue 
                            : (invoiceTypeObj.invoiceType == Constants.LETTER) ? invoiceTypeObj.letterReferenceValue 
                            : '';*/

        acc.Email_Invoice__c = invoiceTypeObj.invoiceType == Constants.PDF ? invoiceTypeObj.pdfEmailValue : '';

        acc.ShippingStreet = invoiceTypeObj.invoiceType == Constants.LETTER ? invoiceTypeObj.letterAdresValue : '';
        acc.ShippingCity = invoiceTypeObj.invoiceType == Constants.LETTER ? invoiceTypeObj.letterCityValue : '';
        acc.ShippingCountry = invoiceTypeObj.invoiceType == Constants.LETTER ? invoiceTypeObj.letterCountryValue : '';
        acc.ShippingPostalCode = invoiceTypeObj.invoiceType == Constants.LETTER ? invoiceTypeObj.letterPoNumValue : '';
        acc.C_O_Name__c = invoiceTypeObj.invoiceType == Constants.LETTER ? invoiceTypeObj.letterCoNameValue : '';
        
        //Updating reference at Quote
        Quote quote = new Quote();
        quote.id = eSignRecord.Quote__c;
        quote.Reference__c = (invoiceTypeObj.invoiceType == Constants.EDI) ? invoiceTypeObj.ediRefrenceValue 
                            : (invoiceTypeObj.invoiceType == Constants.PDF) ? invoiceTypeObj.pdfReferenceValue 
                            : (invoiceTypeObj.invoiceType == Constants.LETTER) ? invoiceTypeObj.letterReferenceValue 
                            : '';
        
        try{  
            new GenericUtilityClass.WoSDMLProcessor().updateRecords(new list<account>{acc});
            new GenericUtilityClass.WoSDMLProcessor().updateRecords(new list<Quote>{quote});
            return true;    
        }catch(Exception e){
            ErrorLogger errorLog = new ErrorLogger();
            errorLog.logException(e, Constants.GENERIC_ERRORLOG_RECORDTYPE, eSignRecord.Opportunity__r.End_User__c, true);       
            return false;           
        }
    }
    
     /**
    *Method name: getUnsignDoc
    *Purpose: call queable method  because this method is invoked by PB for list Requests (1 transaction per 1 Id)
    */ 
    @InvocableMethod(label='Get UnSignDoc' description='Send UnSigned doc to DCV only one time for Each Document type' callout=true)
    public static void getUnsignDoc(List<Request> requests) {
        Set<String> uniqueReq = new Set<String>();
        
        //Bulkifying request for executing query
        for (Request request : requests) {
           
            //Identify unique PB requests based on quote and document name if there is multiple signer of any document type
            if(!uniqueReq.contains( request.quoteId+'#'+request.documentName)){
                sendUnsignDocCallOut(request.quoteId,request.documentName);
            }
             uniqueReq.add(request.quoteId+'#'+request.documentName);
            
        }
    } 
        
     /**
    *Method name: sendUnsignDocCallOut
    *Purpose: Send UnSigned PDF to  DCV only one time if document has been
    signed by any signer in case of there is multiple signer for any document type
    */     
      public static void sendUnsignDocCallOut(Id quoteId, String docName) {
          Boolean sendToDCV = false;
          E_Sign_Information__c esignInfo;
          
          List<E_Sign_Information__c> esignInfoList= new WoSSelector().getESignInfoListByQuoteId(quoteId,docName);
          
          //check status of unSigned doc.If none of the Signed Document Sent to DCV then make callout 
          //for sending document to DCV
          for(E_Sign_Information__c eachObj:  esignInfoList){
              
              if(eachObj.Status__c == Constants.COMPLETE_STATUS  &&  eachObj.UnSigned_Doc_Status__c != Constants.UNSIGNED_STATUS_SENT){
                  sendToDCV = true;   
                  esignInfo = eachObj;
              }else if(eachObj.Status__c == Constants.COMPLETE_STATUS  &&  eachObj.UnSigned_Doc_Status__c == Constants.UNSIGNED_STATUS_SENT){
                  sendToDCV = false;
                  break;
              }
          }
          
        if(sendToDCV){
            try{
                 List<ContentDocumentLink> files = new WoSSelector().getContentDocumentLinkByLinkedId(quoteId);
                List<ID> fileIDs = new List<ID>();
                
                for (ContentDocumentLink docLink : files) {
                    fileIDs.add(docLink.ContentDocumentId);
                }               
                
                //query Doc based on fileIDs and Document name
               List<ContentVersion> unsignedPdf =  new WoSSelector().getContentVersionsByDocumentIds(fileIDs,docName);
                
                //create params for send doc to DCV
                Map<String,Object> sendDocParam = new Map<String,Object>();
                sendDocParam.put('orderId', esignInfo.Id);
                sendDocParam.put('documents', new Map<String,String>{unsignedPdf[0].Title => EncodingUtil.base64Encode(unsignedPdf[0].VersionData)});
                sendDocParam.put('documentType', unsignedPdf[0].Document_Type__c);                
                sendDocParam.put('oppName', esignInfo.Opportunity__r.Name);
                sendDocParam.put('quoteName', esignInfo.Quote__r.Name);                
                sendDocParam.put('type', Constants.UNSIGNED_DOCUMENT_TYPE);
                
                //send Doc to DCV async bcz we need to perfrom callout and DML which invoke PB not commited yet
                //sync callout cause uncommitted work pending before callout                  
                Id jobId = System.enqueueJob(new QueueableCalloutService(
                    Constants.SEND_DOCUMENTS, 
                    sendDocParam
                ));
                
            } catch(Exception e){
                ErrorLogger errorLog = new ErrorLogger();
                errorLog.logException(e,Constants.INTEGRATION_ERRORLOG_RECORDTYPE, quoteId, true);                        
            }
        }
    }
      
        /**
        * check if there is multiple signer of given document name then return 
        * status of Signing process completed by any Signer
        */
        @AuraEnabled(cacheable=true)
        public static String getMultipleSignerInfo(Id quoteId ,String documentName) {
            String signingStatus = '';
            
            for(E_Sign_Information__c eachObj:  new WoSSelector().getESignInfoListByQuoteId(quoteId,documentName)){              
                if(eachObj.Status__c == Constants.COMPLETE_STATUS  ){
                    signingStatus = eachObj.Status__c;
                    break;
                }
            }
            return signingStatus;
        }
        
    /*
   * @method uploadFileinReviewScreen() 
   * 
   * @param docsStr {String} base64 - base64 string that represents the file
   * docsStr {String} filename - full file name with extension, i.e. 'products.pdf' 
   *   upload was successful(200) US 674749
   */
    @AuraEnabled
    public static integer uploadFileinReviewScreen(string docsStr) {
    
        DocumentQuestionClass docQsntClass = (DocumentQuestionClass)System.JSON.deserialize(docsStr, DocumentQuestionClass.class);
        Map<String,Object> sendDocParam = new Map<String,Object>();
        Map<String,String> documents = new Map<String,String>();
        sendDocParam.put('type', 'ReviewPageDoc');
        sendDocParam.put('documentType', String.isNotBlank(docQsntClass.docType) ? docQsntClass.docType : '');
        sendDocParam.put('oppName', String.isNotBlank(docQsntClass.dealName) ? docQsntClass.dealName.substringBefore(':') : '');
        sendDocParam.put('quoteName', String.isNotBlank(docQsntClass.dealName) ? docQsntClass.dealName.substringAfter(':') : '');
        
        for(UploadDocClass eachDoc : docQsntClass.uploadDocList){
            documents.put(eachDoc.filename, eachDoc.base64);
        }             
        sendDocParam.put('documents', documents);
        return RESTCalloutHelper.sendDocumentsToDCV(sendDocParam);      
    } 
    
    /*
     * This class is used by PB for sending list of inputs to invocable method for sending Unsigned Doc to DCV
  */    
    public class Request {
        @InvocableVariable(label='Quote ID' required=true)
        public ID quoteId;
        
        @InvocableVariable(label='Document Name' required=true)
        public String documentName;    
    } 
    
    
    /**
     * Inner class-selector
     */
    public without sharing class WoSSelector {
 
        private List<E_Sign_Information__c> getESignInfoListByQuoteId(Id quoteId,String docName) {
           
            
            String queryString = 'SELECT  Id, Status__c, UnSigned_Doc_Status__c,Customer_Email__c, LastModifiedDate, Date_Of_Signing__c, First_Email_Sending_Date__c, CreatedDate,'+
                ' Document_Type__c,Document_Name__c, Signer_Name__c, SSN_Number__c,Opportunity__r.Name,Quote__r.Name  FROM E_Sign_Information__c WHERE   Quote__c = :quoteId ';
            if(docName!=null){
                queryString = queryString+' and Document_Name__c=:docName ';  
            }
            
            queryString = queryString+'ORDER BY CreatedDate DESC';
           
            return Database.query(queryString); 
            
            
        }

        /**
        * SOQL to get the related Document_Questionnaire__c for a quoteid
        */
        private List<Document_Questionnaire__c> getDocumentQuestionaires(string quoteId){
            return [
                SELECT  id,Comment__c,Question_Name__c,Response__c,Reason_Code__c,Document_Type__c,
                        Quote__r.name,Quote__r.Opportunity.name 
                FROM    Document_Questionnaire__c 
                WHERE   Quote__c =:quoteId
            ];
        }

        private List<Contact> getAuthorizedSignatories(String opportunityId){
            return [
                SELECT  Id, Name, Authorized_signatory_Text__c, External_ID__c, Title
                FROM    Contact
                WHERE   AccountId IN (SELECT End_User__c FROM Opportunity WHERE Id = :opportunityId)
                AND     Role__c = :Constants.LEASE_SIGNER_CONTACT_ROLE        
            ];
        }

        /**
         * Method gets E_Sign_Information__c record by order Id.
         * 
         * @return E_Sign_Information__c record
         */
        public E_Sign_Information__c getESignInfo(Id eSignInfoId) {
            return [
                SELECT  Id, Name, Status__c, Quote__c,Quote__r.Name, Date_Of_Signing__c,Signer_Name__c, SSN_Number__c, ExpirationDate__c, Customer_Email__c,
                UnSigned_Doc_Status__c, Document_Type__c,Document_Name__c,iFrame_URL__c,  
                Opportunity__r.Name, Opportunity__r.End_User__c, Opportunity__r.End_User__r.Ultimate_Beneficial_Owner__c,
                Opportunity__r.End_User__r.Invoice_Type__c,Opportunity__r.End_User__r.People_ID__c,
                Opportunity__r.End_User__r.Reference__c,Opportunity__r.End_User__r.Email_Invoice__c,
                Opportunity__r.End_User__r.C_O_Name__c,Opportunity__r.End_User__r.ShippingPostalCode,
                Opportunity__r.End_User__r.ShippingStreet,Opportunity__r.End_User__r.ShippingCity,
                Opportunity__r.End_User__r.ShippingCountry, Quote__r.Reference__c   
                FROM    E_Sign_Information__c 
                WHERE   Id = :eSignInfoId
            ];
        }

        private List<ContentDocumentLink> getContentDocumentLinkByLinkedId(Id linkedId) {
            return [SELECT ContentDocumentId FROM ContentDocumentLink WHERE LinkedEntityId = :linkedId];
        }

        private List<ContentVersion> getContentVersionsByDocumentIds(List<Id> fileIDs,String docName ) {
           
              String queryString = 'SELECT  ContentDocumentId, FileExtension, Title, VersionData, Description, Document_Type__c'+
                ' FROM ContentVersion WHERE  ContentDocumentId IN : fileIDs';
            
             if(docName!=null){
                queryString = queryString+' AND Title =: docName';
            }
            
             queryString = queryString+' AND FileExtension=\'pdf\' AND IsLatest = TRUE';
           
            return Database.query(queryString);
            
        }

        /**
        * SOQL on the contact object to get the related contact for a particualr accountid
        */
        public List<Contact> getContacts(string accountid){
            return [
                SELECT id, name,FirstName,LastName,middleName, External_ID__c , Account.ShippingCountry
                FROM Contact 
                WHERE Role__c =: Constants.ULTIMATE_BENEFICIAL_OWNER_CONTACT_ROLE 
                AND Accountid =: accountid
            ];
        }

        private List<Contact> getContactsByIds(List<Id> deletedContactIds) {
            return [SELECT id from contact where id in: deletedContactIds];
        }
    }

    public class ContactWrapperClass{      
        public string contactName;       
        public string ssn; 
        public string orderId; 
        public string contactId;
        public boolean ultimateBenOwner;
    }
    
    public class EsignInfoClass{
        public string docType;
        public string docName;
        public string email;
        public string opptyId;
        public string quoteId;
        public string primaryProduct;
        public string primaryProductDesc;
    }

    public class DocumentQuestionClass{    
        @AuraEnabled  
        public string questionName;       
        @AuraEnabled
        public string response; 
        @AuraEnabled
        public string comment; 
        @AuraEnabled
        public string reasonCode; 
        @AuraEnabled
        public string docType; 
        @AuraEnabled
        public string dealName; 

        public list<UploadDocClass> uploadDocList; 

        public DocumentQuestionClass(string questionName,string response, string comment,string reasonCode,string docType,string dealName){
            this.questionName = questionName;
            this.response = response;
            this.comment = comment;
            this.reasonCode = reasonCode;
            this.docType = docType;
            this.dealName = dealName;
        }
    }

    public class UploadDocClass{

        public string filename;
        public string base64;
    }

    public class InvoiceDataWrapperClass{
        private string invoiceType;
        private string pepolIdValue;
        private string ediRefrenceValue;
        private string pdfEmailValue;
        private string pdfReferenceValue;
        private string letterCoNameValue;
        private string letterAdresValue;
        private string letterPoNumValue;
        private string letterCityValue;
        private string letterCountryValue;
        private string letterReferenceValue;
        private string orderId;
    }
}