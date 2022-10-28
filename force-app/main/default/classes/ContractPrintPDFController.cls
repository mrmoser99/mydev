/********
* This class is built to Print the Contract/Portfolio information in PDF Format.
* In Portfolio view - Generate/PrintPDF in DLL on Demand
* Author:Geetha Bharadwaj
*/

public class ContractPrintPDFController {
    
    public class contractWrapper{
        @AuraEnabled public contract__c contract{get;set;}
        @AuraEnabled public List<asset__c> assetList{get;set;}
    }
    
    @AuraEnabled
    public static contractWrapper getContractsAssets(String recordId){
         List<contract__c> conlist = [SELECT Name, End_user__r.AccountNumber, End_user__r.BillingAddress, Contract_Start_Date__c,
                                      Maturity_Date__c,Days_Deliquent__c,Payments_Remaining__c,Finance_Type__c,Status_Text__c,
                                      Payment_Amount__c,Service_Payment__c,Signer__c,End_user__r.Name,Purchase_Option__c,
                                      Contract_Term_months__c,
                                      (select id, Name, Asset_Brand_Make__c, Asset_Model__c, Asset_Serial_Number__c, 
                                       Asset_City_Install_Address__c,Asset_Install_Address_Line_1__c,Install_Date__c, Asset_Status__c from Assets__r)
                                      FROM Contract__c where id = :recordId limit 1];
        
        contractWrapper wrap = new contractWrapper();
        if(conlist.size() >0){
            for(contract__c con:conlist){
                wrap.contract = con;
                wrap.assetList = con.assets__r;
            }
        }
        system.debug('wrap = ' +wrap);
        return wrap;
    }
   
}