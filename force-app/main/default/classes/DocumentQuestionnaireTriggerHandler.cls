/**
 * This class is used as trigger handler for Document Questionnaire object
 * 
 * Version 1.0 @author - Ravisha Chugani @date 23-11-2021
 * 
 */
public with sharing class DocumentQuestionnaireTriggerHandler extends TriggerHandler{
    
    private static Set<Id> quoteIds;
    private static List<Document_Questionnaire__c> newRecordsWithYesResponse;
    private static Set<Id> quoteIdsWithContractDoc;
    
    public override void beforeInsert() {
        updateEsignAODStatus();
    }

    public override void beforeUpdate() {
        updateEsignAODStatus();
    }
       
    /**
     * Method is called from before insert and update to check if there is a document type contract or not. 
     * If not then it will check for wet signed question is there and if it is then in the esign record 
     * with AOD document type, the status is changed to NEW from Pending Contract. 
     */
    @TestVisible
    private static void updateEsignAODStatus() {
        // Set of quote Ids for new/updated document questionaires
        quoteIds = new Set<Id>();
        
        quoteIdsWithContractDoc  = new Set<Id>();
            
        // List of document questionaires with yes response
        newRecordsWithYesResponse = new List<Document_Questionnaire__c>();
        
        List<E_Sign_Information__c> eSignAODPendingStatusRecord = new  List<E_Sign_Information__c>();
        
        for (Document_Questionnaire__c docQuesItem : (List<Document_Questionnaire__c>) Trigger.new) {
            if (docQuesItem.Response__c == Constants.DOC_YES && docQuesItem.Question_Name__c == System.Label.Contract_Certified_as_Complete) {
                quoteIds.add(docQuesItem.Quote__c);
                newRecordsWithYesResponse.add(docQuesItem);
            }
        }
        
        List<E_Sign_Information__c> esignRecords = new WoSSelector().getEsignRecordsByQuoteId(quoteIds);
        for(E_Sign_Information__c eachEsign : esignRecords){
            
            //checks if document is AOD and status is pending contract
            if(eachEsign.Document_Type__c == Constants.AOD_DOCUMENT_TYPE &&  eachEsign.Status__c == Constants.PENDING_CONTRACT_STATUS){
                eSignAODPendingStatusRecord.add(eachEsign);
            }
            //checks if document is contract and returns if true
            else if(eachEsign.Document_Type__c == Constants.CONTRACT_DOCUMENT_TYPE){
                quoteIdsWithContractDoc.add(eachEsign.Quote__c);
                return;
            }  
        }
        
        //updates AOD status to NEW when no Contract record is there.
        if(eSignAODPendingStatusRecord.size() > 0){
            for(E_Sign_Information__c eSignInfo : eSignAODPendingStatusRecord){
                if(!quoteIdsWithContractDoc.contains(eSignInfo.Quote__c)){
                  eSignInfo.Status__c = Constants.NEW_STATUS;//update to New from 'pending contract'
                }
            }
            new GenericUtilityClass.WoSDMLProcessor().updateRecords(eSignAODPendingStatusRecord); //DML on e-sign information object
        }               
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
        private List<E_Sign_Information__c> getEsignRecordsByQuoteId(set<id> quoteIdSet) {
            return [SELECT id,Customer_Email__c,Status__c,Signer_Name__c,Quote__c,Document_Type__c 
                    FROM E_Sign_Information__c WHERE Quote__c in: quoteIdSet 
                   	ORDER BY LastModifiedDate ASC];
        }    
    }
}