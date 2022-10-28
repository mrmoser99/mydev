/**
 * Created by samuelmeyers on 12/31/18.
 * @update: Updated by Traction Team on 04/22/2020
 * 			Added Region and Legal_Entity_Description logic (345304)
 * 
 */

global class AccountUpdateBatch implements Database.Batchable<sObject>{

    global final String query;

    global AccountUpdateBatch(String q){
        this.query = q;
    }

    global Database.QueryLocator start(Database.BatchableContext BC){
        return Database.getQueryLocator(this.query);
    }

    global void execute(Database.BatchableContext BC, List<sObject> scope){
        if(scope != null && scope.size() > 0){
            List<Account_Business_Unit_Mapping__c> accBUs = (List<Account_Business_Unit_Mapping__c>) scope;
            Map<Id, Account> accById = new Map<Id, Account>();

            for(Account_Business_Unit_Mapping__c accBU : accBUs){
                Account acc = accById.get(accBU.Account__c);
                if(acc == null){
                    acc = new Account(Id = accBU.Account__c);
                }
                if(accBU.Digital_Imaging__c){
                    acc.Digital_Imaging__c = true;
                }
                if(accBU.CleanTech__c){
                    acc.CleanTech__c = true;
                }
                if(accBU.Commercial_Finance__c){
                    acc.Commercial_Finance__c = true;
                }
                if(accBU.CT_and_I__c){
                    acc.CT_and_I__c = true;
                }
                if(accBU.Healthcare__c){
                    acc.Healthcare__c = true;
                }
                if(accBU.Technology_Solutions__c){
                    acc.Technology_Solutions__c = true;
                }
                if(accBU.Food_and_Ag__c){
                    acc.Food_and_Ag__c = true;
                }
                //PBI:446085:Account Business Unit Mapping: Golf and Turf:Added Golf_and_Turf__c to set to true:Geetha
                if(accBU.Golf_and_Turf__c){
                    acc.Golf_and_Turf__c = true;
                }
                if(String.isNotBlank(accBU.Legal_Entity_Description__c)){
                    acc.Legal_Entity_Description__c = accBU.Legal_Entity_Description__c;
                }
                if(String.isNotBlank(accBU.Region_Description__c)){
                    acc.Region_Description__c = accBU.Region_Description__c;
                }
                if(String.isNotBlank(accBU.Region_SFDC_ID__c)){
                    acc.Region_Relationship__c = accBU.Region_SFDC_ID__c;
                }

                accById.put(acc.Id, acc);
            }

            update accById.values();
            delete accBUs;
        }
    }

    global void finish(Database.BatchableContext BC){
        System.debug('Account Business Units Updated');
    }
}