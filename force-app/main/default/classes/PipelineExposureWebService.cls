/**
 * Class implements REST webservice for getting information about opportunities (amount) by the customer id
 * Example: https://host/services/apexrest/account/00102000006TaohAAC
 * 
 * Version 1.0 @author Elena Sokolova @date 2021-02-25
 * Version 1.1 @author Neha Tyagi @date 2021-03-12 
 */
@RestResource(urlMapping='/financialrisks/*')
global with sharing class PipelineExposureWebService {

    /**
     * Name: getQuoteAmountByCustomerId
     * Purpose : Method is a custom REST API call. It’s annotated with @HttpGet and is invoked for a GET request.
     * It returns the pendingOpportunitiesAmount & approvedOpportunitiesAmount as response body.
     */
    @HttpGet
    global static void getQuoteAmountByCustomerId() {
        // Get access to the request
        RestRequest request = RestContext.request;
        // Represents an object used to pass data from an Apex RESTful Web service method to an HTTP response
        RestResponse response = RestContext.response;
        // get the customer Id from the end of the URL
        String customerId = (string) request.requestURI.substring(request.requestURI.lastIndexOf('/') + 1);
    
        // check if an account Id is not empty and an account with this Id exists
        if (String.isNotEmpty(customerId) && !(new WoSSelector().getAccountsByExternalId(customerId).isEmpty())) {
            
            // get quotes with this customer
            List<Quote> quoteList = new WoSSelector().getQuotesByCustomerId(customerId);
         	QuoteAmountWrapper quoteAmount;
           
            // return empty array if opportunities with pending/approved amount are not found   
            if (!quoteList.isEmpty()) { 
                
                Map<Id,Decimal> maxApprovedAmounts = new Map<Id,Decimal>();
                Map<Id,Decimal> maxReferAmounts = new Map<Id,Decimal>();
                Decimal approvedOpportunitiesAmount = 0.0;
            	Decimal pendingOpportunitiesAmount = 0.0;
                
                for (Quote quote: quoteList) {
                    //search for maximum Finance Amount for each opportunity with Approved Status
                    if (quote.Status == Constants.QUOTE_APPROVED_STATUS || quote.Status == Constants.QUOTE_APPROVED_WITH_CON_STATUS || 
                        quote.Status == Constants.QUOTE_DOCUMENT_GEN_STATUS || quote.Status == Constants.QUOTE_PENDING_DOCUMENT_STATUS || 
                        quote.Status == Constants.QUOTE_PENDING_VALIDATION_STATUS || quote.Status == Constants.QUOTE_PENDING_INFO_STATUS || 
                        quote.Status == Constants.QUOTE_PENDINGESIGN_STATUS || quote.Status == Constants.QUOTE_PENDING_REVIEW_STATUS || 
                        quote.Status == Constants.QUOTE_BLOCKED_DUE_TO_MULTIPLE_PG_STATUS) {
                        if (maxApprovedAmounts.containsKey(quote.OpportunityId)) {
                            if (maxApprovedAmounts.get(quote.OpportunityId) < quote.Financed_Amount__c) {
                                approvedOpportunitiesamount += quote.Financed_Amount__c - maxApprovedAmounts.get(quote.OpportunityId);
                                maxApprovedAmounts.put(quote.OpportunityId,quote.Financed_Amount__c);    
                            }  
                        } else {
                            approvedOpportunitiesamount += quote.Financed_Amount__c;
                            maxApprovedAmounts.put(quote.OpportunityId,quote.Financed_Amount__c);
                        }
                    }
                    //search for maximum Finance Amount for each opportunity with Refer Status
                    else if (quote.Status == Constants.QUOTE_REFER_STATUS || quote.Status == Constants.QUOTE_ASSESSMENT_STATUS) {
                        if (maxReferAmounts.containsKey(quote.OpportunityId)) {
                            if (maxReferAmounts.get(quote.OpportunityId) < quote.Financed_Amount__c) {
                                pendingOpportunitiesAmount += quote.Financed_Amount__c - maxReferAmounts.get(quote.OpportunityId);
                                maxReferAmounts.put(quote.OpportunityId,quote.Financed_Amount__c);
                            }  
                        } else {
                            pendingOpportunitiesAmount += quote.Financed_Amount__c;
                            maxReferAmounts.put(quote.OpportunityId,quote.Financed_Amount__c);
                        }
                    }   
                }                     
               quoteAmount = new QuoteAmountWrapper(pendingOpportunitiesAmount, approvedOpportunitiesAmount);  
            }  
            response.statusCode = 200;  
            response.responseBody= ( quoteAmount != null) ? Blob.valueOf(JSON.serialize(quoteAmount)) : Blob.valueOf(JSON.serialize(new QuoteAmountWrapper(0.0, 0.0)));  

        } else {
            response.statusCode = 404;  
            response.responseBody= Blob.valueof(JSON.serialize('No Account Found.'));
        }       
    }
 
    // inner class-selector
    public without sharing class WoSSelector {

        /**
         * Name : getQuotesByCustomerId
         * Purpose : query the quotes with customer id
         */         
         private List<Quote> getQuotesByCustomerId(String customerId) {
            return [
            SELECT       OpportunityId, Financed_Amount__c, Status  
            FROM         Quote
            WHERE        Opportunity.End_User__r.External_Identifier__c = :customerId
                AND      Status IN (
                            :Constants.QUOTE_REFER_STATUS,
                            :Constants.QUOTE_ASSESSMENT_STATUS ,
                    		:Constants.QUOTE_APPROVED_STATUS,
                    		:Constants.QUOTE_APPROVED_WITH_CON_STATUS,
                    		:Constants.QUOTE_DOCUMENT_GEN_STATUS,
                    		:Constants.QUOTE_PENDING_DOCUMENT_STATUS,
                    		:Constants.QUOTE_PENDING_VALIDATION_STATUS,
                    		:Constants.QUOTE_PENDING_INFO_STATUS,
                    		:Constants.QUOTE_PENDINGESIGN_STATUS,
                    		:Constants.QUOTE_PENDING_REVIEW_STATUS,
                    		:Constants.QUOTE_BLOCKED_DUE_TO_MULTIPLE_PG_STATUS
                                )
            ];     
        }
        
        
        /**
         * Name : getAccountsByExternalId
         * Purpose : get Account list by External Id
         */
        private List<Account> getAccountsByExternalId(String customerId) {
            return [SELECT Id FROM Account WHERE External_Identifier__c =: customerId];
        }
    }

    /**
    * Name : QuoteAmountWrapper
    * Purpose : Wrapper class for response body
    */            
    public class QuoteAmountWrapper{
        public Decimal pendingOpportunitiesAmount;
        public Decimal approvedOpportunitiesAmount;
            
        public QuoteAmountWrapper(Decimal pendingOpportunitiesAmount, Decimal approvedOpportunitiesAmount) {
            this.pendingOpportunitiesAmount = pendingOpportunitiesAmount;
            this.approvedOpportunitiesAmount = approvedOpportunitiesAmount;
            }
        }  
}