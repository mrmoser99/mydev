/**
 * This class is used as apex controller for Nordics Email Templates
 * 
 * Version 1.0 @author Ravisha Chugani @date 09-12-2021
 * 
 */
public with sharing class NordicsEmailController {  
        
        public Id accountId {get;set;}
    	public Id quoteId {get;set;}
        
        /**
        * Method is called from VisualForce Component to get and display authorized signees in email template.
        * 
        * @return Contact list
        */
        public List<Contact> getContactList(){
            
            List<Contact> ContactList = [SELECT Name, External_ID__c FROM Contact WHERE Role__c =: Constants.LEASE_SIGNER_CONTACT_ROLE AND Accountid =: accountId];  
            return ContactList;   
        }
                
        /**
        * Method is called from VisualForce Component to get and display personal gaurantee in email template.
        * 
        * @return Related_Party__c list
        */
        public List<Related_Party__c> getRelatedPartyList(){
             return [SELECT Id, Name, Amount__c, Type_Code__c, Quote__r.Type_downpayment__c,External_Id__c,
                    Quote__r.Value_downpayment__c, Quote__r.Value_term__c
                    FROM Related_Party__c 
                    WHERE Quote__c =: quoteId
                    ];
         } 
    
        /**
        * Method is called from VisualForce Component to get and display Quote details in email template.
        * This query will run only when there is no related parties.
        * 
        * @return Quote list
        */
        public Quote getQuoteList(){
             return [SELECT Name, Type_downpayment__c, Value_downpayment__c, Value_term__c
                    FROM Quote 
                    WHERE Id =: quoteId
                    ];
         }
    	
    	/**
        * Method is called from VisualForce Component to display related party and quote information in email template.
        * 
        * @return outputValue 
        */
        public String getOutputValue(){
            
            String outputValue = '';
            List<Related_Party__c> relatedParty = getRelatedPartyList();
            Quote quote = new Quote();
            
            if(relatedParty.size() == 0){
            	 quote = getQuoteList();       
            }
            
            if(relatedParty.size() != 0){ 
                for(Related_Party__c eachRelatedParty : relatedParty){
                    
                    if(eachRelatedParty.Amount__c != null){ 
                        outputValue += Constants.SEN1  + ' ' + eachRelatedParty.Name  + ' ' + Constants.SEN2  + ' ' + eachRelatedParty.External_Id__c  + ' ' + Constants.SEN3 + ' ' + eachRelatedParty.Amount__c  + ' ' + Constants.SEN4 +'. \n';     
                    }
                    if(eachRelatedParty.Amount__c == null){
                        outputValue += Constants.SEN1  + ' ' + eachRelatedParty.Name  + ' ' + Constants.SEN2  + ' ' + eachRelatedParty.External_Id__c +'. \n'; 
                    }
                    if(eachRelatedParty.Type_Code__c == Constants.COMPANY){
                        outputValue += Constants.SEN1 + ' '  + eachRelatedParty.Name  + ' ' + Constants.SEN5  + ' ' + eachRelatedParty.External_Id__c +'. \n';     
                    }         
                } 
            }
    		
            if(relatedParty.size() > 0 && relatedParty[0].Quote__r.Value_downpayment__c != null){
                outputValue +=  Constants.SEN6  + ' ' + relatedParty[0].Quote__r.Type_downpayment__c   + '. ' + Constants.SEN3 + 
                          ' ' + relatedParty[0].Quote__r.Value_downpayment__c  + ' ' +  Constants.SEN4 +'. \n'; 
            }
            else if(quote.Value_downpayment__c != null){
                 outputValue +=  Constants.SEN6  + ' ' + quote.Type_downpayment__c   + '. ' + Constants.SEN3 + ' ' +
                        quote.Value_downpayment__c + ' ' + Constants.SEN4 +'. \n';  
                
            }
            
            if(relatedParty.size() > 0 && relatedParty[0].Quote__r.Value_term__c != null ){
                outputValue +=  Constants.SEN7  + ' ' + relatedParty[0].Quote__r.Value_term__c   + ' ' + Constants.SEN8 + '.';
            }
            else if(quote.Value_term__c != null){
                outputValue +=  Constants.SEN7  + ' ' + quote.Value_term__c   + ' ' + Constants.SEN8 + '.';
            }
            
            return outputValue;
            
        }
    
}