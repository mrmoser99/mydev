/**
 * This class is used as trigger handler for Esign information object
 * 
 * Version 1.0 @author Elena Sokolova, Anujit Das @date 2021-07-02
 * 
 */
public with sharing class ESignInformationTriggerHandler extends TriggerHandler {
    
    private static Set<Id> oppOdsForPendingOrders;
    private static List<E_Sign_Information__c> newRecordsWithPendingStatus;
    
    public override void beforeInsert() {
        checkPossibilityToSendToSignature();
        findAodRecords();
    }

    public override void beforeUpdate() {
        checkPossibilityToSendToSignature();
        findAodRecords();
        updatedQuoteWithSignedContract();
    }
    
     /**
     * Method is called from before insert and update to check if there is already a quote with 'pending e-sign status'
     * check if there is already a matching email id and document type existing before creating an order
     */
    private static void checkPossibilityToSendToSignature() {
        // Set of Opportunity Ids for new/updated orders
        oppOdsForPendingOrders = new Set<Id>();
        // List of pending orders (with 'Pending_Contract', 'Active','New' statuses)
        newRecordsWithPendingStatus = new List<E_Sign_Information__c>();

        for (E_Sign_Information__c eSignInfoItem : (List<E_Sign_Information__c>) Trigger.new) {
            if (eSignInfoItem.Status__c == Constants.PENDING_CONTRACT_STATUS || eSignInfoItem.Status__c == Constants.ACTIVE_STATUS || eSignInfoItem.Status__c == Constants.NEW_STATUS) {
                oppOdsForPendingOrders.add(eSignInfoItem.Opportunity__c);
                newRecordsWithPendingStatus.add(eSignInfoItem);
            }
        }

        // get all existing orders by opportunity ids
        List<E_Sign_Information__c> existingPendingESignInfoByOppIds = new WoSSelector().getExistingESignInfoByOppIds();

        List<String> pendingStatuses = new List<String>{Constants.NEW_STATUS, Constants.PENDING_CONTRACT_STATUS, Constants.ACTIVE_STATUS};
        List<String> invalidStatuses = new List<String>{Constants.CANCELLED_STATUS, Constants.EXPIRED_STATUS, Constants.REJECTED_STATUS, Constants.FAILED_STATUS};

        for (E_Sign_Information__c eSignInfoItem : newRecordsWithPendingStatus) {
            for (E_Sign_Information__c existingESignInfoItem : existingPendingESignInfoByOppIds) {
                if (eSignInfoItem.Opportunity__c == existingESignInfoItem.Opportunity__c &&
                    eSignInfoItem.Quote__c != existingESignInfoItem.Quote__c &&
                    pendingStatuses.contains(existingESignInfoItem.Status__c)) {
                    eSignInfoItem.addError(String.format(
                        Label.E_Sign_Info_Error_Signing_Is_Pending_For_Another_Version,
                        new List<String>{existingESignInfoItem.Opportunity__r.Name, existingESignInfoItem.Quote__r.Name}
                    ));
                // user cannot create a new e-sign order for the same document and email for the same quote unless the previous one has been cancelled  
                } else if (eSignInfoItem.Quote__c == existingESignInfoItem.Quote__c &&
                            existingESignInfoItem.Customer_Email__c == eSignInfoItem.Customer_Email__c && 
                            existingESignInfoItem.Document_Type__c == eSignInfoItem.Document_Type__c &&
                            (!invalidStatuses.contains(existingESignInfoItem.Status__c)) &&
                            existingESignInfoItem.Id != eSignInfoItem.Id) {
                    eSignInfoItem.addError(String.format(
                        Label.E_Sign_Info_Error_Same_Document_Type_And_Email,
                        new List<String>{existingESignInfoItem.Customer_Email__c, existingESignInfoItem.Document_Type__c}
                    ));            
                }
            }
        }
    }

    /**
    * Method is used to check if there is any AOD records.
    * If a contract is successfully signed, then send mail to the AOD records customer mail.
    */
    private static void findAodRecords(){
       
        map<id,E_Sign_Information__c> quoteIdtoEsignInfoMap = new map<id,E_Sign_Information__c>();
        map<id,E_Sign_Information__c> quoteIdtoAodMap = new map<id,E_Sign_Information__c>();
        List<E_Sign_Information__c> existingNonPendingAodRecords = new List<E_Sign_Information__c>();
        List<Document_Questionnaire__c> docQuestionList = new List<Document_Questionnaire__c>();
        
        for (E_Sign_Information__c eSignInfoItem : (List<E_Sign_Information__c>) Trigger.new) {
            //when one of the contract is gettin completed
             if(eSignInfoItem.Document_Type__c.equalsIgnorecase(Constants.CONTRACT_DOCUMENT_TYPE) && eSignInfoItem.Status__c.equalsIgnorecase(Constants.COMPLETE_STATUS)){ //if one of the document type = contract is signed/completed               
                quoteIdtoEsignInfoMap.put(eSignInfoItem.Quote__c,eSignInfoItem);               
             }
             //Option1 : Only for E-sign, not for wetsign
             //update the AOD record status to 'NEW'(skip 'pending contract') when there is already contract is signed completed. only for E-sign case
              //Option2 : Only for wetsign, not for e-sign (contract type document doesnt exist in sfdc)
             //if any of the AOD document type is not 'Pending contract', then make all susbequesnt AOD doc as New
             if(eSignInfoItem.Document_Type__c.equalsIgnorecase(Constants.AOD_DOCUMENT_TYPE) && eSignInfoItem.Status__c.equalsIgnorecase(Constants.PENDING_CONTRACT_STATUS)){ 
                quoteIdtoAodMap.put(eSignInfoItem.Quote__c,eSignInfoItem);
             }
        }
                
        if(quoteIdtoEsignInfoMap.size() > 0){
            List<E_Sign_Information__c> existingAodRecords = new WoSSelector().getExistingOrdersByQuoteId(quoteIdtoEsignInfoMap.keySet(),Constants.AOD_DOCUMENT_TYPE,Constants.PENDING_CONTRACT_STATUS);
            updateAodRecords(existingAodRecords,quoteIdtoEsignInfoMap);
        }

        if(quoteIdtoAodMap.size() > 0){
            List<E_Sign_Information__c> existingContractRecords = new WoSSelector().getExistingOrdersByQuoteId(quoteIdtoAodMap.keySet(),Constants.CONTRACT_DOCUMENT_TYPE,Constants.COMPLETE_STATUS);          
            //List<Document_Questionnaire__c> docQuestionList = new WoSSelector().getExistingDocQuesInfo(quoteIdtoAodMap.keySet(),Constants.QUESTION_WET_CONTRACT,Constants.DOC_YES);
            //if there is no contract document type record, then it is a wet-sign
            if(existingContractRecords.size() == 0){
                existingNonPendingAodRecords = new WoSSelector().getExistingNonPendingAODRecs(quoteIdtoAodMap.keySet(),Constants.AOD_DOCUMENT_TYPE,Constants.PENDING_CONTRACT_STATUS);          
            }
            for(E_Sign_Information__c eachEsignItem : quoteIdtoAodMap.values()){
               
                if(existingContractRecords.size() > 0){
                    eachEsignItem.Status__c = Constants.NEW_STATUS; 
                    eachEsignItem.Contract_Signer_Name__c =	existingContractRecords[0].Signer_Name__c;
                }else if(existingContractRecords.size() == 0 && existingNonPendingAodRecords.size() > 0){ //if there is no existing contract & any AOD doc type records that is not in 'pending contract' status
                    eachEsignItem.Status__c = Constants.NEW_STATUS;
                }
            }
            
            //if there is no existing pending AOD records only then Document questioniare will be queried.
            if(existingNonPendingAodRecords == null){
                docQuestionList = new WoSSelector().getExistingDocQuesInfo(quoteIdtoAodMap.keySet(),Constants.QUESTION_WET_CONTRACT,Constants.DOC_YES);
            }
            
            //if size of doc list is greater than 0 then check if the quote Id exists in AOD map, if so then update status to NEW.
            if(docQuestionList.size() > 0){
                for(Document_Questionnaire__c eachDocItem : docQuestionList){
                    if(quoteIdtoAodMap.containskey(eachDocItem.Quote__c)){
                        quoteIdtoAodMap.get(eachDocItem.quote__c).Status__c = Constants.NEW_STATUS;
                    }
                }
            }
        }
    }

    /**
     * Method is used to update the status of AOD records to new
     * 
     */
    private static void updateAodRecords(List<E_Sign_Information__c> existingAodRecords,map<id,E_Sign_Information__c> quoteIdtoEsignInfoMap){

        for(E_Sign_Information__c eachEsign : existingAodRecords){
            eachEsign.Status__c = Constants.NEW_STATUS; //update to new from 'pending contract'\
            eachEsign.Contract_Signer_Name__c = quoteIdtoEsignInfoMap.get(eachEsign.Quote__c).Signer_Name__c;
            eachEsign.AOD_Exists__c = True;
        }

        new GenericUtilityClass.WoSDMLProcessor().updateRecords(existingAodRecords); //DML on e-sign information object
    }

    /**
     * Method is used to update the quote status to Pending Validation
     * when first Contract is signed 
     */
    private static void updatedQuoteWithSignedContract() {
        Set<Id> newQuotesWithCompleteContract = new Set<Id>();
        Set<Id> quotesWithCompleteContract = new Set<Id>();
        Set<Id> quotesIdToUpdate = new Set<Id>();

        for (E_Sign_Information__c eSignInfoItem : (List<E_Sign_Information__c>) Trigger.new) {
            if (eSignInfoItem.Status__c == Constants.COMPLETE_STATUS && eSignInfoItem.Document_Type__c == Constants.CONTRACT_DOCUMENT_TYPE) {
                newQuotesWithCompleteContract.add(eSignInfoItem.Quote__c);
            }
        }

        List<E_Sign_Information__c> signedContractsByQuoteIds = new WoSSelector().getExistingOrdersByQuoteId(newQuotesWithCompleteContract,Constants.CONTRACT_DOCUMENT_TYPE,Constants.COMPLETE_STATUS);

        for (E_Sign_Information__c eSignInfoItem : signedContractsByQuoteIds) {
            quotesWithCompleteContract.add(eSignInfoItem.Quote__c);
        }

        for (Id quoteId : newQuotesWithCompleteContract) {
            if (!quotesWithCompleteContract.contains(quoteId)) {
                quotesIdToUpdate.add(quoteId);
            }
        }

        updateQuotesWithPendingValidationStatus(quotesIdToUpdate);
    }

    /**
     * Method is used to update the quote status to Pending Validation
     * 
     * This logic runs Synced Quote Flow from Quote PB. The Opportunity SuncedQuote field, 
     * which is updated in this flow, is read only within the trigger,
     * so we update quotes in future method to avoid exception.
     */
    @future
    private static void updateQuotesWithPendingValidationStatus(Set<Id> quoteIds) {
        List<Quote> quotesToUpdate = new List<Quote>();

        for (Id quoteId : quoteIds) {
            quotesToUpdate.add(new Quote(Id = quoteId, Status = Constants.QUOTE_PENDING_VALIDATION_STATUS));
        }

        update quotesToUpdate;
    }

    /**
     * Inner class-selector
     */
    public without sharing class WoSSelector {

        /**
        * Method is used to query existing esign information records under the quote
        * 
        * @return list of E_Sign_Information__c
        */
        @TestVisible
        private List<E_Sign_Information__c> getExistingOrdersByQuoteId(set<id> quoteIdSet,string documentType, string status) {
            return [SELECT id,Customer_Email__c,Status__c,Signer_Name__c,Quote__c, AOD_Exists__c
                    FROM E_Sign_Information__c WHERE Quote__c in: quoteIdSet 
                    AND Document_Type__c =:documentType 
                    AND Status__c =:status
                   	ORDER BY LastModifiedDate ASC];
        }

        /**
        * Method is used to query existing esign information records under the opportunity
        * 
        * @return E_Sign_Information__c list
        */
        private List<E_Sign_Information__c> getExistingESignInfoByOppIds() {
            return [
                SELECT  Id, Status__c, Quote__c, Quote__r.Name, Opportunity__c, Opportunity__r.Name, Customer_Email__c, Document_Type__c
                FROM    E_Sign_Information__c
                WHERE   Opportunity__c IN :oppOdsForPendingOrders
            ];
        } 
        
        /**
        * Method is used to query existing document questionaire records under the quote
        * 
        * @return Document_Questionnaire__c list
        */
       private List<Document_Questionnaire__c> getExistingDocQuesInfo(Set<id> quoteIdSet, String Question, String Response) {
            return [
                SELECT  Id, Question_Name__c, Quote__c, Response__c
                FROM    Document_Questionnaire__c
                WHERE   Quote__c IN :quoteIdSet AND Question_Name__c =: Question AND Response__c =: Response
            ];
        }
        
        /**
        * Method is used to query existing esign information records under the quote
        * 
        * @return list of E_Sign_Information__c according to list of status 
        */
        private List<E_Sign_Information__c> getExistingNonPendingAODRecs(set<id> quoteIdSet,string documentType, string status) {
            return [SELECT id,Customer_Email__c,Status__c,Signer_Name__c,Quote__c
                    FROM E_Sign_Information__c WHERE Quote__c in: quoteIdSet 
                    AND Document_Type__c =:documentType 
                    AND Status__c !=: status 
                   	ORDER BY LastModifiedDate ASC];
        }
    }
}