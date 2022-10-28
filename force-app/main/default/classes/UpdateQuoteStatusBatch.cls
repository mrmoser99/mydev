/**
 * Batch job to update Quote Status based on related Rate and Offer records validity.
 * Author: Alexey(Cognizant)
 */
public class UpdateQuoteStatusBatch implements Database.Batchable<sObject> {

    private static final String CALCULATION_STATUS = 'Calculation';
    private static final String CALCULATION_EXPIRED_STATUS = 'Calculation Expired';

    public Database.QueryLocator start(Database.BatchableContext bc) {
        return Database.getQueryLocator('SELECT Id, Status FROM Quote WHERE Status = \'' +  CALCULATION_STATUS  
            + '\' AND (Quote_Rate__r.Valid_Until__c <= TODAY OR Applicable_Offers__r.Offer__r.Valid_Until__c <= TODAY)');
    }

    public void execute(Database.BatchableContext bc, List<Quote> quotesToUpdate){
        for (Quote quote : quotesToUpdate) {
            quote.Status = CALCULATION_EXPIRED_STATUS;            
        }
        //DML on quotes
        update quotesToUpdate;
    }

    public void finish(Database.BatchableContext bc){
    
    }
}