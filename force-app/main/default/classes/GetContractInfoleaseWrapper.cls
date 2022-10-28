/**************************************************************************************************
Info- This Wrapper class is created to map the fields from Infolease and Salesforce fields

PBI:475643,357157
Author - Geetha Bharadwaj
Date - 02/10/2021
***************************************************************************************************/

public class GetContractInfoleaseWrapper {
    
    @AuraEnabled public String contactName{get;set;}
    @AuraEnabled public String phoneNumber{get;set;}
    @AuraEnabled public String customerName{get;set;}
    @AuraEnabled public String sourceSystemId{get;set;}
    @AuraEnabled public String applicationNumber{get;set;}
    @AuraEnabled public String delinquencyStatus{get;set;}
    @AuraEnabled public String leadDays{get;set;}
    @AuraEnabled public Decimal paymentAmount{get;set;}
    @AuraEnabled public Integer renewalterminMonths{get;set;}
    @AuraEnabled public Integer termInMonths{get;set;}
    @AuraEnabled public string terminationDate{get;set;}
    @AuraEnabled public Integer timesDelinquent{get;set;}
    @AuraEnabled public Decimal totalDueAmount{get;set;}
    @AuraEnabled public Decimal totalPastDueAmount{get;set;}
    
    @AuraEnabled public Boolean jan{get;set;}
    @AuraEnabled public Boolean feb{get;set;}
    @AuraEnabled public Boolean mar{get;set;}
    @AuraEnabled public Boolean apr{get;set;}
    @AuraEnabled public Boolean may{get;set;}
    @AuraEnabled public Boolean jun{get;set;}
    @AuraEnabled public Boolean jul{get;set;}
    @AuraEnabled public Boolean aug{get;set;}
    @AuraEnabled public Boolean sep{get;set;}
    @AuraEnabled public Boolean oct{get;set;}
    @AuraEnabled public Boolean nov{get;set;}
    @AuraEnabled public Boolean dec{get;set;}

    @AuraEnabled public Integer statusCode{get;set;}
    @AuraEnabled public string statusMessage{get;set;}
    
}