/**
 * Created by samuelmeyers on 12/31/18.
 */

global class OpportunityMatchUpdateBatch implements Database.Batchable<sObject>{

    global final String query;

    global OpportunityMatchUpdateBatch(String q){
        this.query = q;
    } 

    global Database.QueryLocator start(Database.BatchableContext BC){
        return Database.getQueryLocator(this.query);
    }

    global void execute(Database.BatchableContext BC, List<sObject> scope){
        if(scope != null && scope.size() > 0){
            List<Opportunity> oppsWithMatches = (List<Opportunity>) scope;
            List<Opportunity> oppsToDelete = new List<Opportunity>();
            Map<Id, Opportunity> matches = new Map<Id, Opportunity>();

            for(Opportunity opp : oppsWithMatches){
                if(opp.Existing_Match__c != null){
                    if(!opp.Existing_Match__r.isDeleted){
                        Opportunity match = new Opportunity();
                        match.Id = opp.Existing_Match__c;
                        match.AccountId = opp.AccountId;
                        match.End_User__c = opp.End_User__c;
                        match.Sales_Rep_ID__c = opp.Sales_Rep_ID__c;
                        match.Sales_Rep_Name__c = opp.Sales_Rep_Name__c;
                        match.Amount = opp.Amount;
                        match.UNQ_Opportunity__c = opp.UNQ_Opportunity__c;
                        match.Application_Date__c = opp.Application_Date__c;
                        //match.Vendor_Program__c = opp.Vendor_Program__c;
                        match.Risk_Grade__c = opp.Risk_Grade__c;
                        match.StageName = opp.StageName;
                        match.Purchase_Option__c = opp.Purchase_Option__c;
                        match.Source_System__c = opp.Source_System__c;
                        match.Application_Approval_Date__c = opp.Application_Approval_Date__c;
                        match.Funded_Date__c = opp.Funded_Date__c;
                        //match.End_User_Phone__c = opp.End_User_Phone__c;
                        //PBI:446238:Update OpportunityMatchUpdateBatch to correct field mapping:Geetha
                        match.Sub_Stage__c = opp.Sub_Stage__c;
                        match.Program__c = opp.Program__c;
                        //PBI:507338: New fields added to update existing manual opp
                        match.UNQ_Customer__c = opp.UNQ_Customer__c;
                        match.UNQ_Program__c = opp.UNQ_Program__c;
                        match.Business_Unit__c = opp.Business_Unit__c;
                        match.Application_Number__c = opp.Application_Number__c; 
                        match.Business_Unit_Description__c = opp.Business_Unit_Description__c; 
                        match.CloseDate = opp.CloseDate;
                        match.Contract__c = opp.Contract__c;
                        match.Customer_Code__c = opp.Customer_Code__c; 
                        match.End_User_Company_Name__c = opp.End_User_Company_Name__c; 
                        match.Legal_Entity_Description__c =  opp.Legal_Entity_Description__c;
                        match.Region_Relationship__c = opp.Region_Relationship__c; 
                        match.Region_Description__c = opp.Region_Description__c;
                        match.Sales_Rep_ID_2__c = opp.Sales_Rep_ID_2__c;
                        match.Sales_Rep_Name_2__c = opp.Sales_Rep_Name_2__c; 
                        match.UNQ_Vendor__c = opp.UNQ_Vendor__c;
                        match.Vendor_ID__c = opp.Vendor_ID__c;
                        
                        matches.put(match.Id, match);
                        oppsToDelete.add(opp);
                    }else{
                        opp.Existing_Match__c = null;
                        matches.put(opp.Id, opp);
                    }
                }
            }
            //Flipped the logic to delete first and then update 
            //PBI:507338:Error in Opportunity Match Update Batch - Merge Opportunity Batch Failed - Root Cause UNQ_Opportunity is Unique field now
           
            if(oppsToDelete.size() > 0){
                delete oppsToDelete;
            }
            
            if(matches.size() > 0){
                update matches.values();
            }
        }
    }

    global void finish(Database.BatchableContext BC){
        System.debug('Matching Opportunities Consolidated');
    }
}